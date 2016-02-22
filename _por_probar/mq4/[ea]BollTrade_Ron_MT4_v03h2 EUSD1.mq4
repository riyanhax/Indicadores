//+------+
//|BollTrade
//+------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

//3g - added refreshrates in order close sections matching the order open sections
//3g - changed CurrTime in logwrite() to gregorian format
//3g - changed TradeComment and MagicNumber
//3g - changed logging and logerrs default to true 
//3g - added logwrite of blank line when opening orders to create visual seperation in log
//3g - added logwrite of data excursions outside upper and lower bollinger bands
//3g - cleaned up some blank line spacing
//3g - added halfPip variable, but not using it just yet
//3h - changed LossLimit to 39(+1) and BDistance to 14(-1)
//3h - added 500mS delay after order errors
//3h - added Compounding to increase orders as peak rises. (Wow!)
//3h - no longer using TradeAllowed on a per-bar basis
//3h - no longer using OnlyOneOrder
//3h - removed halfpip
//3h - added Comment to tell the EA is alive

/*v3h2 is v3h with absolutely nothing changed but the addition of Volume

Let me know how it compares to v3h

Ron


At 11:04 PM 10/15/2006, Ash Woods wrote:



Ron:

As I already wrote, I think that is a wise decision... From reading Ben's posts about volume, it just might be the only modification the EA needs to be significantly more profitable, and I would like to be able to test a version that is basically the same as v3h but with just that addition (and maybe a few bug fixes, etc).

But I'm not actually writing just to pat you on the back; I was thinking that if you do end up putting in something to avoid trading the news, it should be something like what Abhi posted:  We should use a DLL to get the exact time of news announcements for the given currency, and get out of the market just at those times....

I have not looked into Abhi's code yet, but was excited to see his post because it looks like he's doing just what I was about to do.  A generic library that one could use to tell any EA when there is news would be very useful....

-Derk */


// user input
extern double ProfitMade   =       8;    // how much money do you expect to make
extern double LossLimit    =      39;    // how much loss can you take
extern bool   Compounding  =   false;    // buy more as the distance outside the band increases
extern double VolumeMax    =     330;    // limit trading is volume exceeds this maximum
extern double BDistance    =      14;    // plus how much
extern int    BPeriod      =      15;    // Bollinger period
extern int    Deviation    =       2;    // Bollinger deviation
extern double Lots         =       1.0;  // how many lots to trade at a time 
extern bool   LotIncrease  =    true ;   // grow lots based on balance = true
extern bool   logging      =   false ;   // log data or not
extern bool   logerrs      =   false ;   // log errors or not
extern bool   logtick      =   false ;   // log tick data while orders open (or not)

// non-external flag settings
int    Slippage=2;                       // how many pips of slippage can you tolorate
double CompoundTrack;                    // used to track compounding and steps

// naming and numbering
int    MagicNumber  = 363638;            // allows multiple experts to trade on same account
string TradeComment = "_bolltrade_v03h.txt";
double StartingBalance=0;                // lot size control if LotIncrease == true

// Bar handling
datetime bartime=0;                      // used to determine when a bar has moved
int      bartick=0;                      // number of times bars have moved

// Trade control
bool   TradeAllowed=true;                // used to manage trades


// Min/Max tracking and tick logging
int    maxOrders;                        // statistic for maximum numbers or orders open at one time
double maxEquity;                        // statistic for maximum equity level
double minEquity;                        // statistic for minimum equity level
double maxOEquity;                       // statistic for maximum equity level per order
double minOEquity;                       // statistic for minimum equity level per order 
double EquityPos=0;                      // statistic for number of ticks order was positive
double EquityNeg=0;                      // statistic for number of ticks order was negative
double EquityZer=0;                      // statistic for number of ticks order was zero

// used for verbose error logging
#include <stdlib.mqh>


//+-------------+
//| Custom init |
//|-------------+
// Called ONCE when EA is added to chart or recompiled

int init()
  {
   if(LotIncrease)
     {
      //StartingBalance=AccountBalance()/Lots;
      StartingBalance=1402;
      logwrite(TradeComment,"LotIncrease ACTIVE Account balance="+AccountBalance()+" Lots="+Lots+" StartingBalance="+StartingBalance);
     }
    else
     {
      logwrite(TradeComment,"LotIncrease NOT ACTIVE Account balance="+AccountBalance()+" Lots="+Lots);
     }

   logwrite(TradeComment,"Init Complete");
   Comment(" ");
  }

//+----------------+
//| Custom DE-init |
//+----------------+
// Called ONCE when EA is removed from chart

int deinit()
  {

   // always indicate deinit statistics
   logwrite(TradeComment,"MAX number of orders "+maxOrders);
   logwrite(TradeComment,"MAX equity           "+maxEquity);
   logwrite(TradeComment,"MIN equity           "+minEquity);

   // so you can see stats in journal
   Print("MAX number of orders "+maxOrders);
   Print("MAX equity           "+maxEquity);
   Print("MIN equity           "+minEquity);


   logwrite(TradeComment,"DE-Init Complete");
   
   Comment(" ");
  }


//+-----------+
//| Main      |
//+-----------+
// Called EACH TICK and each Bar[]

int start()
  {

   int      cnt=0;
   int      gle=0;
   int      ticket=0;
   int      OrdersPerSymbol=0;
   int      OrdersBUY=0;
   int      OrdersSELL=0;
  
   // stoploss and takeprofit and close control
   double SL=0;
   double TP=0;
   
   double CurrentProfit=0;
   double CurrentBasket=0;
   
   // direction control
   bool BUYme=false;
   bool SELLme=false;
      
   // bar counting
   if(bartime!=Time[0]) 
     {
      bartime=Time[0];
      bartick++; 
     }

   // Lot increasement based on AccountBalance when expert is started
   // this will trade 1.0, then 1.1, then 1.2 etc as account balance grows
   // or 0.9 then 0.8 then 0.7 as account balance shrinks 
   if(LotIncrease)
     {
      Lots=NormalizeDouble(AccountBalance()/StartingBalance,1);
      if(Lots>50.0) Lots=50.0;
     }


   OrdersPerSymbol=0;
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
        {
         OrdersPerSymbol++;
         if(OrderType()==OP_BUY) {OrdersBUY++;}
         if(OrderType()==OP_SELL){OrdersSELL++;}
        }
     }
   
   if(OrdersPerSymbol==0)
     {
      CompoundTrack=0;
      
      // This allows the 1st order at BDistance after everything closes
      // others are handled in the indicator section 
      TradeAllowed=true;
     }


   // keep some statistics
   if(OrdersPerSymbol>maxOrders) maxOrders=OrdersPerSymbol;

     
   //+-----------------------------+
   //| Insert your indicator here  |
   //| And set either BUYme or     |
   //| SELLme true to place orders |
   //+-----------------------------+
   
   double bup=iBands(Symbol(),0,BPeriod,Deviation,0,PRICE_OPEN,MODE_UPPER,0);
   double bdn=iBands(Symbol(),0,BPeriod,Deviation,0,PRICE_OPEN,MODE_LOWER,0);

   if(Close[0]>bup)                 Comment("S Up="+bup+" Dn="+bdn);
   if(Close[0]<bdn)                 Comment("B Up="+bup+" Dn="+bdn);
   if(Close[0]<bup && Close[0]>bdn) Comment("- Up="+bup+" Dn="+bdn);

   // < and NOT <= so tick won't match 0 in a non-tick bar
   bool  volumeOK=false;
   if( Volume[1]<VolumeMax && Volume[0]<VolumeMax) volumeOK=true;
   if (VolumeMax==0) volumeOK=true;
 
   // if close is above upper band + BDistance then SELL
   if(Close[0]>bup+(BDistance*Point) && volumeOK) 
     {
      SELLme=true; 
      logwrite("BollTick3g.txt","---SELLme happened"); 
      if(Compounding && CompoundTrack>0 && Close[0]>CompoundTrack)
        {
         SELLme=true; 
         TradeAllowed=true;
         logwrite("BollTick3h.txt","---SELLme happened again "+CompoundTrack ); 
        }
     }

   // if close is below lower band + BDistance then BUY
   if(Close[0]<bdn-(BDistance*Point) && volumeOK) 
     {
      BUYme=true;  
      logwrite("BollTick3h.txt","----BUYme happened"); 
      if(Compounding && CompoundTrack>0 && Close[0]<CompoundTrack)
        {
         BUYme=true;
         TradeAllowed=true;
         logwrite("BollTick3g.txt","----BUYme happened again "+CompoundTrack ); 
        }
     }

   //+------------+
   //| End Insert |
   //+------------+

   //ENTRY LONG (buy, Ask) 
   if( TradeAllowed && BUYme )
     {
      while(true)
        {
         if(LossLimit ==0) SL=0; else SL=Ask-((LossLimit+10)*Point );
         if(ProfitMade==0) TP=0; else TP=Ask+((ProfitMade+10)*Point );
         ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,SL,TP,TradeComment,MagicNumber,White);
         gle=GetLastError();
         if(gle==0)
           {
            CompoundTrack=Close[0];
            //CompoundTrack=Ask;
            if(logging) logwrite(TradeComment,"                                                                ");
            if(logging) logwrite(TradeComment,"BUY Ticket="+ticket+" Ask="+Ask+" Lots="+Lots+" SL="+SL+" TP="+TP);
            maxOEquity=0;
            minOEquity=0;
            EquityPos=0;
            EquityNeg=0;
            EquityZer=0;
            TradeAllowed=false;
            break;
           }
            else 
           {
            if(logerrs) logwrite(TradeComment,"-----ERROR-----  opening BUY order: SL="+SL+" TP="+TP+" Bid="+Bid+" Ask="+Ask+" ticket="+ticket+" Err="+gle+" "+ErrorDescription(gle)); 
            Print("-----ERROR-----  opening BUY order :"+gle+" ticket="+ticket+" "+ErrorDescription(gle)); 
            RefreshRates();
            Sleep(500);
           }
        }//while   
     }//BUYme
        

   //ENTRY SHORT (sell, Bid)
   if( TradeAllowed && SELLme )
     {
      while(true)
        {
         if(LossLimit ==0) SL=0; else SL=Bid+((LossLimit+10)*Point );
         if(ProfitMade==0) TP=0; else TP=Bid-((ProfitMade+10)*Point );
         ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,SL,TP,TradeComment,MagicNumber,Red);
         gle=GetLastError();
         if(gle==0)
           {
            CompoundTrack=Close[0];
            //CompoundTrack=Bid;
            if(logging) logwrite(TradeComment,"                                                                 ");
            if(logging) logwrite(TradeComment,"SELL Ticket="+ticket+" Bid="+Bid+" Lots="+Lots+" SL="+SL+" TP="+TP);
            maxOEquity=0;
            minOEquity=0;
            EquityPos=0;
            EquityNeg=0;
            EquityZer=0;
            TradeAllowed=false;
            break;
           }
            else 
           {
            if(logerrs) logwrite(TradeComment,"-----ERROR-----  opening SELL order: SL="+SL+" TP="+TP+" Bid="+Bid+" Ask="+Ask+" ticket="+ticket+" Err="+gle+" "+ErrorDescription(gle)); 
            Print("-----ERROR-----  opening SELL order :"+gle+" ticket="+ticket+" "+ErrorDescription(gle));
            RefreshRates();
            Sleep(500);
           }
        }//while
     }//SELLme

     
   // accumulate statistics
   CurrentBasket=AccountEquity()-AccountBalance();
   if(CurrentBasket>maxEquity) { maxEquity=CurrentBasket; maxOEquity=CurrentBasket; }
   if(CurrentBasket<minEquity) { minEquity=CurrentBasket; minOEquity=CurrentBasket; }
   if(CurrentBasket>0)  EquityPos++;
   if(CurrentBasket<0)  EquityNeg++;
   if(CurrentBasket==0) EquityZer++;
   

   //
   // Order Management
   //
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber )
        {
        
         if(OrderType()==OP_BUY)
           {
            CurrentProfit=(Bid-OrderOpenPrice()) ;
            if(logtick) logwrite(TradeComment,"BUY  CurrentProfit="+CurrentProfit/Point+" CurrentBasket="+CurrentBasket/Point);

            //
            // Did we make a profit
            //======================
            //
            if(ProfitMade>0 && CurrentProfit>=(ProfitMade*Point))
              {
               while(true)
                 {
                  OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,White);
                  gle=GetLastError();
                  if(gle==0)
                    {
                     if(logging) logwrite(TradeComment,"CLOSE BUY PROFIT Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                     if(logging) logwrite(TradeComment,"MAX order equity "+maxOEquity);
                     if(logging) logwrite(TradeComment,"MIN order equity "+minOEquity);
                     if(logging) logwrite(TradeComment,"order equity positive ticks ="+EquityPos);
                     if(logging) logwrite(TradeComment,"order equity negative ticks ="+EquityNeg);
                     if(logging) logwrite(TradeComment,"order equity   zero   ticks ="+EquityZer);
                     break;
                    }
                   else 
                    {
                     if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE BUY PROFIT Bid="+Bid+" error="+gle+" "+ErrorDescription(gle));
                     Print("-----ERROR----- CLOSE BUY PROFIT Bid="+Bid+" error="+gle+" "+ErrorDescription(gle));
                     RefreshRates();
                     Sleep(500);
                    }
                 }//while
              }//if
              

            //
            // Did we take a loss
            //====================
            //
            if( LossLimit>0 && CurrentProfit<=(LossLimit*(-1)*Point)  )
              {
               while(true)
                 {
                  OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,White);
                  gle=GetLastError();
                  if(gle==0)
                    {
                     if(logging) logwrite(TradeComment,"CLOSE BUY LOSS Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                     if(logging) logwrite(TradeComment,"MAX order equity "+maxOEquity);
                     if(logging) logwrite(TradeComment,"MIN order equity "+minOEquity);
                     if(logging) logwrite(TradeComment,"order equity positive ticks ="+EquityPos);
                     if(logging) logwrite(TradeComment,"order equity negative ticks ="+EquityNeg);
                     if(logging) logwrite(TradeComment,"order equity   zero   ticks ="+EquityZer);
                     break;
                    }
                   else 
                    {
                     if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE BUY LOSS Bid="+Bid+" error="+gle+" "+ErrorDescription(gle));
                     Print("-----ERROR----- CLOSE BUY LOSS Bid="+Bid+" error="+gle+" "+ErrorDescription(gle));
                     RefreshRates();
                     Sleep(500);
                    }
                 }//while
                 
              }//if
              
           } // if BUY


         if(OrderType()==OP_SELL)
           {
            CurrentProfit=(OrderOpenPrice()-Ask);
            if(logtick) logwrite(TradeComment,"SELL CurrentProfit="+CurrentProfit/Point+" CurrentBasket="+CurrentBasket/Point);

            //
            // Did we make a profit
            //======================
            //
            if( ProfitMade>0 && CurrentProfit>=(ProfitMade*Point) )
              {
               while(true)
                 {
                  OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,Red);
                  gle=GetLastError();
                  if(gle==0)
                    {
                     if(logging) logwrite(TradeComment,"CLOSE SELL PROFIT Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                     if(logging) logwrite(TradeComment,"MAX order equity "+maxOEquity);
                     if(logging) logwrite(TradeComment,"MIN order equity "+minOEquity);
                     if(logging) logwrite(TradeComment,"order equity positive ticks ="+EquityPos);
                     if(logging) logwrite(TradeComment,"order equity negative ticks ="+EquityNeg);
                     if(logging) logwrite(TradeComment,"order equity   zero   ticks ="+EquityZer);
                     break;
                    }
                     else 
                    {
                     if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE SELL PROFIT Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
                     Print("-----ERROR----- CLOSE SELL PROFIT Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
                     RefreshRates();
                     Sleep(500);
                    }
                 }//while                 
              }//if


            //
            // Did we take a loss
            //====================
            //
            if( LossLimit>0 && CurrentProfit<=(LossLimit*(-1)*Point) )
              {
               while(true)
                 {
                  OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,Red);
                  gle=GetLastError();
                  if(gle==0)
                    {
                     if(logging) logwrite(TradeComment,"CLOSE SELL LOSS Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                     if(logging) logwrite(TradeComment,"MAX order equity "+maxOEquity);
                     if(logging) logwrite(TradeComment,"MIN order equity "+minOEquity);
                     if(logging) logwrite(TradeComment,"order equity positive ticks ="+EquityPos);
                     if(logging) logwrite(TradeComment,"order equity negative ticks ="+EquityNeg);
                     if(logging) logwrite(TradeComment,"order equity   zero   ticks ="+EquityZer);
                     break;
                    }
                     else 
                    {
                     if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE SELL LOSS Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
                     Print("-----ERROR----- CLOSE SELL LOSS Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
                     RefreshRates();
                     Sleep(500);
                    }
                 }//while

              }//if

           } //if SELL
           
        } // if(OrderSymbol)
        
     } // for

  } // start()


void logwrite (string filename, string mydata)
  {
   int myhandle;
   string gregorian=TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS);
   
   myhandle=FileOpen(Symbol()+"_"+filename, FILE_CSV|FILE_WRITE|FILE_READ, ";");
   if(myhandle>0)
     {
      FileSeek(myhandle,0,SEEK_END);
      FileWrite(myhandle, mydata+" "+gregorian);
      FileClose(myhandle);
     }
  } 


/* this expert is a spinoff of the previous envelope ea mod's, however
this one uses Limit orders to buy and sell when Bid is above the ma but below 
bline, & below the ma but above the sline respectively.  initial SL is the sline for 
buylimit orders and the bline for selllimit orders.  TP's are much smaller, grab it and
go philosophy.

if one backtests on 5min data, then selects open chart, mt4 will open a chart with the 
ma & it's accompanying envelopes along with all the buy and sell arrows, sl's & tp's.
this will aid in understanding what this ea is meant to do, and how it performed given
past data.  i have more that a year's worth of 1 & 5 minute gbpusd data, email me should
you want to import it into your copy of mt4. gl/gt tag. 
*/
//+------------------------------------------------------------------+
//|                                                 e.2.16 5 min.mq4 |
//|                      Copyright � 2005, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2005, tageiger aka fxid10t@yahoo.com"
#property copyright "Copyright � 2005, MetaQuotes Software Corp."
#property link      "fxid10t@yahoo.com"
#property link      "http://finance.groups.yahoo.com/group/MetaTrader_Experts_and_Indicators/join"

//---- input parameters
extern int        EnvelopePeriod    =144;//ma bars
extern int        EnvTimeFrame      =0; //envelope time frame: 0=chart,60=1hr,240=4hr, etc.
extern int        EnvMaMethod       =1; //0=sma,1=ema,2=smma,3=lwma.
extern double     EnvelopeDeviation =0.05;//%shift above & below ma 
extern int        MaElineTSL        =1;//0=iMA trailing stoploss  1=Opposite Envelope TSL
extern int        TimeOpen          =0;//time order placement can begin
extern int        TimeClose         =23;//open order deletion time
extern double     FirstTP           =8.0;
extern double     SecondTP          =13.0;
extern double     ThirdTP           =21.0;
extern double     Lots              =0.1;//initial lot size
extern double     MaximumRisk       =0.02;//percentage of account to risk each order
extern double     DecreaseFactor    =3;//lot size reducer during losing streak

int               b1,b2,b3,b4,s1,s2,s3,s4;
double            TSL               =0;

double LotsOptimized()  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
   if(DecreaseFactor>0) {
      for(int i=orders-1;i>=0;i--)  {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL) continue;
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
         }
      if(losses>1) lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
      }
   if(lot<0.1) lot=0.1;
   return(lot);
   }

int init()  {   return(0);  }

int deinit()  {   return(0);  }

int start() {
   int      p=0;     p=EnvelopePeriod;
   int      etf=0;   etf=EnvTimeFrame;
   int      mam=0;   mam=EnvMaMethod;
   double   d=0;     d=EnvelopeDeviation;
   double   btp1,btp2,btp3,stp1,stp2,stp3;
   double   bline=0,sline=0,ma=0,spread,eup,edown;
   int      cnt, ticket, total;
   double   digit; digit=MarketInfo(Symbol(),MODE_DIGITS);

   ma=iMA(NULL,etf,p,0,mam,PRICE_CLOSE,0);
   bline=iEnvelopes(NULL,etf,p,mam,0,PRICE_CLOSE,d,MODE_UPPER,0);
   sline=iEnvelopes(NULL,etf,p,mam,0,PRICE_CLOSE,d,MODE_LOWER,0);
   //spread=0;//Ask-Bid;
   //bline=eup+spread;
   //sline=edown-spread;
      
   total=OrdersTotal();
   if(OrdersTotal()==0) {  b1=0;b2=0;b3=0;b4=0;s1=0;s2=0;s3=0;s4=0;   }
   if(OrdersTotal()>0)  {
      for(cnt=0;cnt<total;cnt++) {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderMagicNumber()==2)  {  b1=OrderTicket(); }
         if(OrderMagicNumber()==4)  {  b2=OrderTicket(); }
         if(OrderMagicNumber()==6)  {  b3=OrderTicket(); }
         if(OrderMagicNumber()==8)  {  b4=OrderTicket(); }
         if(OrderMagicNumber()==1)  {  s1=OrderTicket(); }
         if(OrderMagicNumber()==3)  {  s2=OrderTicket(); }
         if(OrderMagicNumber()==5)  {  s3=OrderTicket(); }
         if(OrderMagicNumber()==7)  {  s4=OrderTicket(); }
         }
      }

   if(b1==0)   {  
      if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid>ma && Bid<bline)   {
            btp1=(NormalizeDouble(ma,digit))+(FirstTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_BUYLIMIT,
                              LotsOptimized(),
                              (NormalizeDouble(ma,digit)),
                              0,
                              (NormalizeDouble(sline,digit)),
                              btp1,
                              "e.2.18 BL1",
                              2,
                              TimeClose,
                              Aqua);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  b1=ticket;  Print(ticket); }
                                 else Print("Error Opening BuyLimit Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }         

   if(b2==0)   {
      if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid>ma && Bid<bline)   {      
            btp2=(NormalizeDouble(ma,digit))+(SecondTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_BUYLIMIT,
                              LotsOptimized(),
                              (NormalizeDouble(ma,digit)),
                              0,
                              (NormalizeDouble(sline,digit)),
                              btp2,
                              "e.2.18 BL2",
                              4,
                              TimeClose,
                              Aqua);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))  
                                    {  b2=ticket;  Print(ticket); }
                                 else Print("Error Opening BuyLimit Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }                              

   if(b3==0)   {
      if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid>ma && Bid<bline)   {      
            btp3=(NormalizeDouble(ma,digit))+(ThirdTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_BUYLIMIT,
                              LotsOptimized(),
                              (NormalizeDouble(ma,digit)),
                              0,
                              (NormalizeDouble(sline,digit)),
                              btp3,
                              "e.2.18 BL3",
                              6,
                              TimeClose,
                              Aqua);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  b3=ticket;  Print(ticket); }
                                 else Print("Error Opening BuyLimit Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }                     

   if(b4==0)   {
      if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid>ma && Bid<bline)   {      
            ticket=OrderSend(Symbol(),
                              OP_BUYLIMIT,
                              LotsOptimized(),
                              (NormalizeDouble(ma,digit)),
                              0,
                              (NormalizeDouble(sline,digit)),
                              0,
                              "e.2.18 BL4",
                              8,
                              TimeClose,
                              Aqua);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  b4=ticket;  Print(ticket); }
                                 else Print("Error Opening BuyLimit Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }
   
   if(s1==0)   {
      if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid<ma && Bid>sline)   {      
            stp1=NormalizeDouble(ma,digit)-(FirstTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_SELLLIMIT,
                              LotsOptimized(),
                              (NormalizeDouble(ma,digit)),
                              0,
                              (NormalizeDouble(bline,digit)),
                              stp1,
                              "e.2.18 SL1",
                              1,
                              TimeClose,
                              HotPink);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  s1=ticket;  Print(ticket); }
                                 else Print("Error Opening SellLimit Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }

   if(s2==0)   {
      if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid<ma && Bid>sline)   {      
            stp2=NormalizeDouble(ma,digit)-(SecondTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_SELLLIMIT,
                              LotsOptimized(),
                              (NormalizeDouble(ma,digit)),
                              0,
                              (NormalizeDouble(bline,digit)),
                              stp2,
                              "e.2.18 SL2",
                              3,
                              TimeClose,
                              HotPink);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  s2=ticket;  Print(ticket); }
                                 else Print("Error Opening SellLimit Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }                     
   
   if(s3==0)   {
      if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid<ma && Bid>sline)   {      
            stp3=NormalizeDouble(ma,digit)-(ThirdTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_SELLLIMIT,
                              LotsOptimized(),
                              (NormalizeDouble(ma,digit)),
                              0,
                              (NormalizeDouble(bline,digit)),
                              stp3,
                              "e.2.18 SL3",
                              5,
                              TimeClose,
                              HotPink);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  s3=ticket;  Print(ticket); }
                                 else Print("Error Opening SellLimit Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }

   if(s4==0)   {
      if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid<ma && Bid>sline)   {      
            ticket=OrderSend(Symbol(),
                              OP_SELLLIMIT,
                              LotsOptimized(),
                              (NormalizeDouble(ma,digit)),
                              0,
                              (NormalizeDouble(bline,digit)),
                              0,
                              "e.2.18 SL4",
                              7,
                              TimeClose,
                              HotPink);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  s4=ticket;  Print(ticket); }
                                 else Print("Error Opening SellLimit Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }
   
   for(cnt=0;cnt<total;cnt++) {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);            
      if(OrderType()==OP_BUY) {
         if(MaElineTSL==0) {TSL=NormalizeDouble(ma,digit); }
         if(MaElineTSL==1) {TSL=NormalizeDouble(sline,digit); }
         if(Close[0]>OrderOpenPrice()) {
            if((Close[0]>bline) && (TSL>OrderStopLoss()))   {
               double bsl;bsl=TSL;
               OrderModify(OrderTicket(),
                           OrderOpenPrice(),
                           bsl,
                           OrderTakeProfit(),
                           0,//Order expiration server date/time
                           Green);
                           return;            
               }
            }
         }
      if(OrderType()==OP_SELL)   {
         if(MaElineTSL==0) {TSL=NormalizeDouble(ma,digit); }
         if(MaElineTSL==1) {TSL=NormalizeDouble(bline,digit); }         
         if(Close[0]<OrderOpenPrice()) {
            if((Close[0]<sline) && (TSL<OrderStopLoss()))   {
               double ssl;ssl=TSL;
               OrderModify(OrderTicket(),
                           OrderOpenPrice(),
                           ssl,
                           OrderTakeProfit(),
                           0,//Order expiration server date/time
                           Red);
                           return;            
               }
            }
         }
      }

      for(cnt=0;cnt<total;cnt++) {
      OrderSelect(cnt,SELECT_BY_TICKET);
         if(OrderTicket()==b1)   {
            if(OrderMagicNumber()==2 &&
            OrderType()==OP_BUYLIMIT &&
            OrderOpenPrice()!=NormalizeDouble(ma,digit))  {
               btp1=(NormalizeDouble(bline,digit))+(FirstTP*Point);
               OrderModify(OrderTicket(),
                           NormalizeDouble(ma,digit),
                           NormalizeDouble(sline,digit),
                           btp1,
                           0,
                           LimeGreen);
                           return;  }  }     
         if(OrderTicket()==b2)   {
            if(OrderMagicNumber()==4 &&
            OrderType()==OP_BUYLIMIT &&
            OrderOpenPrice()!=NormalizeDouble(ma,digit))  {
               btp2=(NormalizeDouble(ma,digit))+(SecondTP*Point);
               OrderModify(OrderTicket(),
                           NormalizeDouble(ma,digit),
                           NormalizeDouble(sline,digit),
                           btp2,
                           0,
                           LimeGreen);
                           return;  }  }
         if(OrderTicket()==b3)   {
            if(OrderMagicNumber()==6 &&
            OrderType()==OP_BUYLIMIT &&
            OrderOpenPrice()!=NormalizeDouble(ma,digit))  {
               btp3=(NormalizeDouble(ma,digit))+(ThirdTP*Point);
               OrderModify(OrderTicket(),
                           NormalizeDouble(ma,digit),
                           NormalizeDouble(sline,digit),
                           btp3,
                           0,
                           LimeGreen);
                           return;  }  }
         if(OrderTicket()==b4)   {
            if(OrderMagicNumber()==8 &&
            OrderType()==OP_BUYLIMIT &&
            OrderOpenPrice()!=NormalizeDouble(ma,digit))  {
               OrderModify(OrderTicket(),
                           NormalizeDouble(ma,digit),
                           NormalizeDouble(sline,digit),
                           0,
                           0,
                           LimeGreen);
                           return;  }  }
         if(OrderTicket()==s1)   {
            if(OrderMagicNumber()==1 &&
            OrderType()==OP_SELLLIMIT &&
            OrderOpenPrice()!=NormalizeDouble(ma,digit))  {
               stp1=(NormalizeDouble(ma,digit))-(FirstTP*Point);
               OrderModify(OrderTicket(),
                           NormalizeDouble(ma,digit),
                           NormalizeDouble(bline,digit),
                           stp1,
                           0,
                           HotPink);
                           return;  }  }
         if(OrderTicket()==s2)   {
            if(OrderMagicNumber()==3 &&
            OrderType()==OP_SELLLIMIT &&
            OrderOpenPrice()!=NormalizeDouble(ma,digit))  {
               stp2=(NormalizeDouble(ma,digit))-(SecondTP*Point);
               OrderModify(OrderTicket(),
                           NormalizeDouble(ma,digit),
                           NormalizeDouble(bline,digit),
                           stp2,
                           0,
                           HotPink);
                           return;  }  }
         if(OrderTicket()==s3)   {
            if(OrderMagicNumber()==5 &&
            OrderType()==OP_SELLLIMIT &&
            OrderOpenPrice()!=NormalizeDouble(ma,digit))  {
               stp3=(NormalizeDouble(ma,digit))-(ThirdTP*Point);
               OrderModify(OrderTicket(),
                           NormalizeDouble(ma,digit),
                           NormalizeDouble(bline,digit),
                           stp3,
                           0,
                           HotPink);
                           return;  }  }
         if(OrderTicket()==s4)   {
            if(OrderMagicNumber()==7 &&
            OrderType()==OP_SELLLIMIT &&
            OrderOpenPrice()!=NormalizeDouble(ma,digit))  {
               OrderModify(OrderTicket(),
                           NormalizeDouble(ma,digit),
                           NormalizeDouble(bline,digit),
                           0,
                           0,
                           HotPink);
                           return;  }  }
      }
      
      for(cnt=0;cnt<total;cnt++) {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);   
      if(Hour()==TimeClose && OrderType()==OP_BUYLIMIT)  {
         OrderDelete(OrderTicket());
         if(OrderTicket()==b1) {b1=0; return;}
         if(OrderTicket()==b2) {b2=0; return;}
         if(OrderTicket()==b3) {b3=0; return;}
         if(OrderTicket()==b4) {b4=0; return;}                   
         }
     OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);            
     if(Hour()==TimeClose && OrderType()==OP_SELLLIMIT)  {
         OrderDelete(OrderTicket());
         if(OrderTicket()==s1) {s1=0; return;}
         if(OrderTicket()==s2) {s2=0; return;}
         if(OrderTicket()==s3) {s3=0; return;}
         if(OrderTicket()==s4) {s4=0; return;}
         }
      OrderSelect(b1,SELECT_BY_TICKET);
      if(OrderClosePrice()>0) {b1=0;}
      OrderSelect(b2,SELECT_BY_TICKET);
      if(OrderClosePrice()>0) {b2=0;}
      OrderSelect(b3,SELECT_BY_TICKET);
      if(OrderClosePrice()>0) {b3=0;}
      OrderSelect(b4,SELECT_BY_TICKET);
      if(OrderClosePrice()>0) {b4=0;}
      OrderSelect(s1,SELECT_BY_TICKET);
      if(OrderClosePrice()>0) {s1=0;}
      OrderSelect(s2,SELECT_BY_TICKET);
      if(OrderClosePrice()>0) {s2=0;}     
      OrderSelect(s3,SELECT_BY_TICKET);
      if(OrderClosePrice()>0) {s3=0;}
      OrderSelect(s4,SELECT_BY_TICKET);
      if(OrderClosePrice()>0) {s4=0;}
      }
   return(0);
   }

  


//+------------------------------------------------------------------+
//|                                                 e.2.21 5 min.mq4 |
//|                      Copyright � 2005, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2005, tageiger aka fxid10t@yahoo.com"
#property copyright "Copyright � 2005, MetaQuotes Software Corp."
#property link      "fxid10t@yahoo.com"
#property link      "http://finance.groups.yahoo.com/group/MetaTrader_Experts_and_Indicators/join"

//---- input parameters
extern int        EnvelopePeriod    =144;//ma bars
extern int        EnvTimeFrame      =1; //envelope time frame: 0=chart,60=1hr,240=4hr, etc.
extern int        EnvMaMethod       =1; //0=sma,1=ema,2=smma,3=lwma.
extern double     EnvelopeDeviation =0.1;//%shift above & below ma 
//extern int        TimeOpen          =0;//time order placement can begin
//extern int        TimeClose         =23;//open order deletion time
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
   if(lot<0.1) lot=0.1;//  <<<---IBFX MINI MODIFICATION
   return(lot);
   }

int init()  {   return(0);  }

int deinit()  {   return(0);  }

int start() {
   int      p=0;     p=EnvelopePeriod;
   int      etf=0;   etf=EnvTimeFrame;
   int      mam=0;   mam=EnvMaMethod;
   double   d=0;     d=EnvelopeDeviation;
   double   btp1,btp2,btp3,stp1,stp2,stp3,bsl,ssl,buy,sell;
   double   bline=0,sline=0,ma=0,spread,eup,edown;
   int      cnt, ticket, total;
   double   digit; digit=MarketInfo(Symbol(),MODE_DIGITS);

   ma=iMA(NULL,etf,p,0,mam,PRICE_CLOSE,0);
   bline=iEnvelopes(NULL,etf,p,mam,0,PRICE_CLOSE,d,MODE_UPPER,0);
   sline=iEnvelopes(NULL,etf,p,mam,0,PRICE_CLOSE,d,MODE_LOWER,0);
   spread=Ask-Bid;
   
   buy=NormalizeDouble(ma,digit)+spread;
   bsl=NormalizeDouble(sline,digit);
   sell=NormalizeDouble(ma,digit);   
   ssl=NormalizeDouble(bline,digit)+spread;

      
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
      //if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid<buy && Bid>sline)   {
            btp1=buy+(FirstTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_BUYSTOP,
                              LotsOptimized(),
                              buy,
                              0,
                              bsl,
                              btp1,
                              "e.2.21 b1",
                              2,
                              0,
                              Aqua);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  b1=ticket;  Print(ticket); }
                                 else Print("Error Opening BuyStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
         //}
      }         

   if(b2==0)   {
      //if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid<buy && Bid>sline)   {      
            btp2=buy+(SecondTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_BUYSTOP,
                              LotsOptimized(),
                              buy,
                              0,
                              bsl,
                              btp2,
                              "e.2.21 b2",
                              4,
                              0,
                              Aqua);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))  
                                    {  b2=ticket;  Print(ticket); }
                                 else Print("Error Opening BuyStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
         //}
      }                              

   if(b3==0)   {
      //if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid<buy && Bid>sline)   {      
            btp3=buy+(ThirdTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_BUYSTOP,
                              LotsOptimized(),
                              buy,
                              0,
                              bsl,
                              btp3,
                              "e.2.21 b3",
                              6,
                              0,
                              Aqua);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  b3=ticket;  Print(ticket); }
                                 else Print("Error Opening BuyStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
         //}
      }                     

   if(b4==0)   {
      //if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid<buy && Bid>sline)   {      
            ticket=OrderSend(Symbol(),
                              OP_BUYSTOP,
                              LotsOptimized(),
                              buy,
                              0,
                              bsl,
                              0,
                              "e.2.21 b4",
                              8,
                              0,
                              Aqua);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  b4=ticket;  Print(ticket); }
                                 else Print("Error Opening BuyStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
        //}
      }
   
   if(s1==0)   {
      //if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid>ma && Bid<ssl)   {      
            stp1=sell-(FirstTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_SELLSTOP,
                              LotsOptimized(),
                              sell,
                              0,
                              ssl,
                              stp1,
                              "e.2.21 s1",
                              1,
                              0,
                              HotPink);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  s1=ticket;  Print(ticket); }
                                 else Print("Error Opening SellStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
        // }
      }

   if(s2==0)   {
      //if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid>ma && Bid<ssl)   {      
            stp2=sell-(SecondTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_SELLSTOP,
                              LotsOptimized(),
                              sell,
                              0,
                              ssl,
                              stp2,
                              "e.2.21 s2",
                              3,
                              0,
                              HotPink);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  s2=ticket;  Print(ticket); }
                                 else Print("Error Opening SellStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
         //}
      }                     
   
   if(s3==0)   {
      //if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid>ma && Bid<ssl)   {      
            stp3=sell-(ThirdTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_SELLSTOP,
                              LotsOptimized(),
                              sell,
                              0,
                              ssl,
                              stp3,
                              "e.2.21 s3",
                              5,
                              0,
                              HotPink);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  s3=ticket;  Print(ticket); }
                                 else Print("Error Opening SellStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
        // }
      }

   if(s4==0)   {
      //if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(Bid>ma && Bid<ssl)   {      
            ticket=OrderSend(Symbol(),
                              OP_SELLSTOP,
                              LotsOptimized(),
                              sell,
                              0,
                              ssl,
                              0,
                              "e.2.21 s4",
                              7,
                              0,
                              HotPink);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  s4=ticket;  Print(ticket); }
                                 else Print("Error Opening SellStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
        // }
      }
   
   for(cnt=0;cnt<total;cnt++) {

      ma=iMA(NULL,etf,p,0,mam,PRICE_CLOSE,0);
      bline=iEnvelopes(NULL,etf,p,mam,0,PRICE_CLOSE,d,MODE_UPPER,0);
      sline=iEnvelopes(NULL,etf,p,mam,0,PRICE_CLOSE,d,MODE_LOWER,0);
      spread=Ask-Bid;

      buy=NormalizeDouble(ma,digit)+spread;
      bsl=NormalizeDouble(sline,digit);
      sell=NormalizeDouble(ma,digit);   
      ssl=NormalizeDouble(bline,digit)+spread;

      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);            
      if(OrderType()==OP_BUY) {
         if(Bid>OrderOpenPrice())   {
            TSL=NormalizeDouble(sline,digit);
            if(TSL>OrderStopLoss()) {
               bsl=TSL;
               OrderModify(OrderTicket(),
                           OrderOpenPrice(),
                           bsl,
                           OrderTakeProfit(),
                           0,//Order expiration server date/time
                           Green);
                           return;  }  }
         if(Bid>bline)  {
            TSL=NormalizeDouble(ma,digit);
            if(TSL>OrderStopLoss()) {
               bsl=TSL;
               OrderModify(OrderTicket(),
                           OrderOpenPrice(),
                           bsl,
                           OrderTakeProfit(),
                           0,//Order expiration server date/time
                           Green);
                           return;  }  } 
         }

      if(OrderType()==OP_SELL)   {
         if(Ask<OrderOpenPrice())   {
            TSL=NormalizeDouble(bline,digit)+spread;
            if(TSL<OrderStopLoss()) {
               ssl=TSL;
               OrderModify(OrderTicket(),
                           OrderOpenPrice(),
                           ssl,
                           OrderTakeProfit(),
                           0,//Order expiration server date/time
                           Red);
                           return;  }  }
         if(Bid<sline)  {
            TSL=NormalizeDouble(ma,digit)+spread;
            if(TSL<OrderStopLoss()) {
               ssl=TSL;
               OrderModify(OrderTicket(),
                           OrderOpenPrice(),
                           ssl,
                           OrderTakeProfit(),
                           0,//Order expiration server date/time
                           Red);
                           return;  }  }
         }

      if(OrderType()==OP_BUYSTOP)  {
         if(OrderOpenPrice()!=MathAbs(buy) &&
            (OrderOpenPrice()-Ask)>=spread)  {
            if(OrderTicket()==b1)   {
               btp1=buy+(FirstTP*Point);
               OrderModify(OrderTicket(),
                           buy,
                           bsl,
                           btp1,
                           0,
                           LimeGreen);
                           }
            if(OrderTicket()==b2)   {
               btp2=buy+(SecondTP*Point);
               OrderModify(OrderTicket(),
                           buy,
                           bsl,
                           btp2,
                           0,
                           LimeGreen);
                           }
            if(OrderTicket()==b3)   {
               btp3=buy+(ThirdTP*Point);
               OrderModify(OrderTicket(),
                           buy,
                           bsl,
                           btp3,
                           0,
                           LimeGreen);
                           }
            if(OrderTicket()==b4)   {
               OrderModify(OrderTicket(),
                           buy,
                           bsl,
                           0,
                           0,
                           LimeGreen);
                           }
            }
         }
      if(OrderType()==OP_SELLSTOP) {
         if(OrderOpenPrice()!=MathAbs(sell) &&
            (Bid-OrderOpenPrice())>=spread)  {                  
            if(OrderTicket()==s1)   {
               stp1=sell-(FirstTP*Point);
               OrderModify(OrderTicket(),
                           sell,
                           ssl,
                           stp1,
                           0,
                           HotPink);
                           }
            if(OrderTicket()==s2)   {
               stp2=(NormalizeDouble(ma,digit))-(SecondTP*Point);
               OrderModify(OrderTicket(),
                           sell,
                           ssl,
                           stp2,
                           0,
                           HotPink);
                           }
            if(OrderTicket()==s3)   {
               stp3=sell-(ThirdTP*Point);
               OrderModify(OrderTicket(),
                           sell,
                           ssl,
                           stp3,
                           0,
                           HotPink);
                           }
            if(OrderTicket()==s4)   {
               OrderModify(OrderTicket(),
                           sell,
                           ssl,
                           0,
                           0,
                           HotPink);
                           }
         }
      }
/*      
      if(Hour()==TimeClose && OrderType()==OP_BUYSTOP)  {
         OrderDelete(OrderTicket());
         if(OrderTicket()==b1) {b1=0; return;}
         if(OrderTicket()==b2) {b2=0; return;}
         if(OrderTicket()==b3) {b3=0; return;}
         if(OrderTicket()==b4) {b4=0; return;}                   
         }
      if(Hour()==TimeClose && OrderType()==OP_SELLSTOP)  {
         OrderDelete(OrderTicket());
         if(OrderTicket()==s1) {s1=0; return;}
         if(OrderTicket()==s2) {s2=0; return;}
         if(OrderTicket()==s3) {s3=0; return;}
         if(OrderTicket()==s4) {s4=0; return;}
         }*/
      OrderSelect(b1,SELECT_BY_TICKET);
      if(OrderCloseTime()>0) {b1=0;}
      OrderSelect(b2,SELECT_BY_TICKET);
      if(OrderCloseTime()>0) {b2=0;}
      OrderSelect(b3,SELECT_BY_TICKET);
      if(OrderCloseTime()>0) {b3=0;}
      OrderSelect(b4,SELECT_BY_TICKET);
      if(OrderCloseTime()>0) {b4=0;}
      OrderSelect(s1,SELECT_BY_TICKET);
      if(OrderCloseTime()>0) {s1=0;}
      OrderSelect(s2,SELECT_BY_TICKET);
      if(OrderCloseTime()>0) {s2=0;}     
      OrderSelect(s3,SELECT_BY_TICKET);
      if(OrderCloseTime()>0) {s3=0;}
      OrderSelect(s4,SELECT_BY_TICKET);
      if(OrderCloseTime()>0) {s4=0;}
      }
   return(0);
   }

  


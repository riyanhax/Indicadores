//+------------------------------------------------------------------+
//| 3MA Bunny Cross Expert                               |
//+------------------------------------------------------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//|------------------------------------------------------------------|

int init()
  {
   return(0);
  }


//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }


//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int start()
  {
   double   cMAfst=0, pMAfst=0;
   double   cMAslo=0, pMAslo=0;
   double    MA100=0;

      
   int    total=0;
   bool   found=false;
   int    otype=0;
   int    otime=0;

   int      cnt=0;
   
   string cmmt="";
   
   //
   // Error checking
   //
   
   if(Bars<100)
     {
      Print("bars less than 100");
      return(0);
     }
   
   if(AccountFreeMargin()<(1000*Lots))
     {
      Print("We have no money");
      return(0);
     }



   
   cMAfst=iMA(Symbol(),0,5 ,0,MODE_LWMA,PRICE_CLOSE, 1);
   pMAfst=iMA(Symbol(),0,5 ,0,MODE_LWMA,PRICE_CLOSE, 2);
      
   cMAslo=iMA(Symbol(),0,25,0,MODE_LWMA,PRICE_CLOSE, 1);
   pMAslo=iMA(Symbol(),0,25,0,MODE_LWMA,PRICE_CLOSE, 2);


   found=false;


   // rising or falling
   if ((pMAfst<=pMAslo && cMAfst>=cMAslo) || (pMAfst>=pMAslo && cMAfst<=cMAslo))
     {
      // check for existing order
      cmmt=cmmt+"crossover ";
      Comment(cmmt);
      
      total=OrdersTotal();
      for(cnt=0;cnt<OrdersTotal();cnt++)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if(OrderSymbol()==Symbol())
           {
            found=true;
            otype=OrderType();
            otime=OrderOpenTime();
            break;
           }
        }
     }

   if (found==true)
     {
      Comment("experimental close"); 
      OrderClose(OrderTicket(),Lots,Ask,0,White);
     }
   return(0);




   if (found==true)
     {
      cmmt=cmmt+" infound";
      Comment(cmmt);
      
      if (pMAfst<=pMAslo && cMAfst>=cMAslo && otype==1)  //exist sell
        {
         cmmt=cmmt+" CLOSE sell BUY buy";
         Comment(cmmt);
         OrderClose(OrderTicket(),Lots,Bid,0,Red);
         //Print("BUY  Order started  ",Ask);
         //OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"BC Buy ",16123,0,White);
         //if(GetLastError()==0)Comment("BC_BUY  Order opened : ",Ask);
        }
      if (pMAfst>=pMAslo && cMAfst<=cMAslo && otype==0)  // exist buy
        {
         cmmt=cmmt+" CLOSE buy BUY sell";
         Comment(cmmt); 
         OrderClose(OrderTicket(),Lots,Ask,0,White);
         //Print("SELL Order started  ",Bid);
         //OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"BC Sell",16321,0,Red);
         //if(GetLastError()==0)Comment("BC_SELL Order opened : ",Bid );
        }
     }


   return(0);
  }


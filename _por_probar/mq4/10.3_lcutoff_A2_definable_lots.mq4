//+------------------------------------------------------------------+
//|                                                   10points 3UserSelectableLots.mq4 |
//|                              Copyright � 2005, Alejandro Galindo |
//|                                              http://elCactus.com |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2005, Alejandro Galindo  mods by emsjoflo"
#property link      "http://elCactus.com"

extern double First  = 0.01;
extern double Second  = 0.01;
extern double Third  = 0.02;
extern double Fourth  = 0.03;
extern double Fifth  = 0.06;
extern double Sixth  = 0.07;
extern double Seventh  = 0.12;
extern double Eighth  = 0.21;
extern double Ninth  = 0.4;    
extern double Tenth =  0.7;
extern double EleventhPlus =0.01;   

extern double TakeProfit = 40;
extern double Lots = 0.01;
extern double InitialStop = 0;
extern double TrailingStop = 20;
extern double MaxLoss = 150;
extern int MaxTrades=10;
extern int Pips=15;
int MagicNumber=546757;
extern int SecureProfit=10;
extern int AccountProtection=1;
extern int OrderstoProtect=3;
extern int ReverseCondition=0;
extern double EURUSDPipValue=10;
extern double GBPUSDPipValue=10;
extern double USDCHFPipValue=10;
extern double USDJPYPipValue=9.715;
extern int StartYear=2005;
extern int StartMonth=1;
extern int EndYear=2006;
extern int EndMonth=12;
extern int EndHour=22;
extern int EndMinute=30;
extern int mm=0;
extern int risk=12;
extern int AccountisNormal=0;

int  OpenOrders=0, cnt=0;
int  slippage=5;
double sl=0, tp=0;
double BuyPrice=0, SellPrice=0;
double lotsi=0, mylotsi=0;
int mode=0, myOrderType=0;
bool ContinueOpening=True;
double LastPrice=0;
int  PreviousOpenOrders=0;
double Profit=0;
int LastTicket=0, LastType=0;
double LastClosePrice=0, LastLots=0;
double Pivot=0;
double PipValue=0;
string text="", text2="";

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//---- 
   if (AccountisNormal==1)
   {
	  if (mm!=0) { lotsi=MathCeil(AccountBalance()*risk/10000); }
		else { lotsi=Lots; }
   } else {  // then is mini
    if (mm!=0) { lotsi=MathCeil(AccountBalance()*risk/10000)/10; }
		else { lotsi=Lots; }
   }

   if (lotsi>100){ lotsi=100; }
   
   OpenOrders=0;
   for(cnt=0;cnt<OrdersTotal();cnt++)   
   {
     OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
	  if (OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
	  {				
	  	  OpenOrders++;
	  }
   }     
   
   if (OpenOrders<1) 
   {
	  if (TimeYear(CurTime())<StartYear) { return(0);  }
	  if (TimeMonth(CurTime())<StartMonth) { return(0); }
	  if (TimeYear(CurTime())>EndYear) { return(0); }
	  if (TimeMonth(CurTime())>EndMonth ) { return(0); }
   }
   
   if (Symbol()=="EURUSD" || Symbol()=="EURUSDm") { PipValue=EURUSDPipValue; }
   if (Symbol()=="GBPUSD" || Symbol()=="GBPUSDm") { PipValue=GBPUSDPipValue; }
   if (Symbol()=="USDJPY" || Symbol()=="USDJPYm") { PipValue=USDJPYPipValue; }
   if (Symbol()=="USDCHF" || Symbol()=="USDCHFm") { PipValue=USDCHFPipValue; }
   if (PipValue==0) { PipValue=5; }
   
   if (PreviousOpenOrders>OpenOrders) 
   {	  
	  for(cnt=OrdersTotal();cnt>=0;cnt--)
	  {
	     OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
	  	  mode=OrderType();
		  if (OrderSymbol()==Symbol()) 
		  {
			if (mode==OP_BUY && OrderMagicNumber()==MagicNumber) { OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),slippage,Blue); }
			if (mode==OP_SELL && OrderMagicNumber()==MagicNumber) { OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),slippage,Red); }
			return(0);
		 }
	  }
   }

   PreviousOpenOrders=OpenOrders;
   if (OpenOrders>=MaxTrades) 
   {
	  ContinueOpening=False;
   } else {
	  ContinueOpening=True;
   }

   if (LastPrice==0) 
   {
	  for(cnt=0;cnt<OrdersTotal();cnt++)
	  {	
	    OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
		 mode=OrderType();	
		 if (OrderSymbol()==Symbol()) 
		 {
			LastPrice=OrderOpenPrice();
			if (mode==OP_BUY && OrderMagicNumber()==MagicNumber) { myOrderType=2; }
			if (mode==OP_SELL && OrderMagicNumber()==MagicNumber) { myOrderType=1;	}
		 }
	  }
   }

   if (OpenOrders<1) 
   {
	  myOrderType=3;
	  //if (iMACD(14,26,9,MODE_MAIN,0)>0 and iMACD(14,26,9,MODE_MAIN,0)>iMACD(14,26,9,MODE_MAIN,1)) then OrderType=2;
	  if (iMACD(NULL,0,14,26,9,PRICE_CLOSE,MODE_MAIN,0)>iMACD(NULL,0,14,26,9,PRICE_CLOSE,MODE_MAIN,1)) { myOrderType=2; }
	  //if (iMACD(14,26,9,MODE_MAIN,0)<0 and iMACD(14,26,9,MODE_MAIN,0)<iMACD(14,26,9,MODE_MAIN,1)) then OrderType=1;
	  if (iMACD(NULL,0,14,26,9,PRICE_CLOSE,MODE_MAIN,0)<iMACD(NULL,0,14,26,9,PRICE_CLOSE,MODE_MAIN,1)) { myOrderType=1; }
	  if (ReverseCondition==1)
	  {
	  	  if (myOrderType==1) { myOrderType=2; }
		  else { if (myOrderType==2) { myOrderType=1; } }
	  }
   }

   // if we have opened positions we take care of them
   for(cnt=OrdersTotal();cnt>=0;cnt--)
   {
     OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
	  if (OrderSymbol() == Symbol()) 
	  {	
	  	  if (OrderType()==OP_SELL && OrderMagicNumber()==MagicNumber) 
	  	  {			
	  	  	  if (TrailingStop>0) 
			  {
				  if (OrderOpenPrice()-Ask>=(TrailingStop+Pips)*Point) 
				  {						
					 if (OrderStopLoss()>(Ask+Point*TrailingStop))
					 {			
					    OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderClosePrice()-TakeProfit*Point-TrailingStop*Point,800,Purple);
	  					 return(0);	  					
	  				 }
	  			  }
			  }
	  	  }
   
	  	  if (OrderType()==OP_BUY && OrderMagicNumber()==MagicNumber)
	  	  {
	  		 if (TrailingStop>0) 
	  		 {
			   if (Bid-OrderOpenPrice()>=(TrailingStop+Pips)*Point) 
				{
					if (OrderStopLoss()<(Bid-Point*TrailingStop)) 
					{					   
					   OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderClosePrice()+TakeProfit*Point()+TrailingStop*Point(),800,Yellow);
                  return(0);
					}
  				}
			 }
	  	  }
   	}
   }
   
   Profit=0;
   LastTicket=0;
   LastType=0;
	LastClosePrice=0;
	LastLots=0;	
	for(cnt=0;cnt<OrdersTotal();cnt++)
	{
	  OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
	  if (OrderSymbol()==Symbol()) 
	  {			
	  	   LastTicket=OrderTicket();
			if (OrderType()==OP_BUY && OrderMagicNumber()==MagicNumber) { LastType=OP_BUY; }
			if (OrderType()==OP_SELL && OrderMagicNumber()==MagicNumber) { LastType=OP_SELL; }
			LastClosePrice=OrderClosePrice();
			LastLots=OrderLots();
			if (LastType==OP_BUY) 
			{
				//Profit=Profit+(Ord(cnt,VAL_CLOSEPRICE)-Ord(cnt,VAL_OPENPRICE))*PipValue*Ord(cnt,VAL_LOTS);				
				if (OrderClosePrice()<OrderOpenPrice()) 
					{ Profit=Profit-(OrderOpenPrice()-OrderClosePrice())*OrderLots()/Point; }
				if (OrderClosePrice()>OrderOpenPrice()) 
					{ Profit=Profit+(OrderClosePrice()-OrderOpenPrice())*OrderLots()/Point; }
			}
			if (LastType==OP_SELL) 
			{
				//Profit=Profit+(Ord(cnt,VAL_OPENPRICE)-Ord(cnt,VAL_CLOSEPRICE))*PipValue*Ord(cnt,VAL_LOTS);
				if (OrderClosePrice()>OrderOpenPrice()) 
					{ Profit=Profit-(OrderClosePrice()-OrderOpenPrice())*OrderLots()/Point; }
				if (OrderClosePrice()<OrderOpenPrice()) 
					{ Profit=Profit+(OrderOpenPrice()-OrderClosePrice())*OrderLots()/Point; }
			}
			//Print(Symbol,":",Profit,",",LastLots);
	  }
   }
	
	Profit=Profit*PipValue;
	text2="Profit: $"+DoubleToStr(Profit,2)+" +/-";
   CheckExit();
   if (OpenOrders>=(MaxTrades-OrderstoProtect) && AccountProtection==1) 
   {	    
	     //Print(Symbol,":",Profit);
	     if (Profit>=SecureProfit) 
	     {
	        OrderClose(LastTicket,LastLots,LastClosePrice,slippage,Yellow);		 
	        ContinueOpening=False;
	        return(0);
	     }
   }

      if (!IsTesting()) 
      {
	     if (myOrderType==3) { text="No conditions to open trades"; }
	     else { text="                         "; }
	     Comment("LastPrice=",LastPrice," Previous open orders=",PreviousOpenOrders,"\nContinue opening=",ContinueOpening," OrderType=",myOrderType,"\n",text2,"\nLots=",lotsi,"\n",text);
      }

      if (myOrderType==1 && ContinueOpening) 
      {	
	     if ((Bid-LastPrice)>=Pips*Point || OpenOrders<1) 
	     {		
		    SellPrice=Bid;				
		    LastPrice=0;
		    if (TakeProfit==0) { tp=0; }
		    else { tp=SellPrice-TakeProfit*Point; }	
		    if (InitialStop==0) { sl=0; }
		    else { sl=SellPrice+InitialStop*Point;  }
		    if (OpenOrders!=0) 
		    {
			      if (OpenOrders == 1) mylotsi = Second; 
			      if (OpenOrders == 2) mylotsi = Third;
			      if (OpenOrders == 3) mylotsi = Fourth;
			      if (OpenOrders == 4) mylotsi = Fifth;
			      if (OpenOrders == 5) mylotsi = Sixth;
			      if (OpenOrders == 6) mylotsi = Seventh;
			      if (OpenOrders == 7) mylotsi = Eighth;
			      if (OpenOrders == 8) mylotsi = Ninth;
			      if (OpenOrders == 9) mylotsi = Tenth;
			      if (OpenOrders > 9)  mylotsi = EleventhPlus;
			      NormalizeDouble(mylotsi,2);			
			      
		    } else { mylotsi=First; }
		    if (mylotsi>100) { mylotsi=100; }
		    OrderSend(Symbol(),OP_SELL,mylotsi,SellPrice,slippage,sl,tp,"10 pt 3 cutoff",MagicNumber,0,Red);		    		    
		    return(0);
	     }
      }
      
      if (myOrderType==2 && ContinueOpening) 
      {
	     if ((LastPrice-Ask)>=Pips*Point || OpenOrders<1) 
	     {		
		    BuyPrice=Ask;
		    LastPrice=0;
		    if (TakeProfit==0) { tp=0; }
		    else { tp=BuyPrice+TakeProfit*Point; }	
		    if (InitialStop==0)  { sl=0; }
		    else { sl=BuyPrice-InitialStop*Point; }
		    if (OpenOrders!=0) {
			  	   if (OpenOrders == 1) mylotsi = Second; 
			      if (OpenOrders == 2) mylotsi = Third;
			      if (OpenOrders == 3) mylotsi = Fourth;
			      if (OpenOrders == 4) mylotsi = Fifth;
			      if (OpenOrders == 5) mylotsi = Sixth;
			      if (OpenOrders == 6) mylotsi = Seventh;
			      if (OpenOrders == 7) mylotsi = Eighth;
			      if (OpenOrders == 8) mylotsi = Ninth;
			      if (OpenOrders == 9) mylotsi = Tenth;
			      if (OpenOrders > 9)  mylotsi = EleventhPlus;
			      NormalizeDouble(mylotsi,2);
		    } else { mylotsi=lotsi; }
		    if (mylotsi>100) { mylotsi=100; }
		    OrderSend(Symbol(),OP_BUY,mylotsi,BuyPrice,slippage,sl,tp,"10 pt 3 cutoff",MagicNumber,0,Blue);		    
		    return(0);
	     }
      }   

//----
   return(0);
  }
//+------------------------------------------------------------------+






int CheckExit()
{

if (Profit<-MaxLoss) 
   {	  
	  for(cnt=OrdersTotal();cnt>=0;cnt--)
	  {
	     OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
	  	  mode=OrderType();
		  if (OrderSymbol()==Symbol()) 
		  {
			if (mode==OP_BUY) { OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),slippage,Blue); }
			if (mode==OP_SELL) { OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),slippage,Red); }
			return(0);
		 }
	  }
   }



}


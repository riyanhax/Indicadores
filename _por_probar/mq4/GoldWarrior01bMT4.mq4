//+------------------------------------------------------------------+
//| GoldWarrior01bMT4.mq4 |
//| Star |
//| Copyright � 2005, HomeSoft Corp. and Star|
//+------------------------------------------------------------------+
#property copyright "Copyright � 2005, HomeSoft Corp. and Star"
#property link "bors224@mail.ru"

extern double Lots =0.1;
extern double StopLoss = 1000;
extern double TakeProfit = 50;
extern double TrailingStop = 0;
extern int ZN=1,ZM=0, per=14,d=3,depth=12,deviation=5,backstep=3,mgod=2005,porog=300,test=1,
imps=30,impb=-30,k1=2,k2=4;
double LastTradeTime;
double kors=0.30,korb=0.15,ZZ2=0,ZZ3=0,cci0=0,cci1=0,nimp =0,wpr0=0,wpr1=0,summa=0,
down=0,imp=0,mlot=0,ZZ0=0,ssum=0,bsum=0;
int cnt=0,j=0,ssig=0,bsig=0,b=0,bsb=0,sbo=0,bloks=0,blokb=0,pm=0,s=0,blok=1;

//---------------------------------------------------------------------------------------------------------------------//
// per - ?????? ???? ??????????? //
// d - ?????????? ?????? ???????? ??? ??????? //
// depth,deviation,backstep - ????????? ?????????? ?????? // 
// mgod - ??? ???????????? //
// porog - ???????? ??????????? ????-??????? ??? ???????? ???? ??????? //
// test - ???? ?????? ??????? ?????????? - ??? 1 ????????? ? ?????? //
// imps - ????????? ???????? ????????????? ????? ???????? ???? ??? 
// ???????????? ??????? ?? ??????? //
// impb - ????????? ???????? ????????????? ????? ???????? ???? ???
// ???????????? ??????? ?? ??????? //
// k1 & k2 - ????????? ??? ??????????? ??????? ????? ????-??????? 
//??????? ? ??????? ??????. k2/k1=2 - ??????????? //
//---------------------------------------------------------------------------------------------------------------------//

void SetArrow(datetime t, double p, int k, color c) 
{
ObjectSet("Arrow", OBJPROP_TIME1 , t);
ObjectSet("Arrow", OBJPROP_PRICE1 , p);
ObjectSet("Arrow", OBJPROP_ARROWCODE, k);
ObjectSet("Arrow", OBJPROP_COLOR , c);
} 
int start()
{ 
{
LastTradeTime=GlobalVariableGet("LastTradeTime");
if (mgod!=Year()) 
j=j+1;
if (j==10000) j=0;//??????? ?????
if (k2<2*k1)
{
Comment("??? ?????????? ?????? ???? ????????? ?2!",
"\n","?2 ?????? ???? ?? ????? 2*?1");
return(0);
} 
if (sbo==0 && AccountBalance()<1000)
{
Comment("??? ?????????? ?????? ????????? ??? ??????? ?? ???????????? ??????? ? 1000$");
return(0);
} 
imp=iCustom(NULL,0,"DayImpuls",per,d,0,1); //?????????? ???????????
nimp=iCustom(NULL,0,"DayImpuls",per,d,0,0);
ZZ3=iCustom(NULL,0,"Zigzag",depth,deviation,backstep,ZN);
ZZ2=iCustom(NULL,0,"Zigzag",depth,deviation,backstep,ZM);
cci1=iCCI(NULL,0,per,PRICE_CLOSE,1);
cci0=iCCI(NULL,0,per,PRICE_CLOSE,0);
wpr1=iWPR(NULL,0,per,1);
wpr0=iWPR(NULL,0,per,0);

if ((ZZ3!=0 || ZZ2!=0)//?????? ??? ????????
&& cci0 && cci1>0 
&& cci0>0 
&& nimp<0 
&& imp>0)
{ 
SetArrow(Time[0],High[0]+5*Point,242,GreenYellow);
ssig=1;
Comment("ZZ0=",MathRound(ZZ2)," ZZ1=",MathRound(ZZ3)," CCI0=",MathRound(cci0)," Impuls=",MathRound(nimp),
"\n","???? ??? iZigZag ????????? ????? - ?????? ???? ????? ??????");
}

if ((ZZ3!=0 || ZZ2!=0) //?????? ??? ???????
&& cci0>cci1 
&& cci1<0 
&& cci0<0 
&& nimp>0 
&& imp<0) 
{
SetArrow(Time[0],Low[0]-5*Point,241,Gold);
bsig=1;
Comment("ZZ0=",MathRound(ZZ2)," ZZ1=",MathRound(ZZ3)," CCI0=",MathRound(cci0)," Impuls=",MathRound(imp),
"\n","???? ??? iZigZag ????????? ???? - ???? ???? ????? ??????");
}

if ((ZZ2==0 && ZZ3==0)//?????? ?????????? ??????
|| sbo!=0 //?????? ??????? ???????? ???????
|| (imp<=imps && imp>=impb))
{
ssig=0;//?????? ???????
bsig=0; //?????? ???????
Comment("ZZ0=",MathRound(ZZ2)," ZZ1=",MathRound(ZZ3)," CCI1=",MathRound(cci1)," CCI0=",MathRound(cci0),
" Impuls=",MathRound(imp),
"\n"," ?????? ?? ?????????? ?????? ???????????");
}
}

sbo=0;s=0;b=0;summa=0;ssum=0;bsum=0;
for (cnt=1; cnt {
if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)) 
{
sbo=sbo+1;//???? ???????? ???????
if ((OrderType()==OP_SELL && OrderSymbol()==Symbol()) || (OrderType()==OP_BUY && OrderSymbol()==Symbol()))
summa=summa+OrderProfit();// ?????? ?? ???????? ??????? 
}
if ((OrderType()==OP_SELL && OrderSymbol()==Symbol())) 
{ 
s=s+1;//?????? ???????? ??????? - ???????
ssum=ssum+OrderProfit();//?????? ??? ???????
}
if (OrderType()==OP_BUY && OrderSymbol()==Symbol())
{ 
b=b+1;//?????? ???????? ??????? - ???????
bsum=bsum+OrderProfit();//?????? ??? ???????
}
}
if ((s+b)==0) porog=300; //???????? ?????????? ???????? ???????

if (blok==0) //??????? ? ?????? ? ????????? ????? ??????? ??????
{
if (s==1 
&& summa>0 //??????? ? ??????? ??????? ??? ??????? ?????? 30
&& cci0>50 
&& nimp>0 
&& imp>nimp) 
{
mlot=k1*Lots;
int ticket=OrderSend(Symbol(),OP_SELL,mlot,Bid,3,Bid+StopLoss*Point,Bid-TakeProfit*Point,"Sculp_Sell",1,0,Yellow);
bsb=0; //?????????? ?? ???????? ????? ??????? ??????
blok=1; //?????????? ?? ???????? ????? ??????? ??????
return(0);
}
//}

if (s==1 //????????? Hedg ??????? ?????? ???????? ???????
&& summa<-30
&& cci0<-120 
&& nimp<-30 
&& imp {
mlot=k1*Lots;
ticket=OrderSend(Symbol(),OP_BUY,mlot,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,"Sculp_BUY",1,0,Yellow);
//Setorder(OP_BUY,mlot,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,Gold);
bsb=0; //?????????? ?? ???????? ????? ??????? ??????
blok=1;//?????????? ?? ???????? ????? ??????? ??????
return(0);
} 
// }
if (b==1 //????????? Hedg ??????? ?????? ???????? ???????
&& summa<-30 
&& cci0>120 
&& nimp>30 
&& imp>nimp) 
{
mlot=k1*Lots;
ticket=OrderSend(Symbol(),OP_SELL,mlot,Bid,3,Bid+StopLoss*Point,Bid-TakeProfit*Point,"Sculp_Sell",1,0,Yellow);
// Setorder(OP_SELL,mlot,Bid,3,Bid+StopLoss*Point,Bid -TakeProfit*Point,Gold);
bsb=0; //?????????? ?? ???????? ????? ??????? ??????
blok=1; //?????????? ?? ???????? ????? ??????? ??????
return(0);
}

if(b==1 //??????? ? ??????? ??????? ??? ??????? ?????? 30
&& summa>0 
&& cci0<-50 
&& nimp<0 
&& imp {
mlot=k1*Lots;
ticket=OrderSend(Symbol(),OP_BUY,mlot,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,"Sculp_BUY",1,0,Yellow);
//Setorder(OP_BUY,mlot,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,Gold);
bsb=0;//?????????? ?? ???????? ????? ??????? ??????
blok=1;//?????????? ?? ???????? ????? ??????? ??????
return(0);
}
}//*/

if (blok==1 // ????????? ????? ??????? ??????
&& (b+s)==2 
&& summa<-2000 //???????? ???????? ??????
&& bsb==0 )//?????????? ?? ???????? ????? ??????? ??????
{ 
// ????????? ????? ??????? ?????? ??? ???????
if (((b==1 && s==1)
|| b==2
|| (b==1 && s==0))
&& bsum<0 
&& nimp>50)
{ 
mlot=k2*Lots;
ticket=OrderSend(Symbol(),OP_SELL,mlot,Bid,3,Bid+StopLoss*Point,Bid-TakeProfit*Point,"Sculp_Sell",1,0,Yellow);
//Setorder(OP_SELL,mlot,Bid,3,Bid+StopLoss*Point,Bid -TakeProfit*Point,Gold);
bsb=1; //?????? ?? ???????? ????? ??????? ?????? ????????
porog=100;
return(0);
}

// ????????? ????? ??????? ?????? ??? ??????? 
if (((s==1 && b==1) 
|| s==2
|| (s==1 && b==0)) 
&& ssum<0 
&& nimp<-50) 
{
mlot=k2*Lots;
ticket=OrderSend(Symbol(),OP_BUY,mlot,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,"Sculp_BUY",1,0,Yellow); 
//Setorder(OP_BUY,mlot,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,Gold);
bsb=1; //?????? ?? ???????? ????? ??????? ?????? ????????
porog=100;
return(0);
}
}//*/

if (sbo==0) //???????? ??????? ???
{
bloks=0;//?????????? ?? ???????? ??????? ??????
blokb=0;//?????????? ?? ???????? ??????? ???????
pm=0; //?????? ?? ??????? ?? ???????? ???????? ???????
bsb=1;//?????? ?? ???????? ????? ??????? ?????? ????????
}//*/

if (summa<0 
&& down>summa) 
down=(MathRound(summa)); //???????? ??????

if (test==1) //?????????? ?? ?????? ?????? ? ?????? ??? ?? ?????
{
Print ("Data: ",Year(),".",Month(),".",Day()," Time ",Hour(),":",Minute(),":",Seconds(),
" Bloks=",bloks," Blokb=",blokb, " Blok=",blok," ZZ0=",MathRound(ZZ2),
" ZZ1=",MathRound(ZZ3)," CCI0=",MathRound(cci0)," Imp=",MathRound(nimp),
" Prof=",MathRound(summa)," DDown=",MathRound(down/30)," BSB=",bsb);
if (j<=2) Comment(" ");
} 
else 
{
Comment ("Data: ",Year(),".",Month(),".",Day()," Time ",Hour(),":",Minute(),":",Seconds(),
" Bloks=",bloks," Blokb=",blokb," Blok=",blok," ZZ0=",MathRound(ZZ2),
" ZZ1=",MathRound(ZZ3)," CCI0=",MathRound(cci0)," Imp=",MathRound(nimp),
" Prof=",MathRound(summa)," DDown=",MathRound(down/30));
}//*/

if (CurTime()-LastTradeTime<15) return(0); 
if (summa>porog) // ????? ?? ???????
{pm=1;}
if (pm==1) //???????? ??????? ?? ???????
{
for (cnt=1; cnt {
OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
if (OrderType()==OP_SELL && OrderSymbol()==Symbol()) 
{
OrderClose(OrderTicket(),OrderLots(),Ask,5,Red);
return(0);
}
if (OrderType()==OP_BUY && OrderSymbol()==Symbol()) 
{
OrderClose(OrderTicket(),OrderLots(),Bid,5,Red);
return(0);
}
}
} //*/

if (AccountFreeMargin()>=1000 //???????? ????? ???????
&& sbo==0 //???????? ??????? ???
&& (Minute()==14 || Minute()==29 || Minute()==44 || Minute()==59) //??????????? ????? ???????
&& Seconds()>=45) //?????? ? ??????? ?????
{
mlot=Lots; 
{if (ssig==1 && bloks==0) 
{
SetArrow(Time[0],High[0]+5*Point,242,Red); 
ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+StopLoss*Point,Bid-TakeProfit*Point,"Sculp_Sell",1,0,Yellow);
blokb=1;//?????? ?????????? ???????? ??????? ?? ???????
bsb=1; //?????? ?? ???????? ????? ??????? ?????? ????????
blok=0; //?????????? ?? ???????? ??????? ?? ??????? ? ????????? ????? ??????? ??????
GlobalVariableSet("LastTradeTime",CurTime());
return(0);
}
{
if (bsig==1 && blokb==0)
{
SetArrow(Time[0],Low[0]-5*Point,241,Gold); 
ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,"Sculp_Sell",1,0,Yellow); 
bloks=1;//?????? ?????????? ???????? ??????? ?? ???????
bsb=1; //?????? ?? ???????? ????? ??????? ?????? ????????
blok=0; //?????????? ?? ???????? ??????? ?? ??????? ? ????????? ????? ??????? ??????
GlobalVariableSet("LastTradeTime",CurTime());
return(0);
} 
}
return(0);
}//---------End-----------
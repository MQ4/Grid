//+------------------------------------------------------------------+
//|                                                            otinn |
//|                                          https://weibo.com/otinn |
//+------------------------------------------------------------------+
#property copyright "点我+Q群152036642"
#property link      "https://shang.qq.com/wpa/qunwpa?idkey=5e9b9aca378e2fccb5cde77b999ab27cd4ffef0e51d3ec2f253e46ae7009d1fc#"
//#property description "如有问题请+Q群152036642"
#property version   "1.00"
#property strict
//
enum Mode{多单,空单};
input Mode     UpMode=多单;//上部模式
input Mode     DnMode=空单;//下部模式
input double   LotSize=0.1;//挂单手数 
input int      MaxNum=5;     //最大单数
input int      Step=30;      //间隔点数
input int      TakeProfit=0; //止盈点数
input int      StopLoss=0;   //止损点数
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Trade
  {
protected:
   string            Symbol;
   int               Stop,Take;
   int               MagicNum;
   int               SlipPage;
   string            Comments;
   double Point(){return MarketInfo(this.Symbol,MODE_POINT);}
   double Bid(){return MarketInfo(this.Symbol,MODE_BID);}
   double Ask(){return MarketInfo(this.Symbol,MODE_ASK);}
   int Digits(){return (int)MarketInfo(this.Symbol,MODE_DIGITS);}
   int Open(int type,double op,double lot,string comm)
     {
      for(int i=OrdersTotal()-1;i>=0;i--)
        {
         if(!OrderSelect(i,SELECT_BY_POS))continue;
         if(OrderSymbol()!=this.Symbol)continue;
         if(OrderMagicNumber()!=this.MagicNum)continue;
         if(OrderType()%2!=type)continue;
         if(StringFind(OrderComment(),comm,0)>=0)return(0);
        }
      int mode=-1;double sl=0,tp=0;
      if(type==0)
        {
         mode=op>this.Ask()?OP_BUYSTOP:OP_BUYLIMIT;
         if(this.Stop!=0)sl=op-this.Stop*this.Point();
         if(this.Take!=0)tp=op+this.Take*this.Point();
        }
      else if(type==1)
        {
         mode=op>this.Bid()?OP_SELLLIMIT:OP_SELLSTOP;
         if(this.Stop!=0)sl=op+this.Stop*this.Point();
         if(this.Take!=0)tp=op-this.Take*this.Point();
        }
      else return(-1);
      int tix=OrderSend(this.Symbol,mode,lot,op,SlipPage,sl,tp,comm,MagicNum,0,(mode%2==0?Red:Lime));
      if(tix<=0)Print((string)mode+"  op="+(string)op+"  Guadan Error #",GetLastError());
      return(tix);
     }
public:
   void Trade(string sym,int stop,int take)
     {
      this.Symbol=sym;
      this.Stop=stop;
      this.Take=take;
      this.MagicNum=888;
      this.SlipPage=9;
      this.Comments="+Q群152036642:";
     }
  };
//
class Grid:public Trade
  {
private:
   double            Begin;
   int               Step;
   double            Lots;
   int               UpMode,DnMode;
   int               MaxNum;
   double            UpStart,DnStart;
   double UpOpen()
     {
      double opp=EMPTY_VALUE;
      int num=0,i=1;
      while(num<MaxNum)
        {
         opp=this.UpStart+this.Step*i*this.Point();
         Open(this.UpMode,opp,this.Lots,this.Comm(opp));
         num++;i++;
        }
      return opp;
     }
   double DnOpen()
     {
      double opp=0;
      int num=0,i=1;
      while(num<MaxNum)
        {
         opp=this.DnStart-Step*i*this.Point();
         Open(this.DnMode,opp,this.Lots,this.Comm(opp));
         num++;i++;
        }
      return opp;
     }
   void Delete(double max,double min)
     {
      for(int i=OrdersTotal()-1;i>=0;i--)
        {
         if(!OrderSelect(i,SELECT_BY_POS))continue;
         if(OrderSymbol()!=this.Symbol)continue;
         if(OrderMagicNumber()!=this.MagicNum)continue;
         bool result=true;
         if(OrderOpenPrice()>max || OrderOpenPrice()<min) result=OrderDelete(OrderTicket(),Yellow);
         if(result==false){Print("CloseError  "+(string)OrderTicket()+"  "+(string)GetLastError());Sleep(3000);}
         else Sleep(1000);
        }
     }
   string Comm(double opp){return this.Comments+DoubleToString(opp,this.Digits());}
public:
   void Grid(string sym,double lots,int step,
             int upMode,int dnMode,int maxNum,
             int stop,int take):Trade(sym,stop,take)
     {
      this.Lots=lots;
      this.UpMode=upMode;
      this.DnMode=dnMode;
      this.MaxNum=maxNum;
      this.Step=step;
     }
   void Loop()
     {
      double num=(this.Bid()-this.Begin)/Step/this.Point();
      this.UpStart=(this.Begin+MathCeil(num)*this.Step*this.Point());
      this.DnStart=(this.Begin+MathFloor(num)*this.Step*this.Point());
      Comment(this.UpStart,"  ",this.DnStart);
      double max=this.UpOpen();
      double min=this.DnOpen();
      this.Delete(max+this.Step/2*this.Point(),min-this.Step/2*this.Point());
     }
  };
Grid G(Symbol(),LotSize,Step,UpMode,DnMode,MaxNum,StopLoss,TakeProfit);
//
int OnInit(){return(INIT_SUCCEEDED);}
//
void OnDeinit(const int reason){}
//
void OnTick(){G.Loop();}
//

//+------------------------------------------------------------------+
//|                                             DT_channel_trade.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_icons.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
#include <WinUser32.mqh>

double CHANNEL_LOT = 0.1;
int CT_TIMER1 = 0;
int CT_TIMER2 = 0;
int CT_START_TIME;
double CT_OFFSET = 0.0;
double CT_MIN_DIST = 0.0;
double CT_MAX_DIST = 0.0;
string CT_LINES[];

int init(){
  CT_OFFSET = 60/MarketInfo(Symbol(),MODE_TICKVALUE)*Point;
  CT_MIN_DIST = 333/MarketInfo(Symbol(),MODE_TICKVALUE)*Point;
  CT_MAX_DIST = 1100/MarketInfo(Symbol(),MODE_TICKVALUE)*Point;
  CT_START_TIME = GetTickCount() + 180000; // 3 min
  return(0);
}

int start(){
  if( GetTickCount() > CT_TIMER1 ){
    CT_TIMER1 = GetTickCount() + 6000;
    setChannelLinesArr();
  }

  if( GetTickCount() > CT_TIMER2 ){
    CT_TIMER2 = GetTickCount() + 4000;

    int ticket, o_type;
    string comment, ts;
    double fibo_100 = 0.0, fibo_23_dif, trade_line_price, spread, op;

    ticket = getOpenPositionByMagic(Symbol(), 333);
    if( ticket != 0 ){
      o_type = OrderType();

      if( o_type < 2 ){
        return (0);
      }else{
        comment = OrderComment();
        ts = StringSubstr(comment, 0, 10);
        trade_line_price = ObjectGetValueByShift( "DT_GO_t_line_"+ts, 0);
        spread = getMySpread();
        op = NormalizeDouble( OrderOpenPrice(), Digits );
        double new_op;

        if( o_type == OP_BUYLIMIT ){
          new_op = NormalizeDouble( trade_line_price + spread, Digits );
        }else{
          new_op = NormalizeDouble( trade_line_price, Digits );
        }
        
        if( new_op == op ){
          return (0);
        }else{
          double new_sl, new_tp;
          fibo_100 = StrToDouble(StringSubstr(comment, 11, StringLen(comment)-11));
          fibo_23_dif = getFibo23Dif( trade_line_price, fibo_100 );

          if( o_type == OP_BUYLIMIT ){            
            new_sl = NormalizeDouble( trade_line_price - fibo_23_dif, Digits );
            new_tp = NormalizeDouble( trade_line_price + fibo_23_dif, Digits );
          }else{            
            new_sl = NormalizeDouble( trade_line_price + fibo_23_dif + spread, Digits );
            new_tp = NormalizeDouble( trade_line_price - fibo_23_dif + spread, Digits );
          }

          OrderModify(ticket, new_op, new_sl, new_tp, TimeCurrent()+5400);

/* !! */  Print(StringConcatenate("Mod: ", Symbol(), " Order type:", o_type, " Ticket:", ticket, " Open price:", new_op, " Stop loss:", new_sl, " Take profit:", new_tp, " Expired:", TimeCurrent()+5400, " Bid:", Bid, " Ask:", Ask));
/* !! */  Alert(StringConcatenate("Mod: ", Symbol(), " Order type:", o_type, " Ticket:", ticket, " Open price:", new_op, " Stop loss:", new_sl, " Take profit:", new_tp, " Expired:", TimeCurrent()+5400, " Bid:", Bid, " Ask:", Ask));

/* !! */  ObjectSet("DT_GO_channel_hist_op_"+ts, OBJPROP_TIME1, new_op);
/* !! */  ObjectSet("DT_GO_channel_hist_sl_"+ts, OBJPROP_TIME1, new_sl);
/* !! */  ObjectSet("DT_GO_channel_hist_tp_"+ts, OBJPROP_TIME1, new_tp);

          if( !errorCheck("Channel trade OrderModify Bid:"+ Bid+ " Ask:"+ Ask)){
            return(0);
          }
        }
      }

    }else{
      double h, l;
      string trade_line = "";

      RefreshRates();
      l = iLow( NULL, PERIOD_H1, 0);
      h = iHigh( NULL, PERIOD_H1, 0);
      
      int i, len = ArraySize(CT_LINES);
      for( i = 0; i < len; i++ ) {
        trade_line_price = ObjectGetValueByShift( CT_LINES[i], 0 );
        if( trade_line_price != 0.0){
          if( ( l < trade_line_price + CT_OFFSET && l > trade_line_price - CT_OFFSET ) || ( h > trade_line_price - CT_OFFSET && h < trade_line_price + CT_OFFSET ) ){
            fibo_23_dif = getFibo23Dif( trade_line_price, fibo_100, 9901, CT_MIN_DIST, CT_MAX_DIST );
            if( fibo_23_dif != 0.0 ){
              trade_line = CT_LINES[i];
              break;
            }
          }
        }else{
          GetLastError();
        }  
      }
          
      if( trade_line != "" ){
        double o, sl, tp;

        o = iOpen( NULL, PERIOD_H1, 0);
        spread = getMySpread();
        ts = StringSubstr( trade_line, StringLen( trade_line ) - 10, 10 );
        comment = ts +" "+ DoubleToStr( fibo_100, Digits );

        if( o > trade_line_price ){
          if( l > trade_line_price ){   // ---- BUY LIMIT -----
            o_type = OP_BUYLIMIT;
            op = NormalizeDouble( trade_line_price + spread, Digits );

          }else if( Bid < trade_line_price + fibo_23_dif){  // ------- BUY --------
            o_type = OP_BUY;
            op = NormalizeDouble( Ask, Digits );
          }else{
            return(0);
          }
          sl = NormalizeDouble( trade_line_price - fibo_23_dif, Digits );
          tp = NormalizeDouble( trade_line_price + fibo_23_dif, Digits );

        }else{
          if( h < trade_line_price ){ // ---- SELL LIMIT ----
            o_type = OP_SELLLIMIT;
            op = NormalizeDouble( trade_line_price, Digits );

          }else if( Ask > trade_line_price - fibo_23_dif ){ // ------- SELL -------
            o_type = OP_SELL;
            op = NormalizeDouble( Bid, Digits );
          }else{
            return(0);
          }
          sl = NormalizeDouble( trade_line_price + fibo_23_dif + spread, Digits );
          tp = NormalizeDouble( trade_line_price - fibo_23_dif + spread, Digits );
        }
        if( GetTickCount() < CT_START_TIME ){
          if(IDNO == MessageBox(StringConcatenate("Terminal just started, do you want open position in ", Symbol()), "Channel trading", MB_YESNO|MB_ICONQUESTION )){
            return(0);
          }
        }

        string error_text;
        if( o_type < 2 ){
          ticket = OrderSend(Symbol(), o_type, CHANNEL_LOT, op, 3, 0, 0, comment, 333);
          errorCheck("Channel trade OrderSend");

          OrderSelect( ticket, SELECT_BY_TICKET );
          OrderModify( OrderTicket(), OrderOpenPrice(), sl, tp, 0 );

          error_text = "Channel trade OrderModify";


        }else{
          OrderSend( Symbol(), o_type, CHANNEL_LOT, op, 2, sl, tp, comment, 333, TimeCurrent()+5400 );

          error_text = "Channel trade OrderSend Pending";

        }

        RefreshRates();

/* !! */  Print(StringConcatenate(Symbol(), " Order type:", o_type, " Lots:", CHANNEL_LOT, " Open price:", op, " Stop loss:", sl, " Take profit:", tp, " Comment:", comment, " Magic:", 333, " Expired:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask));
/* !! */  Alert(StringConcatenate(Symbol(), " Order type:", o_type, " Lots:", CHANNEL_LOT, " Open price:", op, " Stop loss:", sl, " Take profit:", tp, " Comment:", comment, " Magic:", 333, " Expired:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask));

/* !! */  createHistoryLine(op, Blue, "Order type: "+o_type+", OP", "op_"+ts);
/* !! */  createHistoryLine(sl, Red, "Order type: "+o_type+", SL", "sl_"+ts);
/* !! */  createHistoryLine(tp, Green, "Order type: "+o_type+", TP", "tp_"+ts);

        errorCheck(error_text+" Bid:"+ Bid+ " Ask:"+ Ask);
        renameChannelLine( trade_line );
        setChannelLinesArr();

      }
    }
    errorCheck("Channel trade");
  }

  return(0);
}

int deinit(){
  return(0);
}

int setChannelLinesArr(){
  int j = 1, i, len;
  string name, type;

  ArrayResize(CT_LINES, 0);
  len= ObjectsTotal();
  for (i= len - 1; i>=0; i--) {
    name = ObjectName(i);
    type = StringSubstr(name,7,8);
    if( type == "_line_s_" ){
      ArrayResize(CT_LINES, j);
      CT_LINES[j-1] = name;
      j++;
    }
  }
  return(0);
}

int createHistoryLine(double price, color c, string text, string ts){
  double offset = PERIOD_H1*60;
  double time1 = Time[0]-offset;
  double time2 = Time[0]+offset;
  string name = "DT_GO_channel_hist_"+ts;

  if(ObjectFind(name) == -1){
    ObjectCreate(name, OBJ_TREND, 0, time1, price, time2, price);
  }else{
    ObjectSet(name, OBJPROP_TIME1, time1);
    ObjectSet(name, OBJPROP_TIME2, time2);
    ObjectSet(name, OBJPROP_PRICE1, price);
    ObjectSet(name, OBJPROP_PRICE2, price);
  }
	ObjectSet(name, OBJPROP_COLOR, c);
	ObjectSet(name, OBJPROP_RAY, false);
	ObjectSet(name, OBJPROP_STYLE, 4);
	ObjectSet(name, OBJPROP_BACK, true);
	ObjectSetText(name, text, 8);
}


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

int CT_TIMER1 = 0;
int CT_TIMER2 = 0;
double CT_OFFSET = 0.0;
string CT_LINES[];

int init(){
  CT_OFFSET = 75/MarketInfo(Symbol(),MODE_TICKVALUE)*Point;
  return(0);
}

int start(){
  if( GetTickCount() > CT_TIMER1 ){
    CT_TIMER1 = GetTickCount() + 6000;
    setChannelLinesArr();
  }
  
  if( GetTickCount() > CT_TIMER2 ){
    CT_TIMER2 = GetTickCount() + 4000;
    
    int i, len, ticket;
    double cur_l_price, spread, dif;
    len = OrdersTotal();
    for( i = 0; i < len; i++ ){      
      if( OrderSelect(i, SELECT_BY_POS) ){        
        if( OrderSymbol() == Symbol() ){
          if( OrderMagicNumber() == 333 ){
return (0);
/*          
            int o_type = OrderType();
            if( o_type < 2){
              return (0);
            }else{
              double op, sl, tp;
              string ts = OrderComment();
              int 
              sl = OrderStopLoss();
              tp = OrderTakeProfit();
              op = OrderOpenPrice();
              cur_l_price = ObjectGetValueByShift( "DT_GO_t_line_"+ts, 0);
              ticket = OrderTicket();
              spread = getMySpread();
              
              if( o_type == OP_BUYSTOP ){
                if( cur_l_price+spread == op ){
                  return (0);
                }else{
                  dif = cur_l_price+spread - op;
                  
                  Print(StringConcatenate("Mod: " ,Symbol(), " ", ticket, " ", NormalizeDouble(op+dif, Digits), " ", NormalizeDouble(sl+dif, Digits), " ", NormalizeDouble(tp+dif, Digits), " ", TimeCurrent()+5400));
                  Alert(StringConcatenate("Mod: " ,Symbol(), " ", ticket, " ", NormalizeDouble(op+dif, Digits), " ", NormalizeDouble(sl+dif, Digits), " ", NormalizeDouble(tp+dif, Digits), " ", TimeCurrent()+5400));
                
                  OrderModify(ticket, NormalizeDouble(op+dif, Digits), NormalizeDouble(sl+dif, Digits), NormalizeDouble(tp+dif, Digits), TimeCurrent()+5400);
              
              //--------------------------------------------   
                  ObjectSet("DT_GO_channel_hist_op_"+ts, OBJPROP_TIME1, op+dif);
                  ObjectSet("DT_GO_channel_hist_sl_"+ts, OBJPROP_TIME1, sl+dif);
                  ObjectSet("DT_GO_channel_hist_tp_"+ts, OBJPROP_TIME1, tp+dif);
              //-------------------------------------------- 
                }
              }else{
                if( cur_l_price == op ){
                  return (0);
                }else{
                  dif = cur_l_price - op;
                  
                  Print(StringConcatenate("Mod: " ,Symbol(), " ", ticket, " ", NormalizeDouble(op+dif, Digits), " ", NormalizeDouble(sl+dif, Digits), " ", NormalizeDouble(tp+dif, Digits), " ", TimeCurrent()+5400));
                  Alert(StringConcatenate("Mod: " ,Symbol(), " ", ticket, " ", NormalizeDouble(op+dif, Digits), " ", NormalizeDouble(sl+dif, Digits), " ", NormalizeDouble(tp+dif, Digits), " ", TimeCurrent()+5400));
                
                  OrderModify(ticket, NormalizeDouble(op+dif, Digits), NormalizeDouble(sl+dif, Digits), NormalizeDouble(tp+dif, Digits), TimeCurrent()+5400);
              
              //--------------------------------------------   
                  ObjectSet("DT_GO_channel_hist_op_"+ts, OBJPROP_TIME1, op+dif);
                  ObjectSet("DT_GO_channel_hist_sl_"+ts, OBJPROP_TIME1, sl+dif);
                  ObjectSet("DT_GO_channel_hist_tp_"+ts, OBJPROP_TIME1, tp+dif);
              //-------------------------------------------- 
                }
              
              }
            }
*/            
          }
        }
      }
    }
    
    len = ArraySize(CT_LINES);
    double h, l, o;
    if( len > 0 ){
      RefreshRates();
      l = iLow( NULL, PERIOD_H4, 0);
      h = iHigh( NULL, PERIOD_H4, 0);
      for( i = 0; i < len; i++ ) {
        cur_l_price = ObjectGetValueByShift( CT_LINES[i], 0);
        if( ( l < cur_l_price + CT_OFFSET && l > cur_l_price - CT_OFFSET ) || ( h > cur_l_price - CT_OFFSET && h < cur_l_price + CT_OFFSET ) ){
        
          o = iOpen( NULL, PERIOD_H4, 0);
          spread = getMySpread();
          double lots = StrToDouble(getGlobal("LOT"));
          string comment = StringSubstr(CT_LINES[i], StringLen(CT_LINES[i])-10, 10);
          double fibo_23 = getFibo23(cur_l_price, comment);
          
          if( o > cur_l_price ){
            if( l > cur_l_price ){
              Print(StringConcatenate(Symbol(), " ", OP_BUYSTOP, " ", lots, " ", NormalizeDouble(cur_l_price+spread, Digits), " ", 2, " ", NormalizeDouble(cur_l_price-fibo_23, Digits), " ", NormalizeDouble(cur_l_price+fibo_23, Digits), " ", comment, " ", 333, " ", TimeCurrent()+5400));
              Alert(StringConcatenate(Symbol(), " ", OP_BUYSTOP, " ", lots, " ", NormalizeDouble(cur_l_price+spread, Digits), " ", 2, " ", NormalizeDouble(cur_l_price-fibo_23, Digits), " ", NormalizeDouble(cur_l_price+fibo_23, Digits), " ", comment, " ", 333, " ", TimeCurrent()+5400));
              OrderSend(Symbol(), OP_BUYSTOP, lots, NormalizeDouble(cur_l_price+spread, Digits), 2, NormalizeDouble(cur_l_price-fibo_23, Digits), NormalizeDouble(cur_l_price+fibo_23, Digits), comment, 333, TimeCurrent()+5400 );
          
          //--------------------------------------------    
              createHistoryLine(NormalizeDouble(cur_l_price+spread, Digits), Blue, "buy stop OP", "op_"+comment);
              createHistoryLine(NormalizeDouble(cur_l_price-fibo_23, Digits), Red, "buy stop SL", "sl_"+comment);
              createHistoryLine(NormalizeDouble(cur_l_price+fibo_23, Digits), Green, "buy stop TP", "tp_"+comment);
          //--------------------------------------------    
              
            }else{
              Print(StringConcatenate(Symbol(), " ", OP_BUY, " ", lots, " ", NormalizeDouble(cur_l_price, Digits), "(", Ask,")", " ", 2, " ", NormalizeDouble(cur_l_price-fibo_23, Digits), " ", NormalizeDouble(cur_l_price+fibo_23, Digits), " ", comment, " ", 333, " ", TimeCurrent()+5400));
              Alert(StringConcatenate(Symbol(), " ", OP_BUY, " ", lots, " ", NormalizeDouble(cur_l_price, Digits), "(", Ask,")", " ", 2, " ", NormalizeDouble(cur_l_price-fibo_23, Digits), " ", NormalizeDouble(cur_l_price+fibo_23, Digits), " ", comment, " ", 333, " ", TimeCurrent()+5400));
              
              ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, 3, 0, 0, comment, 333);
              OrderSelect(ticket, SELECT_BY_TICKET);
              OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(cur_l_price-fibo_23, Digits), NormalizeDouble(cur_l_price+fibo_23, Digits), 0);
              
          //--------------------------------------------    
              createHistoryLine(NormalizeDouble(cur_l_price, Digits), Blue, "buy OP", "op_"+comment);
              createHistoryLine(NormalizeDouble(cur_l_price-fibo_23, Digits), Red, "buy SL", "sl_"+comment);
              createHistoryLine(NormalizeDouble(cur_l_price+fibo_23, Digits), Green, "buy TP", "tp_"+comment);
              createHistoryLine(NormalizeDouble(Ask, Digits), Orange, "buy ASK", "op2_"+comment);
          //--------------------------------------------    
            }
          }else{
            if( h < cur_l_price ){
              Print(StringConcatenate(Symbol(), " ", OP_SELLSTOP, " ", lots, " ", NormalizeDouble(cur_l_price, Digits), " ", 2, " ", NormalizeDouble(cur_l_price+fibo_23+spread, Digits), " ", NormalizeDouble(cur_l_price-fibo_23+spread, Digits), " ", comment, " ", 333, " ", TimeCurrent()+5400));
              Alert(StringConcatenate(Symbol(), " ", OP_SELLSTOP, " ", lots, " ", NormalizeDouble(cur_l_price, Digits), " ", 2, " ", NormalizeDouble(cur_l_price+fibo_23+spread, Digits), " ", NormalizeDouble(cur_l_price-fibo_23+spread, Digits), " ", comment, " ", 333, " ", TimeCurrent()+5400));
              OrderSend(Symbol(), OP_SELLSTOP, lots, NormalizeDouble(cur_l_price, Digits), 2, NormalizeDouble(cur_l_price+fibo_23+spread, Digits), NormalizeDouble(cur_l_price-fibo_23+spread, Digits), comment, 333, TimeCurrent()+5400 );
              
          //--------------------------------------------    
              createHistoryLine(NormalizeDouble(cur_l_price, Digits), Blue, "Sell stop OP", "op_"+comment);
              createHistoryLine(NormalizeDouble(cur_l_price+fibo_23+spread, Digits), Red, "Sell stop SL", "sl_"+comment);
              createHistoryLine(NormalizeDouble(cur_l_price-fibo_23+spread, Digits), Green, "Sell stop TP", "tp_"+comment);
          //--------------------------------------------
              
            }else{
              Print(StringConcatenate(Symbol(), " ", OP_SELL, " ", lots, " ", NormalizeDouble(cur_l_price, Digits), "(", Bid,")", " ", 2, " ", NormalizeDouble(cur_l_price+fibo_23+spread, Digits), " ", NormalizeDouble(cur_l_price-fibo_23+spread, Digits), " ", comment, " ", 333, " ", TimeCurrent()+5400));
              Alert(StringConcatenate(Symbol(), " ", OP_SELL, " ", lots, " ", NormalizeDouble(cur_l_price, Digits), "(", Bid,")", " ", 2, " ", NormalizeDouble(cur_l_price+fibo_23+spread, Digits), " ", NormalizeDouble(cur_l_price-fibo_23+spread, Digits), " ", comment, " ", 333, " ", TimeCurrent()+5400));
              
              ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, 3, 0, 0, comment, 333);
              OrderSelect(ticket, SELECT_BY_TICKET);
              OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(cur_l_price+fibo_23+spread, Digits), NormalizeDouble(cur_l_price-fibo_23+spread, Digits), 0);
              
          //--------------------------------------------    
              createHistoryLine(NormalizeDouble(cur_l_price, Digits), Blue, "Sell OP", "op_"+comment);
              createHistoryLine(NormalizeDouble(cur_l_price+fibo_23+spread, Digits), Red, "Sell stop SL", "sl_"+comment);
              createHistoryLine(NormalizeDouble(cur_l_price-fibo_23+spread, Digits), Green, "Sell stop TP", "tpp_"+comment);
              createHistoryLine(NormalizeDouble(Bid, Digits), Orange, "Sell Bid", "op2_"+comment);
          //--------------------------------------------
            }
            
          }
          errorCheck("Channel trade");
          // deselect
          renameChannelLine(CT_LINES[i]);
          setChannelLinesArr();
          return(1);
        }
      }
    }
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

double getFibo23(double fibo_0, string comment){
  double time;
  double fibo_100 = getZigZag(PERIOD_M15, 12, 5, 3, 0, time);
  
  //--------------------------------------------    
      createHistoryLine(NormalizeDouble(fibo_100, Digits), Black, "fibo_100", "f100_"+comment);
  //--------------------------------------------    
  return ( (MathMax(fibo_0, fibo_100)-MathMin(fibo_0, fibo_100)) * 0.23 ); // 0.236
}

int createHistoryLine(double price, color c, string text, string ts){
  double offset = PERIOD_H4*60;
  double time1 = Time[0]-offset;
  double time2 = Time[0]+offset;
  string name = "DT_GO_channel_hist_"+ts;
  
  ObjectCreate(name, OBJ_TREND, 0, time1, price, time2, price);
	ObjectSet(name, OBJPROP_COLOR, c);             
	ObjectSet(name, OBJPROP_RAY, false);
	ObjectSet(name, OBJPROP_STYLE, 4);
	ObjectSet(name, OBJPROP_BACK, true);
	ObjectSetText(name, text, 8);
}

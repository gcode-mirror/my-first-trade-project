//+------------------------------------------------------------------+
//|                                                    t_line_DT.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_icons.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  double price = WindowPriceMax(0)-((WindowPriceMax(0)-WindowPriceMin(0))/10);
  double time = TimeLocal();
  double t1 = Time[WindowLastVisibleBar() + (WindowBarsPerChart() / 3)];
  double t2 = Time[WindowLastVisibleBar() + 20];
  string name = "DT_GO_cLine_g0_sig_"+DoubleToStr( time, 0 );
  
  ObjectCreate(name, OBJ_TREND, 0, t1, price, t2, price);
  ObjectSet(name, OBJPROP_COLOR, CornflowerBlue);
  ObjectSet(name, OBJPROP_RAY, true);
  ObjectSet(name, OBJPROP_BACK, true);
  ObjectSetText(name, TimeToStr( time, TIME_DATE|TIME_SECONDS)+" G0 ", 8);
  
  if(Period() > PERIOD_H4){    
    ObjectSet(name, OBJPROP_WIDTH, 2);  
  }else{
    ObjectSet(name, OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M5|OBJ_PERIOD_M15|OBJ_PERIOD_M30|OBJ_PERIOD_H1|OBJ_PERIOD_H4);
  }
  
  showCLineGroups();
  
  errorCheck( "t_line_DT" );
  
  return(0);
}
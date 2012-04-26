//+------------------------------------------------------------------+
//|                                                    DT_t_line.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  double price = WindowPriceMax(0)-((WindowPriceMax(0)-WindowPriceMin(0))/10);
  double time1 = Time[WindowBarsPerChart()/4];
  double time2 = Time[0];
  string name = "DT_GO_t_line_"+DoubleToStr(TimeLocal(),0);
  
  ObjectCreate(name, OBJ_TREND, 0, time1, price, time2, price);
  ObjectSet(name, OBJPROP_COLOR, CornflowerBlue);
  ObjectSet(name, OBJPROP_RAY, true);
  ObjectSet(name, OBJPROP_BACK, true);
  
  if(Period() > PERIOD_H4){    
    ObjectSet(name, OBJPROP_WIDTH, 2);  
  }else{
    ObjectSet(name, OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M5|OBJ_PERIOD_M15|OBJ_PERIOD_M30|OBJ_PERIOD_H1|OBJ_PERIOD_H4);
  }
  
  int e = GetLastError();
  if(e != 0){
    Alert(StringConcatenate("Error :",e));
  }
  return(0);
}
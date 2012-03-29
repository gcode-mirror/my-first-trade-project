//+------------------------------------------------------------------+
//|                                                    DT_h_line.mq4 |
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
  string name = "DT_GO_h_line"+DoubleToStr(TimeCurrent(),0);
  
  ObjectCreate(name, OBJ_HLINE, 0, 0, price);
  ObjectSet(name, OBJPROP_COLOR, Peru);
  ObjectSet(name, OBJPROP_RAY, false);
  ObjectSet(name, OBJPROP_BACK, true);
  
  if(Period() > PERIOD_H4){    
    ObjectSet(name, OBJPROP_WIDTH, 2);  
  }else{
    ObjectSet(name, OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M5|OBJ_PERIOD_M15|OBJ_PERIOD_M30|OBJ_PERIOD_H1|OBJ_PERIOD_H4);
  }
  
  return(0);
}
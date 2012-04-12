//+------------------------------------------------------------------+
//|                                                  DT_line_ray.mq4 |
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
  string sel_name = getSelectedLine(WindowTimeOnDropped(), WindowPriceOnDropped());
  
  if( sel_name != "" ){
    double t1, t2, p1, p2;
    t1 = ObjectGet(sel_name,OBJPROP_TIME1);
    t2 = ObjectGet(sel_name,OBJPROP_TIME2);
    p1 = ObjectGet(sel_name,OBJPROP_PRICE1);
    p2 = ObjectGet(sel_name,OBJPROP_PRICE2);
    if(t1 > t2){      
      ObjectSet(sel_name, OBJPROP_TIME1, t2);
      ObjectSet(sel_name, OBJPROP_TIME2, t1);
      ObjectSet(sel_name, OBJPROP_PRICE1, p2);
      ObjectSet(sel_name, OBJPROP_PRICE2, p1);
    }
    if( ObjectGet(sel_name,OBJPROP_RAY) ){
      ObjectSet(sel_name, OBJPROP_RAY, false);
    }else{
      ObjectSet(sel_name, OBJPROP_RAY, true);
    }
  }
  return(0);
}
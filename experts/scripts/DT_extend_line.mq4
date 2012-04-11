//+------------------------------------------------------------------+
//|                                               DT_extend_line.mq4 |
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
  string sel_name = getSelectedLine();
  
  if( sel_name != "" ){
    double t1, t2, p1, p2;
    int shift;
    
    t1 = ObjectGet(sel_name,OBJPROP_TIME1);
    t2 = ObjectGet(sel_name,OBJPROP_TIME2);
    p1 = ObjectGet(sel_name,OBJPROP_PRICE1);
    p2 = ObjectGet(sel_name,OBJPROP_PRICE2);
    if(t1 > t2){      
      ObjectSet(sel_name, OBJPROP_TIME1, t2);
      ObjectSet(sel_name, OBJPROP_TIME2, t1);
      ObjectSet(sel_name, OBJPROP_PRICE1, p2);
      ObjectSet(sel_name, OBJPROP_PRICE2, p1);
      t2 = t1;
    }
    
    shift = ObjectGetShiftByValue(sel_name, p2);    
    
    shift = shift-20;
    
    ObjectSet(sel_name, OBJPROP_RAY, true);
    
    p2 = ObjectGetValueByShift(sel_name, shift);
    if(ObjectSet(sel_name, OBJPROP_PRICE2, p2)){
      ObjectSet(sel_name, OBJPROP_TIME2, getShiftToFuture(t2, 20));
    }    
    
    ObjectSet(sel_name, OBJPROP_RAY, false);
  }
  
  return(0);
}



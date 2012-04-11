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
  string sel_name = getSelectedLine(WindowTimeOnDropped(), WindowPriceOnDropped());
  
  if( sel_name != "" ){
    double t1, t2, p1, p2, tmp, offset = 150*Period()*60;
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
      tmp = t2;
      t2 = t1;
      t1 = tmp;
    }
    ObjectSet(sel_name, OBJPROP_TIME1, t1-offset);
    ObjectSet(sel_name, OBJPROP_TIME2, t2-offset);
    
    shift = ObjectGetShiftByValue(sel_name, p2);    
    Alert(shift+" "+iBarShift( NULL, 0, t2-offset)+" "+TimeToStr( Time[shift], TIME_DATE|TIME_MINUTES) );
    shift = shift-20;
    
    Alert(TimeToStr( t1+offset, TIME_DATE|TIME_MINUTES)+" "+TimeToStr( Time[shift]+offset, TIME_DATE|TIME_MINUTES) );
    
    ObjectSet(sel_name, OBJPROP_RAY, true);
    return(0);
    
    tmp = ObjectGetValueByShift( sel_name, shift );
    ObjectSet(sel_name, OBJPROP_PRICE2, tmp);
    ObjectSet(sel_name, OBJPROP_TIME1, t1+offset);
    ObjectSet(sel_name, OBJPROP_TIME2, Time[shift]+offset);
    
    ObjectSet(sel_name, OBJPROP_RAY, false);
  }
  
  return(0);
}



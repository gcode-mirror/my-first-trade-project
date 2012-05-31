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
  string sel_name = getSelectedLine( WindowTimeOnDropped(), WindowPriceOnDropped(), true );

  if( sel_name != "" && ObjectType( sel_name ) == OBJ_TREND ){
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
      t2 = t1;
    }
    if( ObjectGet(sel_name,OBJPROP_RAY) ){
      ObjectSet(sel_name, OBJPROP_RAY, false);
    }else{
      ObjectSet(sel_name, OBJPROP_RAY, true);
    }
    
    if( t2 > Time[0] ){
      ObjectSet(sel_name, OBJPROP_PRICE2, ObjectGetValueByShift( sel_name, 0 ));
      ObjectSet(sel_name, OBJPROP_TIME2, Time[0]);
    }
    
    addComment(sel_name+" selected.",2);
  }else{
    addComment("Can not find trend line!",1);
  }
  return(0);
}
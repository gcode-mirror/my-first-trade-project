//+------------------------------------------------------------------+
//|                                               DT_select_line.mq4 |
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
  int j, obj_total= ObjectsTotal();
  string type, name, sel_name = "";
  double price, ts, tod, pod, t1, t2, dif, sel_dif = 999999;
  
  tod = WindowTimeOnDropped();
  pod = WindowPriceOnDropped();
  
  for (j= obj_total-1; j>=0; j--) {
    name = ObjectName(j);
    type = StringSubstr(name,6,6);
    if ( type == "t_line"){
      t1 = ObjectGet(name,OBJPROP_TIME1);
      t2 = ObjectGet(name,OBJPROP_TIME2);
      if( MathMax(t1, t2) > tod && MathMin(t1, t2) < tod ){
        price = ObjectGetValueByShift( name, iBarShift(NULL,0,tod));
        dif = MathMax(price, pod) - MathMin(price, pod);
        if( dif < sel_dif ){
          sel_dif = dif;
          sel_name = name;
        }
      }
    }else if( type == "h_line"){
      price = ObjectGet(name, OBJPROP_PRICE1);
      dif = MathMax(price, pod) - MathMin(price, pod);
      if( dif < sel_dif ){
        sel_dif = dif;
        sel_name = name;
      }
    }else{
      continue;
    }
  }
  
  if( sel_name != "" ){
    renameChannelLine(sel_name);
  }
  
  return(0);
}
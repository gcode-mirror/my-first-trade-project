//+------------------------------------------------------------------+
//|                                          DT_pos_fibo100_line.mq4 |
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
    if( ObjectGet( sel_name, OBJPROP_STYLE ) == STYLE_SOLID ){
      ObjectSet( sel_name, OBJPROP_STYLE, STYLE_DASH );
    }else{
      ObjectSet( sel_name, OBJPROP_STYLE, STYLE_SOLID );
    }
  }
  return(0);
}
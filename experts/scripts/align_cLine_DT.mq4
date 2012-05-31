//+------------------------------------------------------------------+
//|                                               align_cLine_DT.mq4 |
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
  double pod = WindowPriceOnDropped();
  double tod = WindowTimeOnDropped();
  int i = 0, len = ObjectsTotal();
  string name, sel_name = "";
  for( ; i < len; i++ ) {
    name = ObjectName(i);
    if( StringSubstr( name, 5, 7 ) == "_cLine_" ){
      if( ObjectGet( name, OBJPROP_COLOR ) == C'128,128,128' ){
        sel_name = name;
      }
    }
  }
  
  if( pod == 0.0 ){
    if( sel_name != "" ){
      renameChannelLine( sel_name );
    }
  }else{
    if( sel_name != "" ){
    }else{
      sel_name = getSelectedLine( tod, pod );
      ObjectSet(name, OBJPROP_COLOR, c);
    }
  
  }
}
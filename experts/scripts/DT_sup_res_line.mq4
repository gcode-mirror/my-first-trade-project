//+------------------------------------------------------------------+
//|                                              DT_sup_res_line.mq4 |
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
  string sel_name = getSelectedLine(tod, pod);
  if( sel_name != "" ){
    double price;
    if( ObjectType(sel_name) == OBJ_TREND ){
      price = ObjectGetValueByShift( sel_name, iBarShift( NULL, 0, tod) );
    }else{
      price = ObjectGet(sel_name,OBJPROP_PRICE1);
    }
    if( pod > price ){
      renameChannelLine( sel_name, "sup" );
    }else{
      renameChannelLine( sel_name, "res" );
    }
  }
  
  return(0);
}
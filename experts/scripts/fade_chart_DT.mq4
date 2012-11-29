//+------------------------------------------------------------------+
//|                                               DT_window_fade.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_functions.mqh>
#include <DT_fade.mqh>

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  if( GlobalVariableGet("DT_window_fade") == 0.0 ){
    GlobalVariableSet( "DT_window_fade", 1.0 );
  }else{
    GlobalVariableSet( "DT_window_fade", 0.0 );
  }
  fakeTick();
  return(0);
}
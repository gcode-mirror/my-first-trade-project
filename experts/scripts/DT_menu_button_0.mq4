//+------------------------------------------------------------------+
//|                                             DT_menu_button_0.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_functions.mqh>
#include <DT_icons.mqh>

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  if( getGlobal( "RULER" ) == 0.0 ){
    setGlobal( "RULER", 1.0 );
  }else{
    setGlobal( "RULER", 0.0 );
  }
  fakeTick();
  return(0);
}
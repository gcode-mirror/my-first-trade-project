//+------------------------------------------------------------------+
//|                                             DT_menu_button_1.mq4 |
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
  if( getGlobal( "SESSION" ) == 0.0 ){
    setGlobal( "SESSION", 1.0 );
  }else{
    setGlobal( "SESSION", 0.0 );
  }
  fakeTick();
  return(0);
}
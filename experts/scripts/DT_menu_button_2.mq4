//+------------------------------------------------------------------+
//|                                             DT_menu_button_2.mq4 |
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
  if( getGlobal( "ARCHIVE" ) == 0.0 ){
    setGlobal( "ARCHIVE", 1.0 );
  }else{
    setGlobal( "ARCHIVE", 0.0 );
  }
  fakeTick();
  return(0);
}
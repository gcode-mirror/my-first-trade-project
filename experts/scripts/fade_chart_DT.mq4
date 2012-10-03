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
  if( ObjectFind( "DT_BO_w0_fade_main" ) != -1 ){
    if( GlobalVariableGet("DT_window_fade") == 1.0 ){
      GlobalVariableSet( "DT_window_fade", 0.0 );
      ObjectSet( "DT_BO_w0_fade_main", OBJPROP_TIMEFRAMES, -1 );
      removeObjects("w0_fade_txt");
    }else{
      GlobalVariableSet( "DT_window_fade", 1.0 );
      ObjectSet( "DT_BO_w0_fade_main", OBJPROP_TIMEFRAMES, 0 );
      if( ObjectFind( "DT_BO_w1_hud_fade_txt_0" ) == -1 ){
        printRandomText();
      }
    }
  }  
  return(0);
}
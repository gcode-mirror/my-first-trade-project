//+------------------------------------------------------------------+
//|                                               DT_window_fade.mq4 |
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
  if( GlobalVariableCheck( "DT_window_fade" ) ){
    if( GlobalVariableGet("DT_window_fade") == 1.0 ){
      GlobalVariableSet( "DT_window_fade", 0.0 );
      ObjectSet( "DT_BO_w0_hud_fade_main", OBJPROP_TIMEFRAMES, -1 );
      if( ObjectFind( "DT_BO_w_hud_fade_txt_0" ) != -1 ){
        toggleObjects( "w_hud", -1 );      
      }
      addComment( "Window fade OFF", 2 );
    }else{
      ObjectSet( "DT_BO_w0_hud_fade_main", OBJPROP_TIMEFRAMES, 0 );
      GlobalVariableSet( "DT_window_fade", 1.0 );      
      if( ObjectFind( "DT_BO_w_hud_fade_txt_0" ) != -1 ){
        toggleObjects( "w_hud", 0 );      
      }
      addComment( "Window fade ON", 2 );
    }
  }
  return(0);
}
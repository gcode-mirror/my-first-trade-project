//+------------------------------------------------------------------+
//|                                              DT_alt_button_0.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_functions.mqh>
#include <DT_objects.mqh>

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  int i, len = ObjectsTotal(), width, state = 0;
  string name, ts;
  
  for( i = 0; i < len; i++ ){
    name = ObjectName(i);
    if( ObjectGet( name, OBJPROP_TIMEFRAMES ) != -1 ){
      if( StringSubstr( name, 0, 9 ) == "Trendline" || StringSubstr( name, 0, 10 ) == "Horizontal" ){
        state = -1;
        break;
      }
    }
  }
  
  for( i = 0; i < len; i++ ){
    name = ObjectName(i);
    if( StringSubstr( name, 0, 9 ) == "Trendline" ){
      toggleRealPriceLines( StringSubstr( name, 10 ), state );
    }else if( StringSubstr( name, 0, 10 ) == "Horizontal" ){
    
    }else{
      continue;
    }
    ObjectSet( name, OBJPROP_TIMEFRAMES, state );
  }
  
  if( state == -1 ){
    changeObjectsIcon( 0, true );
  }else{
    changeObjectsIcon( 0, false );
  }
  
  return(0);
}
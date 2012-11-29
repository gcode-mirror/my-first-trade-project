//+------------------------------------------------------------------+
//|                                              DT_alt_button_3.mq4 |
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
  string name;
  
  for( i = 0; i < len; i++ ){
    name = ObjectName(i);
    if( ObjectGet( name, OBJPROP_TIMEFRAMES ) != -1 ){
      if( ObjectType( name ) == OBJ_TREND || ObjectType( name ) == OBJ_HLINE ){
        if( StringSubstr( name, 5, 7 ) == "_tLine_" && ObjectGet( name, OBJPROP_WIDTH ) == 2 ){
          state = -1;
          break;
        }
      }
    }
  }
  
  for( i = 0; i < len; i++ ){
    name = ObjectName(i);
    if( StringSubstr( name, 5, 7 ) == "_tLine_" && ObjectGet( name, OBJPROP_WIDTH ) == 2 ){  
      if( ObjectType( name ) == OBJ_TREND ){
        toggleRealPriceLines( StringSubstr( name, 16, 10 ), state );
      }
      ObjectSet( name, OBJPROP_TIMEFRAMES, state );
    }
  }
  
  if( state == -1 ){
    changeObjectsIcon( 3, true );
  }else{
    changeObjectsIcon( 3, false );
  }
  return(0);
}
//+------------------------------------------------------------------+
//|                                              DT_alt_button_1.mq4 |
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
  bool hide = false;
  int i, len = ObjectsTotal(), width, state = 0;
  string name;
  
  for( i = 0; i < len; i++ ){
    name = ObjectName(i);
    if( ObjectGet( name, OBJPROP_TIMEFRAMES ) != -1 ){
      if( ObjectType( name ) == OBJ_FIBO ){
        state = -1;
        break;
      }
    }
  }
  
  for( i = 0; i < len; i++ ){
    name = ObjectName(i);
    if( ObjectType( name ) == OBJ_FIBO ){
      ObjectSet( name, OBJPROP_TIMEFRAMES, state );
    }
  }
  
  if( state == -1 ){
    changeObjectsIcon( 1, true );
  }else{
    changeObjectsIcon( 1, false );
  }
  return(0);
}
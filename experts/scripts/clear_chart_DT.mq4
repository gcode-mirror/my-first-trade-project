//+------------------------------------------------------------------+
//|                                               DT_clear_chart.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <WinUser32.mqh>

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  int i, all_line, len = ObjectsTotal();
  string name;
  bool show_obj = true;
  
  
  for ( i = 0; i < len; i++) {
    name = ObjectName(i);
    if( StringSubstr( name, 0, 5 ) == "Trend" || StringSubstr( name, 0, 5 ) == "Horiz" || StringSubstr( name, 5, 7 ) == "_cLine_" ){
      if( ObjectGet( name, OBJPROP_TIMEFRAMES ) == -1 ){
        show_obj = true;
        break;
      }else{
        show_obj = false;
        break;
      }
    }
  }
  
  if( !show_obj ){
    all_line = MessageBox( "Do you want hide the all line?", "Clear chart", MB_YESNOCANCEL|MB_ICONQUESTION );
    if( all_line == IDCANCEL ){
      return (0);
    }
  }
  
  if( show_obj ){
    for ( i = 0; i < len; i++){
      name = ObjectName(i);
      if( ObjectType(name) == OBJ_TREND || ObjectType(name) == OBJ_HLINE ){
        if( StringSubstr( name, 5, 7 ) == "_cLine_" ){
          if( ObjectGet( name, OBJPROP_WIDTH ) == 2 ){
            ObjectSet( name, OBJPROP_TIMEFRAMES, 0 );
          }else{
            ObjectSet( name, OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M5|OBJ_PERIOD_M15|OBJ_PERIOD_M30|OBJ_PERIOD_H1|OBJ_PERIOD_H4 );
          }
        }else{
          ObjectSet( name, OBJPROP_TIMEFRAMES, 0 );
        }
      }
    }
  }else{
    if( all_line == IDYES ){
      for ( i = 0; i < len; i++){
        name = ObjectName(i);
        if( StringSubstr( name, 0, 5 ) == "Trend" || StringSubstr( name, 0, 5 ) == "Horiz" || StringSubstr( name, 5, 7 ) == "_cLine_" ){
          ObjectSet( name, OBJPROP_TIMEFRAMES, -1 );
        }
      }
    }else{
      for ( i = 0; i < len; i++){
        name = ObjectName(i);
        if( StringSubstr( name, 5, 7 ) == "_cLine_" ){
          ObjectSet( name, OBJPROP_TIMEFRAMES, -1 );
        }
      }
    }
  }
  return(0);
}
//+------------------------------------------------------------------+
//|                                               DT_clear_chart.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  int i, len = ObjectsTotal();
  string name;
  bool show_obj = true;
  
  for ( i = 0; i < len; i++) {
    name = ObjectName(i);
    if( StringSubstr( name, 5, 7 ) == "_cLine_" ){
      if( ObjectGet( name, OBJPROP_TIMEFRAMES ) == -1 ){
        show_obj = true;
        break;
      }else{
        show_obj = false;
        break;
      }
    }
  }
  
  for ( i = 0; i < len; i++) {
    name = ObjectName(i);
    if( StringSubstr( name, 5, 7 ) == "_cLine_" ){
      if( show_obj ){
        if( ObjectGet( name, OBJPROP_WIDTH ) == 2 ){
          ObjectSet( name, OBJPROP_TIMEFRAMES, 0 );
        }else{
          ObjectSet( name, OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M5|OBJ_PERIOD_M15|OBJ_PERIOD_M30|OBJ_PERIOD_H1|OBJ_PERIOD_H4 );
        }
      }else{
        ObjectSet( name, OBJPROP_TIMEFRAMES, -1 );
      }
    }
  }  
  return(0);
}
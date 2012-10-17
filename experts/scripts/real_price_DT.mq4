//+------------------------------------------------------------------+
//|                                          real_price_level_DT.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+

#include <DT_defaults.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  int i, len = ObjectsTotal(), shift;
  string name, rpl_name;

  for( i = 0; i < len; i++ ){
    name = ObjectName(i);
    if( StringSubstr( name, 0, 17 ) == "DT_GO_real_price_" ){
      removeObjects( "real_price", "GO" );
      return (0);
    }
  }
  
  if( Period() < PERIOD_H4 ){
    addComment( "Wrong period!", 1 );
    return (0);
  }
  
  double p;
  int bars = Bars - 1, idx = 0;
  string lines[50][2];
  
  for( i = 0; i < len; i++ ){
    name = ObjectName(i);
    if( ObjectType( name ) == OBJ_TREND ){
      if( ObjectGet( name, OBJPROP_TIMEFRAMES ) != -1 ){
        if( StringSubstr( name, 5, 7 ) == "_tLine_" ){
          lines[idx][1] = StringConcatenate( "DT_GO_real_price_", StringSubstr( name, 16, 10 ), "_" );
        }else if( StringSubstr( name, 0, 9 ) == "Trendline" ){
          lines[idx][1] = StringConcatenate( "DT_GO_real_price_", StringSubstr( name, 10 ), "_" );
        }else{
          continue;
        }
        lines[idx][0] = name;
        idx++;
      }
    }
  }
  
  for( i = 0; i < idx; i++ ){
    shift = iBarShift( NULL, 0, ObjectGet( lines[i][0], OBJPROP_TIME2 ) );
    while( shift >= 0 ){
      if( shift >= bars ){
        shift = bars - 1;
      }
      
      rpl_name = StringConcatenate( lines[i][1], shift );
      p = ObjectGetValueByShift( lines[i][0], shift );
      if( shift == 0 ){
        ObjectCreate( rpl_name, OBJ_TREND, 0, Time[shift], p, Time[shift] + (Period() * 60), p );
      }else{
        ObjectCreate( rpl_name, OBJ_TREND, 0, Time[shift], p, Time[shift - 1], p );
      }
      ObjectSet( rpl_name, OBJPROP_COLOR, ObjectGet(lines[i][0], OBJPROP_COLOR) );
      ObjectSet( rpl_name, OBJPROP_WIDTH, 1 );
      ObjectSet( rpl_name, OBJPROP_BACK, true );
      ObjectSet( rpl_name, OBJPROP_RAY, false);
      ObjectSetText( rpl_name, ObjectDescription( lines[i][0] ) );
      
      shift--;
    }
  }
  
  return (0.0);
}
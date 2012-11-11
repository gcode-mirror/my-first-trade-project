//+------------------------------------------------------------------+
//|                                          DT_trendline_trader.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#define TL_NAME 0
#define TL_STATE 1
#define TL_ID 2

#include <DT_defaults.mqh>
#include <DT_functions.mqh>
#include <WinUser32.mqh>

#import "user32.dll"
  int GetAncestor(int, int);
#import

// #define TIME_BWEEN_TRADES 18000 // 5 hour (min 4 hour !!!!)
// #define FIBO_TP 0.380 // 0.382
// #define TRADE_LOT 0.1
// #define EXPIRATION_TIME 7200 // 2 hour

bool CONNECTION_FAIL = true;

int init(){
// #############################################################  Set connection state  ##############################################################
  if( MarketInfo(Symbol(),MODE_TICKVALUE) == 0.0 ){
    CONNECTION_FAIL = true;
    return (0);
  }else{
    CONNECTION_FAIL = false;
  }

  return(0);
}

int deinit(){
  ObjectsDeleteAll();
  return(0);
}

int start(){
  static string st_tLine[][3];
  static bool st_trade_allowed = true;
  
  static int start_delay = 0;
  if( start_delay < GetTickCount() ){
    start_delay = GetTickCount() + 2000;
    if( IsTesting() ){
      start_delay = GetTickCount() + 9999999999; // run only once
    }
    
    loadTrendlines( st_tLine );
   
    if( ObjectFind("DT_GO_trade_timing") != -1 ){
      if( ObjectGet( "DT_GO_trade_timing", OBJPROP_TIME1 ) < iTime( NULL, PERIOD_M1, 0) ){
        st_trade_allowed = false;
      }else{
        st_trade_allowed = true;
      }
    }
    
    if( Period() != PERIOD_H4 ){
      log( StringConcatenate( Symbol()," trendline trader not in H4 period! curr. is ", Period() ), 1.0 );
      st_trade_allowed = false;
    }
    
  }
  
  if( !st_trade_allowed ){
    return (0);
  }
  
  
}


void loadTrendlines( string &arr[][] ){
  static double st_last_mod = 1.0;
  static string st_gv_name = "";
  static string st_file_name = "";

  if( st_gv_name == "" ){
    st_gv_name = StringConcatenate( getSymbol(), "_tLines_lastMod" );
    st_file_name = StringConcatenate( getSymbol(), "_tLines.csv" );
  }

  if( st_last_mod != GlobalVariableGet( st_gv_name ) ){
    st_last_mod = GlobalVariableGet( st_gv_name );

    ObjectsDeleteAll();
    int j = 0, handle = FileOpen( st_file_name, FILE_READ, ";" );
    if( handle < 1 ){
      Alert( StringConcatenate( "File load error in trendline trader (", Symbol(), ")" ) );
      return ( false );
    }

    ArrayResize( arr, 50 );

    string name;
    int type, c, nr = 0;
    double t1, p1, t2, p2;

    while( !FileIsEnding(handle) ){
      switch( j ){
        case 0: name = FileReadString(handle); break;
        case 1: t1 = NormalizeDouble( StrToDouble(FileReadString(handle)), 0 ); break;
        case 2: p1 = NormalizeDouble( StrToDouble(FileReadString(handle)), Digits ); break;
        case 3: t2 = NormalizeDouble( StrToDouble(FileReadString(handle)), 0 ); break;
        case 4: p2 = NormalizeDouble( StrToDouble(FileReadString(handle)), Digits ); break;
        case 5: c = StrToInteger( FileReadString(handle) ); break;
        case 6:
          j = -1;
          type = StrToInteger( FileReadString(handle) );

          if( type == OBJ_TREND ){
            if( !(NormalizeDouble(iCustom( Symbol(), PERIOD_H4, "ZigZag", 12, 5, 3, 0, iBarShift( NULL, PERIOD_H4, t1 ) ), Digits) == p1 || NormalizeDouble(iCustom( Symbol(), PERIOD_D1, "ZigZag", 12, 5, 3, 0, iBarShift( NULL, PERIOD_D1, t1 ) ), Digits) == p1) ){
              log( StringConcatenate( Symbol()," Line P1 val not match to ZZ: ", p1, " name:", name ), 11.0, StrToDouble(StringSubstr( name, 16, 10 )) );
              break;
            }

            if( !(NormalizeDouble(iCustom( Symbol(), PERIOD_H4, "ZigZag", 12, 5, 3, 0, iBarShift( NULL, PERIOD_H4, t2 ) ), Digits) == p2 || NormalizeDouble(iCustom( Symbol(), PERIOD_D1, "ZigZag", 12, 5, 3, 0, iBarShift( NULL, PERIOD_D1, t2 ) ), Digits) == p2) ){
              log( StringConcatenate( Symbol()," Line P2 val not match to ZZ: ", p2, " name:", name ), 11.0, StrToDouble(StringSubstr( name, 16, 10 )) );
              break;
            }
          }

          ObjectCreate( name, type, 0, t1, p1, t2, p2 );
          ObjectSet( name, OBJPROP_RAY, true );
          ObjectSet( name, OBJPROP_COLOR, c );

          if( StringSubstr( name, 5, 7 ) == "_tLine_" ){
            arr[nr][TL_NAME] = name;
            arr[nr][TL_STATE] = StringSubstr( name, 12, 3 );
            arr[nr][TL_ID] = StringSubstr( name, 16, 10 );
            nr++;
          }
        break;
      }
      j++;

    }
    FileClose( handle );
    ArrayResize( arr, nr );
  }
}

void log( string text, double val = 0.0, double id = 0.0 ){
  static double last_log_val[1][2];
  bool uknown = true;
  int len = ArrayRange( last_log_val, 0 );

  if( id == 0.0 ){
    if( last_log_val[0][1] == val ){
      return;
    }else{
      last_log_val[0][1] = val;
    }
  }else{
    for( int i = 1; i < len; i++ ){
      if( last_log_val[i][0] == id ){
        if( last_log_val[i][1] == val ){
          return;
        }else{
          last_log_val[i][1] = val;
          uknown = false;
          break;
        }
      }
    }
    if( uknown ){
      ArrayResize( last_log_val, len + 1 );
      last_log_val[len][0] = id;
      last_log_val[len][1] = val;
    }
  }
  Alert( text );
  if( IsTesting() ){
    PlaySound( "alert2.wav" );
    PostMessageA(GetAncestor(WindowHandle(Symbol(), Period()), 2), WM_COMMAND, 0x57a, 0);
  }else{
    GlobalVariableSet( "TLINE_TRADER_LOG_IDX", GlobalVariableGet( "TLINE_TRADER_LOG_IDX" ) + 1.0 );
  }
}
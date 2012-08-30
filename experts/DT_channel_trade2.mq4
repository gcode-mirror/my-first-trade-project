//+------------------------------------------------------------------+
//|                                             DT_channel_trade.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

bool CONNECTION_FAIL = true;
string INP_FILE_NAME;
string GV_LAST_MOD;

int init(){
// #############################################################  Set connection state  ##############################################################  
  if( MarketInfo(Symbol(),MODE_TICKVALUE) == 0.0 ){
    CONNECTION_FAIL = true;
    return (0);
  }else{
    CONNECTION_FAIL = false;
  }
// ###############################################################  Load test lines  ################################################################
  if( IsTesting() ){
    setChannelLinesArr( StringConcatenate( StringSubstr(Symbol(), 0, 6), "_test_cLines.csv" ) );
    WindowRedraw();
  }
  
  INP_FILE_NAME = StringConcatenate( StringSubstr(Symbol(), 0, 6), "_cLines.csv" );
  GV_LAST_MOD = = StringConcatenate( StringSubstr(Symbol(), 0, 6), "_cLines_lastMod" );
}


int start(){
// ###############################################################  Check connection  ################################################################  
  if( CONNECTION_FAIL ){
    init();
    return (0);
  }
  
// ##############################################################  Periodic functions  ###############################################################  
  static int timer_1 = 0;
  if( !IsTesting() && GetTickCount() > timer_1 ){
    timer_1 = GetTickCount() + 2000;

  // ============================================================  Save Lines to array  =============================================================
    setChannelLinesArr( INP_FILE_NAME );
    
  // ===============================================================  Period check  =================================================================
    if( Period() != PERIOD_M15 ){
      log( StringConcatenate( "WARNING! Channel trade line not in M15 period! curr. is ", Period(), " (", Symbol(),")" ), 1.0 );
    }

  // ============================================================  Trade scedule check  =============================================================
    static bool trade_allowed = true;
    if( ObjectFind("DT_GO_channel_trade_time_limit") != -1 ){
      if( ObjectGet( "DT_GO_channel_trade_time_limit", OBJPROP_TIME1 ) < iTime( NULL, PERIOD_M1, 0) ){
        trade_allowed = false;
      }else{
        trade_allowed = true;
      }
    }
  }
}

void setChannelLinesArr( string &file_name ){
  static double last_mod = 1.0;
  if( last_mod != GlobalVariableGet( EXP_LAST_MOD_GV ) ){
    last_mod = GlobalVariableGet( EXP_LAST_MOD_GV );

    readCLinesFromFile( file_name );
  }
}

bool readCLinesFromFile( string &file_name ){
  string in, arr[7]; // name = 0, t1 = 1, p1 = 2, t2 = 3, p2 = 4, col = 5, type = 6
  int j = 0, handle;
  double time_0_p;

  ObjectsDeleteAll();

  handle = FileOpen( file_name, FILE_READ, ";" );
  if( handle < 1){
    int e = GetLastError();
    if( e != 4103 ){
      Alert( "File read fail ("+file_name+")"+ e );
    }
    FileClose( handle );
    return ( false );
  }

  while( !FileIsEnding(handle) ){
    in = FileReadString(handle);

    arr[j] = in;
    j++;

    if( j == 7 ){
      ObjectCreate( arr[0], StrToInteger( arr[6] ), 0, StrToDouble(arr[1]), StrToDouble(arr[2]), StrToDouble(arr[3]), StrToDouble(arr[4]) );
      ObjectSet( arr[0], OBJPROP_RAY, true );
      ObjectSet( arr[0], OBJPROP_COLOR, StrToInteger(arr[5]) );
      j = 0;
    }
  }
  FileClose( handle );
  return ( true );
}
//+------------------------------------------------------------------+
//|                                          DT_trader_functions.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#define TL_NAME 0
#define TL_TYPE 1
#define TL_STATE 2
#define TL_ID 3

void setChannelLinesArr( string file_type, string &arr[][] ){
  static double last_mod = 1.0;
  string g_name = StringConcatenate( StringSubstr(Symbol(), 0, 6), "_cLines_lastMod" );
	
  if( last_mod != GlobalVariableGet( g_name ) ){
    last_mod = GlobalVariableGet( g_name );
    
    readCLinesFromFile();
    
    int len = ObjectsTotal(), j = 0;
    string name, type;
    for( int i = 0; i < len; i++ ){
      name = ObjectName(i);
      type = getCLineProperty( name, "type" );
      if( type == file_type ){
        ArrayResize( arr, j + 1 );
        arr[j][TL_NAME] = name;
        arr[j][TL_TYPE] = type;
        arr[j][TL_STATE] = getCLineProperty( name, "state" );
        arr[j][TL_ID] = getCLineProperty( name, "ts" );
        j++;
      }
    }
    if( j == 0 ){
      ArrayResize( arr, 0 );
    }
  }
}

bool readCLinesFromFile(){
  string file_name, in, arr[7]; // name = 0, t1 = 1, p1 = 2, t2 = 3, p2 = 4, col = 5, type = 6
  int j = 0, handle;
  double t1, t2, p1, p2;

  ObjectsDeleteAll();
	if( IsTesting() ){
		file_name = StringConcatenate( StringSubstr(Symbol(), 0, 6) , "_test_cLines.csv" );
	}else{
		file_name = StringConcatenate( StringSubstr(Symbol(), 0, 6), "_cLines.csv" );
	}
  handle = FileOpen( file_name, FILE_READ, ";" );
  if( handle < 1){
    int e = GetLastError();
    if( e != 4103 ){
      Alert( "File read fail readCLinesFromFile:"+ e );
    }
    FileClose( handle );
    return ( false );
  }

  while( !FileIsEnding(handle) ){
    in = FileReadString(handle);

    arr[j] = in;
    j++;

    if( j == 7 ){
      t1 = NormalizeDouble( StrToDouble(arr[1]), 0 );
      p1 = NormalizeDouble( StrToDouble(arr[2]), Digits );
      t2 = NormalizeDouble( StrToDouble(arr[3]), 0 );
      p2 = NormalizeDouble( StrToDouble(arr[4]), Digits );
      j = 0;
      
      if( !(NormalizeDouble(iCustom( Symbol(), PERIOD_H4, "ZigZag", 12, 5, 3, 0, iBarShift( NULL, PERIOD_H4, t1 ) ), Digits) == p1 || NormalizeDouble(iCustom( Symbol(), PERIOD_D1, "ZigZag", 12, 5, 3, 0, iBarShift( NULL, PERIOD_D1, t1 ) ), Digits) == p1) ){
        // log( StringConcatenate( Symbol()," Line P1 val not match to ZZ: ", arr[0] ), 11.0, StrToDouble(getCLineProperty( arr[0], "ts" )) );
        log( StringConcatenate( Symbol()," ", iBarShift( NULL, PERIOD_H4, t1 )," Line P1 val not match to ZZ: ", arr[0]," p1 ",p1, "zz ", iCustom( Symbol(), PERIOD_H4, "ZigZag", 12, 5, 3, 0, iBarShift( NULL, PERIOD_H4, t1 ) ) ), 11.0, StrToDouble(getCLineProperty( arr[0], "ts" )) );
        continue;
      }
      
      if( !(NormalizeDouble(iCustom( Symbol(), PERIOD_H4, "ZigZag", 12, 5, 3, 0, iBarShift( NULL, PERIOD_H4, t2 ) ), Digits) == p2 || NormalizeDouble(iCustom( Symbol(), PERIOD_D1, "ZigZag", 12, 5, 3, 0, iBarShift( NULL, PERIOD_D1, t2 ) ), Digits) == p2) ){
        log( StringConcatenate( Symbol()," Line P2 val not match to ZZ: ", arr[0] ), 11.0, StrToDouble(getCLineProperty( arr[0], "ts" )) );
        continue;
      }

      ObjectCreate( arr[0], StrToInteger( arr[6] ), 0, t1, p1, t2, p2 );
      ObjectSet( arr[0], OBJPROP_RAY, true );
      ObjectSet( arr[0], OBJPROP_COLOR, StrToInteger(arr[5]) );
    }
  }
  FileClose( handle );
  return ( true );
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
  if( !IsTesting() ){
    GlobalVariableSet( "CT_NR_OF_LOGS", GlobalVariableGet( "CT_NR_OF_LOGS" ) + 1.0 );
  }
}

bool alreadyBelowCLine( double tLine_price ,double fibo_100, double fibo_100_time ){
  int i = 0, len = iBarShift( NULL, 0, fibo_100_time );
  if( fibo_100 > tLine_price ){
    for( ; i < len; i++ ){
      if( Low[i] < tLine_price ){
        return ( true );
      }
    }
  }else{
    for( ; i < len; i++ ){
      if( High[i] > tLine_price ){
        return ( true );
      }
    }
  }
  return ( false );
}

double priceSpeed( string cLine, string& log ){
  double p1 = iMA( NULL, PERIOD_M15, 3, 0, MODE_LWMA, PRICE_MEDIAN, 0 );
  double p2 = iMA( NULL, PERIOD_M15, 3, 0, MODE_LWMA, PRICE_MEDIAN, 1 );
  double peri, speed = 9999.9, dist, h, l, dif = MathAbs( p1 - p2 ) * 0.4;
  int i = 2;
  if( p2 > p1 ){
    while( p2 > p1 && p2 - p1 > dif ){
      p1 = p2;
      p2 = iMA( NULL, PERIOD_M15, 3, 0, MODE_LWMA, PRICE_MEDIAN, i );
      i++;
    }
    dist = ( (iHigh( NULL, PERIOD_M15, i - 2 ) - iLow( NULL, PERIOD_M15, 0 )) / MarketInfo( Symbol(), MODE_POINT ) ) * MarketInfo( Symbol(), MODE_TICKVALUE );
    h = iHigh( NULL, PERIOD_M15, i - 2 );
    l = iLow( NULL, PERIOD_M15, 0 );
  }else{
    while( p2 < p1 && p1 - p2 > dif ){
      p1 = p2;
      p2 = iMA( NULL, PERIOD_M15, 3, 0, MODE_LWMA, PRICE_MEDIAN, i );
      i++;
    }
    dist = ( (iHigh( NULL, PERIOD_M15, 0 ) - iLow( NULL, PERIOD_M15, i - 2 )) / MarketInfo( Symbol(), MODE_POINT ) ) * MarketInfo( Symbol(), MODE_TICKVALUE );
    h = iHigh( NULL, PERIOD_M15, 0 );
    l = iLow( NULL, PERIOD_M15, i - 2 );
  }
  peri = (i - 2) + ( MathMod( Minute(), PERIOD_M15 ) / PERIOD_M15 );
  speed = dist / peri;
  log = StringConcatenate( Symbol()," Cline: ", cLine," Speed: ", DoubleToStr(speed, 2), " Bar nr:", i-1, " (", DoubleToStr( peri, 2 ),") high:", DoubleToStr( h, Digits ), " low:", DoubleToStr( l , Digits ) );
  return (speed);
}

bool tLineLatelyUsed( int magic, double allow_break ){
  int i = 0, len = OrdersTotal();
  string symb = Symbol();
  for( ; i < len; i++ ) {
    if( OrderSelect( i, SELECT_BY_POS ) ) {
      if( OrderSymbol() == symb ) {
        if( OrderMagicNumber() == magic ){
          return (true);
        }
      }
    }
  }
  
  len = OrdersHistoryTotal();
  for( i = 0; i < len; i++ ) {
    if( OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) {
      if( OrderSymbol() == symb ) {
        if( OrderMagicNumber() == magic ){
          if( OrderOpenTime() + allow_break > TimeCurrent() ){
            return (true);
          }
        }
      }
    }
  }
  return (false);
}

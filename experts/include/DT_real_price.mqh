//+------------------------------------------------------------------+
//|                                                DT_real_price.mqh |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

void startRealPrice(){
  static int st_timer = 0;
  static double st_switch = -1.0;
  static double st_curr_H4_time = -1.0;
 // static double st_last_mod = -1.0;
  
  if( st_switch == -1.0 ){
    showIcon( "REAL_PRICE", 3, 1, "4", "Wingdings 3", 0.0 );
  }
  
  double gl_rp = getGlobal("REAL_PRICE");

  if( st_switch != gl_rp ){
  addComment("reload",1);
    st_switch = gl_rp;
    changeIcon( "REAL_PRICE", st_switch );
    if( st_switch == 0.0 ){
      deInitRealPrice();
			addComment( "Switch OFF Real Price." );
      return;
    }else if( st_switch == 1.0 ){
      if( Period() == PERIOD_H4 ){
        st_curr_H4_time = iTime( NULL, PERIOD_H4, 0 );
        //st_last_mod = getGlobal( "SYNC_TL" );
        setGlobal( "REAL_PRICE", 2.0 );
        showRealPrices();
        return;
      }else{
        setGlobal( "REAL_PRICE", getCurrPeriodKey() );
        PostMessageA( WindowHandle( Symbol(), Period() ), WM_COMMAND, 33136, 0 );
        return;
      }
    }else if( st_switch == 2.0 ){
      st_curr_H4_time = iTime( NULL, PERIOD_H4, 0 );
      //st_last_mod = getGlobal( "SYNC_TL" );
      
    }else if( st_switch > 2.0 ){
      showRealPrices();
      setGlobal( "REAL_PRICE", 2.0 );
      int tmp = st_switch;
      PostMessageA( WindowHandle( Symbol(), Period() ), WM_COMMAND, tmp, 0 );
      return;
    }
  }
  
  if( st_switch != 2.0 || GetTickCount() < st_timer ){
    return;
  }
  st_timer = GetTickCount() + 4000;
  
  if( st_curr_H4_time != iTime( NULL, PERIOD_H4, 0 )/* || st_last_mod != getGlobal( "SYNC_TL" ) */){
    st_curr_H4_time = iTime( NULL, PERIOD_H4, 0 );
   // st_last_mod = getGlobal( "SYNC_TL" );
    
    setGlobal( "REAL_PRICE", getCurrPeriodKey() );
    PostMessageA( WindowHandle( Symbol(), Period() ), WM_COMMAND, 33136, 0 );
    return;
  }
    
}

void deInitRealPrice(){
  removeObjects( "real_price", "GO" );
}

void showRealPrices(){
  deInitRealPrice();
  
  int i, idx = 0, shift, len = ObjectsTotal(), bars = Bars - 1;
  string name, lines[60][2];
  double p;
  
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
      
      name = StringConcatenate( lines[i][1], shift );
      p = ObjectGetValueByShift( lines[i][0], shift );
      if( shift == 0 ){
        ObjectCreate( name, OBJ_TREND, 0, Time[shift], p, Time[shift] + (Period() * 60), p );
      }else{
        ObjectCreate( name, OBJ_TREND, 0, Time[shift], p, Time[shift - 1], p );
      }
      ObjectSet( name, OBJPROP_COLOR, ObjectGet(lines[i][0], OBJPROP_COLOR) );
      ObjectSet( name, OBJPROP_WIDTH, 1 );
      ObjectSet( name, OBJPROP_BACK, true );
      ObjectSet( name, OBJPROP_RAY, false);
      ObjectSetText( name, ObjectDescription( lines[i][0] ) );
      shift--;
    }
  }
}

int getCurrPeriodKey(){
  static int period_keys[9][2] = {
    1,      33137,
    5,      33138,
    15,     33139,
    30,     33140,
    60,     35400,
    240,    33136,
    1440,   33134,
    10080,  33141,
    43200,  33334
  };
  
  for( int i = 0; i < 9; i++ ){
    if( Period() == period_keys[i][0] ){
      return ( period_keys[i][1] );
    }
  }
  return (-1);
}
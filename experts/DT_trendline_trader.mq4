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

#define FIBO_TP 0.380 // 0.382
#define TRADE_LOT 0.1
#define EXPIRATION_TIME 7200 // 2 hour
// #define TIME_BWEEN_TRADES 18000 // 5 hour (min 4 hour !!!!)

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
  // ObjectsDeleteAll();
  return(0);
}

int start(){
  static string st_tLine[][3];
  static bool st_trade_allowed = true;
  
  static int st_start_time = -1;
  static double st_offset = 0.0;
  static double st_spread = 0.0;
  static double st_min_tp = 0.0;
  static double st_max_tp = 0.0;
  static double st_stop_loss = 0.0;
  static double st_sml_tp = 0.0;
  static double st_fail_sl = 0.0;
  static double st_fail_tp = 0.0;
  static double st_sml_magnet = 0.0;
  static double st_max_dist = 0.0;
  
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
    
    if( st_start_time == -1 ){ // init variables
      st_start_time = GetTickCount() + 180000; // 3 min
      st_offset = 60 / MarketInfo( Symbol(), MODE_TICKVALUE ) * Point;
      st_spread = getSymbolData( SPREAD );
      st_min_tp = getSymbolData( MIN_PROFIT );
      st_max_tp = getSymbolData( MAX_PROFIT );
      st_stop_loss = getSymbolData( STOPLOSS );
      st_sml_tp = getSymbolData( SML_TP );
      st_fail_sl = getSymbolData( FAIL_SL );
      st_fail_tp = getSymbolData( FAIL_TP );
      st_sml_magnet = getSymbolData( SML_MAGNET );
      st_max_dist = getSymbolData( MAX_DIST );
    } 
    
  }
  
  if( !st_trade_allowed ){
    return (0);
  }
  
  double tLine_price, tp, sl, op, fibo_100;
  string comment = "";
  int i = 0, o_type, len = OrdersTotal(), magic, ticket, main_ticket;
  // #####################################################  modify Positions  ######################################################
  
  static double st_mod_timer = 0.0;
  for( ; i < len; i++ ){
    if( OrderSelect( i, SELECT_BY_POS ) ){
      if( OrderSymbol() == Symbol() ){
        magic = OrderMagicNumber();
        if( magic > 1000 ){
          o_type = OrderType();
          ticket = OrderTicket();
          // #####################################################  Immediate actions  #####################################################
          if( o_type < 2 ){
            double peak;
            int shift = iBarShift( NULL, PERIOD_M1, OrderOpenTime() );
            peak = getPeakPrice( o_type % 2, shift );
            
            if( o_type == OP_BUY ){
              if( peak >= NormalizeDouble( OrderTakeProfit(), Digits ) ){
                OrderClose( ticket, TRADE_LOT, Ask, 3, Red );
                errorCheck( StringConcatenate( Symbol()," Open position is manually closed, tp: ",NormalizeDouble( OrderTakeProfit(), Digits )," highest:", peak, " ticket id :", ticket, " Bid:", Bid, " Ask:", Ask ) );
                log( StringConcatenate( Symbol()," Open position is manually closed, tp: ",NormalizeDouble( OrderTakeProfit(), Digits )," highest:", peak, " ticket id :", ticket, " Bid:", Bid, " Ask:", Ask ), 8.0, magic );
                continue;
              }
            }else{
              if( peak <= NormalizeDouble( OrderTakeProfit(), Digits ) ){
                OrderClose( ticket, TRADE_LOT, Ask, 3, Red );
                errorCheck( StringConcatenate( Symbol()," Open position is manually closed, tp: ",NormalizeDouble( OrderTakeProfit(), Digits )," lowest:", peak, " ticket id :", ticket, " Bid:", Bid, " Ask:", Ask ) );
                log( StringConcatenate( Symbol()," Open position is manually closed, tp: ",NormalizeDouble( OrderTakeProfit(), Digits )," lowest:", peak, " ticket id :", ticket, " Bid:", Bid, " Ask:", Ask ), 8.0, magic );
                continue;
              }
            }
            
          }else if( o_type > 3 ){
            main_ticket = StrToInteger( OrderComment() );
            if( main_ticket != 0 ){
/* !!!*/      if( OrderSelect( main_ticket, SELECT_BY_TICKET, MODE_HISTORY ) ){
                if( OrderMagicNumber() == magic ){
                  if( OrderProfit() > 0.0 && OrderCloseTime() != 0.0 ){
                    OrderDelete( ticket );
                    errorCheck( StringConcatenate( Symbol()," close safety position ticket id :", main_ticket, " magic:", magic, " closed ticket:", ticket ) );
                    log( StringConcatenate( Symbol()," close safety position ticket id :", main_ticket, " magic:", magic, " closed ticket:", ticket ), 8.0, magic );
										
										Alert(OrderTicket()+"  OrderComment:"+ OrderComment()+" OrderCloseTime:"+OrderCloseTime()+" OrderType:"+OrderType()+" OrderProfit:"+OrderProfit() );
                    continue;
                  }
                }
              }
            }
          }
          
        }
      }
    }
  }
  
  bool is_buy;
  // ###########################################################  Find NEW Positons  ############################################################
  int idx = getClosestTLineId( st_tLine, st_offset );
  if( idx != -1 ){
    tLine_price = getTLineValueByShift( st_tLine[idx][TL_NAME] );
    
    if( GetTickCount() < st_start_time ){
      if( IDNO == MessageBox(StringConcatenate( Symbol(), " Terminal just started, do you want OPEN position?"), "New order?", MB_YESNO|MB_ICONQUESTION ) ){
        return(0);
      }
    }
    is_buy = ( iOpen( NULL, PERIOD_M1, 1 ) > tLine_price );
    
    RefreshRates();
    if( st_tLine[idx][TL_STATE] == "sml" ){
      if( peekIsNotEnoughFar( is_buy, tLine_price, st_max_dist ) ){
        log( StringConcatenate( Symbol()," Closest Peek is not enought far: ",st_tLine[idx][TL_NAME]," tLine_price:", tLine_price, " is_buy", is_buy ), 7.0, StrToDouble(st_tLine[idx][TL_ID]) );
        return(0);
      }
    
      tp = getSmallTakeProfit( is_buy, tLine_price, st_tLine, st_spread, st_sml_tp, st_sml_magnet );
    
      if( is_buy ){
        o_type = OP_BUYLIMIT;
        op = NormalizeDouble( tLine_price + st_spread, Digits );
        sl = NormalizeDouble( tLine_price - st_stop_loss, Digits );
      }else{
        o_type = OP_SELLLIMIT;
        op = NormalizeDouble( tLine_price, Digits );
        sl = NormalizeDouble( tLine_price + st_stop_loss + st_spread, Digits );
      }
    }else if( st_tLine[idx][TL_STATE] == "big" ){
    
      tp = getBigTakeProfit( idx, is_buy, fibo_100, tLine_price, st_tLine, st_spread, st_min_tp, st_max_tp );
      
      if( is_buy ){
        o_type = OP_BUYLIMIT;
        op = NormalizeDouble( tLine_price + st_spread, Digits );
        sl = NormalizeDouble( tLine_price - st_stop_loss, Digits );
      }else{
        o_type = OP_SELLLIMIT;
        op = NormalizeDouble( tLine_price, Digits );
        sl = NormalizeDouble( tLine_price + st_stop_loss + st_spread, Digits );
      }
      
      comment = DoubleToStr( fibo_100, 5 );
    }else{
      log( StringConcatenate( Symbol()," unknown state:", st_tLine[idx][TL_STATE], " line:", st_tLine[idx][TL_NAME], Period() ), 2.0, StrToDouble(st_tLine[idx][TL_ID]) );
      return (0);
    }
    
    if( tp == -1.0 ){
      return(0);
    }
    
    ticket = OrderSend( Symbol(), o_type, TRADE_LOT, op, 5, sl, tp, comment, StrToInteger( st_tLine[idx][TL_ID] ), TimeCurrent() + EXPIRATION_TIME, Orange );
    if( ticket != -1 ){
/* !! */  Print(StringConcatenate("New Ty:", o_type, " Lot:", TRADE_LOT, " OP:", op, " SL:", sl, " TP:", tp, " Mag:", st_tLine[idx][TL_ID], " Exp:", TimeCurrent()+EXPIRATION_TIME, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Stat:", tLine_price, " H:", High[0]," L:", Low[0], " (", Symbol(), ")"));
/* !! */  log(StringConcatenate("New Ty:", o_type, " Lot:", TRADE_LOT, " OP:", op, " SL:", sl, " TP:", tp,  " Mag:", st_tLine[idx][TL_ID], " Exp:", TimeCurrent()+EXPIRATION_TIME, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Stat:", tLine_price," H:", High[0]," L:", Low[0], " (", Symbol(), ")"), 18.0, StrToDouble(st_tLine[idx][TL_ID]) );        

      if( is_buy ){
        o_type = OP_SELLSTOP;
        op = sl;
        tp = NormalizeDouble( op - st_fail_tp + st_spread, Digits );
        sl = NormalizeDouble( op + st_fail_sl + st_spread, Digits );
      }else{
        o_type = OP_BUYSTOP;
        op = sl;
        tp = NormalizeDouble( op + st_fail_tp, Digits );
        sl = NormalizeDouble( op - st_fail_sl, Digits );
      }
      comment = ticket+"";
      OrderSend( Symbol(), o_type, TRADE_LOT, op, 5, sl, tp, comment, StrToInteger( st_tLine[idx][TL_ID] ), TimeCurrent() + EXPIRATION_TIME, Blue );
      
    }
    
/* !! */  Print(StringConcatenate("NFail Ty:", o_type, " Lot:", TRADE_LOT, " OP:", op, " SL:", sl, " TP:", tp, " Mag:", st_tLine[idx][TL_ID], " Exp:", TimeCurrent()+EXPIRATION_TIME, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Stat:", tLine_price, " H:", High[0]," L:", Low[0], " (", Symbol(), ")"));
/* !! */  log(StringConcatenate("NFail Ty:", o_type, " Lot:", TRADE_LOT, " OP:", op, " SL:", sl, " TP:", tp,  " Mag:", st_tLine[idx][TL_ID], " Exp:", TimeCurrent()+EXPIRATION_TIME, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Stat:", tLine_price," H:", High[0]," L:", Low[0], " (", Symbol(), ")"), 18.0, StrToDouble(st_tLine[idx][TL_ID]) );    
    
  }
}

int getClosestTLineId( string &st_tLine[][], double &st_offset ){
  int i = 0, len = ArrayRange( st_tLine, 0 ), order_history[], used_idx = -1;
  double tLine_price, tmp, min_dist = 999999.0;
  
  setHistoryArray( order_history );
  for( ; i < len; i++ ){
    // missing tLine
    if( ObjectFind( st_tLine[i][TL_NAME] ) == -1 ){
      log( StringConcatenate( Symbol()," Error tLine is missing: ",st_tLine[i][TL_NAME] ), 7.0, StrToDouble(st_tLine[i][TL_ID]) );
      loadTrendlines( st_tLine );
      return (-1);
    }
    
    // signal line
    if( st_tLine[i][TL_STATE] == "sig" ){
      continue;
    }
    
    // Current time not cross tLine (tLine is too short or below Time[0])
    tLine_price = getTLineValueByShift( st_tLine[i][TL_NAME] );
    if( tLine_price == 0.0 ){
      log( StringConcatenate( Symbol()," Error tLine is not enought long: ",st_tLine[i][TL_NAME] ), 8.0, StrToDouble(st_tLine[i][TL_ID]) );
      continue;
    }
    
    // tLine not in trade zone
    if( Bid > tLine_price + st_offset || Bid < tLine_price - st_offset ){
      continue;
    }
    
    // has lately used tLine 
    if( alreadyUsedThisTLine( order_history, StrToInteger( st_tLine[i][TL_ID] ) ) ){
      // log( StringConcatenate( Symbol()," In ",TimeToStr( TIME_BWEEN_TRADES, TIME_MINUTES)," hours there was Opened Position! id:", st_tLine[i][TL_ID] ), 11.0, StrToDouble(st_tLine[i][TL_ID]) );
      continue;
    }
    
     // get the closest line
    tmp = MathAbs( tLine_price - Bid );
    if( tmp < min_dist ){
      min_dist = tmp;
      used_idx = i;
    }else{
      continue;
    }
  }
  return ( used_idx );
}

double getSmallTakeProfit( bool is_buy, double &tLine_price, string& st_tLine[][3], double& st_spread, double& st_sml_tp, double& st_sml_magnet ){
  double tp = -1.0, nearest_line_price; 
  if( is_buy ){
    tp = NormalizeDouble( tLine_price + st_sml_tp, Digits );
    nearest_line_price = getNearestLinePriceByDir( false, tp, st_tLine );
  }else{
    tp = NormalizeDouble( tLine_price - st_sml_tp + st_spread, Digits );
    nearest_line_price = getNearestLinePriceByDir( true, tp, st_tLine );
  }
  
  if( nearest_line_price < st_sml_magnet ){
    if( is_buy ){
      tp = tp + nearest_line_price;
    }else{
      tp = tp - nearest_line_price;
    }
  }
  return ( tp );
}

bool peekIsNotEnoughFar( bool is_buy, double &tLine_price, double &st_max_dist ){
  int i = 0;
  if( is_buy ){
    for( ;i < 50; i++ ){
      if( iHigh( NULL, PERIOD_M5, i ) - tLine_price > st_max_dist ){
        return ( false );
      }
    }
  }else{
    for( ;i < 50; i++ ){
      if( tLine_price - iLow( NULL, PERIOD_M5, i )  > st_max_dist ){
        return ( false );
      }
    }
  }
  return ( true );
}

double getBigTakeProfit( int idx, bool is_buy, double &fibo_100, double &tLine_price, string& st_tLine[][3], double& st_spread, double& st_min_tp, double& st_max_tp ){
  static int peris[4] = { 240, 60, 30, 15 };
  double fibo_tp, nearest_line_price = getNearestLinePriceByDir( is_buy, tLine_price, st_tLine );
  
  for( int i = 0; i < 4; i++ ){ // hard code!!!
    fibo_100 = getFibo100( peris[i], tLine_price, is_buy );
    if( fibo_100 == -1.0 ){
      log( StringConcatenate( Symbol()," Wrong fibo100! Cline: ", st_tLine[idx][TL_NAME] ), 13.0, StrToDouble(st_tLine[idx][TL_ID]) );
      return ( -1.0 );
    }
    
    fibo_tp = MathAbs( fibo_100 - tLine_price ) * FIBO_TP;
    
    if( nearest_line_price < fibo_tp ){
      fibo_tp = nearest_line_price;
    }
    
    if( fibo_tp < st_min_tp ){
      log( StringConcatenate( Symbol()," TP fibo is too close! Cline: ", st_tLine[idx][TL_NAME], " Distance:", DoubleToStr(fibo_tp, Digits) ), 13.0, StrToDouble(st_tLine[idx][TL_ID]) );
      return ( -1.0 );
    }else if( fibo_tp > st_max_tp ){
      if( i == 3 ){ // hard code!!!
        log( StringConcatenate( Symbol()," TP fibo is too far! Cline:", st_tLine[idx][TL_NAME], " Distance:", DoubleToStr(fibo_tp, Digits) ), 14.0, StrToDouble(st_tLine[idx][TL_ID]) );
        return ( -1.0 );
      }
      continue;
    }else{
      if( is_buy ){
        return ( NormalizeDouble( tLine_price + fibo_tp, Digits ) );
      }else{
        return ( NormalizeDouble( tLine_price - fibo_tp + st_spread, Digits ) );
      }
    }
  }
}

double getNearestLinePriceByDir( bool above_tLine_price, double &ref_price, string& st_tLine[][3]){
  int i = 0, len = ArrayRange( st_tLine, 0 );
  double tmp, min = 99999999.9;

  if( above_tLine_price ){
    for( ; i < len; i++ ){
      tmp = getTLineValueByShift( st_tLine[i][TL_NAME] );
      if( tmp > ref_price ){
        tmp = tmp - ref_price;
        if( tmp < min ){
          min = tmp;
        }
      }
    }
  }else{
    for( ; i < len; i++ ){
      tmp = getTLineValueByShift( st_tLine[i][TL_NAME] );
      if( tmp < ref_price ){
        tmp = ref_price - tmp;
        if( tmp < min ){
          min = tmp;
        }
      }
    }
  }
  return (min);
}

double getFibo100( int peri, double &tLine_price, bool &is_buy ){
  int nr = 0, i = 0;
  double tmp;
  while( nr < 2 ){
    tmp = iCustom( Symbol(), peri, "ZigZag", 12, 5, 3, 0, i );
    if( tmp != 0.0 ){
      if( is_buy ){
        if( tmp > tLine_price ){
          return ( tmp );
        }
      }else{
        if( tmp < tLine_price ){
          return ( tmp );
        }
      }
      nr++;
    }
    i++;
  }
  return ( -1.0 );
}

bool alreadyUsedThisTLine( int &arr[], int magic ){
  int i = 0, len = ArrayRange( arr, 0 );
  for( ; i < len; i++ ){
    if( arr[i] == magic ){
      return (true);
    }
  }
  return (false);
}

void setHistoryArray( int &arr[] ){
  ArrayResize( arr, 100 );
  int i = 0, nr = 0, len = OrdersTotal(), magic;
  string symb = Symbol();
  for( ; i < len; i++ ) {
    if( OrderSelect( i, SELECT_BY_POS ) ) {
      if( OrderSymbol() == symb ) {
        magic = OrderMagicNumber();
        if( magic > 1000 ){
          arr[nr] = magic;
          nr++;
        }
      }
    }
  }
  
  len = OrdersHistoryTotal();
  for( i = 0; i < len; i++ ) {
    if( OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) {
      if( OrderSymbol() == symb ) {
        magic = OrderMagicNumber();
        if( magic > 1000 ){
          arr[nr] = magic;
          nr++;
        }
      }
    }
  }
  ArrayResize( arr, nr );
}


void loadTrendlines( string &st_tLine[][] ){
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

    ArrayResize( st_tLine, 50 );

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
            st_tLine[nr][TL_NAME] = name;
            st_tLine[nr][TL_STATE] = StringSubstr( name, 12, 3 );
            st_tLine[nr][TL_ID] = StringSubstr( name, 16, 10 );
            nr++;
          }
        break;
      }
      j++;

    }
    FileClose( handle );
    ArrayResize( st_tLine, nr );
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

double getPeakPrice( bool get_high, int to, int from = 0 ){
  double peak, tmp;
  if( get_high ){
    peak = 99999999.9;
    for( ;from < to; from++ ){
      tmp = iLow( NULL, PERIOD_M1, from);
      if( tmp < peak ){
        peak = tmp;
      }
    }
  }else{
    peak = 0.0;
    for( ;from < to; from++ ){
      tmp = iHigh( NULL, PERIOD_M1, from);
      if( tmp > peak ){
        peak = tmp;
      }
    }
  }
  return ( peak );
}
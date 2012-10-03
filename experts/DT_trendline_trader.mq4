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

#define TIME_BWEEN_TRADES 18000 // 5 hour
#define FIBO_TP 0.380 // 0.382
#define TRADE_LOT 0.01
#define EXPIRATION_TIME 7200 // 2 hour

bool CONNECTION_FAIL = true;

int init(){
// #############################################################  Set connection state  ##############################################################
  if( MarketInfo(Symbol(),MODE_TICKVALUE) == 0.0 ){
    CONNECTION_FAIL = true;
    return (0);
  }else{
    CONNECTION_FAIL = false;
  }

  GlobalVariableSet( "TLINE_TRADER_LOG_IDX", 0.0 );
  return(0);
}

int deinit(){
  return(0);
}

int start(){
  if( CONNECTION_FAIL ){
		Sleep(1000);
    init();
    return (0);
  }

  static double st_offset = 0.0;
  static double st_min_profit = 0.0;
  static double st_max_profit = 0.0;
  static double st_spread = 0.0;
  static double st_stop_loss = 0.0;
  static int st_start_time = 0.0;
  static double st_op_mod = 0.0;

  static string st_tLine[][3];
  static bool st_trade_allowed = true;
  static int st_timer_1 = 0;

  if( GetTickCount() > st_timer_1 ){
    if( IsTesting() ){
      st_timer_1 = GetTickCount() + 2000;
    }

    loadTrendlines( st_tLine );

    if( ObjectFind("DT_GO_trade_timing") != -1 ){
      if( ObjectGet( "DT_GO_trade_timing", OBJPROP_TIME1 ) < iTime( NULL, PERIOD_M1, 0) ){
        st_trade_allowed = false;
      }else{
        st_trade_allowed = true;
      }
    }

    if( st_offset == 0.0 ){
      st_offset = 80 / MarketInfo( Symbol(), MODE_TICKVALUE ) * Point;
      st_min_profit = getSymbolData( MIN_PROFIT );
      st_max_profit = getSymbolData( MAX_PROFIT );
      st_spread = getSymbolData( SPREAD );
      st_stop_loss = getSymbolData( STOPLOSS );
      st_start_time = GetTickCount() + 180000; // 3 min
    }
  }

  if( !st_trade_allowed ){
    return (0);
  }

  int i, magic, o_type, shift, ticket;
  double tLine_price, op, sl, tp, fibo_100 = 0.0, new_op, new_tp, new_sl, expiration;
  string comment, tLine_name;
  
// #####################################################  modify Positions  ######################################################
  static double st_timer_2 = 0.0;
  
  if( iTime( NULL, PERIOD_M1, 0) > st_timer_2 ){
    st_timer_2 = iTime( NULL, PERIOD_M1, 0) + 120; // 2min
    for( i = OrdersTotal() - 1; i >= 0; i-- ){
      if( OrderSelect( i, SELECT_BY_POS ) ){
        if( OrderSymbol() == Symbol() ){
          magic = OrderMagicNumber();
          if( magic > 1000 ){
            o_type = OrderType();
            ticket = OrderTicket();
            // #####################################################  OP_BUYLIMIT - OP_SELLLIMIT #####################################################
            if( o_type > 1 ){
              if( st_op_mod < Time[0] ){
                st_op_mod = Time[0];
                tLine_name = getTLineName( st_tLine, magic+"" );
                tLine_price = getTLineValueByShift( tLine_name );
                
                if( tLine_name == "" || tLine_price == 0.0 ){
                  OrderDelete( ticket );
                  errorCheck( StringConcatenate( Symbol()," Limit position is closed due to missing channel line: ",tLine_name,"! ticket id :", ticket ) );
                  log( StringConcatenate( Symbol()," Error limit position is closed due to missing channel line: ",tLine_name,"! ticket id :", ticket ), 8.0, magic );
                  continue;
                }
                
                if( o_type == OP_BUYLIMIT ){ // Buy
                  new_op = NormalizeDouble( tLine_price + st_spread, Digits );
                  new_sl = NormalizeDouble( tLine_price - st_stop_loss, Digits );
                }else{  // Sell
                  new_op = NormalizeDouble( tLine_price, Digits );
                  new_sl = NormalizeDouble( tLine_price + st_stop_loss + st_spread, Digits );
                }
                
                op = NormalizeDouble( OrderOpenPrice(), Digits );
                if( new_op == op ){
                  continue;
                }
                
                new_tp = getTakeProfit( magic+"", tLine_price, o_type, st_min_profit, st_max_profit, st_spread, getNearestLinePrice(o_type, tLine_price, st_tLine, magic+""), fibo_100 );
                if( new_tp == -1.0 ){
                  log( StringConcatenate( Symbol()," Error Limit position tp change ticket id :", ticket ), 8.0, magic );
                  continue;
                }
                
                expiration = TimeCurrent() + EXPIRATION_TIME;
              }
              
            // #####################################################  OP_BUY - OP_SELL ###############################################################
            }else{
              shift = iBarShift( NULL, PERIOD_M1, OrderOpenTime() ) + 1;
              if( o_type == OP_BUY ){ // Buy
                if( iHigh( NULL, PERIOD_M5, 0 ) > NormalizeDouble( OrderTakeProfit(), Digits ) ){
                  OrderClose( ticket, TRADE_LOT, Ask, 3, Red );
                  errorCheck( StringConcatenate( Symbol()," Open position is manually closed, tp: ",NormalizeDouble( OrderTakeProfit(), Digits )," high:", iHigh( NULL, PERIOD_M5, 0 ), " ticket id :", ticket ) );
                  log( StringConcatenate( Symbol()," Open position is manually closed, tp: ",NormalizeDouble( OrderTakeProfit(), Digits )," high:", iHigh( NULL, PERIOD_M5, 0 ), " ticket id :", ticket ), 8.0, magic );
                  continue;
                }
              
                tLine_price = NormalizeDouble( iLow( NULL, PERIOD_M1, iLowest( NULL, PERIOD_M1, MODE_LOW, shift) ), Digits );
                new_op = NormalizeDouble( tLine_price + st_spread, Digits );
                
              }else{ // Sell
                if( iLow( NULL, PERIOD_M5, 0 ) < NormalizeDouble( OrderTakeProfit(), Digits ) ){
                  OrderClose( ticket, TRADE_LOT, Ask, 3, Red );
                  errorCheck( StringConcatenate( Symbol()," Open position is manually closed, tp: ",NormalizeDouble( OrderTakeProfit(), Digits )," low:", iLow( NULL, PERIOD_M5, 0 ), " ticket id :", ticket ) );
                  log( StringConcatenate( Symbol()," Open position is manually closed, tp: ",NormalizeDouble( OrderTakeProfit(), Digits )," low:", iLow( NULL, PERIOD_M5, 0 ), " ticket id :", ticket ), 8.0, magic );
                  continue;
                }
              
                tLine_price = NormalizeDouble( iHigh( NULL, PERIOD_M1, iHighest( NULL, PERIOD_M1, MODE_HIGH, shift) ), Digits );
                new_op = tLine_price;
              }
              
              new_tp = getTakeProfit( magic+"", tLine_price, o_type, st_min_profit, st_max_profit, st_spread, getNearestLinePrice(o_type, tLine_price, st_tLine, magic+""), fibo_100 );
              
              if( new_tp == -1.0 ){
                log( StringConcatenate( Symbol()," Error Open position tp change ticket id :", ticket ), 8.0, magic );
                continue;
              }
              
              if( new_tp == NormalizeDouble( OrderTakeProfit(), Digits ) ){
                continue;
              }
              
              new_op = NormalizeDouble( OrderOpenPrice(), Digits );
              new_sl = NormalizeDouble( OrderStopLoss(), Digits );
              
              expiration = OrderExpiration();
            }
            
            OrderModify( ticket, new_op, new_sl, new_tp, expiration, Red );
            
/* !! */    Print(StringConcatenate("OP Mod: ", Symbol(), " oType:", o_type, " Ticket:", ticket, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Mag:", magic, " new_op:", new_op, " new_tp:", new_tp, " new_sl:", new_sl));
/* !! */    log(StringConcatenate("OP Mod: ", Symbol(), " oType:", o_type, " Ticket:", ticket,  " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Mag:", magic, " new_op:", new_op, " new_tp:", new_tp, " new_sl:", new_sl), MathRand(), magic );     

            errorCheck(StringConcatenate(Symbol(), " Modify Positions Bid:", Bid, " Ask:", Ask, " new_op:", new_op, " new_tp:", new_tp, " new_sl:", new_sl ));            
            
          }
        }
      }
    }
  }
// ###########################################################  Find NEW LMIT Positons  ############################################################
  int len = ArrayRange( st_tLine, 0 );
  for( i = 0; i < len; i++ ){
    // error missing tLine
    if( ObjectFind( st_tLine[i][TL_NAME] ) == -1 ){
      log( StringConcatenate( Symbol()," Error tLine is missing: ",st_tLine[i][TL_NAME] ), 7.0, StrToDouble(st_tLine[i][TL_ID]) );
      loadTrendlines( st_tLine );
      len = ArrayRange( st_tLine, 0 );
      continue;
    }

    // signal line
    if( st_tLine[i][TL_STATE] == "sig" ){
      continue;
    }

    // Current time not cross tLine (tLine is too short or below Time[0])
    tLine_price = getTLineValueByShift( st_tLine[i][TL_NAME] );
    if( tLine_price == 0.0){
      log( StringConcatenate( Symbol()," Error tLine is not enought long: ",st_tLine[i][TL_NAME] ), 8.0, StrToDouble(st_tLine[i][TL_ID]) );
      loadTrendlines( st_tLine );
      len = ArrayRange( st_tLine, 0 );
      continue;
    }

    // tLine not in trade zone
    if( Bid > tLine_price + st_offset || Bid < tLine_price - st_offset ){
      continue;
    }

    // price go against Resistance or Suppress tLine
    if( Open[0] > tLine_price ){
      if( st_tLine[i][TL_STATE] == "res" ){  // Resistance
        log( StringConcatenate( Symbol()," Resistance line: ",st_tLine[i][TL_NAME]," Curr Open[0]:", Open[0] ), 9.0, StrToDouble(st_tLine[i][TL_ID]) );
        continue;
      }else{
        if( Low[0] < tLine_price ){
          log( StringConcatenate( Symbol(), " Warning you are late from BUY LIMIT trade line price:", tLine_price," bar low: ", Low[0] ), 15.0, StrToDouble(st_tLine[i][TL_ID]) );
          continue;
        }
      }
      o_type = OP_BUYLIMIT;

    }else{
      if( st_tLine[i][TL_STATE] == "sup" ){  // Suppress
        log( StringConcatenate( Symbol()," Suppress line: ",st_tLine[i][TL_NAME]," Curr Open[0]:", Open[0] ), 10.0, StrToDouble(st_tLine[i][TL_ID]) );
        continue;
      }else{
        if( High[0] > tLine_price ){
          log( StringConcatenate( Symbol(), " Warning you are late from SELL LIMIT trade line price:", tLine_price," bar high: ", High[0] ), 16.0, StrToDouble(st_tLine[i][TL_ID]) );
          continue;
        }
      }
      o_type = OP_SELLLIMIT;
    }

    // to this tLine there was closed position lately
    if( tLineLatelyUsed( StrToInteger(st_tLine[i][TL_ID]), TIME_BWEEN_TRADES ) ){
      log( StringConcatenate( Symbol()," During ",TimeToStr( TIME_BWEEN_TRADES, TIME_MINUTES)," hours at ", st_tLine[i][TL_NAME]," line we have Opened Position!" ), 11.0, StrToDouble(st_tLine[i][TL_ID]) );
      return (0);
    }

    tp = getTakeProfit( st_tLine[i][TL_ID], tLine_price, o_type, st_min_profit, st_max_profit, st_spread, getNearestLinePrice(o_type, tLine_price, st_tLine, st_tLine[i][TL_ID]), fibo_100 );
    if( tp == -1.0 ){
      continue;
    }

    if( GetTickCount() < st_start_time ){
      if( IDNO == MessageBox(StringConcatenate( Symbol(), " Terminal just started, do you want OPEN position?"), "New order?", MB_YESNO|MB_ICONQUESTION ) ){
        return(0);
      }
    }

    RefreshRates();
    if( Open[0] > tLine_price ){ // Buy
      op = NormalizeDouble( tLine_price + st_spread, Digits );
      sl = NormalizeDouble( tLine_price - st_stop_loss, Digits );
    }else{  // Sell
      op = NormalizeDouble( tLine_price, Digits );
      sl = NormalizeDouble( tLine_price + st_stop_loss + st_spread, Digits );
    }

    comment = DoubleToStr( fibo_100, 5 );
    OrderSend( Symbol(), o_type, TRADE_LOT, op, 5, sl, tp, comment, StrToInteger(st_tLine[i][TL_ID]), TimeCurrent() + EXPIRATION_TIME, Orange );

/* !! */  Print(StringConcatenate("Ty:", o_type, " Lot:", TRADE_LOT, " OP:", op, " SL:", sl, " TP:", tp, " Mag:", st_tLine[i][TL_ID], " Exp:", TimeCurrent()+EXPIRATION_TIME, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Stat:", tLine_price, " H:", High[0]," L:", Low[0], " (", Symbol(), ")"));
/* !! */  log(StringConcatenate("Ty:", o_type, " Lot:", TRADE_LOT, " OP:", op, " SL:", sl, " TP:", tp,  " Mag:", st_tLine[i][TL_ID], " Exp:", TimeCurrent()+EXPIRATION_TIME, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Stat:", tLine_price," H:", High[0]," L:", Low[0], " (", Symbol(), ")"), 18.0, StrToDouble(st_tLine[i][TL_ID]) );

    errorCheck("NEW LIMIT pos Bid:"+ Bid+ " Ask:"+ Ask);
  }

  errorCheck("ppppp");
}

double getTakeProfit( string tl_id, double tLine_price, int o_type, double st_min_profit, double st_max_profit, double spread, double nearest_line_price, double& fibo_100 ){
  static int peris[4] = { 240, 60, 30, 15 };
  double fibo_tp;

  for( int i = 0; i < 4; i++ ){
    fibo_100 = getFibo100( peris[i], tLine_price );
    if( o_type % 2 == 0 ){
      if( fibo_100 < tLine_price ){
        continue;
      }
    }else{
      if( fibo_100 > tLine_price ){
        continue;
      }
    }

    fibo_tp = MathAbs( fibo_100 - tLine_price ) * FIBO_TP;
    if( fibo_tp < st_min_profit ){
      log( StringConcatenate( Symbol()," TP fibo is too close! Cline: ", tl_id, " Distance:", DoubleToStr(fibo_tp, Digits) ), 13.0, StrToDouble(tl_id) );
      return ( -1.0 );
    }else if( fibo_tp > st_max_profit ){
      continue;
    }else{
      if( nearest_line_price < fibo_tp ){
        fibo_tp = nearest_line_price;
      }

      if( o_type % 2 == 0 ){
        return ( NormalizeDouble( tLine_price + fibo_tp, Digits ) );
      }else{
        return ( NormalizeDouble( tLine_price - fibo_tp + spread, Digits ) );
      }
    }
  }

  if( nearest_line_price < st_min_profit ){
    log( StringConcatenate( Symbol()," Another Line is too close! Cline:", tl_id, " Distance:", DoubleToStr(nearest_line_price, Digits) ), 14.0, StrToDouble(tl_id) );
    return ( -1.0 );
  }else if( nearest_line_price > st_max_profit ){
    log( StringConcatenate( Symbol()," TP fibo and any other Line is too far! Cline:", tl_id, " Min Distance:", DoubleToStr(MathMin(nearest_line_price, fibo_tp), Digits) ), 14.0, StrToDouble(tl_id) );
    return ( -1.0 );
  }else{
    if( o_type % 2 == 0 ){
      return ( NormalizeDouble( tLine_price + nearest_line_price, Digits ) );
    }else{
      return ( NormalizeDouble( tLine_price - nearest_line_price + spread, Digits ) );
    }
  }

  if( nearest_line_price > st_min_profit && nearest_line_price < st_max_profit ){
    if( o_type % 2 == 0 ){
      return ( NormalizeDouble( tLine_price + nearest_line_price, Digits ) );
    }else{
      return ( NormalizeDouble( tLine_price - nearest_line_price + spread, Digits ) );
    }
  }else{
    log( StringConcatenate( Symbol()," TP fibo is too far! Cline:", tl_id, " Distance:", DoubleToStr(fibo_tp, Digits) ), 14.0, StrToDouble(tl_id) );
    return ( -1.0 );
  }

}

double getNearestLinePrice( int o_type, double tLine_price, string& st_tLine[][3], string tLine_id ){
  int i = 0, len = ArrayRange( st_tLine, 0 );
  double tmp, min = 99999999.9;

  if( o_type % 2 == 0 ){
    for( ; i < len; i++ ){
      if( tLine_id != st_tLine[i][TL_ID] ){
        tmp = getTLineValueByShift( st_tLine[i][TL_NAME] );
        if( tmp > tLine_price ){
          tmp = tmp - tLine_price;
          if( tmp < min ){
            min = tmp;
          }
        }
      }
    }
  }else{
    for( ; i < len; i++ ){
      if( tLine_id != st_tLine[i][TL_ID] ){
        tmp = getTLineValueByShift( st_tLine[i][TL_NAME] );
        if( tmp < tLine_price ){
          tmp = tLine_price - tmp;
          if( tmp < min ){
            min = tmp;
          }
        }
      }
    }
  }
  return (min);
}

double getFibo100( int peri, double tLine_price ){
  int nr = 0, i = 0;
  double tmp, zz[2];
  while( nr < 2 ){
    tmp = iCustom( Symbol(),  peri, "ZigZag", 12, 5, 3, 0, i );
    if( tmp != 0.0 ){
      zz[nr] = tmp;
      nr++;
    }
    i++;
  }

  if( MathMax(zz[0], zz[1]) > tLine_price && MathMin(zz[0], zz[1]) < tLine_price ){
    return ( zz[0] );
  }else if( MathAbs( zz[0] - tLine_price ) > MathAbs( zz[1] - tLine_price ) ){
    return ( zz[0] );
  }else{
    return ( zz[1] );
  }
}

void loadTrendlines( string &arr[][] ){
  static double st_last_mod = 1.0;
  static string st_gv_name = "";
  static string st_file_name = "";

  if( st_gv_name == "" ){
    st_gv_name = StringConcatenate( getSymbol(), "_tLines_lastMod.csv" );
    if( IsTesting() ){
      st_file_name = StringConcatenate( getSymbol(), "_tLines_test.csv" );
    }else{
      st_file_name = StringConcatenate( getSymbol(), "_tLines.csv" );
    }
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

bool tLineLatelyUsed( int magic, double time_between ){
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
          if( OrderOpenTime() + time_between > TimeCurrent() ){
            return (true);
          }
        }
      }
    }
  }
  return (false);
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
    GlobalVariableSet( "TLINE_TRADER_LOG_IDX", GlobalVariableGet( "TLINE_TRADER_LOG_IDX" ) + 1.0 );
  }
}

string getTLineName( string& st_tLine[][3], string line_id ){
  int i = 0, len = ArrayRange( st_tLine, 0 );
  for( ; i < len; i++ ){
    if( st_tLine[i][TL_ID] == line_id ){
      return ( st_tLine[i][TL_NAME] );
    }
  }
  return ( "" );
}
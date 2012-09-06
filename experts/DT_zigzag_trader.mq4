//+------------------------------------------------------------------+
//|                                             DT_zigzag_trader.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_icons.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
#include <DT_trader_functions.mqh>
#include <WinUser32.mqh>

#define TRADE_LOT 0.1
#define CT_TIME_BWEEN_TRADES 72000 // 20 hour

string TLINES[][5];
string GV_HEARTBEAT;
double CT_OFFSET = 0.0;
double CT_MIN_DIST = 0.0;
double CT_SPREAD = 0.0;
double CT_THRESHOLD = 0.0;
int CT_START_TIME;
int CT_SYM_ID;
bool CONNECTION_FAIL = true;

int init(){
// #############################################################  Set connection state  ##############################################################
  if( MarketInfo(Symbol(),MODE_TICKVALUE) == 0.0 ){
    CONNECTION_FAIL = true;
    return (0);
  }else{
    CONNECTION_FAIL = false;
  }

	if( IsTesting() ){
    setChannelLinesArr( "zLine", TLINES );
    WindowRedraw();
  }

	CT_SYM_ID = getSymbolID();
	CT_SPREAD = NormalizeDouble( getMySpread(), Digits );
  CT_THRESHOLD = NormalizeDouble( CT_SPREAD * 0.2, Digits );
	CT_OFFSET = 65 / MarketInfo(Symbol(),MODE_TICKVALUE) * Point;
	CT_MIN_DIST = 270 / MarketInfo(Symbol(),MODE_TICKVALUE) * Point;
	GV_HEARTBEAT = StringConcatenate( StringSubstr(Symbol(), 0, 6), "_ZZ_", getPeriodSortName( Period() ), "_heartbeat" );
	CT_START_TIME = GetTickCount() + 180000; // 3 min
  return(0);
}

int start(){
// ###############################################################  Check connection  ################################################################
  if( CONNECTION_FAIL ){
		Sleep(1000);
    init();
    return (0);
  }

// ##############################################################  Periodic functions  ###############################################################
  static int timer_1 = 0;
  if( !IsTesting() && GetTickCount() > timer_1 ){
    timer_1 = GetTickCount() + 2000;

  // ============================================================  Save Lines to array  =============================================================
    setChannelLinesArr( "zLine", TLINES );

  // ==============================================================  Heartbeat check  =================================================================
    // if( GlobalVariableGet( GV_HEARTBEAT ) > 0.0 ){
      // GlobalVariableSet( GV_HEARTBEAT, 0.0 );
    // }

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
  
  if( !trade_allowed ){
    return (0);
  }

// ###########################################################  Find NEW LMIT Positons  ############################################################
  int i, o_type, len = ArrayRange( TLINES, 0 ), magic;
  double tLine_price, fibo_100, fibo_100_time, op, tp, sl, fibo_time_cross_line, dif, peek;
  for( i = 0; i < len; i++ ){
    // error missing cLine
    if( ObjectFind( TLINES[i][TL_NAME] ) == -1 ){
      log( StringConcatenate( Symbol()," Error cLine is missing: ",TLINES[i][TL_NAME] ), 7.0, StrToDouble(TLINES[i][TL_ID]) );
      setChannelLinesArr( "zLine", TLINES );
      continue;
    }

    // current cLine price
    tLine_price = getClineValueByShift( TLINES[i][TL_NAME] );

    // Current time not cross cLine (cLine is too short or below Time[0])
    if( tLine_price == 0.0){
      log( StringConcatenate( Symbol()," Error cLine is not enought long: ",TLINES[i][TL_NAME] ), 8.0, StrToDouble(TLINES[i][TL_ID]) );
      setChannelLinesArr( "zLine", TLINES );
      continue;
    }

    // cLine not in trade zone
    if( Bid > tLine_price + CT_OFFSET || Bid < tLine_price - CT_OFFSET ){
      continue;
    }

    // get Fibo 100, Fibo 100 time
		getFibo100( PERIOD_M15, tLine_price ,fibo_100, fibo_100_time );

    // price go against Resistance or Suppress clLine
    if( fibo_100 > tLine_price ){
      if( TLINES[i][TL_STATE] == "res" ){  // Resistance
        log( StringConcatenate( Symbol()," Resistance line: ",TLINES[i][TL_NAME]," Curr fibo 100:",fibo_100 ), 9.0, StrToDouble(TLINES[i][TL_ID]) );
        continue;
      }
    }else{
      if( TLINES[i][TL_STATE] == "sup" ){  // Suppress
        log( StringConcatenate( Symbol()," Suppress line: ",TLINES[i][TL_NAME]," Curr fibo 100:",fibo_100 ), 10.0, StrToDouble(TLINES[i][TL_ID]) );
        continue;
      }
    }

    // to this cLine there was closed position lately
    if( tLineLatelyUsed( StrToDouble(TLINES[i][TL_ID]), CT_TIME_BWEEN_TRADES ) ){
      log( StringConcatenate( Symbol()," During ",TimeToStr( CT_TIME_BWEEN_TRADES, TIME_MINUTES)," hours at ", TLINES[i][TL_NAME]," line we have Opened Position!" ), 11.0, StrToDouble(TLINES[i][TL_ID]) );
      return (0);
    }

    // where fibo100 time cross the cLine
    fibo_time_cross_line = getClineValueByShift( TLINES[i][TL_NAME], iBarShift( NULL, 0, fibo_100_time ) );

    // Fibo 100 time not cross the cLine
    if( fibo_time_cross_line == 0.0 ){
      log( StringConcatenate( Symbol()," Error fibo100 time:", fibo_100_time," not cross current cLine:", TLINES[i][TL_NAME] ), 12.0, StrToDouble(TLINES[i][TL_ID]) );
      continue;
    }

    // Fibo 100 <=> cLine difference
    dif = MathAbs( fibo_100 - fibo_time_cross_line );

    // distance is too small between Fibo 100 and cLine
    if( dif < CT_MIN_DIST ){  // Min Distance
      log( StringConcatenate( Symbol()," Fibo DISTANCE is too SMALL! Cline: ", TLINES[i][TL_NAME]," Min Distance: ",CT_MIN_DIST," Curr distance:", dif ), 13.0, StrToDouble(TLINES[i][TL_ID]) );
      continue;
    }

    // fake Fibo 100 price is already below cLine
    if( alreadyBelowCLine( tLine_price ,fibo_100, fibo_100_time ) ){
      log( StringConcatenate( Symbol()," Price is already below trade_line: ", TLINES[i][TL_NAME]," Curr fibo 100:",fibo_100 ), 14.0, StrToDouble(TLINES[i][TL_ID]) );
      continue;
    }

    if( GetTickCount() < CT_START_TIME ){
      CT_START_TIME = GetTickCount();
      if(IDNO == MessageBox(StringConcatenate( Symbol(), " Terminal just started, do you want OPEN position?"), "Channel trading", MB_YESNO|MB_ICONQUESTION )){
        return(0);
      }
    }

    RefreshRates();
    if( fibo_100 > tLine_price ){ // BUY LIMIT
      peek = iLow( NULL, PERIOD_M30, 0);
      if( peek > tLine_price ){
        o_type = OP_BUYLIMIT;
				op = NormalizeDouble( tLine_price + CT_SPREAD + CT_THRESHOLD, Digits );
        tp = NormalizeDouble( op + SYMBOLS_TP[CT_SYM_ID], Digits );
        sl = NormalizeDouble( op - SYMBOLS_SL[CT_SYM_ID], Digits );
      }else{
        log( StringConcatenate( Symbol(), " Warning you are late from BUY LIMIT trade line price:", tLine_price," bar low: ", peek ), 15.0, StrToDouble(TLINES[i][TL_ID]) );
        return (0);
      }

    }else{  // SELL LIMIT
      peek = iHigh( NULL, PERIOD_M30, 0);
      if( peek < tLine_price ){
        o_type = OP_SELLLIMIT;
				op = NormalizeDouble( tLine_price - CT_THRESHOLD, Digits );
        tp = NormalizeDouble( op - SYMBOLS_TP[CT_SYM_ID] + CT_SPREAD, Digits );
        sl = NormalizeDouble( op + SYMBOLS_SL[CT_SYM_ID] + CT_SPREAD, Digits );
      }else{
        log( StringConcatenate( Symbol(), " Warning you are late from SELL LIMIT trade line price:", tLine_price," bar high: ", peek ), 16.0, StrToDouble(TLINES[i][TL_ID]) );
        return (0);
      }
    }

    // comment = StringConcatenate( TLINES[i][TL_TYPE], " ", DoubleToStr( fibo_100, 5 ) );
    OrderSend( Symbol(), o_type, TRADE_LOT, op, 5, sl, tp, TLINES[i][TL_NAME], StrToInteger(TLINES[i][TL_ID]), TimeCurrent()+5400, Orange );

/* !! */  Print(StringConcatenate("Ty:", o_type, " Lot:", TRADE_LOT, " OP:", op, " SL:", sl, " TP:", tp, " Mag:", TLINES[i][TL_ID], " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Stat:", tLine_price," Dist:", dif," H:", iHigh( NULL, PERIOD_M15, 0)," L:", iLow( NULL, PERIOD_M15, 0), " (", Symbol(), ")"));
/* !! */  log(StringConcatenate("Ty:", o_type, " Lot:", TRADE_LOT, " OP:", op, " SL:", sl, " TP:", tp,  " Mag:", TLINES[i][TL_ID], " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Stat:", tLine_price," Dist:", dif," H:", iHigh( NULL, PERIOD_M15, 0)," L:", iLow( NULL, PERIOD_M15, 0), " (", Symbol(), ")"), 18.0, StrToDouble(TLINES[i][TL_ID]) );

    errorCheck("NEW LIMIT pos Bid:"+ Bid+ " Ask:"+ Ask);
  }
  return(0);
}

int deinit(){
  return(0);
}

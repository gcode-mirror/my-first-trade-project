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
#define CT_TIME_BWEEN_TRADES 18000 // 5 hour

#define CT_FIBO_23 0.234 // 0.236
#define CT_FIBO_38 0.380 // 0.382

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
  CT_THRESHOLD = NormalizeDouble( CT_SPREAD * 0.5, Digits );
	CT_OFFSET = 80 / MarketInfo(Symbol(),MODE_TICKVALUE) * Point;
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
  
// #####################################################  modify OP_BUY - OP_SELL Positions  ###################################################### 
  int o_type, magic, i = 0, len;
  double tLine_price, fibo_100, fibo_100_time, op, tp, sl, new_tp, fibo_time_cross_line, dif, peek;
  string comment;
  
  static int timer_2 = 0;
  if( IsTesting() || GetTickCount() > timer_2 ){
    timer_2 = GetTickCount() + 120000; // 2 minutes
    len = OrdersTotal();
    for( ; i < len; i++ ) {
      if( OrderSelect( i, SELECT_BY_POS ) ) {
        if( OrderSymbol() == Symbol() ) {
          magic = OrderMagicNumber();
          if( magic > 1000 ){
            o_type = OrderType();
            double new_sl, new_op, lowest, highest;
            int shift = iBarShift( NULL, PERIOD_M1, OrderOpenTime() ) + 1;
            lowest = NormalizeDouble( iLow( NULL, PERIOD_M1, iLowest( NULL, PERIOD_M1, MODE_LOW, shift) ), Digits );
            highest = NormalizeDouble( iHigh( NULL, PERIOD_M1, iHighest( NULL, PERIOD_M1, MODE_HIGH, shift) ), Digits );
            
            op = NormalizeDouble( OrderOpenPrice(), Digits );
            sl = NormalizeDouble( OrderStopLoss(), Digits );
            tp = NormalizeDouble( OrderTakeProfit(), Digits );
            if( o_type % 2 == 0 ){ // BUY
              new_op = lowest;
              if( highest > op + SYMBOLS_SL_CHANGE[CT_SYM_ID] ){
                new_sl = NormalizeDouble( op + SYMBOLS_SL_2[CT_SYM_ID], Digits );
                if( new_sl == sl ){
                  continue;
                }
                new_tp = tp;
              }else if( NormalizeDouble( new_op + CT_SPREAD + CT_THRESHOLD, Digits ) < op ){
                fibo_100 = NormalizeDouble( StrToDouble( OrderComment() ), Digits );
                new_tp = getTpPrice( o_type, new_op, fibo_100, fibo_100_time );
                
                if( new_tp == tp ){
                  continue;
                }
                new_sl = sl;
              }else{
                continue;
              }  
            }else{
              new_op = highest;
              if( lowest < op - SYMBOLS_SL_CHANGE[CT_SYM_ID] ){
                new_sl = NormalizeDouble( op - SYMBOLS_SL_2[CT_SYM_ID] + CT_SPREAD, Digits );
                if( new_sl == sl ){
                  continue;
                }
                new_tp = tp;
                
              }else if( NormalizeDouble( new_op - CT_THRESHOLD, Digits ) > NormalizeDouble( OrderOpenPrice(), Digits ) ){
                fibo_100 = NormalizeDouble( StrToDouble( OrderComment() ), Digits );
                new_tp = getTpPrice( o_type, new_op, fibo_100, fibo_100_time );
                
                if( new_tp == tp ){
                  continue;
                }
                new_sl = sl;
              }else{
                continue;
              }
            }
            
            if( GetTickCount() < CT_START_TIME ){
              CT_START_TIME = GetTickCount();
              if(IDNO == MessageBox(StringConcatenate( Symbol(), " Terminal just started, do you want MODIFY position?"), "ZigZag trading", MB_YESNO|MB_ICONQUESTION )){
                return(0);
              }
            }
            
            OrderModify( OrderTicket(), op, new_sl, new_tp, TimeCurrent()+5400, Red );
            
/* !! */    Print(StringConcatenate("OP Mod: ", Symbol(), " oType:", o_type, " Ticket:", OrderTicket(), " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Mag:", OrderMagicNumber(), " op:", op, " new_op:", new_op, " tp:", tp, " new_tp:", new_tp, " sl:", sl, " new_sl:", new_sl));
/* !! */    log(StringConcatenate("OP Mod: ", Symbol(), " oType:", o_type, " Ticket:", OrderTicket(),  " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Mag:", OrderMagicNumber(), " op:", op, " new_op:", new_op, " tp:", tp, " new_tp:", new_tp, " sl:", sl, " new_sl:", new_sl), MathRand(), magic );     

            errorCheck(StringConcatenate(Symbol(), " Modify Positions Bid:", Bid, " Ask:", Ask, " op:", op, " new_op:", new_op, " tp:", tp, " new_tp:", new_tp, " sl:", sl, " new_sl:", new_sl ));            
          }
        }
      }
    }
  }

// ###########################################################  Find NEW LMIT Positons  ############################################################
  len = ArrayRange( TLINES, 0 );
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
		getFibo100( PERIOD_H1, tLine_price ,fibo_100, fibo_100_time );

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
      if(IDNO == MessageBox(StringConcatenate( Symbol(), " Terminal just started, do you want OPEN position?"), "ZigZag trading", MB_YESNO|MB_ICONQUESTION )){
        return(0);
      }
    }

    RefreshRates();
    if( fibo_100 > tLine_price ){ // BUY LIMIT
      peek = iLow( NULL, PERIOD_M30, 0);
      if( peek > tLine_price ){
        o_type = OP_BUYLIMIT;
				op = NormalizeDouble( tLine_price + CT_SPREAD + CT_THRESHOLD, Digits );
        tp = getTpPrice( o_type, tLine_price, fibo_100, fibo_100_time );
        sl = NormalizeDouble( tLine_price - SYMBOLS_SL[CT_SYM_ID], Digits );
      }else{
        log( StringConcatenate( Symbol(), " Warning you are late from BUY LIMIT trade line price:", tLine_price," bar low: ", peek ), 15.0, StrToDouble(TLINES[i][TL_ID]) );
        return (0);
      }

    }else{  // SELL LIMIT
      peek = iHigh( NULL, PERIOD_M30, 0);
      if( peek < tLine_price ){
        o_type = OP_SELLLIMIT;
				op = NormalizeDouble( tLine_price - CT_THRESHOLD, Digits );
        tp = getTpPrice( o_type, tLine_price, fibo_100, fibo_100_time );
        sl = NormalizeDouble( tLine_price + SYMBOLS_SL[CT_SYM_ID] + CT_SPREAD, Digits );
      }else{
        log( StringConcatenate( Symbol(), " Warning you are late from SELL LIMIT trade line price:", tLine_price," bar high: ", peek ), 16.0, StrToDouble(TLINES[i][TL_ID]) );
        return (0);
      }
    }

    comment = DoubleToStr( fibo_100, 5 );
    OrderSend( Symbol(), o_type, TRADE_LOT, op, 5, sl, tp, comment, StrToInteger(TLINES[i][TL_ID]), TimeCurrent()+5400, Orange );

/* !! */  Print(StringConcatenate("Ty:", o_type, " Lot:", TRADE_LOT, " OP:", op, " SL:", sl, " TP:", tp, " Mag:", TLINES[i][TL_ID], " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Stat:", tLine_price," Dist:", dif," H:", iHigh( NULL, PERIOD_M15, 0)," L:", iLow( NULL, PERIOD_M15, 0), " (", Symbol(), ")"));
/* !! */  log(StringConcatenate("Ty:", o_type, " Lot:", TRADE_LOT, " OP:", op, " SL:", sl, " TP:", tp,  " Mag:", TLINES[i][TL_ID], " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Stat:", tLine_price," Dist:", dif," H:", iHigh( NULL, PERIOD_M15, 0)," L:", iLow( NULL, PERIOD_M15, 0), " (", Symbol(), ")"), 18.0, StrToDouble(TLINES[i][TL_ID]) );

    errorCheck("NEW LIMIT pos Bid:"+ Bid+ " Ask:"+ Ask);
  }
  return(0);
}

double getTpPrice( int o_type, double tLine_price, double& fibo_100, double& fibo_100_time ){
  double tmp;
  if( o_type % 2 == 0 ){ // BUY
    tmp = ( fibo_100 - tLine_price ) * CT_FIBO_38;
    if( tmp < SYMBOLS_TP[CT_SYM_ID] ){
      getFibo100( PERIOD_H4, tLine_price ,fibo_100, fibo_100_time );
      return ( NormalizeDouble( tLine_price + MathMax( tmp, (( fibo_100 - tLine_price ) * CT_FIBO_23) ), Digits ) );
    }else{
      return ( NormalizeDouble( tLine_price + tmp, Digits ) );
    }
  }else{ // SELL
    tmp = ( tLine_price - fibo_100 ) * CT_FIBO_38;
    if( tmp < SYMBOLS_TP[CT_SYM_ID] ){
      getFibo100( PERIOD_H4, tLine_price ,fibo_100, fibo_100_time );
      return ( NormalizeDouble( tLine_price - MathMax( tmp, (( tLine_price - fibo_100 ) * CT_FIBO_23) ) + CT_SPREAD, Digits ) );
    }else{
      return ( NormalizeDouble( tLine_price - tmp + CT_SPREAD, Digits ) );
    }
  }
}

int deinit(){
  return(0);
}

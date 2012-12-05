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

#define TL_SIB_ABOVE 0
#define TL_SIB_BELOW 1

#include <DT_defaults.mqh>
#include <DT_functions.mqh>
#include <WinUser32.mqh>

#import "user32.dll"
  int GetAncestor(int, int);
#import

#define FIBO_TP 0.380 // 0.382
#define TRADE_LOT 0.1
#define EXPIRATION_TIME 7200 // 2 hour
#define NR_OF_ALLOW_POSITION 8 // x/2!
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
  int i = 0, idx, o_type, len = OrdersTotal(), magic, ticket, main_ticket;
  bool is_buy;
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
                log( StringConcatenate( Symbol()," Open position is manually closed, tp: ",NormalizeDouble( OrderTakeProfit(), Digits )," highest:", peak, " ticket id :", ticket, " Bid:", Bid, " Ask:", Ask ), 2.0, magic );
                continue;
              }
            }else{
              if( peak <= NormalizeDouble( OrderTakeProfit(), Digits ) ){
                OrderClose( ticket, TRADE_LOT, Ask, 3, Red );
                errorCheck( StringConcatenate( Symbol()," Open position is manually closed, tp: ",NormalizeDouble( OrderTakeProfit(), Digits )," lowest:", peak, " ticket id :", ticket, " Bid:", Bid, " Ask:", Ask ) );
                log( StringConcatenate( Symbol()," Open position is manually closed, tp: ",NormalizeDouble( OrderTakeProfit(), Digits )," lowest:", peak, " ticket id :", ticket, " Bid:", Bid, " Ask:", Ask ), 3.0, magic );
                continue;
              }
            }
            
          }else if( o_type > 3 ){
            main_ticket = StrToInteger( OrderComment() );
            if( main_ticket != 0 ){
/*OSelect!!*/ if( OrderSelect( main_ticket, SELECT_BY_TICKET, MODE_HISTORY ) ){
                if( OrderMagicNumber() == magic ){
                  if( OrderProfit() >= 0.0 && OrderCloseTime() != 0.0 ){
                    OrderDelete( ticket );
                    errorCheck( StringConcatenate( Symbol()," close safety position ticket id :", main_ticket, " magic:", magic, " closed ticket:", ticket ) );
                    log( StringConcatenate( Symbol()," close safety position ticket id :", main_ticket, " magic:", magic, " closed ticket:", ticket ), 4.0, magic );
										
										Alert(OrderTicket()+"  OrderComment:"+ OrderComment()+" OrderCloseTime:"+OrderCloseTime()+" OrderType:"+OrderType()+" OrderProfit:"+OrderProfit() );
                    continue;
                  }
                }
              }
            }
          }else{
            idx = getTLineIdx( st_tLine, magic+"" );
            if( idx == -1 ){
              return(0);
            }
            
            tLine_price = getTLineValueByShift( st_tLine[idx][TL_NAME] );
            if( tLine_price == 0 ){
              return(0);
            }
            
            if( o_type == OP_BUYLIMIT ){
              is_buy = true;
              op = NormalizeDouble( tLine_price + st_spread, Digits );
            }else{
              is_buy = false;
              op = NormalizeDouble( tLine_price, Digits );
            }
            
            if( !getPositionData( idx, tLine_price, st_tLine, fibo_100, is_buy, st_spread, st_stop_loss, st_fail_sl, st_max_dist, st_sml_tp, st_sml_magnet, st_min_tp, st_max_tp, tp, sl, comment ) ){
              return(0);
            }
            
            if( op != NormalizeDouble( OrderOpenPrice(), Digits ) || tp != NormalizeDouble( OrderTakeProfit(), Digits ) || sl != NormalizeDouble( OrderStopLoss(), Digits ) ){
            
/* !! */  Print(StringConcatenate("LIMIT MOD Ty:", o_type, " OLD_OP:", DoubleToStr(OrderOpenPrice(), Digits), " OLD_SL:", DoubleToStr(OrderStopLoss(), Digits), " OLD_TP:", DoubleToStr(OrderTakeProfit(), Digits), " OP:", DoubleToStr(op, Digits), " SL:", DoubleToStr(sl, Digits), " TP:", DoubleToStr(tp, Digits), " Mag:", st_tLine[idx][TL_ID], " Exp:", OrderExpiration(), " F100:", fibo_100, " Bid:", DoubleToStr(Bid, Digits), " Ask:", DoubleToStr(Ask, Digits), " Stat:", DoubleToStr(tLine_price, Digits), " H:", DoubleToStr(High[0], Digits)," L:", DoubleToStr(Low[0], Digits), " (", Symbol(), ")"));
/* !! */  log(StringConcatenate("LIMIT MOD Ty:", o_type, " OLD_OP:", DoubleToStr(OrderOpenPrice(), Digits), " OLD_SL:", DoubleToStr(OrderStopLoss(), Digits), " OLD_TP:", DoubleToStr(OrderTakeProfit(), Digits), " OP:", DoubleToStr(op, Digits), " SL:", DoubleToStr(sl, Digits), " TP:", DoubleToStr(tp, Digits),  " Mag:", st_tLine[idx][TL_ID], " Exp:", OrderExpiration(), " F100:", fibo_100, " Bid:", DoubleToStr(Bid, Digits), " Ask:", DoubleToStr(Ask, Digits), " Stat:", DoubleToStr(tLine_price, Digits), " H:", DoubleToStr(High[0], Digits)," L:", DoubleToStr(Low[0], Digits), " (", Symbol(), ")"), 7.0, StrToDouble(st_tLine[idx][TL_ID]) );        
              
              OrderModify( ticket, op, sl, tp, OrderExpiration(), Red );
              
              errorCheck( StringConcatenate( Symbol()," Fail LIMIT position mod! magic:", magic, " ticket:", ticket ) );
            }
          }
        }
      }
    }
  }
  
  // ###########################################################  Find NEW Positons  ############################################################
  idx = getClosestTLineId( st_tLine, st_offset );
  if( idx != -1 ){
    tLine_price = getTLineValueByShift( st_tLine[idx][TL_NAME] );
    
    if( iOpen( NULL, PERIOD_M1, 1 ) > tLine_price ){
      is_buy = true;
      o_type = OP_BUYLIMIT;
      op = NormalizeDouble( tLine_price + st_spread, Digits );
    }else{
      is_buy = false;
      o_type = OP_SELLLIMIT;
      op = NormalizeDouble( tLine_price, Digits );
    }
    
    if( getPositionData( idx, tLine_price, st_tLine, fibo_100, is_buy, st_spread, st_stop_loss, st_fail_sl, st_max_dist, st_sml_tp, st_sml_magnet, st_min_tp, st_max_tp, tp, sl, comment ) == 0 ){
      return(0);
    }
    
    if( !IsTesting() ){
      if( GetTickCount() < st_start_time ){
        if( IDNO == MessageBox(StringConcatenate( Symbol(), " Terminal just started, do you want OPEN position?"), "New order?", MB_YESNO|MB_ICONQUESTION ) ){
          return(0);
        }
      }
    }
 
    ticket = OrderSend( Symbol(), o_type, TRADE_LOT, op, 5, sl, tp, comment, StrToInteger( st_tLine[idx][TL_ID] ), TimeCurrent() + EXPIRATION_TIME, Orange );
    
/* !! */  Print(StringConcatenate("New Ty:", o_type, " Lot:", TRADE_LOT, " OP:", DoubleToStr(op, Digits), " SL:", DoubleToStr(sl, Digits), " TP:", DoubleToStr(tp, Digits), " Mag:", st_tLine[idx][TL_ID], " Exp:", TimeCurrent()+EXPIRATION_TIME, " F100:", fibo_100, " Bid:", DoubleToStr(Bid, Digits), " Ask:", DoubleToStr(Ask, Digits), " Stat:", DoubleToStr(tLine_price, Digits), " H:", DoubleToStr(High[0], Digits)," L:", DoubleToStr(Low[0], Digits), " (", Symbol(), ")"));
/* !! */  log(StringConcatenate("New Ty:", o_type, " Lot:", TRADE_LOT, " OP:", DoubleToStr(op, Digits), " SL:", DoubleToStr(sl, Digits), " TP:", DoubleToStr(tp, Digits),  " Mag:", st_tLine[idx][TL_ID], " Exp:", TimeCurrent()+EXPIRATION_TIME, " F100:", fibo_100, " Bid:", DoubleToStr(Bid, Digits), " Ask:", DoubleToStr(Ask, Digits), " Stat:", DoubleToStr(tLine_price, Digits), " H:", DoubleToStr(High[0], Digits)," L:", DoubleToStr(Low[0], Digits), " (", Symbol(), ")"), 7.0, StrToDouble(st_tLine[idx][TL_ID]) );        

    errorCheck( StringConcatenate( Symbol()," Fail NEW position!" ) );

    if( ticket != -1 ){
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
      OrderSend( Symbol(), o_type, TRADE_LOT, op, 5, sl, tp, comment, StrToInteger( st_tLine[idx][TL_ID] ), 0, Blue );
      
/* !! */  Print(StringConcatenate("Safety Ty:", o_type, " Lot:", TRADE_LOT, " OP:", DoubleToStr(op, Digits), " SL:", DoubleToStr(sl, Digits), " TP:", DoubleToStr(tp, Digits), " Mag:", st_tLine[idx][TL_ID], " Exp:", TimeCurrent()+EXPIRATION_TIME, " F100:", fibo_100, " Bid:", DoubleToStr(Bid, Digits), " Ask:", DoubleToStr(Ask, Digits), " Stat:", DoubleToStr(tLine_price, Digits), " H:", DoubleToStr(High[0], Digits)," L:", DoubleToStr(Low[0], Digits), " (", Symbol(), ")"));
/* !! */  log(StringConcatenate("Safety Ty:", o_type, " Lot:", TRADE_LOT, " OP:", DoubleToStr(op, Digits), " SL:", DoubleToStr(sl, Digits), " TP:", DoubleToStr(tp, Digits),  " Mag:", st_tLine[idx][TL_ID], " Exp:", TimeCurrent()+EXPIRATION_TIME, " F100:", fibo_100, " Bid:", DoubleToStr(Bid, Digits), " Ask:", DoubleToStr(Ask, Digits), " Stat:", DoubleToStr(tLine_price, Digits), " H:", DoubleToStr(High[0], Digits)," L:", DoubleToStr(Low[0], Digits), " (", Symbol(), ")"), 7.0, StrToDouble(st_tLine[idx][TL_ID]) );        

      errorCheck( StringConcatenate( Symbol()," Fail NEW Safety position!" ) );
    }
  }
}

int getPositionData( int& idx, double& tLine_price, string& st_tLine[][3], double& fibo_100, bool& is_buy, double& st_spread, double& st_stop_loss, double& st_fail_sl, double &st_max_dist, double& st_sml_tp, double& st_sml_magnet, double& st_min_tp, double& st_max_tp, double& tp, double& sl, string& comment ){
  double siblings[2];
  getNearestLinePrices( tLine_price, st_tLine, siblings );
    
  sl = getStopLoss( is_buy, tLine_price, st_spread, st_stop_loss, st_fail_sl, siblings, st_tLine[idx][TL_ID] );
  if( sl == -1.0 ){
    return(0);
  }
  
  if( st_tLine[idx][TL_STATE] == "sml" ){
    if( peekIsNotEnoughFar( is_buy, tLine_price, st_max_dist ) ){
      log( StringConcatenate( Symbol()," Closest Peek is not enought far: ",st_tLine[idx][TL_NAME]," tLine_price:", tLine_price, " is_buy:", is_buy ), 5.0, StrToDouble(st_tLine[idx][TL_ID]) );
      return(0);
    }
  
    tp = getSmallTakeProfit( is_buy, tLine_price, st_spread, st_sml_tp, st_sml_magnet, siblings, st_tLine[idx][TL_ID] );
    comment = "";
    
  }else if( st_tLine[idx][TL_STATE] == "big" ){
  
    tp = getBigTakeProfit( is_buy, fibo_100, tLine_price, st_spread, st_min_tp, st_max_tp, siblings, st_tLine[idx][TL_ID] );
    comment = DoubleToStr( fibo_100, 5 );
    
  }else{
    log( StringConcatenate( Symbol()," unknown state:", st_tLine[idx][TL_STATE], " line:", st_tLine[idx][TL_NAME], Period() ), 6.0, StrToDouble(st_tLine[idx][TL_ID]) );
    return (0);
  }
  
  if( tp == -1.0 ){
    return(0);
  }
  return(1);
}

int getTLineIdx( string &st_tLine[][], string id ){
  int i = 0, len = ArrayRange( st_tLine, 0 );
  for( ; i < len; i++ ){
    if( st_tLine[i][TL_ID] == id ){
      return(i);
    }
  }
  return(-1);
}


int getClosestTLineId( string &st_tLine[][], double &st_offset ){
  int i = 0, len = ArrayRange( st_tLine, 0 ), order_history[], used_idx = -1, pos_nr = 0;
  double tLine_price, tmp, min_dist = 999999.0;
  
  setHistoryArray( order_history, pos_nr );
  if( pos_nr >= NR_OF_ALLOW_POSITION ){
    log( StringConcatenate( Symbol()," Allow daily position limit reached! allow:", NR_OF_ALLOW_POSITION, " current:", pos_nr ), 8.0 );
    return (-1);
  }
  
  for( ; i < len; i++ ){
    // missing tLine
    if( ObjectFind( st_tLine[i][TL_NAME] ) == -1 ){
      log( StringConcatenate( Symbol()," Error tLine is missing: ",st_tLine[i][TL_NAME] ), 9.0, StrToDouble(st_tLine[i][TL_ID]) );
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
      log( StringConcatenate( Symbol()," Error tLine is not enought long: ",st_tLine[i][TL_NAME] ), 10.0, StrToDouble(st_tLine[i][TL_ID]) );
      continue;
    }
    
    // tLine not in trade zone
    if( Bid > tLine_price + st_offset || Bid < tLine_price - st_offset ){
      continue;
    }
    
    // has lately used tLine 
    if( alreadyUsedThisTLine( order_history, StrToInteger( st_tLine[i][TL_ID] ) ) ){
      log( StringConcatenate( Symbol()," This line (", StrToDouble(st_tLine[i][TL_ID]) ,") is already used!" ), 11.0, StrToDouble(st_tLine[i][TL_ID]) );
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

double getSmallTakeProfit( bool is_buy, double &tLine_price, double& st_spread, double& st_sml_tp, double& st_sml_magnet, double& siblings[2], string line_id ){
  if( is_buy ){
    if( siblings[TL_SIB_ABOVE] < st_sml_tp ){
      log( StringConcatenate( Symbol()," Above sibling is too close (betweeen trade line and TP)! Line id:", line_id ), 12.0, StrToDouble(line_id) );
      return ( -1.0 );
    }else if( siblings[TL_SIB_ABOVE] < st_sml_magnet ){
      return (NormalizeDouble( tLine_price + siblings[TL_SIB_ABOVE], Digits ));
    }else{
      return (NormalizeDouble( tLine_price + st_sml_tp, Digits ));
    }
  }else{
    if( siblings[TL_SIB_BELOW] < st_sml_tp ){
      log( StringConcatenate( Symbol()," Below sibling is too close (betweeen trade line and TP)! Line id:", line_id ), 13.0, StrToDouble(line_id) );
      return ( -1.0 );
    }else if( siblings[TL_SIB_BELOW] < st_sml_magnet ){
      return (NormalizeDouble( tLine_price - siblings[TL_SIB_BELOW] + st_spread, Digits ));
    }else{
      return (NormalizeDouble( tLine_price - st_sml_tp + st_spread, Digits ));
    }
  }
  return ( -1.0 );
}

double getStopLoss( bool is_buy, double &tLine_price, double& st_spread, double& st_stop_loss, double& st_fail_sl, double& siblings[2], string line_id ){
  if( is_buy ){
    if( siblings[TL_SIB_BELOW] < st_stop_loss + st_fail_sl ){
      log( StringConcatenate( Symbol()," Below sibling is too close (betweeen trade line and SL)! Line id:", line_id ), 14.0, StrToDouble(line_id) );
      return ( -1.0 );
    }else{
      return (NormalizeDouble( tLine_price - st_stop_loss, Digits ));
    }
  }else{
    if( siblings[TL_SIB_ABOVE] < st_stop_loss + st_fail_sl ){
      log( StringConcatenate( Symbol()," Abow sibling is too close (betweeen trade line and SL)! Line id:", line_id ), 15.0, StrToDouble(line_id) );
      return ( -1.0 );
    }else{
      return (NormalizeDouble( tLine_price + st_stop_loss + st_spread, Digits ));
    }
  }
  return ( -1.0 );
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

double getBigTakeProfit( bool is_buy, double &fibo_100, double &tLine_price, double& st_spread, double& st_min_tp, double& st_max_tp, double& siblings[2], string line_id ){
  static int peris[4] = { 240, 60, 30, 15 };
  double fibo_tp;
  
  for( int i = 0; i < 4; i++ ){ // 4 hard code!!!
    fibo_100 = getFibo100( peris[i], tLine_price, is_buy );
    if( fibo_100 == -1.0 ){
      log( StringConcatenate( Symbol()," Wrong fibo100! line ID: ", line_id ), 16.0, StrToDouble(line_id) );
      return ( -1.0 );
    }
    
    fibo_tp = MathAbs( fibo_100 - tLine_price ) * FIBO_TP;
    
    if( is_buy ){
      if( siblings[TL_SIB_ABOVE] < fibo_tp ){
        fibo_tp = siblings[TL_SIB_ABOVE];
      }
    }else{
      if( siblings[TL_SIB_BELOW] < fibo_tp ){
        fibo_tp = siblings[TL_SIB_BELOW];
      }
    }
    
    if( fibo_tp < st_min_tp ){
      log( StringConcatenate( Symbol()," TP fibo is too close! line ID: ", line_id, " Distance:", DoubleToStr(fibo_tp, Digits) ), 17.0, StrToDouble(line_id) );
      return ( -1.0 );
    }else if( fibo_tp > st_max_tp ){
      if( i == 3 ){ // hard code!!!
        log( StringConcatenate( Symbol()," TP fibo is too far! line ID:", line_id, " Distance:", DoubleToStr(fibo_tp, Digits) ), 18.0, StrToDouble(line_id) );
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

void getNearestLinePrices( double& tLine_price, string& st_tLine[][3], double& siblings[2] ){
  int i = 0, len = ArrayRange( st_tLine, 0 );
  double tmp;
  
  siblings[TL_SIB_ABOVE] = 99999999.9;
  siblings[TL_SIB_BELOW] = 99999999.9;
  
  for( ; i < len; i++ ){
    tmp = getTLineValueByShift( st_tLine[i][TL_NAME] );
    if( tmp > tLine_price ){
      tmp = tmp - tLine_price;
      if( tmp < siblings[TL_SIB_ABOVE] ){
        siblings[TL_SIB_ABOVE] = tmp;
      }
    }else if( tmp < tLine_price ){
      tmp = tLine_price - tmp;
      if( tmp < siblings[TL_SIB_BELOW] ){
        siblings[TL_SIB_BELOW] = tmp;
      }
    }
  }
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

void setHistoryArray( int &arr[], int &pos_nr ){
  double today = iTime(NULL, PERIOD_D1, 0);

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
          if( OrderOpenTime() > today ){
            pos_nr++;
          }
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
          if( OrderOpenTime() > today ){
            pos_nr++;
          }
        }
      }
    }
  }
  ArrayResize( arr, nr );
}


void loadTrendlines( string &st_tLine[][] ){
  static double st_last_mod = 1.0;

  if( st_last_mod != getGlobal( "SYNC_TL" ) ){
    st_last_mod = getGlobal( "SYNC_TL" );

    ObjectsDeleteAll();
    int j = 0, handle = FileOpen( StringConcatenate( getSymbol(), "_tLines.csv" ), FILE_READ, ";" );
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
              log( StringConcatenate( Symbol()," Line P1 val not match to ZZ: ", p1, " name:", name ), 19.0, StrToDouble(StringSubstr( name, 16, 10 )) );
              break;
            }

            if( !(NormalizeDouble(iCustom( Symbol(), PERIOD_H4, "ZigZag", 12, 5, 3, 0, iBarShift( NULL, PERIOD_H4, t2 ) ), Digits) == p2 || NormalizeDouble(iCustom( Symbol(), PERIOD_D1, "ZigZag", 12, 5, 3, 0, iBarShift( NULL, PERIOD_D1, t2 ) ), Digits) == p2) ){
              log( StringConcatenate( Symbol()," Line P2 val not match to ZZ: ", p2, " name:", name ), 20.0, StrToDouble(StringSubstr( name, 16, 10 )) );
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
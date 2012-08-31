//+------------------------------------------------------------------+
//|                                             DT_channel_trade.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_icons.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
#include <WinUser32.mqh>

#define TRADE_LOT 0.1

#define TL_NAME 0
#define TL_TYPE 1
#define TL_PERI 2
#define TL_STATE 3
#define TL_ID 4

#define CT_FIBO_23 0.232 // 0.236
#define CT_FIBO_38 0.377 // 0.382
#define CT_FIBO_61 0.613 // 0.618

#define CT_SPEED_LIMIT 330.0

#define CT_KEEP_POS_ALIVE 7200 // 1,5 hour
#define CT_TIME_BWEEN_TRADES 86400 // 24 hour

string CT_TLINES[][5];

bool CONNECTION_FAIL = true;
string INP_FILE_NAME;
string GV_LAST_MOD;
int CT_START_TIME;

double CT_SPREAD = 0.0;
double CT_THRESHOLD = 0.0;
int CT_SYM_ID;
double CT_OFFSET = 0.0;
double CT_MIN_DIST = 0.0;

double CT_MAX_H4_LOSE = 0.0;

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
  
// ###############################################################  set defaultes  ################################################################
  CT_SPREAD = NormalizeDouble( getMySpread() * 1.1, Digits );
  CT_THRESHOLD = NormalizeDouble( CT_SPREAD * 0.5, Digits );
  INP_FILE_NAME = StringConcatenate( StringSubstr(Symbol(), 0, 6), "_cLines.csv" );
  GV_LAST_MOD = StringConcatenate( StringSubstr(Symbol(), 0, 6), "_cLines_lastMod" );
  CT_OFFSET = 65 / MarketInfo(Symbol(),MODE_TICKVALUE) * Point;
  CT_MAX_H4_LOSE = 260 / MarketInfo(Symbol(),MODE_TICKVALUE) * Point;
  CT_MIN_DIST = 270 / MarketInfo(Symbol(),MODE_TICKVALUE) * Point;
  CT_SYM_ID = getSymbolID();
  CT_START_TIME = GetTickCount() + 180000; // 3 min
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
  
  
// #####################################################  check Opened position modification  ######################################################  
  int i = 0, len = OrdersTotal(), magic, o_type, ticket;
  string symb = Symbol(), comment, line_type, line_period, tLine_name;
  double new_op, tp, sl, fibo_100;
  
  for( ; i < len; i++ ) {
    if( OrderSelect( i, SELECT_BY_POS ) ) {
      if( OrderSymbol() == symb ) {
        magic = OrderMagicNumber();
        if( magic > 1000 ){
          o_type = OrderType();
// #####################################################  modify OP_BUY - OP_SELL Positions  ######################################################  
          if( o_type < 2 ){
            int shift = iBarShift( NULL, PERIOD_M1, OrderOpenTime() );
            
            if( o_type == OP_BUY ){
              new_op = NormalizeDouble( iLow( NULL, PERIOD_M1, iLowest( NULL, PERIOD_M1, MODE_LOW, shift) , Digits );
              if( NormalizeDouble( OrderOpenPrice(), Digits ) < getOpenPrice( o_type, new_op ) ){
                continue;
              }
            }else{
              new_op = NormalizeDouble( iHigh( NULL, PERIOD_M1, iHighest( NULL, PERIOD_M1, MODE_HIGH, shift) , Digits );
              if( NormalizeDouble( OrderOpenPrice(), Digits ) > getOpenPrice( o_type, new_op ) ){
                continue;
              }
            }
            
            comment = OrderComment();
            line_type = StringSubstr( comment, 0, 2 );
            line_period = StringSubstr( comment, 3, 2 );
            fibo_100 = NormalizeDouble( StrToDouble( StringSubstr( comment, 6, 7 ) ), Digits );
            
            tLine_name = getTradeLineNameFromId( magic );
            if( tLine_name == "" || ObjectFind( tLine_name ) == -1 ){
              OrderDelete( ticket );
              errorCheck( StringConcatenate( Symbol()," Position is closed due to missing trade line: ",tLine_name,"! ticket id :", ticket ) );
              log( StringConcatenate( Symbol()," Position is closed due to missing trade line: ",tLine_name,"! ticket id :", ticket ), 2.0, magic );
              setChannelLinesArr( INP_FILE_NAME );
              continue;
            }
            
            if( !setPositionPrices( o_type, line_type, tp, sl, new_op, line_period, fibo_100, ObjectGet( tLine_name, OBJPROP_PRICE1 ) < ObjectGet( tLine_name, OBJPROP_PRICE2 ) ) ){
              OrderDelete( ticket );
              errorCheck( StringConcatenate( Symbol()," Position is closed due to modify position prices failed: ",tLine_name,"! ticket id :", ticket ) );
              log( StringConcatenate( Symbol()," Position is closed due to modify position prices failed: ",tLine_name,"! ticket id :", ticket ), 3.0, magic );
              continue;
            }
            
            if( GetTickCount() < CT_START_TIME ){
              CT_START_TIME = GetTickCount();
              if(IDNO == MessageBox(StringConcatenate( Symbol(), " Terminal just started, do you want MODIFY position(", ticket,")" ), "Channel trading", MB_YESNO|MB_ICONQUESTION )){
                return(0);
              }
            }
            
            OrderModify( ticket, new_op, NormalizeDouble( OrderStopLoss(), Digits ), tp, TimeCurrent()+5400, Red );
            
/* !! */  Print(StringConcatenate("OP Mod: ", Symbol(), " oType:", o_type, " Ticket:", ticket,  " NEW TP:", tp, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Mag:", OrderMagicNumber()));
/* !! */  log(StringConcatenate("OP Mod: ", Symbol(), " oType:", o_type, " Ticket:", ticket,  " NEW TP:", tp, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Mag:", OrderMagicNumber()), MathRand(), magic );     

            errorCheck(StringConcatenate(Symbol(), " Modify OP_BUY/OP_SELL Positions Bid:", Bid, " Ask:", Ask, " op:"+ new_op, " tp:", tp));

            
// #####################################################  modify OP_BUYLIMIT / OP_SELLLIMIT Positions  ######################################################         
          }else{
            if( OrderOpenTime() + CT_KEEP_POS_ALIVE < TimeCurrent() || !trade_allowed ){
              OrderDelete( ticket );
              errorCheck( StringConcatenate( Symbol(), " Position closed due to timer expired or trade not allowed, ticket id:", ticket ) );
              log( StringConcatenate( Symbol(), " Position closed due to timer expired or trade not allowed, ticket id:", ticket ), 4.0, magic );
              return (0);
            }
          
            tLine_name = getTradeLineNameFromId( magic );
            if( tLine_name == "" || ObjectFind( tLine_name ) == -1 ){
              OrderDelete( ticket );
              errorCheck( StringConcatenate( Symbol()," Position is closed due to missing trade line: ",tLine_name,"! ticket id :", ticket ) );
              log( StringConcatenate( Symbol()," Position is closed due to missing trade line: ",tLine_name,"! ticket id :", ticket ), 5.0, magic );
              setChannelLinesArr( INP_FILE_NAME );
              continue;
            }
            
            new_op = getOpenPrice( o_type, getClineValueByShift( CT_TLINES[i][TL_NAME] ) );
            if( new_op != NormalizeDouble( OrderOpenPrice(), Digits ) ){
              comment = OrderComment();
              line_type = StringSubstr( comment, 0, 2 );
              line_period = StringSubstr( comment, 3, 2 );
              fibo_100 = NormalizeDouble( StrToDouble( StringSubstr( comment, 6, 7 ) ), Digits );
            
              if( !setPositionPrices( o_type, line_type, tp, sl, new_op, line_period, fibo_100, ObjectGet( tLine_name, OBJPROP_PRICE1 ) < ObjectGet( tLine_name, OBJPROP_PRICE2 ) ) ){
                OrderDelete( ticket );
                errorCheck( StringConcatenate( Symbol()," Position is closed due to modify position prices failed: ",tLine_name,"! ticket id :", ticket ) );
                log( StringConcatenate( Symbol()," Position is closed due to modify position prices failed: ",tLine_name,"! ticket id :", ticket ), 6.0, magic );
                continue;
              }
              
              if( GetTickCount() < CT_START_TIME ){
                CT_START_TIME = GetTickCount();
                if(IDNO == MessageBox(StringConcatenate( Symbol(), " Terminal just started, do you want MODIFY position (", ticket,")" ), "Channel trading", MB_YESNO|MB_ICONQUESTION )){
                  return(0);
                }
              }
            
              OrderModify( ticket, new_op, sl, tp, TimeCurrent()+5400, Blue );
              
/* !! */  Print(StringConcatenate("Mod: ", Symbol(), " oType:", o_type, " Ticket:", ticket,  " OP:", new_op, " SL:", sl, " TP:", tp, " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Mag:", OrderMagicNumber()));
/* !! */  log(StringConcatenate("Mod: ", Symbol(), " oType:", o_type, " Ticket:", ticket,  " OP:", new_op, " SL:", sl, " TP:", tp, " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Mag:", OrderMagicNumber()), MathRand(), magic );

              errorCheck(StringConcatenate(Symbol(), " Modify OP_BUYLIMIT/OP_SELLLIMIT Positions Bid:", Bid, " Ask:", Ask, " op:"+ new_op, " tp:", tp));
            
            }
          }
        }
      }
    }
  }
  
// ###########################################################  Find NEW LMIT Positons  ############################################################         
  len = ArrayRange( CT_TLINES, 0 );
  double tLine_price, fibo_100_time, speed, op, fibo_time_cross_line, dif, peek;
  string speed_log = "";
  for( i = 0; i < len; i++ ){
    // error missing cLine
    if( ObjectFind( CT_TLINES[i][TL_NAME] ) == -1 ){
      log( StringConcatenate( Symbol()," Error cLine is missing: ",CT_TLINES[i][TL_NAME] ), 7.0, StrToDouble(CT_TLINES[i][TL_ID]) );
      setChannelLinesArr( INP_FILE_NAME );
      continue;
    }
    
    // current cLine price
    tLine_price = getClineValueByShift( CT_TLINES[i][TL_NAME] );
    
    // Current time not cross cLine (cLine is too short or below Time[0])
    if( tLine_price == 0.0){
      log( StringConcatenate( Symbol()," Error cLine is not enought long: ",CT_TLINES[i][TL_NAME] ), 8.0, StrToDouble(CT_TLINES[i][TL_ID]) );
      setChannelLinesArr( INP_FILE_NAME );
      continue;
    }
    
    // cLine not in trade zone
    if( Bid > tLine_price + CT_OFFSET || Bid < tLine_price - CT_OFFSET ){
      continue;
    }
    
    // get Fibo 100, Fibo 100 time
    if( CT_TLINES[i][TL_TYPE] == "CL" ){
      getFibo100( PERIOD_H1, tLine_price ,fibo_100, fibo_100_time );
    }else{
      getFibo100( PERIOD_M15, tLine_price ,fibo_100, fibo_100_time );
    }
    
    // price go against Resistance or Suppress clLine
    if( fibo_100 > tLine_price ){
      if( CT_TLINES[i][TL_STATE] == "res" ){  // Resistance
        log( StringConcatenate( Symbol()," Resistance line: ",CT_TLINES[i][TL_NAME]," Curr fibo 100:",fibo_100 ), 9.0, StrToDouble(CT_TLINES[i][TL_ID]) );
        continue;
      }
    }else{
      if( CT_TLINES[i][TL_STATE] == "sup" ){  // Suppress
        log( StringConcatenate( Symbol()," Suppress line: ",CT_TLINES[i][TL_NAME]," Curr fibo 100:",fibo_100 ), 10.0, StrToDouble(CT_TLINES[i][TL_ID]) );
        continue;
      }
    }
    
    // to this cLine there was closed position lately
    if( tLineLatelyUsed( StrToDouble(CT_TLINES[i][TL_ID]) ) ){
      log( StringConcatenate( Symbol()," During ",TimeToStr( CT_TIME_BWEEN_TRADES, TIME_MINUTES)," hours at ", CT_TLINES[i][TL_NAME]," line we have Opened Position!" ), 11.0, StrToDouble(CT_TLINES[i][TL_ID]) );
      return (0);
    }
    
    // where fibo100 time cross the cLine
    fibo_time_cross_line = getClineValueByShift( CT_TLINES[i][TL_NAME], iBarShift( NULL, 0, fibo_100_time ) );

    // Fibo 100 time not cross the cLine
    if( fibo_time_cross_line == 0.0 ){
      log( StringConcatenate( Symbol()," Error fibo100 time:", fibo_100_time," not cross current cLine:", CT_TLINES[i][TL_NAME] ), 12.0, StrToDouble(CT_TLINES[i][TL_ID]) );
      continue;
    }

    // Fibo 100 <=> cLine difference
    dif = MathAbs( fibo_100 - fibo_time_cross_line );
    
    // distance is too small between Fibo 100 and cLine
    if( dif < CT_MIN_DIST ){  // Min Distance
      log( StringConcatenate( Symbol()," Fibo DISTANCE is too SMALL! Cline: ", CT_TLINES[i][TL_NAME]," Min Distance: ",CT_MIN_DIST," Curr distance:", dif ), 13.0, StrToDouble(CT_TLINES[i][TL_ID]) );
      continue;
    }
  
    // fake Fibo 100 price is already below cLine
    if( alreadyBelowCLine( tLine_price ,fibo_100, fibo_100_time ) ){
      log( StringConcatenate( Symbol()," Price is already below trade_line: ", CT_TLINES[i][TL_NAME]," Curr fibo 100:",fibo_100 ), 14.0, StrToDouble(CT_TLINES[i][TL_ID]) );
      continue;
    }
    
    if( CT_TLINES[i][TL_TYPE] != "CL" ){
      // Speed of price movment
      speed = priceSpeed( CT_TLINES[i][TL_NAME], speed_log );
      if( speed > CT_SPEED_LIMIT ){
        log( StringConcatenate( Symbol(), " Bar SPEED is too fast in Boundary cLine!", speed_log ), speed, StrToDouble(CT_TLINES[i][TL_ID]) );
        continue;
      }
    }
    
    if( GetTickCount() < CT_START_TIME ){
      CT_START_TIME = GetTickCount();
      if(IDNO == MessageBox(StringConcatenate( Symbol(), " Terminal just started, do you want OPEN position (", ticket,") "), "Channel trading", MB_YESNO|MB_ICONQUESTION )){
        return(0);
      }
    }
    
    RefreshRates();
    if( fibo_100 > tLine_price ){ // BUY LIMIT
      peek = iLow( NULL, PERIOD_M30, 0);
      if( peek > tLine_price ){
        o_type = OP_BUYLIMIT;
      }else{
        log( StringConcatenate( Symbol(), " Warning you are late from BUY LIMIT trade line price:", tLine_price," bar low: ", peek ), 15.0, StrToDouble(CT_TLINES[i][TL_ID]) );
        return (0);
      }

    }else{  // SELL LIMIT
      peek = iHigh( NULL, PERIOD_M30, 0);
      if( peek < tLine_price ){
        o_type = OP_SELLLIMIT;
      }else{
        log( StringConcatenate( Symbol(), " Warning you are late from SELL LIMIT trade line price:", tLine_price," bar high: ", peek ), 16.0, StrToDouble(CT_TLINES[i][TL_ID]) );
        return (0);
      }
    }
    
    op = getOpenPrice( o_type, tLine_price );
    
    if( !setPositionPrices( o_type, CT_TLINES[i][TL_TYPE], tp, sl, tLine_price, CT_TLINES[i][TL_PERI], fibo_100, ObjectGet( CT_TLINES[i][TL_NAME], OBJPROP_PRICE1 ) < ObjectGet( CT_TLINES[i][TL_NAME], OBJPROP_PRICE2 ) ) ){
      errorCheck( StringConcatenate( Symbol()," Set new Limit position failed: ",  CT_TLINES[i][TL_NAME] ) );
      log( StringConcatenate( Symbol()," Set new Limit position failed: ", CT_TLINES[i][TL_NAME] ), 17.0, StrToDouble(CT_TLINES[i][TL_ID]) );
      continue;
    }
    
    comment = StringConcatenate( CT_TLINES[i][TL_TYPE], " ", CT_TLINES[i][TL_PERI], " ", DoubleToStr( fibo_100, 5 ) );
    
    OrderSend( Symbol(), o_type, TRADE_LOT, op, 5, sl, tp, comment, CT_TLINES[i][TL_ID], TimeCurrent()+5400, Orange );
    
/* !! */  Print(StringConcatenate("Ty:", o_type, " Lot:", TRADE_LOT, " OP:", op, " SL:", sl, " TP:", tp, " Comm:", comment, " Mag:", CT_TLINES[i][TL_ID], " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Stat:", tLine_price," Dist:", dif," H:", iHigh( NULL, PERIOD_M15, 0)," L:", iLow( NULL, PERIOD_M15, 0)," Sp:",DoubleToStr(speed,2), " (", Symbol(), ")"));
/* !! */  log(StringConcatenate("Ty:", o_type, " Lot:", TRADE_LOT, " OP:", op, " SL:", sl, " TP:", tp, " Comm:", comment, " Mag:", CT_TLINES[i][TL_ID], " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Stat:", tLine_price," Dist:", dif," H:", iHigh( NULL, PERIOD_M15, 0)," L:", iLow( NULL, PERIOD_M15, 0)," Sp:",DoubleToStr(speed,2), " (", Symbol(), ")"), 18.0, StrToDouble(CT_TLINES[i][TL_ID]) );
    
    errorCheck("NEW LIMIT pos Bid:"+ Bid+ " Ask:"+ Ask);
  }
}

bool tLineLatelyUsed( int magic ){
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
          if( OrderOpenTime() + CT_TIME_BWEEN_TRADES > Time[0] ){
            return (true);
          }
        }
      }
    }
  }
  return (false);
}

bool setPositionPrices( int o_type, string line_type, double& tp, double& sl, double op, string line_period = "", double fibo_100 = 0.0, bool dir = true ){
  if( line_type == "CL" ){
    if( o_type % 2 == 0 ){ // BUY
      if( dir ){
        tp = NormalizeDouble( op + (MathAbs( fibo_100 - op ) * CT_FIBO_61), Digits );
      }else{
        tp = NormalizeDouble( op + (MathAbs( fibo_100 - op ) * CT_FIBO_38), Digits );
      }
      if( MathAbs( op - sl ) > CT_MAX_H4_LOSE ){
        sl = NormalizeDouble( op - CT_MAX_H4_LOSE, Digits );
      }else{
        sl = NormalizeDouble( op - (MathAbs( fibo_100 - op ) * CT_FIBO_23), Digits );
      }
    }else{ // SELL
      if( dir ){
        tp = NormalizeDouble( op - (MathAbs( fibo_100 - op ) * CT_FIBO_38) + CT_SPREAD, Digits );
      }else{
        tp = NormalizeDouble( op - (MathAbs( fibo_100 - op ) * CT_FIBO_61) + CT_SPREAD, Digits );
      }
      if( MathAbs( op - sl ) > CT_MAX_H4_LOSE ){
        sl = NormalizeDouble( op + CT_MAX_H4_LOSE, Digits );
      }else{
        sl = NormalizeDouble( op + (MathAbs( fibo_100 - op ) * CT_FIBO_23) + CT_SPREAD, Digits );
      }
    }
  }else if( line_type == "ZZ" ){
    if( line_period == "H4" ){
      if( o_type % 2 == 0 ){
        sl = NormalizeDouble( op - H4_SL[CT_SYM_ID], Digits );
        tp = NormalizeDouble( op + H4_TP[CT_SYM_ID], Digits );
      }else{
        sl = NormalizeDouble( op + H4_SL[CT_SYM_ID] + CT_SPREAD, Digits );
        tp = NormalizeDouble( op - H4_TP[CT_SYM_ID] + CT_SPREAD, Digits );
      }                          
    }else if( line_period == "D1" ){
      if( o_type % 2 == 0 ){
        sl = NormalizeDouble( op - D1_SL[CT_SYM_ID], Digits );
        tp = NormalizeDouble( op + D1_TP[CT_SYM_ID], Digits );
      }else{                     
        sl = NormalizeDouble( op + D1_SL[CT_SYM_ID] + CT_SPREAD, Digits );
        tp = NormalizeDouble( op - D1_TP[CT_SYM_ID] + CT_SPREAD, Digits );
      }  
    }else{
      return (false);
    }
  }else{
    return (false);
  }
  return (true);
}

string getTradeLineNameFromId( string id ){
  int i, len = ArrayRange( CT_TLINES, 0 );
  for( i = 0; i < len; i++ ){
    if( CT_TLINES[i][TL_ID] == id ){
      return (CT_TLINES[i][TL_NAME]);
    }
  }
  return ("");
}

int getSymbolID(){
  int len = ArraySize(SYMBOLS_STR);
  for(int i=0; i < len; i++) {
    if(SYMBOLS_STR[i] == Symbol()){
      return (i);
    }
  }
  return (-1);
}

double getOpenPrice( int o_type, double price ){
  if( o_type % 2 == 0 ){
    return (NormalizeDouble( price + CT_SPREAD + CT_THRESHOLD, Digits ));
  }else{
    return (NormalizeDouble( price - CT_THRESHOLD, Digits ));
  }
}

void setChannelLinesArr( string &file_name ){
  static double last_mod = 1.0;
  if( last_mod != GlobalVariableGet( GV_LAST_MOD ) ){
    last_mod = GlobalVariableGet( GV_LAST_MOD );

    readCLinesFromFile( file_name );
    
    int len = ObjectsTotal(), j = 0;
    string name;
    for( int i = 0; i < len; i++ ){
      name = ObjectName(i);
      if( StringSubstr( name, 5, 7 ) == "_tLine_" ){
        ArrayResize( CT_TLINES, j + 1 );
        CT_TLINES[j][TL_NAME] = name;
        CT_TLINES[j][TL_TYPE] = StringSubstr( name, 12, 2 );
        CT_TLINES[j][TL_PERI] = StringSubstr( name, 15, 2 );
        CT_TLINES[j][TL_STATE] = StringSubstr( name, 18, 3 );
        CT_TLINES[j][TL_ID] = StringSubstr( name, 22, 10 );
        j++;
      }
    }
    if( j == 0 ){
      ArrayResize( CT_TLINES, 0 );
    }
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

void log( string text, double val = 0.0, double id = 0.0 ){
  static double last_log_val[1][2];
  bool uknown = true;
  int len = ArrayRange( last_log_val, 0 );
  
  if( id == 0.0 ){
    if( last_log_val[0][1] == val ){
      return;
    }
  }else{
    for( int i = 1; i < len; i++ ){
      if( last_log_val[i][1] == id ){
        if( last_log_val[i][2] == val ){
          return;
        }else{
          uknown = false;
          break;
        }
      }
    }
    if( uknown ){
      ArrayResize( last_log_val, len + 1 );
      last_log_val[len][1] = id;
      last_log_val[len][2] = val;
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
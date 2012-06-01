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

#define CL_NAME 0
#define CL_STATE 1
#define CL_GROUP 2

#define CL_MID_GROUP_DIST 0.5
#define CHANNEL_LOT 0.1
#define CT_SL_FACTOR 1.3
#define CT_MIN_TIME 9901
#define CT_POS_DIF_TIME 21600 // 6 hour

string CT_CLINES[][3];

int CT_TIMER1 = 0;
int CT_TIMER2 = 0;
int CT_START_TIME;

double CT_OFFSET = 0.0;
double CT_MIN_DIST = 0.0;
double CT_MAX_DIST = 0.0;

bool CT_STOP_TRADE = false;

double LAST_LOG_ID = 0.0;

double CT_SPREAD = 0.0;
double CT_THRESHOLD = 0.0;

int init(){
  CT_OFFSET = 65/MarketInfo(Symbol(),MODE_TICKVALUE)*Point;
  CT_MIN_DIST = 270/MarketInfo(Symbol(),MODE_TICKVALUE)*Point;
  CT_MAX_DIST = 1100/MarketInfo(Symbol(),MODE_TICKVALUE)*Point;
  CT_START_TIME = GetTickCount() + 180000; // 3 min
  CT_SPREAD = NormalizeDouble( getMySpread() * 1.3, Digits );
  CT_THRESHOLD = NormalizeDouble( CT_SPREAD * 0.6, Digits );
  
  CT_TIMER1 = GetTickCount() + 6000;
  setChannelLinesArr();
  // checkGroupClines();
  return(0);
}

int start(){
  if( GetTickCount() > CT_TIMER1 ){
    CT_TIMER1 = GetTickCount() + 6000;
    setChannelLinesArr();

    if( ObjectFind("DT_GO_channel_trade_time_limit") == -1 ){
      CT_STOP_TRADE = false;
    }else{
      if( ObjectGet( "DT_GO_channel_trade_time_limit", OBJPROP_TIME1 ) < iTime( NULL, PERIOD_M1, 0) ){
        CT_STOP_TRADE = true;
      }else{
        CT_STOP_TRADE = false;
      }
    }
  }

  if( Period() < PERIOD_D1 /*&& ( IsTesting() || GetTickCount() > CT_TIMER2 )*/ ){
    //CT_TIMER2 = GetTickCount() + 1000;

    int ticket, o_type;
    string comment, trade_line_group, trade_line_type, trade_line_name = "";
    double fibo_100 = 0.0, fibo_23_dif, trade_line_price, op;

    ticket = getClineOpenPosition();
    if( ticket != 0 ){
      o_type = OrderType();

      if( o_type < 2 ){
        return (0);
      }else{
        double open_time = OrderOpenTime();
        if( open_time + 5400 < TimeCurrent() ){
          OrderDelete( ticket );
          errorCheck( StringConcatenate( Symbol(), " Position closed due to timer expired, ticket id:", ticket ) );
          Alert( StringConcatenate( Symbol(), " Position closed due to timer expired, ticket id:", ticket ) );
          return (0);
        }

        if( CT_STOP_TRADE ){
          return (0);
        }

        comment = OrderComment();
        string trade_line_ts_str;
        // trade_line_group = StringSubstr(comment, 0, 2);
        // trade_line_ts_str = StringSubstr(comment, 3, 10);
        // trade_line_name = StringConcatenate( "DT_GO_cLine_", trade_line_group, "_sig_", trade_line_ts_str );

        trade_line_group = StringSubstr(comment, 0, 6);
        trade_line_ts_str = StringSubstr(comment, 7, 10);
        trade_line_name = StringConcatenate( "DT_GO_cLine_", trade_line_group, "_", trade_line_ts_str );

        if( ObjectFind(trade_line_name) == -1 ){
          OrderDelete( ticket );
          errorCheck( StringConcatenate( Symbol()," Limit position is closed due to missing channel line: ",trade_line_name,"! ticket id :", ticket ) );
          Alert( StringConcatenate( Symbol()," Limit position is closed due to missing channel line: ",trade_line_name,"! ticket id :", ticket ) );
          return (0);
        }

        trade_line_price = getClineValueByShift( trade_line_name );

        op = NormalizeDouble( OrderOpenPrice(), Digits );
        double new_op;

        if( o_type == OP_BUYLIMIT ){
          new_op = NormalizeDouble( trade_line_price + CT_SPREAD + CT_THRESHOLD, Digits );
        }else{
          new_op = NormalizeDouble( trade_line_price - CT_THRESHOLD, Digits );
        }

        if( new_op == op ){
          return (0);
        }else{
          double new_sl, new_tp;
          fibo_100 = StrToDouble(StringSubstr(comment, 18, StringLen(comment)-18));
          // fibo_100 = StrToDouble(StringSubstr(comment, 14, StringLen(comment)-14));
          fibo_23_dif = MathAbs( fibo_100 - trade_line_price ) * 0.23; // 0.236
          if( fibo_23_dif <= 0.0 ){
            log( StringConcatenate( Symbol()," Something wrong with limit position fibo 23 number: ",fibo_23_dif,"! ticket id :", ticket ), fibo_100 + 1.1 );
            return (0);
          }

          if( o_type == OP_BUYLIMIT ){
            new_sl = NormalizeDouble( trade_line_price - (fibo_23_dif * CT_SL_FACTOR), Digits );
            new_tp = NormalizeDouble( trade_line_price + fibo_23_dif, Digits );

          }else{
            new_sl = NormalizeDouble( trade_line_price + (fibo_23_dif * CT_SL_FACTOR) + CT_SPREAD, Digits );
            new_tp = NormalizeDouble( trade_line_price - fibo_23_dif + CT_SPREAD, Digits );
          }

          if( GetTickCount() < CT_START_TIME ){
            if(IDNO == MessageBox(StringConcatenate("Terminal just started, do you want MODIFY position(", ticket,") in ", Symbol()), "Channel trading", MB_YESNO|MB_ICONQUESTION )){
              return(0);
            }
          }

          OrderModify( ticket, new_op, new_sl, new_tp, TimeCurrent()+5400 );

/* !! */  Print(StringConcatenate("Mod: ", Symbol(), " oType:", o_type, " Ticket:", ticket,  " OP:", new_op, " SL:", new_sl, " TP:", new_tp, " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Group:", trade_line_group, " Mag:", OrderMagicNumber()));
/* !! */  Alert(StringConcatenate("Mod: ", Symbol(), " oType:", o_type, " Ticket:", ticket,  " OP:", new_op, " SL:", new_sl, " TP:", new_tp, " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Group:", trade_line_group, " Mag:", OrderMagicNumber()));

/* !! */  ObjectSet( "DT_GO_channel_hist_op_"+trade_line_ts_str, OBJPROP_PRICE1, new_op );
/* !! */  ObjectSet( "DT_GO_channel_hist_sl_"+trade_line_ts_str, OBJPROP_PRICE1, new_sl );
/* !! */  ObjectSet( "DT_GO_channel_hist_tp_"+trade_line_ts_str, OBJPROP_PRICE1, new_tp );

          if( !errorCheck("Channel trade OrderModify Bid:"+ Bid+ " Ask:"+ Ask)){
            return(0);
          }
        }
      }
      errorCheck("Channel trade modify position part");
    }else{
      if( CT_STOP_TRADE ){
        return (0);
      }

      double fibo_100_time, dif, sibl_price[2], tmp, cur_min_dist, cur_dist, fibo_time_cross_p;
      int i, len = ArrayRange( CT_CLINES, 0 ), trade_line_ts = 0;
      string line_state, siblings[2];

      for( i = 0; i < len; i++ ){
        if( CT_CLINES[i][CL_STATE] != "sig" ){
          if( ObjectFind( CT_CLINES[i][CL_NAME] ) == -1 ){
            setChannelLinesArr();
            return (0);
          }
          trade_line_price = getClineValueByShift( CT_CLINES[i][CL_NAME] );

          if( trade_line_price != 0.0){
            if( Bid < trade_line_price + CT_OFFSET && Bid > trade_line_price - CT_OFFSET ){  // in zone
              getFibo100( trade_line_price ,fibo_100, fibo_100_time );
              trade_line_ts = getCLineProperty( CT_CLINES[i][CL_NAME], "ts" );

              if( fibo_100 > trade_line_price ){
                if( CT_CLINES[i][CL_STATE] == "res" ){  // Resistance
                  log( StringConcatenate( Symbol()," Resistance line: ",CT_CLINES[i][CL_NAME]," Curr fibo 100:",fibo_100 ), trade_line_ts + 0.1 );
                  return (0);
                }

              }else{
                if( CT_CLINES[i][CL_STATE] == "sup" ){  // Suppress
                  log( StringConcatenate( Symbol()," Suppress line: ",CT_CLINES[i][CL_NAME]," Curr fibo 100:",fibo_100 ), trade_line_ts + 0.2 );
                  return (0);
                }
              }

              fibo_time_cross_p = getClineValueByShift( CT_CLINES[i][CL_NAME], iBarShift( NULL, 0, fibo_100_time ) ); //  where fibo100 time cross the cLine
              if( fibo_time_cross_p == 0.0 ){
                log( StringConcatenate( "Error fibo100 time:", fibo_100_time," not cross current cLine:", CT_CLINES[i][CL_NAME]), trade_line_ts + 0.3 );
                return (0);
              }

              dif = MathAbs( fibo_100 - fibo_time_cross_p );
              if( dif < CT_MIN_DIST ){  // Min Distance
                log( StringConcatenate( Symbol()," Fibo DISTANCE is too SMALL! Cline: ", CT_CLINES[i][CL_NAME]," Min Distance: ",CT_MIN_DIST," Curr distance:", dif ), trade_line_ts + 0.4 );
                return (0);
              }

              if( hasClineHistoryPosition( trade_line_ts ) ){
                log( StringConcatenate( Symbol()," In ",TimeToStr( CT_POS_DIF_TIME, TIME_MINUTES)," hours at ", CT_CLINES[i][CL_NAME]," line we have Opened Position!" ), trade_line_ts + 0.5 );
                return (0);
              }

              if( CT_CLINES[i][CL_GROUP] != "g0" ){   //  Channel Line in group
                siblings[0] = "";
                siblings[1] = "";
                if( fibo_100 > trade_line_price ){
                  getSiblingLines( siblings, i, len, CT_CLINES[i][CL_GROUP], 2 );
                }else{
                  getSiblingLines( siblings, i, 0, CT_CLINES[i][CL_GROUP], 2 );
                }
                if( siblings[1] != "" ){
                  if( MathAbs( getClineValueByShift( siblings[1] ) - trade_line_price ) < MathAbs( fibo_time_cross_p - fibo_100 ) ){
                    fibo_100 = getCLineItercept( siblings[0], fibo_100_time, trade_line_price > fibo_100 );
                    if( fibo_100 == 0.0 ){
                      return (0);
                    }
                    trade_line_name = CT_CLINES[i][CL_NAME];
                    break; // Group X line found with new fibo 100!
                  }
                }

                if( siblings[0] == "" ){ // Go to other direction
                  if( fibo_100 > trade_line_price ){
                    getSiblingLines( siblings, i, 0, CT_CLINES[i][CL_GROUP], 1 );
                  }else{
                    getSiblingLines( siblings, i, len, CT_CLINES[i][CL_GROUP], 1 );
                  }

                  if( siblings[0] == "" ){
                    log( StringConcatenate( Symbol()," Error ",CT_CLINES[i][CL_GROUP]," group only have one line: ",CT_CLINES[i][CL_NAME] ), fibo_100 + 0.6 );
                    return (0);
                  }
                }

                cur_min_dist = MathAbs( getClineValueByShift( siblings[0] ) - trade_line_price) * CL_MID_GROUP_DIST;
                if( cur_min_dist < dif ){  // middle group price reached check
                  trade_line_name = CT_CLINES[i][CL_NAME];
                  break; // Group X line found above CL_MID_GROUP_DIST!

                }else{
                  tmp = MathAbs( getClineValueByShift( siblings[0] ) - trade_line_price) * CL_MID_GROUP_DIST;
                  log( StringConcatenate( Symbol()," Fibo GROUP DISTANCE is too SMALL! Cline: ", CT_CLINES[i][CL_NAME]," Min Distance: ",tmp," Curr distance:", dif ), fibo_100 + 0.7 );
                  return (0);
                }

              }else{      // Channel NOT Line in group
                if( dif > CT_MAX_DIST ){  // Max Distance
                  log( StringConcatenate( Symbol()," Fibo DISTANCE is too HIGH! Cline: ", CT_CLINES[i][CL_NAME]," Max Distance: ",CT_MAX_DIST," Curr distance:", dif ), fibo_100 + 0.8 );
                  return (0);
                }

                if( Time[0] - fibo_100_time < (dif / CT_MAX_DIST) * CT_MIN_TIME ){  // Min Time Distance
                  log( StringConcatenate( Symbol()," Fibo is too QUICK! Cline: ", CT_CLINES[i][CL_NAME]," Min Time: ",(dif / CT_MAX_DIST) * CT_MIN_TIME," sec, Curr time:", dif ), fibo_100 + 0.9 );
                  return (0);
                }
                cur_min_dist = CT_MIN_DIST;
                trade_line_name = CT_CLINES[i][CL_NAME];
                break; // Group 0 line found!
              }
              Alert( "Error does not handle Cline! name:"+CT_CLINES[i][CL_NAME]+" p:"+trade_line_price+" f100:"+fibo_100 );
              return (0);
            }
          }
        }
      }

      if( trade_line_name != "" ){
        if( GetTickCount() < CT_START_TIME ){
          if(IDNO == MessageBox(StringConcatenate("Terminal just started, do you want OPEN position in ", Symbol()), "Channel trading", MB_YESNO|MB_ICONQUESTION )){
            return(0);
          }
        }

        trade_line_group = CT_CLINES[i][CL_GROUP];
        line_state = CT_CLINES[i][CL_STATE];

        fibo_23_dif = MathAbs( fibo_100 - trade_line_price ) * 0.23; // 0.236

        double sl, tp;

        RefreshRates();
        if( fibo_100 > trade_line_price ){ // ================================================ BUY LIMIT ================================================
          double l = iLow( NULL, PERIOD_H1, 0);
          if( l > trade_line_price ){
            o_type = OP_BUYLIMIT;
            op = NormalizeDouble( trade_line_price + CT_SPREAD + CT_THRESHOLD, Digits );
          }else{
            log( StringConcatenate( Symbol()," Warning you are late from BUY LIMIT trade line price:",trade_line_price," bar low: ",l  ), fibo_100 + 0.7 );
            return (0);
          }
          sl = NormalizeDouble( trade_line_price - (fibo_23_dif * CT_SL_FACTOR), Digits );
          tp = NormalizeDouble( trade_line_price + fibo_23_dif, Digits );

        }else{  // ================================================ SELL LIMIT ================================================
          double h = iHigh( NULL, PERIOD_H1, 0);
          if( h < trade_line_price ){
            o_type = OP_SELLLIMIT;
            op = NormalizeDouble( trade_line_price - CT_THRESHOLD, Digits );
          }else{
            log( StringConcatenate( Symbol()," Warning you are late from SELL LIMIT trade line price:",trade_line_price," bar high: ",h  ), fibo_100 + 0.8 );
            return (0);
          }
          sl = NormalizeDouble( trade_line_price + (fibo_23_dif * CT_SL_FACTOR) + CT_SPREAD, Digits );
          tp = NormalizeDouble( trade_line_price - fibo_23_dif + CT_SPREAD, Digits );
        }

        comment = StringConcatenate( trade_line_group,StringSubstr( trade_line_name, 14, 4 ), " ", trade_line_ts, " ", DoubleToStr( fibo_100, Digits ) );

        OrderSend( Symbol(), o_type, CHANNEL_LOT, op, 15, sl, tp, comment, trade_line_ts, TimeCurrent()+5400 );
        
        RefreshRates();

/* !! */  Print(StringConcatenate(Symbol(), " Ty:", o_type, " Lot:", CHANNEL_LOT, " OP:", op, " SL:", sl, " TP:", tp, " Comm:", comment, " Mag:", trade_line_ts, " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " lStat:", trade_line_name, " Gr:", trade_line_group," Min Dist:", cur_min_dist," Dist:", dif));
/* !! */  Alert(StringConcatenate(Symbol(), " Ty:", o_type, " Lot:", CHANNEL_LOT, " OP:", op, " SL:", sl, " TP:", tp, " Comm:", comment, " Mag:", trade_line_ts, " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " lStat:", trade_line_name, " Gr:", trade_line_group," Min Dist:", cur_min_dist," Dist:", dif));

/* !! */  createHistoryLine( op, Blue, "Order type: "+o_type+", OP", "op_"+trade_line_ts, Time[0] );
/* !! */  createHistoryLine( sl, Red, "Order type: "+o_type+", SL", "sl_"+trade_line_ts, Time[0] );
/* !! */  createHistoryLine( tp, Green, "Order type: "+o_type+", TP", "tp_"+trade_line_ts, Time[0] );
/* !! */  createHistoryLine( fibo_100, Black, "Order type: "+o_type+", f100", "f100_"+trade_line_ts, fibo_100_time );

        errorCheck(" Bid:"+ Bid+ " Ask:"+ Ask);
        // renameChannelLine( trade_line_name, "sig" );
        setChannelLinesArr();
      }
      errorCheck("Channel trade new position part");
    }
  }

  return(0);
}

int deinit(){
  return(0);
}

void setChannelLinesArr(){
  double price, tmp_arr[0][2];
  int i, j = 0, len = ObjectsTotal();
  string name;

  for( i = 0; i < len; i++ ){
    name = ObjectName(i);
    if( StringSubstr( name, 5, 7 ) == "_cLine_" ){
      price = getClineValueByShift( name );
      if( price != 0.0 ){
        ArrayResize( tmp_arr, j + 1 );
        tmp_arr[j][0] = price;
        tmp_arr[j][1] = i;
        j++;
      }else{
        GetLastError();
      }
    }
  }

  multiDSort( tmp_arr );

  ArrayResize( CT_CLINES, j );
  for( i = 0; i < j; i++ ){
    name = ObjectName( tmp_arr[i][1] );
    CT_CLINES[i][CL_NAME] = name;
    CT_CLINES[i][CL_STATE] = StringSubstr( name, 15, 3 );
    CT_CLINES[i][CL_GROUP] = StringSubstr( name, 12, 2 );
  }
  errorCheck( "setChannelLinesArr" );
}

void multiDSort( double &arr[][] ){
  int i, j, len = ArrayRange( arr, 0 );
  double newValue_0, newValue_1;

  for( i = 1; i < len; i++ ){
    newValue_0 = arr[i][0];
    newValue_1 = arr[i][1];
    j = i;
    while( j > 0 ){
      if( arr[j - 1][0] > newValue_0 ){
        arr[j][0] = arr[j - 1][0];
        arr[j][1] = arr[j - 1][1];
        j--;
      }else{
        break;
      }
    }
    arr[j][0] = newValue_0;
    arr[j][1] = newValue_1;
  }
}

int createHistoryLine(double p1, color c, string text, string ts, double t1 = 0.0 ){
  string name = "DT_GO_channel_hist_"+ts;
  if( ObjectFind(name) == -1 ){
    if( t1 == 0.0 ){
      t1 = Time[0];
    }
    ObjectCreate( name, OBJ_ARROW, 0, t1, p1 );
  }else{
    if( t1 == 0.0 ){
      t1 = ObjectGet( name, OBJPROP_TIME1 );
    }
    ObjectSet(name, OBJPROP_TIME1, Time[0]);
    ObjectSet(name, OBJPROP_PRICE1, p1);
  }
	ObjectSet(name, OBJPROP_ARROWCODE, 5);
	ObjectSet(name, OBJPROP_COLOR, c);
	ObjectSet(name, OBJPROP_BACK, false);
	ObjectSet(name, OBJPROP_WIDTH, 1);
	ObjectSetText(name, text, 8);
}

void getSiblingLines( string& siblings[], int from, int to, string group, int nr_result ){
  if( from == to ){
    return;
  }
  int i = 0;
  if( from < to ){
    from++;
    for( ; from < to && i < nr_result; from++ ){
      if( CT_CLINES[from][CL_GROUP] == group ){
        siblings[i] = CT_CLINES[from][CL_NAME];
        i++;
      }
    }
  }else{
    from--;
    for( ; from >= to && i < nr_result; from-- ){
      if( CT_CLINES[from][CL_GROUP] == group ){
        siblings[i] = CT_CLINES[from][CL_NAME];
        i++;
      }
    }
  }
}

double getCLineItercept( string line_name, double& fibo_100_time, bool is_sell ){
  int i, fibo_100_shift = iBarShift( NULL , 0, fibo_100_time );
  if( is_sell ){
    double h;
    for( i = fibo_100_shift; i >= 0; i-- ){
      h = iHigh( NULL, 0, i );
      if( h > getClineValueByShift( line_name, i ) ){
        fibo_100_time = iTime( NULL, 0, i );
        return (getClineValueByShift( line_name, i ));
      }
    }
  }else{
    double l;
    for( i = fibo_100_shift; i >= 0; i-- ){
      l = iLow( NULL, 0, i );
      if( l < getClineValueByShift( line_name, i ) ){
        fibo_100_time = iTime( NULL, 0, i );
        return (getClineValueByShift( line_name, i ));
      }
    }
  }
  log( StringConcatenate( Symbol()," Error in getCLineItercept not find itercept: ",line_name ), fibo_100_time+3 );
  return ( 0.0 );
}

void log( string text, double id ){
  if( LAST_LOG_ID == id ){
    return;
  }else{
    Alert( text );
    LAST_LOG_ID = id;
  }
}

int getClineOpenPosition(){
  int i = 0, len = OrdersTotal();
  string symb = Symbol();
  for( ; i < len; i++ ) {
    if( OrderSelect( i, SELECT_BY_POS ) ) {
      if( OrderSymbol() == symb ) {
        if( OrderMagicNumber() > 1000 ){
          return (OrderTicket());
        }
      }
    }
  }
  return (0);
}

bool hasClineHistoryPosition( int magic ){
  int i = 0, len = OrdersHistoryTotal();
  string symb = Symbol();
  for(; i < len; i++) {
    if( OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) {
      if( OrderSymbol() == symb ) {
        if( OrderMagicNumber() == magic ){
          if( OrderOpenTime() + CT_POS_DIF_TIME > Time[0] ){
            return (true);
          }
        }
      }
    }
  }
  return (false);
}

bool checkGroupClines(){
  int i, j, len = ArrayRange( CT_CLINES, 0 );
  double limit, in_time, dif1, dif2, curr, g1_t1 = 0.0, g1_t2 = 9999999999.0, g2_t1 = 0.0, g2_t2 = 9999999999.0;
  limit = 50/MarketInfo(Symbol(),MODE_TICKVALUE)*Point;
  in_time = 1209600; // 2 weeks

  ////////////////// line rays 2. pont ne legyen hosszabb a time[0] nál
  
  for( i = 0; i < len; i++ ){
    if( CT_CLINES[i][CL_GROUP] == "g1" ){
      curr = ObjectGet( CT_CLINES[i][CL_NAME], OBJPROP_TIME1 );
      if( curr > g1_t1 ){
        g1_t1 = curr;
      }
      curr = ObjectGet( CT_CLINES[i][CL_NAME], OBJPROP_TIME2 );
      if( curr < g1_t2 ){
        g1_t2 = curr;
      }

    }else if( CT_CLINES[i][CL_GROUP] == "g2" ){
      curr = ObjectGet( CT_CLINES[i][CL_NAME], OBJPROP_TIME1 );
      if( curr > g2_t1 ){
        g2_t1 = curr;
      }
      curr = ObjectGet( CT_CLINES[i][CL_NAME], OBJPROP_TIME2 );
      if( curr < g2_t2 ){
        g2_t2 = curr;
      }
    }
  }

  if( g1_t2 - g1_t1 > in_time){
    g1_t1 = g1_t2 - in_time;
  }

  if( g2_t2 - g2_t1 > in_time){
    g2_t1 = g2_t2 - in_time;
  }

  for( i = 0; i < len; i++ ){
    if( CT_CLINES[i][CL_GROUP] == "g1" ){
      for( j = i; j < len; j++ ){
        if( CT_CLINES[j][CL_GROUP] == "g1" ){
          dif1 = MathAbs( getClineValueByShift( CT_CLINES[i][CL_NAME], iBarShift( NULL, 0, g1_t1 ) ) - getClineValueByShift( CT_CLINES[j][CL_NAME], iBarShift( NULL, 0, g1_t1 ) ) );
          dif2 = MathAbs( getClineValueByShift( CT_CLINES[i][CL_NAME], iBarShift( NULL, 0, g1_t2 ) ) - getClineValueByShift( CT_CLINES[j][CL_NAME], iBarShift( NULL, 0, g1_t2 ) ) );
          if( MathAbs( dif1 - dif2 ) > limit ){
            addComment( StringConcatenate("G1: between ",getCLineProperty(CT_CLINES[i][CL_NAME], "ts")," <=> ",getCLineProperty(CT_CLINES[j][CL_NAME], "ts")," dif is:", DoubleToStr( MathAbs( dif1 - dif2 ), Digits )," inst:", DoubleToStr( limit, Digits )) ,1 );
          }
          break;
        }
      }
    }else if( CT_CLINES[i][CL_GROUP] == "g2" ){
      for( j = i; j < len; j++ ){
        if( CT_CLINES[j][CL_GROUP] == "g2" ){
          dif1 = MathAbs( getClineValueByShift( CT_CLINES[i][CL_NAME], iBarShift( NULL, 0, g2_t1 ) ) - getClineValueByShift( CT_CLINES[j][CL_NAME], iBarShift( NULL, 0, g2_t1 ) ) );
          dif2 = MathAbs( getClineValueByShift( CT_CLINES[i][CL_NAME], iBarShift( NULL, 0, g2_t2 ) ) - getClineValueByShift( CT_CLINES[j][CL_NAME], iBarShift( NULL, 0, g2_t2 ) ) );
          if( MathAbs( dif1 - dif2 ) > limit ){
            addComment( StringConcatenate("G2: between ",getCLineProperty(CT_CLINES[i][CL_NAME], "ts")," <=> ",getCLineProperty(CT_CLINES[j][CL_NAME], "ts")," dif is:", DoubleToStr( MathAbs( dif1 - dif2 ), Digits )," inst:", DoubleToStr( limit, Digits )) ,1 );
          }
          break;
        }
      }
    }
  }
}
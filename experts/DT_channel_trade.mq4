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
#define CL_POS 3

#define CL_MID_GROUP_DIST 0.5
#define CHANNEL_LOT 0.1
#define CT_SL_FACTOR 1.3

#define CT_MID_SPEED_LIMIT 140.0
#define CT_BOUND_SPEED_LIMIT 420.0 //220

#define CT_KEEP_POS_TIME 7200 // 1,5 hour
#define CT_POS_DIF_TIME 86400 // 24 hour
#define CT_FIBO_23 0.232 // 0.236
#define CT_FIBO_38 0.377 // 0.382
#define CT_FIBO_61 0.613 // 0.618

string CT_CLINES[][4];

int CT_START_TIME;

double CT_OFFSET = 0.0;
double CT_MIN_DIST = 0.0;
double CT_MAX_DIST = 0.0;
double CT_MAX_G1_LOSE = 0.0;
double CT_MAX_G2_LOSE = 0.0;


double CT_ZZ_TP = 0.0;
double CT_ZZ_SL = 0.0;

double CT_SPREAD = 0.0;
double CT_THRESHOLD = 0.0;

string CT_SPREAD_LOG = "";

string EXP_FILE_NAME;
string EXP_LAST_MOD_GV;

bool CONNECTION_FAIL = true;

int init(){
  if( MarketInfo(Symbol(),MODE_TICKVALUE) == 0.0 ){
    CONNECTION_FAIL = true;
    return (0);
  }else{
    CONNECTION_FAIL = false;
  }

  CT_OFFSET = 65/MarketInfo(Symbol(),MODE_TICKVALUE)*Point;
  CT_MIN_DIST = 270/MarketInfo(Symbol(),MODE_TICKVALUE)*Point;
  CT_MAX_DIST = 1100/MarketInfo(Symbol(),MODE_TICKVALUE)*Point;
  CT_MAX_G1_LOSE = 260/MarketInfo(Symbol(),MODE_TICKVALUE)*Point;
  CT_MAX_G2_LOSE = 80/MarketInfo(Symbol(),MODE_TICKVALUE)*Point;
	
  CT_ZZ_TP = 90 / MarketInfo(Symbol(),MODE_TICKVALUE) * Point;
  CT_ZZ_SL = 90 / MarketInfo(Symbol(),MODE_TICKVALUE) * Point;
	
  CT_START_TIME = GetTickCount() + 180000; // 3 min
  CT_SPREAD = NormalizeDouble( getMySpread() * 1.1, Digits );
  CT_THRESHOLD = NormalizeDouble( CT_SPREAD * 0.5, Digits );
  GlobalVariableSet( "CT_NR_OF_LOGS", 0.0 );

  string sym = StringSubstr(Symbol(), 0, 6);

  if( IsTesting() ){
    string test_file_name = StringConcatenate( StringSubstr(Symbol(), 0, 6) , "_test_cLines.csv" );
    setChannelLinesArr( test_file_name );
    WindowRedraw();
	}

  EXP_FILE_NAME = StringConcatenate( sym, "_cLines.csv" );
  EXP_LAST_MOD_GV = StringConcatenate( sym, "_cLines_lastMod" );
  return(0);
}

int start(){
  if( CONNECTION_FAIL ){
    init();
    return (0);
  }
// ###############################################################  Set Chennel Lines  ################################################################
  static int TIMER_1 = 0;
  if( GetTickCount() > TIMER_1 ){
    TIMER_1 = GetTickCount() + 4000;

    if( !IsTesting() ){
      if( Period() != PERIOD_M15 ){
        log( StringConcatenate( "WARNING! Channel trade line not in M15 period! curr. is ", Period(), " (", Symbol(),")" ), 0.01 );
      }

      setChannelLinesArr( EXP_FILE_NAME );
    }
    
// ###############################################################  Init Trade Allowance  ##############################################################
    static bool STOP_TRADE = false;
    if( ObjectFind("DT_GO_channel_trade_time_limit") == -1 ){
      STOP_TRADE = false;
    }else{
      if( ObjectGet( "DT_GO_channel_trade_time_limit", OBJPROP_TIME1 ) < iTime( NULL, PERIOD_M1, 0) ){
        STOP_TRADE = true;
      }else{
        STOP_TRADE = false;
      }
    }
  }

  static double PEEK_FOR_SPREAD_LOG = 0.0;
	static int BAR_TIME_REFRESH = PERIOD_M1;
	static double LAST_PEEK_PRICE = 0.0;
	static double LAST_BAR_TIME = 0.0;

  if( Period() > PERIOD_M5 && Period() < PERIOD_D1  /*&& ( IsTesting() || GetTickCount() > CT_TIMER2 )*/ ){
    //CT_TIMER2 = GetTickCount() + 1000;

    int ticket, o_type;
    string comment, trade_line_ts_str, trade_line_name = "", trade_line_pos = "", trade_line_group = "";
    double fibo_100 = 0.0, fibo_23_dif, trade_line_price, op, tp, tmp;

    ticket = getClineOpenPosition();
    if( ticket != 0 ){
      o_type = OrderType();

// #################################################################  Spread logging  ##################################################################
      if( !IsTesting() ){
        if( PEEK_FOR_SPREAD_LOG == 0.0 ){
          if( o_type == OP_BUYLIMIT ){
            PEEK_FOR_SPREAD_LOG = 99999.0;
          }else{
            PEEK_FOR_SPREAD_LOG = 0.1;
          }
        }

        if( o_type == OP_BUYLIMIT ){
          if( Ask < PEEK_FOR_SPREAD_LOG  ){
            PEEK_FOR_SPREAD_LOG = Ask;
            CT_SPREAD_LOG = StringConcatenate( CT_SPREAD_LOG ,TimeToStr( TimeCurrent(), TIME_DATE|TIME_SECONDS),";",DoubleToStr( High[0], Digits ),";",DoubleToStr( Low[0], Digits ),";",DoubleToStr( Bid, Digits ),";",DoubleToStr( Ask, Digits ),"\r\n" );
          }
        }else{
          if( Bid > PEEK_FOR_SPREAD_LOG  ){
            PEEK_FOR_SPREAD_LOG = Bid;
            CT_SPREAD_LOG = StringConcatenate( CT_SPREAD_LOG ,TimeToStr( TimeCurrent(), TIME_DATE|TIME_SECONDS),";",DoubleToStr( High[0], Digits ),";",DoubleToStr( Low[0], Digits ),";",DoubleToStr( Bid, Digits ),";",DoubleToStr( Ask, Digits ),"\r\n" );
          }
        }
      }

      double new_tp;
// #############################################################  Modify OPEN position  ################################################################
      if( o_type < 2 ){
				
        if( LAST_BAR_TIME == iTime( NULL, BAR_TIME_REFRESH, 0 ) ){
          return (0);
        }else{
          LAST_BAR_TIME = iTime( NULL, BAR_TIME_REFRESH, 0 );
        }
				
				if( LAST_PEEK_PRICE == 0.0 ){
          LAST_PEEK_PRICE = NormalizeDouble( OrderOpenPrice(), Digits );
        }
				
				if( o_type == OP_BUY ){
          tmp = NormalizeDouble( MathMin( Low[0], Low[1] ), Digits );
          if( tmp < LAST_PEEK_PRICE ){
            LAST_PEEK_PRICE = tmp;
          }else{
            return (0);
          }
        }else{
          tmp = NormalizeDouble( MathMax( High[0], High[1] ), Digits );
          if( tmp > LAST_PEEK_PRICE ){
            LAST_PEEK_PRICE = tmp;
          }else{
            return (0);
          }
        }
				
				
				trade_line_ts_str = OrderMagicNumber();
        if( !getCLineData( trade_line_ts_str, trade_line_name, trade_line_group, trade_line_pos ) ){
          OrderDelete( ticket );
          errorCheck( StringConcatenate( Symbol()," Limit position is closed due to missing channel line: ",trade_line_name,"! ticket id :", ticket ) );
          log( StringConcatenate( Symbol()," Limit position is closed due to missing channel line: ",trade_line_name,"! ticket id :", ticket ), 0.03 );
          return (0);
        }
				
        comment = OrderComment();
				fibo_100 = NormalizeDouble( StrToDouble( StringSubstr( comment, 2, 7 ) ), Digits );
				if( StringSubstr( comment, 0, 1 ) == "B" ){ // bound
					setPosData( new_tp, tmp, "bound", fibo_100, LAST_PEEK_PRICE, ObjectGet( trade_line_name, OBJPROP_PRICE1 ) < ObjectGet( trade_line_name, OBJPROP_PRICE2 ), trade_line_group );
					BAR_TIME_REFRESH = PERIOD_M15;
				}else{
					setPosData( new_tp, tmp, "mid", fibo_100, LAST_PEEK_PRICE, ObjectGet( trade_line_name, OBJPROP_PRICE1 ) < ObjectGet( trade_line_name, OBJPROP_PRICE2 ), trade_line_group );
					BAR_TIME_REFRESH = PERIOD_M1;
				}
				
        tp = NormalizeDouble( OrderTakeProfit(), Digits );
				if( o_type == OP_BUY ){
					if( new_tp > tp ){
						return (0);
					}
				}else{
					if( new_tp < tp ){
						return (0);
					}
				}
				
        if( tp == new_tp ){
          return (0);
        }

        if( GetTickCount() < CT_START_TIME ){
          CT_START_TIME = GetTickCount();
          if(IDNO == MessageBox(StringConcatenate("Terminal just started, do you want MODIFY OPEN position(", ticket,") in ", Symbol()), "Channel trading", MB_YESNO|MB_ICONQUESTION )){
            return(0);
          }
        }

        OrderModify( ticket, NormalizeDouble( OrderOpenPrice(), Digits ), NormalizeDouble( OrderStopLoss(), Digits ), new_tp, TimeCurrent()+5400 );

/* !! */  Print(StringConcatenate("OP Mod: ", Symbol(), " oType:", o_type, " Ticket:", ticket,  " NEW TP:", new_tp, " F23:", NormalizeDouble( fibo_23_dif, Digits ), " F100:", fibo_100, " Peek:", LAST_PEEK_PRICE, " Bid:", Bid, " Ask:", Ask, " Mag:", OrderMagicNumber()));
/* !! */  log(StringConcatenate("OP Mod: ", Symbol(), " oType:", o_type, " Ticket:", ticket,  " NEW TP:", new_tp, " F23:", NormalizeDouble( fibo_23_dif, Digits ), " F100:", fibo_100, " Peek:", LAST_PEEK_PRICE, " Bid:", Bid, " Ask:", Ask, " Mag:", OrderMagicNumber()), MathRand());

        trade_line_ts_str = StringSubstr( comment, 7, 10 );
        if( IsTesting() ){
          if( ObjectFind( "DT_GO_channel_hist_new_tp_"+trade_line_ts_str ) == -1 ){
/* !! */    createHistoryLine( new_tp, Indigo, "Order type: "+o_type+", NEW TP", "new_tp_"+trade_line_ts_str, Time[0] );
          }else{
/* !! */    ObjectSet( "DT_GO_channel_hist_new_tp_"+trade_line_ts_str, OBJPROP_PRICE1, new_tp );
          }
        }

        errorCheck(StringConcatenate("Channel trade OPEN OrderModify Bid:", Bid, " Ask:", Ask, " op:"+NormalizeDouble( OrderOpenPrice(), Digits ), " tp:", tp, " new tp:", new_tp));
        return (0);

      }else{
// ###############################################################  Modify LIMIT Position  ################################################################

				if( LAST_BAR_TIME == iTime( NULL, PERIOD_M15, 0 ) ){
          return (0);
        }else{
          LAST_BAR_TIME = iTime( NULL, PERIOD_M15, 0 );
        }

        double open_time = OrderOpenTime();
        if( open_time + CT_KEEP_POS_TIME < TimeCurrent() || STOP_TRADE ){
          OrderDelete( ticket );
          errorCheck( StringConcatenate( Symbol(), " Position closed due to timer expired or trade stopped, ticket id:", ticket ) );
          log( StringConcatenate( Symbol(), " Position closed due to timer expired or trade stopped, ticket id:", ticket ), 0.02 );
          return (0);
        }
				
				trade_line_ts_str = OrderMagicNumber();
        if( !getCLineData( trade_line_ts_str, trade_line_name, trade_line_group, trade_line_pos ) ){
          OrderDelete( ticket );
          errorCheck( StringConcatenate( Symbol()," Limit position is closed due to missing channel line: ",trade_line_name,"! ticket id :", ticket ) );
          log( StringConcatenate( Symbol()," Limit position is closed due to missing channel line: ",trade_line_name,"! ticket id :", ticket ), 0.03 );
          return (0);
        }
				
        double new_op;
				
        trade_line_price = getClineValueByShift( trade_line_name );
        if( o_type == OP_BUYLIMIT ){
          new_op = NormalizeDouble( trade_line_price + CT_SPREAD + CT_THRESHOLD, Digits );
        }else{
          new_op = NormalizeDouble( trade_line_price - CT_THRESHOLD, Digits );
        }

        op = NormalizeDouble( OrderOpenPrice(), Digits );
        if( new_op == op ){
          return (0);
        }else{
					comment = OrderComment();
					fibo_100 = NormalizeDouble( StrToDouble(StringSubstr( comment, 2, 7 ) ), Digits );
          
					double new_sl = 0.0;
					setPosData( new_tp, new_sl, trade_line_pos, fibo_100, trade_line_price, ObjectGet( trade_line_name, OBJPROP_PRICE1 ) < ObjectGet( trade_line_name, OBJPROP_PRICE2 ), trade_line_group );

          if( GetTickCount() < CT_START_TIME ){
            CT_START_TIME = GetTickCount();
            if(IDNO == MessageBox(StringConcatenate("Terminal just started, do you want MODIFY LIMIT position(", ticket,") in ", Symbol()), "Channel trading", MB_YESNO|MB_ICONQUESTION )){
              return(0);
            }
          }

          OrderModify( ticket, new_op, new_sl, new_tp, TimeCurrent()+5400 );

/* !! */  Print(StringConcatenate("Mod: ", Symbol(), " oType:", o_type, " Ticket:", ticket,  " OP:", new_op, " SL:", new_sl, " TP:", new_tp, " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Group:", trade_line_group, " Mag:", OrderMagicNumber()));
/* !! */  log(StringConcatenate("Mod: ", Symbol(), " oType:", o_type, " Ticket:", ticket,  " OP:", new_op, " SL:", new_sl, " TP:", new_tp, " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " Group:", trade_line_group, " Mag:", OrderMagicNumber()), MathRand());

          if( IsTesting() ){
/* !! */    ObjectSet( "DT_GO_channel_hist_op_"+trade_line_ts_str, OBJPROP_PRICE1, new_op );
/* !! */    ObjectSet( "DT_GO_channel_hist_sl_"+trade_line_ts_str, OBJPROP_PRICE1, new_sl );
/* !! */    ObjectSet( "DT_GO_channel_hist_tp_"+trade_line_ts_str, OBJPROP_PRICE1, new_tp );
          }

          if( !errorCheck("Channel trade LIMIT OrderModify Bid:"+ Bid+ " Ask:"+ Ask)){
            return(0);
          }
        }
      }
      errorCheck("Channel trade modify position part");
    }else{
// #################################################################  Find NEW LMIT Positon  ##################################################################    
      if( STOP_TRADE ){
        return (0);
      }
			
			int i, len = ArrayRange( CT_CLINES, 0 ), trade_line_ts = 0;
			double fibo_100_time, dif, fibo_time_cross_p, speed;
			string speed_log = "", siblings[2] = {"",""};
			
			for( i = 0; i < len; i++ ){
				// error missing cLine
				if( ObjectFind( CT_CLINES[i][CL_NAME] ) == -1 ){
					log( StringConcatenate( "Error cLine is missing: ",CT_CLINES[i][CL_NAME]," (", Symbol(), ")" ), trade_line_ts + 0.04 );
					setChannelLinesArr( EXP_FILE_NAME );
					return (0);
				}
				
				// cLine is not trade line
				if( CT_CLINES[i][CL_STATE] == "sig" ){
					continue;
				}
				
				// current cLine price
				trade_line_price = getClineValueByShift( CT_CLINES[i][CL_NAME] );
								
				// Current time not cross cLine
				if( trade_line_price == 0.0){
					log( StringConcatenate( "Error cLine is not enought long: ",CT_CLINES[i][CL_NAME]," (", Symbol(), ")" ), trade_line_ts + 0.05 );
					setChannelLinesArr( EXP_FILE_NAME );
					return (0);
				}
				
				// cLine not in trade zone
				if( Bid > trade_line_price + CT_OFFSET || Bid < trade_line_price - CT_OFFSET ){
					continue;
				}
				
				// get Fibo 100, Fibo 100 time
				if( CT_CLINES[i][CL_POS] == "bound" ){
					getFibo100( PERIOD_H1, trade_line_price ,fibo_100, fibo_100_time );
				}else{
					getFibo100( PERIOD_M15, trade_line_price ,fibo_100, fibo_100_time );
				}
				
				// price go against Resistance or Suppress clLine
				if( fibo_100 > trade_line_price ){
					if( CT_CLINES[i][CL_STATE] == "res" ){  // Resistance
						log( StringConcatenate( "Resistance line: ",CT_CLINES[i][CL_NAME]," Curr fibo 100:",fibo_100, " (", Symbol(), ")" ), trade_line_ts + 0.06 );
						continue;
					}
				}else{
					if( CT_CLINES[i][CL_STATE] == "sup" ){  // Suppress
						log( StringConcatenate( "Suppress line: ",CT_CLINES[i][CL_NAME]," Curr fibo 100:",fibo_100, " (", Symbol(), ")" ), trade_line_ts + 0.07 );
						continue;
					}
				}
				
				// get cLine ID ( timestamp fom it't name )
				trade_line_ts = getCLineProperty( CT_CLINES[i][CL_NAME], "ts" );
				
				// to this cLine there was closed position lately
				if( hasClineHistoryPosition( trade_line_ts ) ){
					log( StringConcatenate( "During ",TimeToStr( CT_POS_DIF_TIME, TIME_MINUTES)," hours at ", CT_CLINES[i][CL_NAME]," line we have Opened Position!", " (", Symbol(), ")" ), trade_line_ts + 0.08 );
					return (0);
				}
				
				// where fibo100 time cross the cLine
				fibo_time_cross_p = getClineValueByShift( CT_CLINES[i][CL_NAME], iBarShift( NULL, 0, fibo_100_time ) );
				
				// Fibo 100 time not cross the cLine
				if( fibo_time_cross_p == 0.0 ){
					log( StringConcatenate( "Error fibo100 time:", fibo_100_time," not cross current cLine:", CT_CLINES[i][CL_NAME], " (", Symbol(), ")" ), trade_line_ts + 0.09 );
					continue;
				}

				// Fibo 100 <=> cLine difference
				dif = MathAbs( fibo_100 - fibo_time_cross_p );
				
				// distance is too small between Fibo 100 and cLine
				if( dif < CT_MIN_DIST ){  // Min Distance
					log( StringConcatenate( "Fibo DISTANCE is too SMALL! Cline: ", CT_CLINES[i][CL_NAME]," Min Distance: ",CT_MIN_DIST," Curr distance:", dif, " (", Symbol(), ")" ), trade_line_ts + 0.10 );
					continue;
				}
				
				// fake Fibo 100 price is already below cLine
				if( alreadyBelowCLine( trade_line_price ,fibo_100, fibo_100_time ) ){
					log( StringConcatenate( "Price is already below trade_line: ",CT_CLINES[i][CL_NAME]," Curr fibo 100:",fibo_100, " (", Symbol(), ")" ), trade_line_ts + 0.11 );
					continue;
				}
				
				// cLine in group or not?
				if( CT_CLINES[i][CL_GROUP] != "g0" ){
					// get cLine siblings
					getSiblingLines( fibo_100 > trade_line_price, siblings, CT_CLINES[i][CL_GROUP], i, len, 2 );
					
					// primary sibling missing
					if( siblings[0] == "" ){
						log( StringConcatenate( "Error primary sibling missing GR:", CT_CLINES[i][CL_GROUP]," cLine:",CT_CLINES[i][CL_NAME], " (", Symbol(), ")" ), trade_line_ts + 0.13 );
						return (0);
					}
				
					// Speed of price movment
					speed = priceSpeed( trade_line_name, speed_log );
					
					if( CT_CLINES[i][CL_POS] == "bound" ){
						if( speed > CT_BOUND_SPEED_LIMIT ){
							log( StringConcatenate( "Bar SPEED is too fast in Boundary cLine!", speed_log ), speed );
							return (0);
						}
					}else{
						// distance between Fibo 100 and cLine farther than secondary sibling
						if( siblings[1] != "" ){
							if( MathAbs( getClineValueByShift( siblings[1] ) - trade_line_price ) < MathAbs( fibo_time_cross_p - fibo_100 ) ){
								fibo_100 = getCLineItercept( siblings[0], fibo_100_time, trade_line_price > fibo_100 );
								if( fibo_100 == 0.0 ){
									log( StringConcatenate( "Error in getCLineItercept not find itercept: ",CT_CLINES[i][CL_NAME], " (", Symbol(), ")" ), trade_line_ts + 0.14 );
									return (0);
								}
							}
						}
					
						if( speed > CT_MID_SPEED_LIMIT ){
							log( StringConcatenate( "Bar SPEED is too fast in midlle cLine!", speed_log ), speed );
							return (0);
						}
					}
				}
				
				trade_line_name = CT_CLINES[i][CL_NAME];
				break;
			}
			
      if( trade_line_name != "" ){

        if( GetTickCount() < CT_START_TIME ){
          if(IDNO == MessageBox(StringConcatenate("Terminal just started, do you want OPEN position in ", Symbol()), "Channel trading", MB_YESNO|MB_ICONQUESTION )){
            return(0);
          }
        }

        trade_line_group = CT_CLINES[i][CL_GROUP];

        double sl, peek;

        RefreshRates();
        if( fibo_100 > trade_line_price ){ // ================================================ BUY LIMIT ================================================
          peek = iLow( NULL, PERIOD_H1, 0);
          if( peek > trade_line_price ){
            o_type = OP_BUYLIMIT;
            op = NormalizeDouble( trade_line_price + CT_SPREAD + CT_THRESHOLD, Digits );
          }else{
            log( StringConcatenate( "Warning you are late from BUY LIMIT trade line price:",trade_line_price," bar low: ",peek , " (", Symbol(), ")" ), trade_line_ts + 0.15 );
            return (0);
          }
					
        }else{  // ================================================ SELL LIMIT ================================================
          peek = iHigh( NULL, PERIOD_H1, 0);
          if( peek < trade_line_price ){
            o_type = OP_SELLLIMIT;
            op = NormalizeDouble( trade_line_price - CT_THRESHOLD, Digits );
          }else{
            log( StringConcatenate( "Warning you are late from SELL LIMIT trade line price:",trade_line_price," bar high: ",peek, " (", Symbol(), ")" ), trade_line_ts + 0.16 );
            return (0);
          }
        }
				
				setPosData( tp, sl, CT_CLINES[i][CL_POS], fibo_100, trade_line_price, ObjectGet( trade_line_name, OBJPROP_PRICE1 ) < ObjectGet( trade_line_name, OBJPROP_PRICE2 ), trade_line_group );
				
				if( crashToCLine( trade_line_name, MathMax( op, sl ), MathMin( op, sl ) ) ){
					log( StringConcatenate( "Stop loss price crash to other cLine! (", Symbol(), ")" ), trade_line_ts + 1.17 );
					return (0);
				}
				
				LAST_PEEK_PRICE = trade_line_price;
        PEEK_FOR_SPREAD_LOG = peek;

				if( CT_CLINES[i][CL_POS] == "bound" ){
					comment = StringConcatenate( "B ", DoubleToStr( fibo_100, 5 ), " ", trade_line_ts );
					BAR_TIME_REFRESH = PERIOD_M15;
				}else{
					comment = StringConcatenate( "N ", DoubleToStr( fibo_100, 5 ), " ", trade_line_ts );
					BAR_TIME_REFRESH = PERIOD_M1;
				}

        OrderSend( Symbol(), o_type, CHANNEL_LOT, op, 15, sl, tp, comment, trade_line_ts, TimeCurrent()+5400 );

/* !! */  Print(StringConcatenate("Ty:", o_type, " Lot:", CHANNEL_LOT, " OP:", op, " SL:", sl, " TP:", tp, " Comm:", comment, " Mag:", trade_line_ts, " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " \n\tStat:", trade_line_name, " Gr:", trade_line_group," Dist:", dif," H:", iHigh( NULL, PERIOD_M15, 0)," L:", iLow( NULL, PERIOD_M15, 0)," Sp:",DoubleToStr(speed,2), " (", Symbol(), ")"));
/* !! */  log(StringConcatenate("Ty:", o_type, " Lot:", CHANNEL_LOT, " OP:", op, " SL:", sl, " TP:", tp, " Comm:", comment, " Mag:", trade_line_ts, " Exp:", TimeCurrent()+5400, " F100:", fibo_100, " Bid:", Bid, " Ask:", Ask, " \n\tStat:", trade_line_name, " Gr:", trade_line_group," Dist:", dif," H:", iHigh( NULL, PERIOD_M15, 0)," L:", iLow( NULL, PERIOD_M15, 0)," Sp:",DoubleToStr(speed,2), " (", Symbol(), ")"), trade_line_ts + 0.18);

        if( IsTesting() ){
/* !! */  createHistoryLine( op, Blue, "Order type: "+o_type+", OP", "op_"+trade_line_ts, Time[0] );
/* !! */  createHistoryLine( sl, Red, "Order type: "+o_type+", SL", "sl_"+trade_line_ts, Time[0] );
/* !! */  createHistoryLine( tp, Green, "Order type: "+o_type+", TP", "tp_"+trade_line_ts, Time[0] );
/* !! */  createHistoryLine( fibo_100, Black, "Order type: "+o_type+", f100", "f100_"+trade_line_ts, fibo_100_time );
        }

        errorCheck("NEW LIMIT pos Bid:"+ Bid+ " Ask:"+ Ask);
      }
      errorCheck("Channel trade new position part");
    }
  }

  return(0);
}

int deinit(){
	if( CT_SPREAD_LOG != "" ){
		string file_name = StringConcatenate( StringSubstr(Symbol(), 0, 6), "_spread_log.csv" );
		int handle = FileOpen( file_name, FILE_READ, ";" );
		handle = FileOpen( file_name, FILE_BIN|FILE_READ|FILE_WRITE );
		if( handle > 0 ){
			FileSeek( handle, 0, SEEK_END );
			FileWriteString( handle, CT_SPREAD_LOG, StringLen(CT_SPREAD_LOG) );
		}
		FileClose(handle);
	}
  return(0);
}

void setChannelLinesArr( string &file_name ){
  static double last_mod = 1.0;
  if( last_mod != GlobalVariableGet( EXP_LAST_MOD_GV ) ){
    last_mod = GlobalVariableGet( EXP_LAST_MOD_GV );

    double price, tmp_arr[0][2];
    int i, j = 0, len;
    string name;

    if( !readCLinesFromFile( file_name ) ){
      return;
    }

    len = ObjectsTotal();
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
		int g1 = -1, g2 = -1;
    for( i = 0; i < j; i++ ){
      name = ObjectName( tmp_arr[i][1] );
      CT_CLINES[i][CL_NAME] = name;
      CT_CLINES[i][CL_STATE] = StringSubstr( name, 15, 3 );
      CT_CLINES[i][CL_GROUP] = StringSubstr( name, 12, 2 );
			if( CT_CLINES[i][CL_GROUP] == "g1" ){
				if( g1 == -1 ){
					CT_CLINES[i][CL_POS] = "bound";
				}else{
					CT_CLINES[i][CL_POS] = "mid";
				}
				g1 = i;
			}else if( CT_CLINES[i][CL_GROUP] == "g2" ){
				if( g2 == -1 ){
					CT_CLINES[i][CL_POS] = "bound";
				}else{
					CT_CLINES[i][CL_POS] = "mid";
				}
				g2 = i;
			}
    }
		
		if( g1 != -1 ){
			CT_CLINES[g1][CL_POS] = "bound";
		}
		if( g2 != -1 ){
			CT_CLINES[g2][CL_POS] = "bound";
		}
		
    errorCheck( "setChannelLinesArr" );
  }
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
	ObjectSetText(name, text, 8);
}

bool isBoundaryCLine( double& fibo_100, double& trade_line_price, int& from, string group ){
  int to = 0, i;
  if( fibo_100 < trade_line_price ){
    to = ArrayRange( CT_CLINES, 0 );
    for( i = from + 1; i < to; i++ ){
      if( CT_CLINES[i][CL_GROUP] == group ){
        return (false);
      }
    }
  }else{
    for( i = from - 1 ; i >= to; i-- ){
      if( CT_CLINES[i][CL_GROUP] == group ){
        return (false);
      }
    }
  }
  return (true);
}

void getSiblingLines( bool dir_up, string& siblings[], string group, int from, int len, int nr_result ){
	int i, nr = 0;
	if( dir_up == true ){
		for( i = from + 1; i < len && nr < nr_result; i++ ){
			if( CT_CLINES[i][CL_GROUP] == group ){
				siblings[nr] = CT_CLINES[i][CL_NAME];
				nr++;
			}
		}
	}else{
		for( i = from - 1; i >= 0 && nr < nr_result; i-- ){
			if( CT_CLINES[i][CL_GROUP] == group ){
				siblings[nr] = CT_CLINES[i][CL_NAME];
				nr++;
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
  return ( 0.0 );
}

void log( string text, double id = 0.0 ){
  static double last_log_id = 0.0;
  if( last_log_id == id ){
    return;
  }else{
    Alert( text );
    last_log_id = id;
    if( !IsTesting() ){
      GlobalVariableSet( "CT_NR_OF_LOGS", GlobalVariableGet( "CT_NR_OF_LOGS" ) + 1.0 );
    }
  }
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
  log = StringConcatenate( " Cline: ", cLine," Speed: ", DoubleToStr(speed, 2), " Bar nr:", i-1, " (", DoubleToStr( peri, 2 ),") high:", DoubleToStr( h, Digits ), " low:", DoubleToStr( l , Digits ), " (", Symbol(), ")" );
  return (speed);
}

bool crashToCLine( string name, double max, double min ){
	int i, len = ArrayRange( CT_CLINES, 0 );
	double price;
	
	for( i = 0; i < len; i++ ){
		if( CT_CLINES[i][CL_NAME] != name ){
			price = getClineValueByShift( CT_CLINES[i][CL_NAME] );
			if( max > price && min < price ){
				return ( true );
			}
		}
	}
	return ( false );
}

bool alreadyBelowCLine( double trade_line_price ,double fibo_100, double fibo_100_time ){
  int i = 0, len = iBarShift( NULL, 0, fibo_100_time );
  if( fibo_100 > trade_line_price ){
    for( ; i < len; i++ ){
      if( Low[i] < trade_line_price ){
        return ( true );
      }
    }
  }else{
    for( ; i < len; i++ ){
      if( High[i] > trade_line_price ){
        return ( true );
      }
    }
  }
  return ( false );
}

void setPosData( double& tp, double& sl, string pos, double fibo_100, double trade_line_price, bool dir, string group ){
	if( pos == "bound" ){
		double max_lose;
		if( group == "g1" ){
			max_lose = CT_MAX_G1_LOSE;
		}else{
			max_lose = CT_MAX_G2_LOSE;
		}
		
		if( fibo_100 > trade_line_price ){ // BUY
			if( dir ){
				tp = NormalizeDouble( trade_line_price + (MathAbs( fibo_100 - trade_line_price ) * CT_FIBO_61), Digits );
			}else{
				tp = NormalizeDouble( trade_line_price + (MathAbs( fibo_100 - trade_line_price ) * CT_FIBO_38), Digits );
			}
			if( MathAbs( trade_line_price - sl ) > max_lose ){
				sl = NormalizeDouble( trade_line_price - max_lose, Digits );
			}else{
				sl = NormalizeDouble( trade_line_price - (MathAbs( fibo_100 - trade_line_price ) * 0.236), Digits );
			}
		}else{ // SELL
			if( dir ){
				tp = NormalizeDouble( trade_line_price - (MathAbs( fibo_100 - trade_line_price ) * CT_FIBO_38) + CT_SPREAD, Digits );
			}else{
				tp = NormalizeDouble( trade_line_price - (MathAbs( fibo_100 - trade_line_price ) * CT_FIBO_61) + CT_SPREAD, Digits );
			}
			if( MathAbs( trade_line_price - sl ) > max_lose ){
				sl = NormalizeDouble( trade_line_price + max_lose, Digits );
			}else{
				sl = NormalizeDouble( trade_line_price + (MathAbs( fibo_100 - trade_line_price ) * 0.236) + CT_SPREAD, Digits );
			}
		}
	}else{
		if( fibo_100 > trade_line_price ){ // BUY
			sl = NormalizeDouble( trade_line_price - CT_ZZ_SL, Digits );
			tp = NormalizeDouble( trade_line_price + CT_ZZ_TP, Digits );
		}else{ // SELL
			sl = NormalizeDouble( trade_line_price + CT_ZZ_SL + CT_SPREAD, Digits );
			tp = NormalizeDouble( trade_line_price - CT_ZZ_TP + CT_SPREAD, Digits );
		}
	}
}

bool getCLineData( string id, string& trade_line_name, string& trade_line_group, string& trade_line_pos ){
	int i, len = ArrayRange( CT_CLINES, 0 );
	for( i = 0; i < len; i++ ){
		if( StringSubstr( CT_CLINES[i][CL_NAME], 19, 10 ) == id ){
			trade_line_name = CT_CLINES[i][CL_NAME];
			trade_line_group = CT_CLINES[i][CL_GROUP];
			trade_line_pos = CT_CLINES[i][CL_POS];
			return (true);
		}
	}
	return (false);
}
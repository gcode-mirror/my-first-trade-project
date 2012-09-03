//+------------------------------------------------------------------+
//|                                                       DT_hud.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#define T1 0
#define P1 1
#define T2 2
#define P2 3

#define UNDO 0
#define REDO 1

double HUD_MY_SPREAD;
double HUD_SPREAD_LIMIT;

double HUD_PRICE_MIN = 0.0, HUD_PRICE_MAX = 0.0;

string HUD_HISTORY_LINE_NAMES[][2];
double HUD_HISTORY_LINE_DATA[][2][4];

string HUD_CHANNEL_LINE_NAMES[];
double HUD_CHANNEL_LINE_DATA[][4];

string HUD_HISTORY_GLOBAL_NAME;
double HUD_SELF_HISTORY_GLOBAL_VAL;

double HUD_WINDOW_FADE = 0.0;

string EXP_FILE_NAME;
string EXP_LAST_MOD_GV;

int HUD_TIMER1 = 0;

bool initHud(){
	deinitHud();
	string sym = StringSubstr(Symbol(), 0, 6);
	int pos_x = ICONS_X_POS + ( (ICONS_RANGE + ICON_SIZE) * ICON_NR );

	// ====================== main info bar ======================
  HUD_MY_SPREAD = getMySpread() * MathPow( 10, Digits );
	HUD_SPREAD_LIMIT = HUD_MY_SPREAD * 1.5;

	ObjectCreate( "DT_BO_hud_info", OBJ_LABEL, 0, 0, 0 );
  ObjectSet( "DT_BO_hud_info", OBJPROP_CORNER, 0 );
  ObjectSet( "DT_BO_hud_info", OBJPROP_XDISTANCE, pos_x );
  ObjectSet( "DT_BO_hud_info", OBJPROP_YDISTANCE, 1 );

	ObjectCreate( "DT_BO_hud_spread", OBJ_LABEL, 0, 0, 0 );
  ObjectSet( "DT_BO_hud_spread", OBJPROP_CORNER, 0 );
  ObjectSet( "DT_BO_hud_spread", OBJPROP_XDISTANCE, pos_x + 270 );
  ObjectSet( "DT_BO_hud_spread", OBJPROP_YDISTANCE, 1 );

	double lot = StrToDouble(getGlobal("LOT"));
  ObjectSetText("DT_BO_hud_info",StringConcatenate( sym ," | ",getPeriodName( Period() )," | Swap (L: "+DoubleToStr((MarketInfo(Symbol(),MODE_SWAPLONG)*lot),2)," / S: ",DoubleToStr((MarketInfo(Symbol(),MODE_SWAPSHORT)*lot),2),") | Lot: ",DoubleToStr(lot, 2)," |"),8,"Arial",Blue);

	// ====================== channel_trade info bar ======================
	if( ObjectFind("DT_BO_channel_trade_info") == -1 ){
    ObjectCreate( "DT_BO_channel_trade_info", OBJ_LABEL, 0, 0, 0 );
    ObjectSet( "DT_BO_channel_trade_info", OBJPROP_CORNER, 0 );
    ObjectSet( "DT_BO_channel_trade_info", OBJPROP_XDISTANCE, 800 );
    ObjectSet( "DT_BO_channel_trade_info", OBJPROP_YDISTANCE, 0 );
    ObjectSet( "DT_BO_channel_trade_info", OBJPROP_BACK, true);
    ObjectSetText( "DT_BO_channel_trade_info", "Channel Trade is OFF", 10, "Arial", DarkOrange );
  }

	// ====================== Scale info line ======================
  int win_width = GlobalVariableGet("DT_window_width");

  ObjectCreate( "DT_BO_hud_scale_info", OBJ_LABEL, 0, 0, 0 );
  ObjectSet( "DT_BO_hud_scale_info", OBJPROP_CORNER, 2 );
  ObjectSet( "DT_BO_hud_scale_info", OBJPROP_XDISTANCE, win_width - 2 );
  ObjectSet( "DT_BO_hud_scale_info", OBJPROP_YDISTANCE, 1 );
  
  ObjectCreate( "DT_BO_hud_scale_label", OBJ_LABEL, 0, 0, 0 );
  ObjectSet( "DT_BO_hud_scale_label", OBJPROP_CORNER, 3 );
  ObjectSet( "DT_BO_hud_scale_label", OBJPROP_XDISTANCE, 1 );
  ObjectSet( "DT_BO_hud_scale_label", OBJPROP_YDISTANCE, 60 );
  ObjectSet( "DT_BO_hud_scale_label", OBJPROP_ANGLE, 90 );

  // ====================== Window Fade ======================
  if( !GlobalVariableCheck( "DT_window_fade" ) ){
    GlobalVariableSet( "DT_window_fade", 0.0 );
  }
  ObjectCreate( "DT_BO_w0_hud_fade_main", OBJ_LABEL, 0, 0, 0 );
  ObjectSet( "DT_BO_w0_hud_fade_main", OBJPROP_CORNER, 0 );
  ObjectSet( "DT_BO_w0_hud_fade_main", OBJPROP_XDISTANCE, 0 );
  ObjectSet( "DT_BO_w0_hud_fade_main", OBJPROP_YDISTANCE, 0 );
  ObjectSet( "DT_BO_w0_hud_fade_main", OBJPROP_BACK, false );
  int width = win_width * 0.7;
  ObjectSetText( "DT_BO_w0_hud_fade_main", "g", width, "Webdings", White );
  ObjectSet( "DT_BO_w0_hud_fade_main", OBJPROP_TIMEFRAMES, -1 );
  
	//  ====================== History info bar and data ======================
	HUD_HISTORY_GLOBAL_NAME = StringConcatenate( sym, "_History" );
  HUD_SELF_HISTORY_GLOBAL_VAL = 1.0;
  GlobalVariableSet( HUD_HISTORY_GLOBAL_NAME, 1.0 );

	ObjectCreate( "DT_BO_hud_history", OBJ_LABEL, 0, 0, 0 );
  ObjectSet( "DT_BO_hud_history", OBJPROP_CORNER, 0 );
  ObjectSet( "DT_BO_hud_history", OBJPROP_XDISTANCE, pos_x );
  ObjectSet( "DT_BO_hud_history", OBJPROP_YDISTANCE, 15 );

  EXP_FILE_NAME = StringConcatenate( sym, "_cLines.csv" );
  EXP_LAST_MOD_GV = StringConcatenate( sym, "_cLines_lastMod" );
  GlobalVariableSet( EXP_LAST_MOD_GV, TimeLocal() );
  
  // updateChannelArray();
  
	return (errorCheck("initHud"));
}

bool startHud(){
	if(delayTimer(APP_ID_HUD, 2000)){return (false);}

	// ====================== main info bar ======================
  double spread = MarketInfo( Symbol(), MODE_SPREAD );
  color c;
  if( spread > HUD_SPREAD_LIMIT ){
    c = Red;
  }else{
    c = Blue;
  }
	ObjectSetText( "DT_BO_hud_spread", StringConcatenate( "Spread: ",DoubleToStr(spread,0), " / ", HUD_MY_SPREAD ), 8, "Arial", c );

	// ====================== channel_trade info bar ======================
	if( IsExpertEnabled() ){
    if( ObjectFind("DT_GO_channel_trade_time_limit") != -1 ){
      if( ObjectGet( "DT_GO_channel_trade_time_limit", OBJPROP_TIME1 ) < iTime( NULL, PERIOD_M1, 0) ){
        ObjectSetText( "DT_BO_channel_trade_info", "Channel Trade Stopped!", 10, "Arial", Red );
      }else{
        ObjectSetText( "DT_BO_channel_trade_info", "Channel Trade is ON", 10, "Arial", LimeGreen );
      }
    }else{
      ObjectSetText( "DT_BO_channel_trade_info", "Channel Trade is ON", 10, "Arial", LimeGreen );
    }
  }else{
    ObjectSetText( "DT_BO_channel_trade_info", "Channel Trade is OFF", 10, "Arial", Black );
  }  

	// ====================== Scale info line ======================
  if( HUD_PRICE_MIN != WindowPriceMin(0) || HUD_PRICE_MAX != WindowPriceMax(0)){
    HUD_PRICE_MIN = WindowPriceMin(0);
    HUD_PRICE_MAX = WindowPriceMax(0);
    
    int win_width = GlobalVariableGet("DT_window_width");

		int scale = ( 500 / getScaleNumber(HUD_PRICE_MIN, HUD_PRICE_MAX, Symbol()) ) * win_width;
    ObjectSetText( "DT_BO_hud_scale_info", "g", scale, "Webdings", Black );
    if( win_width - 2 > ObjectGet( "DT_BO_hud_scale_info", OBJPROP_XDISTANCE ) ){
      ObjectSet( "DT_BO_hud_scale_info", OBJPROP_XDISTANCE, win_width - 2 );
    }
    ObjectSetText( "DT_BO_hud_scale_label", scale+" px", 7, "Microsoft Sans Serif", Black );
  }
  
  // Window Fade
  if( HUD_WINDOW_FADE != GlobalVariableGet("DT_window_fade") ){
    HUD_WINDOW_FADE = GlobalVariableGet("DT_window_fade");
    if( HUD_WINDOW_FADE == 1.0 ){
      ObjectSet( "DT_BO_w0_hud_fade_main", OBJPROP_TIMEFRAMES, 0 );
      if( ObjectFind( "DT_BO_w_hud_fade_txt_0" ) != -1 ){
        toggleObjects( "w_hud", 0 );      
      }else{
        printRandomText();
      }
      
    }else{
      ObjectSet( "DT_BO_w0_hud_fade_main", OBJPROP_TIMEFRAMES, -1 );      
      if( ObjectFind( "DT_BO_w_hud_fade_txt_0" ) != -1 ){
        toggleObjects( "w_hud", -1 );      
      }
    }
  }

	// ====================== History info bar ======================
	int tmp, i, j, histroy_len = ArrayRange( HUD_HISTORY_LINE_NAMES, 0 ), c_line_len = ArraySize(HUD_CHANNEL_LINE_NAMES);
	double t1, p1, t2, p2, tmp2;
	bool has_change = false;
	
	for( i = 0; i < histroy_len; i++ ){
		for( j = 0; j < 2; j++ ){
			if( HUD_HISTORY_LINE_NAMES[i][j] != "" ){
				if( ObjectFind(HUD_HISTORY_LINE_NAMES[i][j]) == -1 ){
					if( removeItemFromArray(HUD_HISTORY_LINE_NAMES[i][j]) ){
						histroy_len = ArrayRange( HUD_HISTORY_LINE_NAMES, 0 );
						has_change = true;
						j = 3;
					}
				}
			}
		}
	}
	
	for( i = 0; i < c_line_len; i++ ){
		if( ObjectFind(HUD_CHANNEL_LINE_NAMES[i]) == -1 ){
			continue;
		}
	
		t1 = ObjectGet( HUD_CHANNEL_LINE_NAMES[i], OBJPROP_TIME1 );
    p1 = NormalizeDouble( ObjectGet( HUD_CHANNEL_LINE_NAMES[i], OBJPROP_PRICE1 ) ,Digits );
    t2 = ObjectGet( HUD_CHANNEL_LINE_NAMES[i], OBJPROP_TIME2 );
    p2 = NormalizeDouble( ObjectGet( HUD_CHANNEL_LINE_NAMES[i], OBJPROP_PRICE2 ) ,Digits );

    if( HUD_CHANNEL_LINE_DATA[i][T1] != t1 || HUD_CHANNEL_LINE_DATA[i][P1] != p1 || HUD_CHANNEL_LINE_DATA[i][T2] != t2 || HUD_CHANNEL_LINE_DATA[i][P2] != p2 ){
			
			HUD_SELF_HISTORY_GLOBAL_VAL = HUD_SELF_HISTORY_GLOBAL_VAL + 1.0;
			tmp = HUD_SELF_HISTORY_GLOBAL_VAL;
			
			ArrayResize( HUD_HISTORY_LINE_NAMES, tmp );
			ArrayResize( HUD_HISTORY_LINE_DATA, tmp );
			
			tmp = HUD_SELF_HISTORY_GLOBAL_VAL - 2.0;
			
			if( histroy_len == 0 ){
				HUD_HISTORY_LINE_NAMES[tmp][REDO] = "";
			}
			
			HUD_HISTORY_LINE_NAMES[tmp][UNDO] = HUD_CHANNEL_LINE_NAMES[i];
			HUD_HISTORY_LINE_DATA[tmp][UNDO][T1] = HUD_CHANNEL_LINE_DATA[i][T1];
			HUD_HISTORY_LINE_DATA[tmp][UNDO][P1] = HUD_CHANNEL_LINE_DATA[i][P1];
			HUD_HISTORY_LINE_DATA[tmp][UNDO][T2] = HUD_CHANNEL_LINE_DATA[i][T2];
			HUD_HISTORY_LINE_DATA[tmp][UNDO][P2] = HUD_CHANNEL_LINE_DATA[i][P2];

			tmp++;

			HUD_HISTORY_LINE_NAMES[tmp][UNDO] = "";
			HUD_HISTORY_LINE_NAMES[tmp][REDO] = HUD_CHANNEL_LINE_NAMES[i];
			HUD_HISTORY_LINE_DATA[tmp][REDO][T1] = t1;
			HUD_HISTORY_LINE_DATA[tmp][REDO][P1] = p1;
			HUD_HISTORY_LINE_DATA[tmp][REDO][T2] = t2;
			HUD_HISTORY_LINE_DATA[tmp][REDO][P2] = p2;
			has_change = true;
			// printArr();
		}
	}
	
	if( !has_change && histroy_len != 0){
		double real_history_global_val = GlobalVariableGet(HUD_HISTORY_GLOBAL_NAME);
		if( HUD_SELF_HISTORY_GLOBAL_VAL > real_history_global_val ){
			for( i = HUD_SELF_HISTORY_GLOBAL_VAL - 1; i >= real_history_global_val - 1; i-- ){
				ObjectSet( HUD_HISTORY_LINE_NAMES[i][UNDO], OBJPROP_TIME1, HUD_HISTORY_LINE_DATA[i][UNDO][T1]);
				ObjectSet( HUD_HISTORY_LINE_NAMES[i][UNDO], OBJPROP_PRICE1, HUD_HISTORY_LINE_DATA[i][UNDO][P1]);
				ObjectSet( HUD_HISTORY_LINE_NAMES[i][UNDO], OBJPROP_TIME2, HUD_HISTORY_LINE_DATA[i][UNDO][T2]);
				ObjectSet( HUD_HISTORY_LINE_NAMES[i][UNDO], OBJPROP_PRICE2, HUD_HISTORY_LINE_DATA[i][UNDO][P2]);
				HUD_SELF_HISTORY_GLOBAL_VAL = real_history_global_val;
			}
			// printArr();
			has_change = true;
		}else if( HUD_SELF_HISTORY_GLOBAL_VAL < real_history_global_val ){
			for( i = HUD_SELF_HISTORY_GLOBAL_VAL; i < real_history_global_val; i++ ){
				ObjectSet( HUD_HISTORY_LINE_NAMES[i][REDO], OBJPROP_TIME1, HUD_HISTORY_LINE_DATA[i][REDO][T1]);
				ObjectSet( HUD_HISTORY_LINE_NAMES[i][REDO], OBJPROP_PRICE1, HUD_HISTORY_LINE_DATA[i][REDO][P1]);
				ObjectSet( HUD_HISTORY_LINE_NAMES[i][REDO], OBJPROP_TIME2, HUD_HISTORY_LINE_DATA[i][REDO][T2]);
				ObjectSet( HUD_HISTORY_LINE_NAMES[i][REDO], OBJPROP_PRICE2, HUD_HISTORY_LINE_DATA[i][REDO][P2]);
				HUD_SELF_HISTORY_GLOBAL_VAL = real_history_global_val;
			}
			// printArr();
			has_change = true;
		}
	}
	
	tmp = getClineNr();
  if( ObjectFind("DT_GO_channel_trade_time_limit") == -1 ){
    tmp2 = 0.0;
  }else{
    tmp2 = ObjectGet( "DT_GO_channel_trade_time_limit", OBJPROP_TIME1 );
  }
	static double trade_time_limit_val = 0.0;
	static double cline_nr = 0;
	if( has_change || cline_nr != tmp || trade_time_limit_val != tmp2 ){
		cline_nr = tmp;
		trade_time_limit_val = tmp2;
		updateChannelArray();
		GlobalVariableSet( HUD_HISTORY_GLOBAL_NAME, HUD_SELF_HISTORY_GLOBAL_VAL );
		ObjectSetText( "DT_BO_hud_history",StringConcatenate( "Histrory: ", ArrayRange( HUD_HISTORY_LINE_NAMES, 0 ), "/", HUD_SELF_HISTORY_GLOBAL_VAL ),8,"Arial", Black );
	}
	
  // ====================== display trade arrows ======================
  if( GetTickCount() > HUD_TIMER1 ){
    HUD_TIMER1 = GetTickCount() + 6000;
    int ticket = getClineOpenPosition();
    if( ticket != 0 ){
      if( OrderType() > 1 ){
        int magic = OrderMagicNumber(), ot = OrderOpenTime(), idx = TimeMinute( ot );
        double op = NormalizeDouble( OrderOpenPrice(), Digits );
        string comment, op_arw = StringConcatenate( "DT_GO_CT_arw_op_", idx, "_", magic );
        if( ObjectFind(op_arw) != -1 ){
          if( NormalizeDouble( ObjectGet( op_arw, OBJPROP_PRICE1), Digits ) == op ){
            return (errorCheck("startHud"));
          }
        }else{
          comment = OrderComment(); 
          double fibo_100_time, fibo_100_val = StrToDouble(StringSubstr(comment, 18, StringLen(comment)-18));
          fibo_100_time = getF100time( fibo_100_val );
          if( fibo_100_time == 0.0 ){
            fibo_100_time = ot;
          }
          channelTradeArrow( StringConcatenate( "DT_GO_CT_arw_f100_", idx, "_", magic ), fibo_100_val, Black, fibo_100_time );
        }
        channelTradeArrow( op_arw, op, Blue, ot );
        channelTradeArrow( StringConcatenate( "DT_GO_CT_arw_tp_", idx, "_", magic ), OrderTakeProfit(), Red, ot );
        channelTradeArrow( StringConcatenate( "DT_GO_CT_arw_sl_", idx, "_", magic ), OrderStopLoss(), Green, ot );
      }
    }
  }
	return (errorCheck("startHud"));
}

int getClineNr(){
	int i, len = ObjectsTotal(), res = 0;
  for (i= len - 1; i>=0; i--) {
    if( StringSubstr( ObjectName(i), 7, 5 ) == "Line_" ){
			res++;
		}
	}
	return (res);
}

double getF100time( double price ){
  int i = 0;
  double time;
  for( ; i < 10; i++ ){
    if( getZigZag( PERIOD_M15, 12, 5, 3, i, time ) == price ){
      return ( time );
    }
  }
  return ( 0.0 );
}

bool deinitHud(){
  removeObjects("hud");
  removeObjects("w_hud");
  removeObjects("w0_hud");
  return (errorCheck("deinitHud"));
}

bool channelTradeArrow( string name, double p1, color c, double t1 = 0.0 ){
  if( ObjectFind( name ) == -1 ){
    ObjectCreate( name, OBJ_ARROW, 0, t1, p1 );
  }else{
    ObjectSet( name, OBJPROP_TIME1, t1 );
    ObjectSet( name, OBJPROP_PRICE1, p1 );
  }
	ObjectSet( name, OBJPROP_ARROWCODE, 5 );
	ObjectSet( name, OBJPROP_COLOR, c );
	ObjectSet( name, OBJPROP_BACK, false );
}

bool removeItemFromArray( string name ){
	int nr = 0, i, j = -1, len = ArrayRange( HUD_HISTORY_LINE_NAMES, 0 );
	for( i = 0; i < len; i++ ){
		if( HUD_HISTORY_LINE_NAMES[i][REDO] == name || HUD_HISTORY_LINE_NAMES[i][UNDO] == name ){
			if( j == -1){
				j = i;
			}
			if( HUD_SELF_HISTORY_GLOBAL_VAL > j ){
				HUD_SELF_HISTORY_GLOBAL_VAL = HUD_SELF_HISTORY_GLOBAL_VAL - 1.0;
			}
			nr++;
			continue;
		}
	
		if( j != -1 && j < len ){
			HUD_HISTORY_LINE_DATA[j][REDO][T1] = HUD_HISTORY_LINE_DATA[i][REDO][T1];
			HUD_HISTORY_LINE_DATA[j][REDO][P1] = HUD_HISTORY_LINE_DATA[i][REDO][P1];
			HUD_HISTORY_LINE_DATA[j][REDO][T2] = HUD_HISTORY_LINE_DATA[i][REDO][T2];
			HUD_HISTORY_LINE_DATA[j][REDO][P2] = HUD_HISTORY_LINE_DATA[i][REDO][P2];
			
			HUD_HISTORY_LINE_DATA[j][UNDO][T1] = HUD_HISTORY_LINE_DATA[i][UNDO][T1];
			HUD_HISTORY_LINE_DATA[j][UNDO][P1] = HUD_HISTORY_LINE_DATA[i][UNDO][P1];
			HUD_HISTORY_LINE_DATA[j][UNDO][T2] = HUD_HISTORY_LINE_DATA[i][UNDO][T2];
			HUD_HISTORY_LINE_DATA[j][UNDO][P2] = HUD_HISTORY_LINE_DATA[i][UNDO][P2];

			HUD_HISTORY_LINE_NAMES[j][REDO] = HUD_HISTORY_LINE_NAMES[i][REDO];
			HUD_HISTORY_LINE_NAMES[j][UNDO] = HUD_HISTORY_LINE_NAMES[i][UNDO];
			j++;
		}
	}

	if( j != -1 ){
		ArrayResize( HUD_HISTORY_LINE_NAMES, j );
		ArrayResize( HUD_HISTORY_LINE_DATA, j );
		errorCheck("removeItemFromArray");
		return (true);
	}else{
		errorCheck("removeItemFromArray");
		return (false);
	}
}

void updateChannelArray(){
	int j = 0, i, len, handle;
  string name, out = "";

  ArrayResize(HUD_CHANNEL_LINE_NAMES, 0);
  ArrayResize(HUD_CHANNEL_LINE_DATA, 0);

  len= ObjectsTotal();
  for (i= len - 1; i>=0; i--) {
    name = ObjectName(i);
    if( StringSubstr( name, 7, 5 ) == "Line_" ){
      ArrayResize( HUD_CHANNEL_LINE_NAMES, j + 1 );
      ArrayResize( HUD_CHANNEL_LINE_DATA, j + 1 );
      HUD_CHANNEL_LINE_NAMES[j] = name;

      HUD_CHANNEL_LINE_DATA[j][T1] = ObjectGet( name, OBJPROP_TIME1 );
      HUD_CHANNEL_LINE_DATA[j][P1] = NormalizeDouble( ObjectGet( name, OBJPROP_PRICE1 ) ,Digits );
      HUD_CHANNEL_LINE_DATA[j][T2] = ObjectGet( name, OBJPROP_TIME2 );
      HUD_CHANNEL_LINE_DATA[j][P2] = NormalizeDouble( ObjectGet( name, OBJPROP_PRICE2 ) ,Digits );
      
      if( getCLineProperty( name, "state" ) != "sig" ){
        out = StringConcatenate(out,name,";",DoubleToStr( HUD_CHANNEL_LINE_DATA[j][T1] ,0 ),";",DoubleToStr( HUD_CHANNEL_LINE_DATA[j][P1] ,Digits ),";",DoubleToStr( HUD_CHANNEL_LINE_DATA[j][T2] ,0 ),";",DoubleToStr( HUD_CHANNEL_LINE_DATA[j][P2] ,Digits ),";",ObjectGet( name, OBJPROP_COLOR ),";",ObjectType( name ),"\r\n");
      }
      j++;
    }
  }
  
  if( ObjectFind("DT_GO_channel_trade_time_limit") != -1 ){
    out = StringConcatenate(out,"DT_GO_channel_trade_time_limit;",DoubleToStr(ObjectGet("DT_GO_channel_trade_time_limit", OBJPROP_TIME1), 0 ),";0;0;0;",ObjectGet( "DT_GO_channel_trade_time_limit", OBJPROP_COLOR ),";",ObjectType( "DT_GO_channel_trade_time_limit" ),"\r\n");
  }
  
  handle = FileOpen( EXP_FILE_NAME, FILE_BIN|FILE_WRITE );
  if(handle > 0){
    FileWriteString( handle, out, StringLen(out) );
    FileClose( handle );
  }
  GlobalVariableSet( EXP_LAST_MOD_GV, TimeLocal() );
}

bool printArr(){
	int i, j = -1, len = ArrayRange( HUD_HISTORY_LINE_NAMES, 0 );
	string p = "";
	for( i = 0; i < len; i++ ){
		p = p + i + " REDO " + HUD_HISTORY_LINE_NAMES[i][REDO]+" "+HUD_HISTORY_LINE_DATA[i][REDO][T1]+" "+HUD_HISTORY_LINE_DATA[i][REDO][P1]+" "+HUD_HISTORY_LINE_DATA[i][REDO][T2]+" "+HUD_HISTORY_LINE_DATA[i][REDO][T2]+" \n";
		p = p + i + " UNDO " + HUD_HISTORY_LINE_NAMES[i][UNDO]+" "+HUD_HISTORY_LINE_DATA[i][UNDO][T1]+" "+HUD_HISTORY_LINE_DATA[i][UNDO][P1]+" "+HUD_HISTORY_LINE_DATA[i][UNDO][T2]+" "+HUD_HISTORY_LINE_DATA[i][UNDO][T2]+" \n";
	}
	Alert(p);
}

bool printRandomText(){
  string name, random_txt[] = {
    "  // constants",
    "  tshark_exe   = '\'C:\\Program Files\\Wireshark\\tshark.exe\'';",
    "  c_temp_dir   = 'C:\\Temp\\';",
    "  cap_file     = detectLstName() + postfix + '.cap';",
    " ",
    "  // determining capture type",
    "  capture_type = 'capture filter';",
    "  filter = strtrim(filter, TRIM_LEADING_SPACE|TRIM_TRAILING_SPACE);",
    " ",
    "  strfetch(detectLstName(),'1-5',fnnum);",
    "  logprint('UPRstartTshark(): log %s \n',fnnum);",
    " ",
    "  // connecting to 'wireshark_pc'",
    "  if (NOT deviceopen('wireshark_pc'))",
    "    logprint('HIT Analysis Verdict: FAILED, reason: UPRstartTshark(), deviceopen(\'wireshark_pc\') failed, tshark.exe was not started.\n');",
    "    return FALSE;",
    "  endif",
    " ",
    "  // get the prompt, as it does not always appear for some unknown reason",
    "  send('\r\n\r\n');",
    " ",
    "  // try if sending in a command works",
    "  tx('echo \'****** %s: UPRstartTshark() is starting tshark.exe for TC %s ******\'', getpctime(3), detectLstName());",
    " ",
    "  // starting the capturing",
    "  if (capture_type == 'capture filter')",
    "    if (filter == strtrim(WIRESHARK_FILTER, TRIM_LEADING_SPACE|TRIM_TRAILING_SPACE))",
    "      logprint('UPRstartTshark(): starting tshark.exe on Wireshark PC (using capture filter = WIRESHARK_FILTER)...\n');",
    "    else",
    "      logprint('UPRstartTshark(): starting tshark.exe on Wireshark PC (using capture filter = \'%s\')...\n', filter);",
    "    endif",
    " ",
    "    promptcheck(BEFORE);",
    " ",
    "    // this is the point!!!",
    "    tx_with_more(strprint('%s -i %s -f \'%s\' -w %s', tshark_exe, WIRESHARK_INTERFACE_ID, filter, c_temp_dir+cap_file));",
    "    promptcheck(BOTH);",
    " ",
    "    delay(1000);  // wait for the printout",
    "    if (getline(line, ''Capturing on ':1-13'))",   
  };
  int i, j, space, len = ArraySize(random_txt), cha;
  color c = Black;
  for( i = 0; i < len; i++ ){
    space = 0;
    for( j = 0; j < StringLen(random_txt[i]); j++ ){
      cha = StringGetChar(random_txt[i], j);
      if( cha == 32 || cha == 9 ){
        space++;
      }else if( cha == 47 ){  
        c = C'0,128,250';
        break;
      }else{
        c = Black;
        break;
      }
    }
    name = "DT_BO_w_hud_fade_txt_"+i;
    ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
    ObjectSet( name, OBJPROP_CORNER, 0 );
    ObjectSet( name, OBJPROP_XDISTANCE, ( space * 40 ) );
    ObjectSet( name, OBJPROP_YDISTANCE, 20 + ( i * 19 ) );
    ObjectSet( name, OBJPROP_BACK, false );
    ObjectSetText( name, StringTrimLeft(random_txt[i]), 10, "Lucida Console", c );
  }

}
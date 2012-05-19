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

double HUD_SPREAD_LIMIT;

double HUD_PRICE_MIN = 0.0, HUD_PRICE_MAX = 0.0;
int HUD_WIDTH;

string HUD_HISTORY_LINE_NAMES[];
double HUD_HISTORY_LINE_DATA[][4];

string HUD_CHANNEL_LINE_NAMES[];
double HUD_CHANNEL_LINE_DATA[][4];

string HUD_HISTORY_GLOBAL_NAME;
double HUD_SELF_HISTORY_GLOBAL_VAL;

bool initHud(){
	deinitHud();
	string sym = StringSubstr(Symbol(), 0, 6);
	int pos_x = ICONS_X_POS + ( (ICONS_RANGE + ICON_SIZE) * ICON_NR );

	// main info bar
	HUD_SPREAD_LIMIT = getMySpread() * MathPow( 10, Digits ) * 1.5;
	
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
	
	// channel_trade info bar
	if( ObjectFind("DT_BO_channel_trade_info") == -1 ){
    ObjectCreate( "DT_BO_channel_trade_info", OBJ_LABEL, 0, 0, 0 );
    ObjectSet( "DT_BO_channel_trade_info", OBJPROP_CORNER, 0 );
    ObjectSet( "DT_BO_channel_trade_info", OBJPROP_XDISTANCE, 800 );
    ObjectSet( "DT_BO_channel_trade_info", OBJPROP_YDISTANCE, 0 );
    ObjectSet( "DT_BO_channel_trade_info", OBJPROP_BACK, true);
    ObjectSetText( "DT_BO_channel_trade_info", "Channel Trade is OFF", 10, "Arial", DarkOrange );
  }
	
	// Scale info line
	int hWnd = WindowHandle(Symbol(), Period());
  int hDC = GetWindowDC(hWnd);
  int rect[4];
  GetWindowRect(hWnd, rect);
  HUD_WIDTH = rect[2] - rect[0] - 47; // Window width

  ObjectCreate( "DT_BO_hud_scale_info", OBJ_LABEL, 0, 0, 0 );
  ObjectSet( "DT_BO_hud_scale_info", OBJPROP_CORNER, 2 );
  ObjectSet( "DT_BO_hud_scale_info", OBJPROP_XDISTANCE, HUD_WIDTH - 2 );
  ObjectSet( "DT_BO_hud_scale_info", OBJPROP_YDISTANCE, 10 );

  ObjectCreate( "DT_BO_hud_scale_label", OBJ_LABEL, 0, 0, 0 );
  ObjectSet( "DT_BO_hud_scale_label", OBJPROP_CORNER, 3 );
  ObjectSet( "DT_BO_hud_scale_label", OBJPROP_XDISTANCE, 1 );
  ObjectSet( "DT_BO_hud_scale_label", OBJPROP_YDISTANCE, 60 );
  ObjectSet( "DT_BO_hud_scale_label", OBJPROP_ANGLE, 90 );
	
	// History info bar and data
	HUD_HISTORY_GLOBAL_NAME = StringConcatenate( sym,"_History");
  HUD_SELF_HISTORY_GLOBAL_VAL = 0.0;
  GlobalVariableSet( HUD_HISTORY_GLOBAL_NAME, 0.0 );
	
	ObjectCreate( "DT_BO_hud_history", OBJ_LABEL, 0, 0, 0 );
  ObjectSet( "DT_BO_hud_history", OBJPROP_CORNER, 0 );
  ObjectSet( "DT_BO_hud_history", OBJPROP_XDISTANCE, pos_x );
  ObjectSet( "DT_BO_hud_history", OBJPROP_YDISTANCE, 15 );

  int j = 0, i, len;
  string name;

  ArrayResize(HUD_CHANNEL_LINE_NAMES, 0);
  ArrayResize(HUD_CHANNEL_LINE_DATA, 0);

  len= ObjectsTotal();
  for (i= len - 1; i>=0; i--) {
    name = ObjectName(i);
    if( StringSubstr( name, 7, 6 ) == "_line_" ){

      ArrayResize( HUD_CHANNEL_LINE_NAMES, j + 1 );
      ArrayResize( HUD_CHANNEL_LINE_DATA, j + 1 );
      HUD_CHANNEL_LINE_NAMES[j] = name;

      HUD_CHANNEL_LINE_DATA[j][T1] = ObjectGet( name, OBJPROP_TIME1 );
      HUD_CHANNEL_LINE_DATA[j][P1] = NormalizeDouble( ObjectGet( name, OBJPROP_PRICE1 ) ,Digits );
      HUD_CHANNEL_LINE_DATA[j][T2] = ObjectGet( name, OBJPROP_TIME2 );
      HUD_CHANNEL_LINE_DATA[j][P2] = NormalizeDouble( ObjectGet( name, OBJPROP_PRICE2 ) ,Digits );

      j++;

    }
  }

	return (errorCheck("initHud"));
}

bool startHud(){
	if(delayTimer(APP_ID_HUD, 1500)){return (false);}

	// main info bar
  double spread = MarketInfo( Symbol(), MODE_SPREAD );
  color c = Blue;
  if( spread > HUD_SPREAD_LIMIT ){
    c = Red;
  }
	ObjectSetText( "DT_BO_hud_spread",StringConcatenate( "Spread: ",DoubleToStr(spread,0) ),8,"Arial",c );
	
	// channel_trade info bar
	if( IsExpertEnabled() ){
    if( ObjectFind("DT_GO_channel_trade_time_limit") == -1 ){
      ObjectSetText( "DT_BO_channel_trade_info", "Channel Trade is ON", 10, "Arial", LimeGreen );
    }else{
      if( ObjectGet( "DT_GO_channel_trade_time_limit", OBJPROP_TIME1 ) < iTime( NULL, PERIOD_M1, 0) ){
        ObjectSetText( "DT_BO_channel_trade_info", "Channel Trade Stopped!", 10, "Arial", Red );
      }else{
        ObjectSetText( "DT_BO_channel_trade_info", "Channel Trade is ON", 10, "Arial", LimeGreen );
      }
    }
  }else{
    ObjectSetText( "DT_BO_channel_trade_info", "Channel Trade is OFF", 10, "Arial", Black );
  }
	
	// Scale info line
  if( HUD_PRICE_MIN != WindowPriceMin(0) || HUD_PRICE_MAX != WindowPriceMax(0)){
    HUD_PRICE_MIN = WindowPriceMin(0);
    HUD_PRICE_MAX = WindowPriceMax(0);
		
		int scale = (((HUD_PRICE_MAX-HUD_PRICE_MIN)/Point) * MarketInfo(Symbol(),MODE_TICKVALUE))/30;
    ObjectSetText( "DT_BO_hud_scale_info", "g", scale, "Webdings", Black );
    ObjectSetText( "DT_BO_hud_scale_label", scale+"", 7, "Microsoft Sans Serif", Black );
  }
	
	// History info bar
	int tmp, i, histroy_len = ArraySize(HUD_HISTORY_LINE_NAMES), c_line_len = ArraySize(HUD_CHANNEL_LINE_DATA);
  double real_history_global_val = GlobalVariableGet(HUD_HISTORY_GLOBAL_NAME);
  if( real_history_global_val > histroy_len ){
    real_history_global_val = histroy_len;
  }
	
	ObjectSetText( "DT_BO_hud_history",StringConcatenate( "Histrory: ", histroy_len, "/", real_history_global_val ),8,"Arial", Black );
	
}

bool deinitHud(){
  removeObjects("hud");
  return (errorCheck("deinitHud"));
}
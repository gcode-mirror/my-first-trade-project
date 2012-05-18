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

double HUD_PRICE_MIN = 0, HUD_PRICE_MAX = 0;
int HUD_WIDTH;

string HUD_HISTORY_LINE_NAMES[];
double HUD_HISTORY_LINE_DATA[][4];

string HUD_CHANNEL_LINE_NAMES[];
double HUD_CHANNEL_LINE_DATA[][4];

string HUD_HISTORY_GLOBAL_NAME;
double HUD_SELF_HISTORY_GLOBAL_VAL;

bool initHud(){
  if(deinitHud()){}
  ObjectCreate("DT_BO_hud_spread", OBJ_LABEL, 0, 0, 0);
  ObjectSet("DT_BO_hud_spread", OBJPROP_CORNER, 0);
  ObjectSet("DT_BO_hud_spread", OBJPROP_XDISTANCE, 272);
  ObjectSet("DT_BO_hud_spread", OBJPROP_YDISTANCE, 28);

  ObjectCreate("DT_BO_hud_info", OBJ_LABEL, 0, 0, 0);
  ObjectSet("DT_BO_hud_info", OBJPROP_CORNER, 0);
  ObjectSet("DT_BO_hud_info", OBJPROP_XDISTANCE, 3);
  ObjectSet("DT_BO_hud_info", OBJPROP_YDISTANCE, 28);

  if( ObjectFind("DT_BO_channel_trade_info") == -1 ){
    ObjectCreate( "DT_BO_channel_trade_info", OBJ_LABEL, 0, 0, 0 );
    ObjectSet( "DT_BO_channel_trade_info", OBJPROP_CORNER, 0 );
    ObjectSet( "DT_BO_channel_trade_info", OBJPROP_XDISTANCE, 800 );
    ObjectSet( "DT_BO_channel_trade_info", OBJPROP_YDISTANCE, 0 );
    ObjectSet( "DT_BO_channel_trade_info", OBJPROP_BACK, true);
    ObjectSetText( "DT_BO_channel_trade_info", "Channel Trade is OFF", 10, "Arial", DarkOrange );
  }

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

  HUD_HISTORY_GLOBAL_NAME = StringConcatenate( StringSubstr(Symbol(), 0, 6),"_History");
  HUD_SELF_HISTORY_GLOBAL_VAL = 0.0;
  GlobalVariableSet( HUD_HISTORY_GLOBAL_NAME, 0.0 );

  int j = 1, i, len;
  string name;

  ArrayResize(HUD_CHANNEL_LINE_NAMES, 0);
  ArrayResize(HUD_CHANNEL_LINE_DATA, 0);

  len= ObjectsTotal();
  for (i= len - 1; i>=0; i--) {
    name = ObjectName(i);
    if( StringSubstr( name, 7, 6 ) == "_line_" ){

      ArrayResize( HUD_CHANNEL_LINE_NAMES, j );
      ArrayResize( HUD_CHANNEL_LINE_DATA, j );
      HUD_CHANNEL_LINE_NAMES[j-1] = name;

      HUD_CHANNEL_LINE_DATA[j-1][T1] = ObjectGet( name, OBJPROP_TIME1 );
      HUD_CHANNEL_LINE_DATA[j-1][P1] = NormalizeDouble( ObjectGet( name, OBJPROP_PRICE1 ) ,Digits );
      HUD_CHANNEL_LINE_DATA[j-1][T2] = ObjectGet( name, OBJPROP_TIME2 );
      HUD_CHANNEL_LINE_DATA[j-1][P2] = NormalizeDouble( ObjectGet( name, OBJPROP_PRICE2 ) ,Digits );

      j++;

    }
  }

	double lot = StrToDouble(getGlobal("LOT"));
  ObjectSetText("DT_BO_hud_info",StringConcatenate(StringSubstr(Symbol(), 0, 6)," | ",getPeriodName( Period() )," | Swap (L: "+DoubleToStr((MarketInfo(Symbol(),MODE_SWAPLONG)*lot),2)," / S: ",DoubleToStr((MarketInfo(Symbol(),MODE_SWAPSHORT)*lot),2),") | Lot: ",DoubleToStr(lot, 2)," |"),8,"Arial",Blue);

  return (errorCheck("initHud"));
}

bool startHud(){
	if(delayTimer(APP_ID_HUD, 1500)){return (false);}

  double spread = MarketInfo(Symbol(),MODE_SPREAD);
  color c = Blue;
  if(spread > 20){
    c = Red;
  }

  int tmp, i, histroy_len = ArraySize(HUD_HISTORY_LINE_NAMES), c_line_len = ArraySize(HUD_CHANNEL_LINE_DATA);
  double real_history_global_val = GlobalVariableGet(HUD_HISTORY_GLOBAL_NAME);
  if( real_history_global_val > histroy_len ){
    real_history_global_val = histroy_len;
  }
  

  ObjectSetText("DT_BO_hud_spread",StringConcatenate( "Spread: ",DoubleToStr(spread,0), " | Histrory: ", histroy_len, "/", real_history_global_val ),8,"Arial",c);

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

  int scale = (((WindowPriceMax(0)-WindowPriceMin(0))/Point)*MarketInfo(Symbol(),MODE_TICKVALUE))/30;

  if( HUD_PRICE_MIN != WindowPriceMin(0) || HUD_PRICE_MAX != WindowPriceMax(0)){
    HUD_PRICE_MIN = WindowPriceMin(0);
    HUD_PRICE_MAX = WindowPriceMax(0);
    ObjectSetText( "DT_BO_hud_scale_info", "g", scale, "Webdings", Black );
    ObjectSetText( "DT_BO_hud_scale_label", scale+"", 7, "Microsoft Sans Serif", Black );
  }

  double t1, p1, t2, p2;
  for( i = 0; i < c_line_len; i++ ){
    t1 = ObjectGet( HUD_CHANNEL_LINE_NAMES[i], OBJPROP_TIME1 );
    p1 = NormalizeDouble( ObjectGet( HUD_CHANNEL_LINE_NAMES[i], OBJPROP_PRICE1 ) ,Digits );
    t2 = ObjectGet( HUD_CHANNEL_LINE_NAMES[i], OBJPROP_TIME2 );
    p2 = NormalizeDouble( ObjectGet( HUD_CHANNEL_LINE_NAMES[i], OBJPROP_PRICE2 ) ,Digits );
    
    if( HUD_CHANNEL_LINE_DATA[i][T1] != t1 || HUD_CHANNEL_LINE_DATA[i][P1] != p1 || HUD_CHANNEL_LINE_DATA[i][T2] != t2 || HUD_CHANNEL_LINE_DATA[i][T2] != p2 ){
      if( histroy_len == 0 ){
        ArrayResize( HUD_HISTORY_LINE_NAMES, 2 );
        ArrayResize( HUD_HISTORY_LINE_DATA, 2 );
        
        HUD_HISTORY_LINE_NAMES[0] = HUD_CHANNEL_LINE_NAMES[i];
        HUD_HISTORY_LINE_DATA[0][T1] = HUD_CHANNEL_LINE_DATA[i][T1];
        HUD_HISTORY_LINE_DATA[0][P1] = HUD_CHANNEL_LINE_DATA[i][P1];
        HUD_HISTORY_LINE_DATA[0][T2] = HUD_CHANNEL_LINE_DATA[i][T2];
        HUD_HISTORY_LINE_DATA[0][P2] = HUD_CHANNEL_LINE_DATA[i][P2];
        
        HUD_HISTORY_LINE_NAMES[1] = HUD_CHANNEL_LINE_NAMES[i];
        HUD_HISTORY_LINE_DATA[1][T1] = t1;
        HUD_HISTORY_LINE_DATA[1][P1] = p1;
        HUD_HISTORY_LINE_DATA[1][T2] = t2;
        HUD_HISTORY_LINE_DATA[1][P2] = p2;
        
        HUD_SELF_HISTORY_GLOBAL_VAL = 2.0;
        GlobalVariableSet( HUD_HISTORY_GLOBAL_NAME, 2.0 );
                                    
      }else{
        ArrayResize( HUD_HISTORY_LINE_NAMES, HUD_SELF_HISTORY_GLOBAL_VAL + 1 );
        ArrayResize( HUD_HISTORY_LINE_DATA, HUD_SELF_HISTORY_GLOBAL_VAL + 1 );
        
        tmp = HUD_SELF_HISTORY_GLOBAL_VAL;
        HUD_HISTORY_LINE_NAMES[tmp] = HUD_CHANNEL_LINE_NAMES[i];
        HUD_HISTORY_LINE_DATA[tmp][T1] = t1;
        HUD_HISTORY_LINE_DATA[tmp][P1] = p1;
        HUD_HISTORY_LINE_DATA[tmp][T2] = t2;
        HUD_HISTORY_LINE_DATA[tmp][P2] = p2;
        
        HUD_SELF_HISTORY_GLOBAL_VAL++;
        GlobalVariableSet( HUD_HISTORY_GLOBAL_NAME, HUD_SELF_HISTORY_GLOBAL_VAL );
      }
      break;
      
    }
  }
      
  if( histroy_len == 0 ){
    return (errorCheck("startHud"));
  }

  if( HUD_SELF_HISTORY_GLOBAL_VAL != real_history_global_val ){
    tmp = real_history_global_val -1;
    ObjectSet( HUD_HISTORY_LINE_NAMES[tmp], OBJPROP_TIME1, HUD_HISTORY_LINE_DATA[tmp][T1]);
    ObjectSet( HUD_HISTORY_LINE_NAMES[tmp], OBJPROP_PRICE1, HUD_HISTORY_LINE_DATA[tmp][P1]);
    ObjectSet( HUD_HISTORY_LINE_NAMES[tmp], OBJPROP_TIME1, HUD_HISTORY_LINE_DATA[tmp][T2]);
    ObjectSet( HUD_HISTORY_LINE_NAMES[tmp], OBJPROP_PRICE2, HUD_HISTORY_LINE_DATA[tmp][P2]);
  }

  // GetLastError();
  return (errorCheck("startHud"));
}

bool deinitHud(){
  removeObjects("hud");
  return (errorCheck("deinitHud"));
}

bool setChannelLinePosFromHistory( int i ){
  ObjectSet( HUD_HISTORY_LINE_NAMES[i], OBJPROP_TIME1, HUD_HISTORY_LINE_DATA[i][T1]);
  ObjectSet( HUD_HISTORY_LINE_NAMES[i], OBJPROP_PRICE1, HUD_HISTORY_LINE_DATA[i][P1]);
  ObjectSet( HUD_HISTORY_LINE_NAMES[i], OBJPROP_TIME1, HUD_HISTORY_LINE_DATA[i][T2]);
  ObjectSet( HUD_HISTORY_LINE_NAMES[i], OBJPROP_PRICE2, HUD_HISTORY_LINE_DATA[i][P2]);
}

//+------------------------------------------------------------------+
//|                                                       DT_hud.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

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
  
	updateHud();
	
  return (errorCheck("initHud"));
}

bool startHud(){
	if(delayTimer(APP_ID_HUD, 1500)){return (false);}
  double spread = MarketInfo(Symbol(),MODE_SPREAD);
  color c = Blue;
  if(spread > 20){
    c = Red;
  }
	
  ObjectSetText("DT_BO_hud_spread",StringConcatenate("Spread: ",DoubleToStr(spread,0)),8,"Arial",c);  
  
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
  // GetLastError(); 
  return (errorCheck("startHud"));  
}

bool deinitHud(){
  removeObjects("hud");
  return (errorCheck("deinitHud"));
}

bool updateHud(){
	double lot = StrToDouble(getGlobal("LOT"));
  ObjectSetText("DT_BO_hud_info",StringConcatenate(StringSubstr(Symbol(), 0, 6)," | ",getPeriodName( Period() )," | Swap (L: "+DoubleToStr((MarketInfo(Symbol(),MODE_SWAPLONG)*lot),2)," / S: ",DoubleToStr((MarketInfo(Symbol(),MODE_SWAPSHORT)*lot),2),") | Lot: ",DoubleToStr(lot, 2)," |"),8,"Arial",Blue);
}

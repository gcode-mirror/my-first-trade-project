//+------------------------------------------------------------------+
//|                                                       DT_hud.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

bool initHud(){
  deinitHud();
  ObjectCreate("DT_BO_hud_spread", OBJ_LABEL, 0, 0, 0);
  ObjectSet("DT_BO_hud_spread", OBJPROP_CORNER, 0);
  ObjectSet("DT_BO_hud_spread", OBJPROP_XDISTANCE, 272);
  ObjectSet("DT_BO_hud_spread", OBJPROP_YDISTANCE, 28);
  
  ObjectCreate("DT_BO_hud_info", OBJ_LABEL, 0, 0, 0);
  ObjectSet("DT_BO_hud_info", OBJPROP_CORNER, 0);
  ObjectSet("DT_BO_hud_info", OBJPROP_XDISTANCE, 3);
  ObjectSet("DT_BO_hud_info", OBJPROP_YDISTANCE, 28);
  
	updateHud();
	
  return (errorCheck("initHud"));
}

bool startHud(){
	if(delayTimer(APP_ID_HUD, 1000)){return (false);}
  double spread = MarketInfo(Symbol(),MODE_SPREAD);
  color c = Blue;
  if(spread > 20){
    c = Red;
  }
	
  ObjectSetText("DT_BO_hud_spread",StringConcatenate("Spread: ",DoubleToStr(spread,0)),8,"Arial",c);  
  return (errorCheck("startHud"));  
}

bool deinitHud(){
  removeObjects("hud");
  return (errorCheck("deinitHud"));
}

bool updateHud(){
	double lot = StrToDouble(getGlobal("LOT"));
  ObjectSetText("DT_BO_hud_info",StringConcatenate(getSymbolShort(Symbol())," | ",getPeriodName()," | Swap (L: "+DoubleToStr((MarketInfo(Symbol(),MODE_SWAPLONG)*lot),2)," / S: ",DoubleToStr((MarketInfo(Symbol(),MODE_SWAPSHORT)*lot),2),") | Lot: ",DoubleToStr(lot, 2)," |"),8,"Arial",Blue);
}

string getPeriodName(){
  switch(Period()){
    case 1: return ("Min 1 ");
    case 5: return ("Min 5 ");
    case 15: return ("Min 15");
    case 30: return ("Min 30");
    case 60: return ("Hour 1");
    case 240: return ("Hour 4");
    case 1440: return ("Daily ");
    case 10080: return ("Weekly");
    case 43200: return ("Month ");
    default: return ("error");
  }
}
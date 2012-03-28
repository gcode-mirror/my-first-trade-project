//+------------------------------------------------------------------+
//|                                                  DT_boundary.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

double BOUNDARY_TOP, BOUNDARY_BOTTOM;

bool initBoundary(string isOn){
  setAppStatus(APP_ID_BOUNDARY, isOn);
  if(isOn == "0"){    
    return (false);
  }
  if(ObjectFind("DT_GO_Boundary_Bottom") == -1){
    int bar_nr = WindowBarsPerChart()/4*3; 
    BOUNDARY_TOP = High[iHighest(NULL, 0, MODE_HIGH, bar_nr, 0)];
    BOUNDARY_BOTTOM = Low[iLowest(NULL, 0, MODE_LOW, bar_nr, 0)];
    
    ObjectCreate("DT_GO_Boundary_Top", OBJ_HLINE, 0, 0, BOUNDARY_TOP);
    ObjectSet("DT_GO_Boundary_Top", OBJPROP_STYLE, STYLE_DASH);
    ObjectSet("DT_GO_Boundary_Top", OBJPROP_COLOR, LightSkyBlue);
    
    ObjectCreate("DT_GO_Boundary_Bottom", OBJ_HLINE, 0, 0, BOUNDARY_BOTTOM);
    ObjectSet("DT_GO_Boundary_Bottom", OBJPROP_STYLE, STYLE_DASH);    
    ObjectSet("DT_GO_Boundary_Bottom", OBJPROP_COLOR, LightCoral);
    
    
  }else{
    BOUNDARY_TOP = ObjectGet("DT_GO_Boundary_Top",OBJPROP_PRICE1);
    BOUNDARY_BOTTOM = ObjectGet("DT_GO_Boundary_Bottom",OBJPROP_PRICE1);
  }
  
  string sym = StringSubstr(Symbol(), 0, 6);
  GlobalVariableSet(StringConcatenate(sym,"_Boundary_Top"),BOUNDARY_TOP);
  GlobalVariableSet(StringConcatenate(sym,"_Boundary_Bottom"),BOUNDARY_BOTTOM);
  
  return (errorCheck("initBoundary"));
}

bool startBoundary(string isOn){
  if(isAppStatusChanged(APP_ID_BOUNDARY, isOn)){
    if(isOn == "1"){
      initBoundary("1");
    }else{
      deInitBoundary();
      return (false);
    }    
  }
  
  if(isOn == "0"){return (false);}
	if(delayTimer(APP_ID_BOUNDARY, 2000)){return (false);}
  
  double top = ObjectGet("DT_GO_Boundary_Top",OBJPROP_PRICE1);
	double bottom = ObjectGet("DT_GO_Boundary_Bottom",OBJPROP_PRICE1);
  if(top != BOUNDARY_TOP || bottom != BOUNDARY_BOTTOM){
    BOUNDARY_TOP = top;
    BOUNDARY_BOTTOM = bottom;
    
    string sym = StringSubstr(Symbol(), 0, 6);
    GlobalVariableSet(StringConcatenate(sym,"_Boundary_Top"),top);
    GlobalVariableSet(StringConcatenate(sym,"_Boundary_Bottom"),bottom);
  }
  
  return (errorCheck("startBoundary"));
}

bool deInitBoundary(){
  removeObjects("Boundary", "GO");
  string sym = StringSubstr(Symbol(), 0, 6), name;
  name = StringConcatenate(sym,"_Boundary_Top");
  if(GlobalVariableCheck(name)){
    GlobalVariableDel(name);
  }
  name = StringConcatenate(sym,"_Boundary_Bottom");
  if(GlobalVariableCheck(name)){
    GlobalVariableDel(name);
  }
  return (errorCheck("deInitBoundary"));
}
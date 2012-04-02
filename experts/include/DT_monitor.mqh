//+------------------------------------------------------------------+
//|                                                   DT_monitor.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

double MON_CURR_VAL[USED_SYM];

bool initMonitor(string isOn){
  setAppStatus(APP_ID_MONITOR, isOn);
  if(isOn == "0"){    
    return (false);
  }
  for(int i=0; i<USED_SYM; i++){
    MON_CURR_VAL[i] = -1.0;
  }
  return (errorCheck("initMonitor"));
}

bool startMonitor(string isOn){
  if(isOn == "0"){return (false);}
	if(delayTimer(APP_ID_MONITOR, 4000)){return (false);}

  int i, profit = 0, has_profit = 0;
  string name, out = "";
  double val;
  bool has_change = false;
  
  for(i=0; i<USED_SYM; i++){
    val = 0.0;
    name = StringConcatenate(SYMBOLS[i],"_Channel");
    if(GlobalVariableCheck(name)){
      val = GlobalVariableGet(name);
      if(MON_CURR_VAL[i] != val){
        MON_CURR_VAL[i] = val;
        has_change = true;
      }
    }
    out = StringConcatenate(out, SYMBOLS[i], ";", DoubleToStr(val,0), ";\r\n");
  }
  
  for (i = 0; i < OrdersTotal(); i++) {
    if (OrderSelect(i, SELECT_BY_POS)) {    
      if(OrderType()<2){
        profit = profit + OrderProfit();
        has_profit = 1;
      }
    }
  }  
  
  if( has_profit == 1 ){
    out = StringConcatenate(out, has_profit, ";", profit, ";\r\n");
  }
  
  if(has_change || has_profit == 1){
    int handle;   
    handle=FileOpen("notify.bin", FILE_BIN|FILE_WRITE);
      if(handle<1){
       errorCheck("startMonitor (open file)");
       return(0);
      }
    FileWriteString(handle, out, StringLen(out));
    FileClose(handle);
  }
  
  return (errorCheck("startMonitor"));
}
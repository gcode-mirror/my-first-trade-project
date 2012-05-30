//+------------------------------------------------------------------+
//|                                                   DT_channel.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

double CH_OFFSET = 0.0;
string CH_NAME;

bool initChannel(string isOn){
  setAppStatus(APP_ID_CHANNEL, isOn);
  if(isOn == "0"){    
    return (false);
  }
  CH_OFFSET = 60/MarketInfo(Symbol(),MODE_TICKVALUE)*Point;
  CH_NAME = StringConcatenate(StringSubstr(Symbol(), 0, 6),"_Channel");
  GlobalVariableSet(CH_NAME, 0.0);
  
  return (errorCheck("initChannel"));
}

bool startChannel(string isOn){
  if(isAppStatusChanged(APP_ID_CHANNEL, isOn)){
    if(isOn == "1"){
      initChannel("1");
    }else{
      deInitChannel();
      return (false);
    }    
  }
  
  if(isOn == "0"){return (false);}
	if(delayTimer(APP_ID_CHANNEL, 4000)){return (false);}
  
  int j, obj_total= ObjectsTotal();
  string type, name;
  double price, ts;
  
  if( ObjectFind("DT_GO_channel_trade_time_limit") != -1 ){
    if( ObjectGet( "DT_GO_channel_trade_time_limit", OBJPROP_TIME1 ) < iTime( NULL, PERIOD_M1, 0) ){
      if( GlobalVariableGet(CH_NAME) != 0.0){
        GlobalVariableSet(CH_NAME, 0.0);
      }
      return (errorCheck("startChannel"));
    }  
  }
  
  for (j= obj_total-1; j>=0; j--) {
    name = ObjectName(j);
    if( StringSubstr( name, 5, 7 ) == "_cLine_" ){
      price = getClineValueByShift( name ); 
      if( price != 0.0 ){
        if( Bid > price - CH_OFFSET && Bid < price + CH_OFFSET ){
          ts = StrToDouble(StringSubstr(name, StringLen(name)-10, 10));
          if( GlobalVariableGet(CH_NAME) != ts ){
            GlobalVariableSet(CH_NAME, ts);
          }
          return (errorCheck("startChannel"));
        }      
      }else{
        GetLastError();
      }
    }
  }
  if( GlobalVariableGet(CH_NAME) != 0.0){
    GlobalVariableSet(CH_NAME, 0.0);
  }
  return (errorCheck("startChannel"));
}

bool deInitChannel(){
  if(GlobalVariableCheck(CH_NAME)){
    GlobalVariableDel(CH_NAME);
  }
  return (errorCheck("deInitChannel"));
}
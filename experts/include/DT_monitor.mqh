//+------------------------------------------------------------------+
//|                                                   DT_monitor.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

bool initMonitor(string isOn){
  setAppStatus(APP_ID_MONITOR, isOn);
  if(isOn == "0"){    
    return (false);
  }
  return (errorCheck("initMonitor"));
}

bool startMonitor(string isOn){
  if(isOn == "0"){return (false);}
	if(delayTimer(APP_ID_MONITOR, 5000)){return (false);}
  
  int i, j, len;
  string symb, name, out = "", profit_txt, log_nr = "0";
  double p, line, dif, profit_sum = 0.0, profit[USED_SYM];
  ArrayInitialize( profit, 0.001 );
  
  len = OrdersTotal();
  for( j = 0; j < len; j++ ){
    if( OrderSelect( j, SELECT_BY_POS) ){
      if( OrderMagicNumber() > 1000 ){
        symb = OrderSymbol();
        for( i = 0; i < USED_SYM; i++ ){
          if( SYMBOLS_STR[i] == symb ){
            p = OrderProfit();
            profit_sum = profit_sum + p;
            if( profit[i] == 0.001 ){
              profit[i] = p;
            }else{
              profit[i] = profit[i] + p;
            }
          }
        }
      }
    }
  }
  
  for( i = 0; i < USED_SYM; i++ ){
    name = StringConcatenate( SYMBOLS[i], "_Channel" );
    if( GlobalVariableCheck(name) ){
      line = GlobalVariableGet(name);
      
      dif = ( (MarketInfo( SYMBOLS_STR[i], MODE_BID ) - iClose( SYMBOLS_STR[i], PERIOD_D1, 1 ))  / MarketInfo( SYMBOLS_STR[i], MODE_POINT ) ) * MarketInfo( SYMBOLS_STR[i], MODE_TICKVALUE ) * 0.1;
      
      if( profit[i] == 0.001 ){
        profit_txt = "-";
      }else{
        profit_txt = DoubleToStr( profit[i], 0 );
      }
      
      out = StringConcatenate( out, SYMBOLS[i], ";", DoubleToStr( line, 0 ), ";", DoubleToStr( dif, 0 ), ";", profit_txt, ";\r\n" );
    }
  }
  
  if( GlobalVariableCheck( "CT_NR_OF_LOGS" ) ){
    log_nr = DoubleToStr( GlobalVariableGet( "CT_NR_OF_LOGS" ), 0 );
  }
  
  out = StringConcatenate( out, log_nr, ";", DoubleToStr( profit_sum, 0 ), ";\r\n" );
  
  int handle;   
  handle=FileOpen("notify.bin", FILE_BIN|FILE_WRITE);
    if(handle<1){
     errorCheck("startMonitor (open file)");
     return(0);
    }
  FileWriteString(handle, out, StringLen(out));
  FileClose(handle);
  
  return (errorCheck("startMonitor"));
}
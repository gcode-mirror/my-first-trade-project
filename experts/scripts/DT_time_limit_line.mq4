//+------------------------------------------------------------------+
//|                                           DT_time_limit_line.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  double tod = WindowTimeOnDropped();
  
  if( tod == 0.0 ){
    tod = Time[0] + (Period()*60);
  }
  
  if( ObjectFind( "DT_GO_channel_trade_time_limit" ) == -1 ){
    ObjectCreate( "DT_GO_channel_trade_time_limit", OBJ_VLINE, 0, tod, 0 );
    ObjectSet( "DT_GO_channel_trade_time_limit", OBJPROP_COLOR, Peru );
    ObjectSet( "DT_GO_channel_trade_time_limit", OBJPROP_BACK, true );
    ObjectSet( "DT_GO_channel_trade_time_limit", OBJPROP_WIDTH, 2 );
  }else{
    ObjectDelete( "DT_GO_channel_trade_time_limit" );
  }
  return(0);
}
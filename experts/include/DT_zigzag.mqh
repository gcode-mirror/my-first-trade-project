//+------------------------------------------------------------------+
//|                                                    DT_zigzag.mqh |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#define ZZ_DEPTH 12
#define ZZ_DEVIATION 5
#define ZZ_BACKSTEP 3

void startZigZag( string isOn ){
	if( isAppStatusChanged( APP_ID_ZIGZAG, isOn ) ){
    if( isVisibleThisTimeframe( isOn ) == "0" ){
      deinitZigZag();
      return (false);
    }    
  }
	
	if( delayTimer( APP_ID_ZIGZAG, 2000 )) { return (false); }
	if( isVisibleThisTimeframe( isOn ) == "0" ){return (false);}
	
	int len = WindowFirstVisibleBar(), peri = Period();
	string sym = Symbol();
	for( int i = 0; i < len; i++ ){
		ZIGZAG_BUF_1[i] = iCustom( sym, peri, "ZigZag", ZZ_DEPTH, ZZ_DEVIATION, ZZ_BACKSTEP, 0, i );
	}
	
}

void deinitZigZag(){
	ArrayInitialize( ZIGZAG_BUF_1, 0.0 ) ;
}

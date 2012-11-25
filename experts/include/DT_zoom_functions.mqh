//+------------------------------------------------------------------+
//|                                            DT_zoom_functions.mqh |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#import "user32.dll"
   bool     GetCursorPos(int& Pos[2]);
	 bool GetWindowRect(int h, int& pos[4]);
	 void keybd_event(int bVk,int bScan,int dwFlags,int dwExtraInfo);
#import

int PERIOD_DATA[9][2] = {
	1,      33137,
	5,      33138,
	15,     33139,
	30,     33140,
	60,     35400,
	240,    33136,
	1440,   33134,
	10080,  33141,
	43200,  33334
};

int getShiftOverCursor(){
	int CursorPoint[2];
	GetCursorPos(CursorPoint);
	
	int WindowDims[4];
	GetWindowRect( WindowHandle( Symbol(), Period() ), WindowDims );
	int window_width = WindowDims[2] - WindowDims[0] - 47;
	double tmp = CursorPoint[0] - WindowDims[0] - 5;
	
	return ( WindowFirstVisibleBar() - MathRound( WindowBarsPerChart() * ( tmp / window_width ) ) );
}

int getPrevPeriKeyID( int peri, int& aim_peri ){
	for( int i = 1; i < ArrayRange( PERIOD_DATA, 0 ); i++ ){
		if( peri == PERIOD_DATA[i][0] ){
			aim_peri = PERIOD_DATA[i - 1][1];
			return ( PERIOD_DATA[i - 1][1] );
		}
	}
	return (-1);
}

int getNextPeriKeyID( int peri, int& aim_peri ){
	for( int i = 0; i < ArrayRange( PERIOD_DATA, 0 ) - 1; i++ ){
		if( peri == PERIOD_DATA[i][0] ){
			aim_peri = PERIOD_DATA[i + 1][1];
			return ( PERIOD_DATA[i + 1][1] );
		}
	}
	return (-1);
}

void createZoomIndicator( double t1 ){
	double p1 = WindowPriceMin() + ((WindowPriceMax() - WindowPriceMin()) / 2); 
	if(ObjectFind( "DT_GO_zoom_indicator" ) == -1 ){
		ObjectCreate( "DT_GO_zoom_indicator", OBJ_TEXT, 0, t1, p1 );
		ObjectSetText( "DT_GO_zoom_indicator", ">>>>>>>>>>>>  o  <<<<<<<<<<<<", 12, "Verdana", DarkBlue );
		ObjectSet( "DT_GO_zoom_indicator", OBJPROP_ANGLE, 90 );
	}else{
		ObjectSet( "DT_GO_zoom_indicator", OBJPROP_TIME1, t1 );
    ObjectSet( "DT_GO_zoom_indicator", OBJPROP_PRICE1, p1 );
	}
}
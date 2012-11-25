//+------------------------------------------------------------------+
//|                                                   zoom_in_DT.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_zoom_functions.mqh>
#include <WinUser32.mqh>

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
	if( ObjectFind( "DT_GO_RULER_SWITCH" ) != -1 ){
		int aim_peri;
		int peri_key_id = getPrevPeriKeyID( Period(), aim_peri );
		if( peri_key_id != -1 ){
			double t1 = Time[getShiftOverCursor()];
			if( iBars( NULL, aim_peri ) - 1 == iBarShift( NULL, aim_peri, t1 ) ){
				if( MessageBox( "Time over cursor is out of aim chart but change?", "Period change?", MB_YESNO|MB_ICONQUESTION ) == IDYES ){
					t1 = Time[Bars - 1];
				}else{
					return(0);
				}
			}
			createZoomIndicator( t1 );
			return( PostMessageA( WindowHandle( Symbol(), Period() ), WM_COMMAND, peri_key_id, 0 ) );
		}
	}
  return(0);
}
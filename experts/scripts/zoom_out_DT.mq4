//+------------------------------------------------------------------+
//|                                                  zoom_out_DT.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
#include <WinUser32.mqh>

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
	if( ObjectFind( "DT_BO_hud_info" ) != -1 ){
		setGlobal( "ZOOM", 0.1 );
    fakeTick();
	}
  return(0);
}
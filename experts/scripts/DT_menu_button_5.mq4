//+------------------------------------------------------------------+
//|                                             DT_menu_button_5.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_functions.mqh>
#include <DT_icons.mqh>

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
	if( IsTesting() ){
		
	}else{
		changeIcon( 5 );
	}
  return(0);
}
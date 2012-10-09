//+------------------------------------------------------------------+
//|                                              DT_history_undo.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_icons.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
	string gv_name = StringConcatenate( getSymbol(), "_History" );
	double gv_val;
	string desc = ObjectDescription( "DT_BO_history_hud" );
	int start = StringFind(desc, "/", 0) + 1;
	int len = StrToInteger(StringSubstr( desc, start ));

	if( GlobalVariableCheck( gv_name ) ){
    gv_val = GlobalVariableGet( gv_name );
    if( gv_val > 0.0 ){
      gv_val = gv_val - 1.0;
      GlobalVariableSet( gv_name, gv_val );
      addComment( "UNDO to "+DoubleToStr(gv_val,0)+" position", 2 );
    }else{
      addComment( "Can't UNDO below 0 position!", 1 );
    }
  }else{
    addComment( "Can't UNDO "+DoubleToStr(gv_val,0)+" does not exist!", 1 );
  }
  return(0);
}
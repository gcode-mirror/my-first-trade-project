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
	string gv_name = StringConcatenate( StringSubstr(Symbol(), 0, 6), "_History");
	double gv_val;
	string desc = ObjectDescription( "DT_BO_hud_history" );
	int start = StringFind(desc, " ", 0) + 1;
	int char_nr = StringFind(desc, "/", 0) - start;
	int len = StrToInteger(StringSubstr( desc, start, char_nr ));
	if( len == 0 ){
		addComment( "Can't UNDO history is empty!", 1 );
	}else{
		if( GlobalVariableCheck( gv_name ) ){
			gv_val = GlobalVariableGet( gv_name );
			if( gv_val > 1.0 ){
				gv_val = gv_val - 1.0;
				GlobalVariableSet( gv_name, gv_val );
				addComment( "UNDO to "+DoubleToStr(gv_val,0)+" position", 2 );
			}else{
				addComment( "Can't UNDO below 1 position!", 1 );
			}
		}else{
			addComment( "Can't UNDO "+DoubleToStr(gv_val,0)+" does not exist!", 1 );
		}
	}
  return(0);
}
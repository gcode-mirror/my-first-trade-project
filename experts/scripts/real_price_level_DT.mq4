//+------------------------------------------------------------------+
//|                                          real_price_level_DT.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+

#include <DT_defaults.mqh>
#include <DT_icons.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
	double tod = WindowTimeOnDropped();
	string hline = "DT_GO_real_price_level_hline";
	string vline = "AA_GO_real_price_level_vline";
	if( ObjectFind( hline ) != -1 ){
		ObjectDelete( hline );
	}
	if( ObjectFind( vline ) != -1 ){
		ObjectDelete( vline );
	}
	if( tod == 0.0 ){
		addComment("Real price level helpers removed.",2);
		return(0);
	}
	
  string sel_name = getSelectedLine( tod, WindowPriceOnDropped(), true );

  if( sel_name != "" && ObjectType( sel_name ) == OBJ_TREND ){
		int shift = iBarShift( NULL, 0, tod );
		double line_price = ObjectGetValueByShift( sel_name, shift );
	
		
		ObjectCreate( hline, OBJ_HLINE, 0, 0, line_price);
    ObjectSet( hline, OBJPROP_COLOR, Orange);
		ObjectSet(hline, OBJPROP_BACK, true);
		
		ObjectCreate( vline, OBJ_VLINE, 0, tod, 0);
    ObjectSet( vline, OBJPROP_COLOR, Orange);
		ObjectSet(vline, OBJPROP_BACK, true);
		
		addComment(sel_name+" marked.",2);
  }else{
    addComment("Can not find line!",1);
  }
  return(0);
}
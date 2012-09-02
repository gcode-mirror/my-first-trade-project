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
	removeObjects("real_price", "GO");
	if( tod == 0.0 ){
		addComment("Real price level helpers removed.",2);
		return(0);
	}
	
  string sel_name = getSelectedLine( tod, WindowPriceOnDropped(), true );

  if( sel_name != "" && ObjectType( sel_name ) == OBJ_TREND ){
		string name, vline = "AA_GO_real_price_level_vline";
		int nr = 20;
		int shift = iBarShift( NULL, 0, tod ) + ( nr / 2 );
		double t1, t2 = Time[shift], line_price;
		
		ObjectCreate( vline, OBJ_VLINE, 0, tod, 0);
		ObjectSet( vline, OBJPROP_COLOR, Orange);
		ObjectSet(vline, OBJPROP_BACK, true);
		
		while( nr > 0 ){
			name = "DT_GO_real_price_level_hline_" + nr;
			line_price = ObjectGetValueByShift( sel_name, shift );
			t1 = t2;
			t2 = t1 + ( Period() * 60 );
			ObjectCreate( name, OBJ_TREND, 0, t1, line_price, t2, line_price );
			ObjectSet( name, OBJPROP_COLOR, Orange );
			ObjectSet( name, OBJPROP_BACK, true );
			ObjectSet( name, OBJPROP_RAY, false);
			shift--;
			nr--;
		}
		
		addComment(sel_name+" marked.",2);
  }else{
    addComment("Can not find line!",1);
  }
  return(0);
}
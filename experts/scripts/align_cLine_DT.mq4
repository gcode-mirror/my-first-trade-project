//+------------------------------------------------------------------+
//|                                               align_cLine_DT.mq4 |
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
  double pod = WindowPriceOnDropped();
  double tod = WindowTimeOnDropped();
  int i = 0, len = ObjectsTotal();
  string name, sel_name = "", para_line = "";
  color c = C'255,128,0';

  for( ; i < len; i++ ) {
    name = ObjectName(i);
    // if( StringSubstr( name, 5, 7 ) == "_cLine_" ){
      if( ObjectGet( name, OBJPROP_COLOR ) == c ){
        sel_name = name;
      }
    // }
  }

  if( pod == 0.0 ){
    if( sel_name != "" ){
			if( StringSubstr( sel_name, 5, 7 ) == "_cLine_" ){
				renameChannelLine( sel_name );
			}else{
				ObjectSet( sel_name, OBJPROP_COLOR, RosyBrown );
			}
    }
  }else{
    if( sel_name == "" ){
      sel_name = getSelectedLine( tod, pod, true, 15 );
      ObjectSet( sel_name, OBJPROP_COLOR, c );

    }else{
      double h, l, dif, line_dist, bar_dist, max_dist = ( WindowPriceMax(0) - WindowPriceMin(0) ) / 20;
      int shift, time_magnet;
      para_line = getSelectedLine( tod, pod, false, 40 );
      
      if( para_line != "" && para_line != sel_name ){
        line_dist = MathAbs( pod - getLineValAtTime( para_line, tod ) );
      }else{
        line_dist = 99999.0;
      }
    
      shift = iBarShift( NULL, 0, tod );
      h = High[shift];
      l = Low[shift];
      bar_dist = MathMin( MathAbs( pod - h ), MathAbs( pod - l ) );
      
      if( MathMin( line_dist, bar_dist ) > max_dist ){
        addComment( "There is no bar or line to align or para line not cLine!", 1 );
        return (0);
      }
    
      if( line_dist < bar_dist ){
        dif = ObjectGet( sel_name, OBJPROP_PRICE1 ) - getLineValAtTime( para_line, ObjectGet( sel_name, OBJPROP_TIME1 ));
        ObjectSet( sel_name, OBJPROP_PRICE2, getLineValAtTime( para_line, ObjectGet( sel_name, OBJPROP_TIME2 )) + dif );
        addComment( "Set paralel to: "+para_line );
      
      }else{
        if( MathAbs( pod - h ) < MathAbs( pod - l ) ){
          dif = getLineValAtTime( sel_name, tod ) - h;
          addComment( "Align to bar High: "+DoubleToStr( h, Digits ));
        }else{
          dif = getLineValAtTime( sel_name, tod ) - l;
          addComment( "Align to bar Low: "+DoubleToStr( l, Digits ));
        }
        
        time_magnet = WindowBarsPerChart()/40;
        if( tod < ObjectGet( sel_name, OBJPROP_TIME1 ) || MathAbs(ObjectGet( sel_name, OBJPROP_TIME1 ) - tod) < Period() * 60 * time_magnet ){
					ObjectSet( sel_name, OBJPROP_PRICE1, getLineValAtTime( sel_name, tod ) - dif );
					ObjectSet( sel_name, OBJPROP_TIME1, tod );
					ObjectSet( sel_name, OBJPROP_PRICE2, ObjectGet( sel_name, OBJPROP_PRICE2 ) - dif );
				}else if( tod > ObjectGet( sel_name, OBJPROP_TIME2 ) || MathAbs(ObjectGet( sel_name, OBJPROP_TIME2 ) - tod) < Period() * 60 * time_magnet ){
					ObjectSet( sel_name, OBJPROP_PRICE2, getLineValAtTime( sel_name, tod ) - dif );
					ObjectSet( sel_name, OBJPROP_PRICE1, ObjectGet( sel_name, OBJPROP_PRICE1 ) - dif );
					ObjectSet( sel_name, OBJPROP_TIME2, tod );
				}else{
					ObjectSet( sel_name, OBJPROP_PRICE1, ObjectGet( sel_name, OBJPROP_PRICE1 ) - dif );
					ObjectSet( sel_name, OBJPROP_PRICE2, ObjectGet( sel_name, OBJPROP_PRICE2 ) - dif );
				}
      }
      
      // if T2 bigger than Time[0] align to Time[0]
      if( ObjectGet( sel_name, OBJPROP_TIME2 ) > Time[0] ){
				ObjectSet( sel_name, OBJPROP_PRICE2, getClineValueByShift( sel_name ) );
				ObjectSet( sel_name, OBJPROP_TIME2, Time[0] );
			}
    }
  }
}
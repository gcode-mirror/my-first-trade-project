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
  double dif, pod = WindowPriceOnDropped();
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
      para_line = getSelectedLine( tod, pod, false, 20 );
      if( para_line != "" && para_line != sel_name ){
        dif = ObjectGet( sel_name, OBJPROP_PRICE1 ) - getLineValAtTime(para_line, ObjectGet( sel_name, OBJPROP_TIME1 ));
        ObjectSet( sel_name, OBJPROP_PRICE2, getLineValAtTime(para_line, ObjectGet( sel_name, OBJPROP_TIME2 )) + dif );
        addComment( "Set paralel to: "+para_line );

      }else{
        double tmp, h, l, max_dist = ( WindowPriceMax(0) - WindowPriceMin(0) ) / 20;
        int shift = iBarShift( NULL, 0, tod ), time_magnet;
        h = High[shift];
        l = Low[shift];
				time_magnet = WindowBarsPerChart()/40;
				
				tmp = MathAbs( pod - h );
        if( tmp < MathAbs( pod - l ) ){
          dif = getLineValAtTime( sel_name, tod ) - h;
          addComment( "Align to bar High: "+DoubleToStr( h, Digits ));
        }else{
					tmp = MathAbs( pod - l );
          dif = getLineValAtTime( sel_name, tod ) - l;
          addComment( "Align to bar Low: "+DoubleToStr( l, Digits ));
        }

				if( tmp > max_dist ){
					addComment( "There is no bar or line to align!", 1 );
					return (0);
				}

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
			if( ObjectGet( sel_name, OBJPROP_TIME2 ) > Time[0] ){
				ObjectSet( sel_name, OBJPROP_PRICE2, getClineValueByShift( sel_name ) );
				ObjectSet( sel_name, OBJPROP_TIME2, Time[0] );
			}
    }
  }
}

double getLineValAtTime( string name, double time ){
  if( ObjectType(name) == OBJ_HLINE ){
    return ( ObjectGet( name, OBJPROP_PRICE1 ) );
  }

  double t1, t2, p1 ,p2, val;
  t1 = ObjectGet( name,OBJPROP_TIME1 );
  p1 = ObjectGet( name,OBJPROP_PRICE1 );
  t2 = ObjectGet( name,OBJPROP_TIME2 );
  p2 = ObjectGet( name,OBJPROP_PRICE2 );
  ObjectSet( name, OBJPROP_RAY, true );

  if( (t1 < t2 && time < t1) || (t1 > t2 && time > t1) ){
    ObjectSet( name, OBJPROP_TIME1, t2 );
    ObjectSet( name, OBJPROP_PRICE1, p2 );
    ObjectSet( name, OBJPROP_TIME2, t1 );
    ObjectSet( name, OBJPROP_PRICE2, p1 );
    val = ObjectGetValueByShift( name, iBarShift( NULL, 0, time ) );

    ObjectSet( name, OBJPROP_TIME1, t1 );
    ObjectSet( name, OBJPROP_PRICE1, p1 );
    ObjectSet( name, OBJPROP_TIME2, t2 );
    ObjectSet( name, OBJPROP_PRICE2, p2 );

    return (val);
  }else{
    return (ObjectGetValueByShift( name, iBarShift( NULL, 0, time ) ));
  }

}

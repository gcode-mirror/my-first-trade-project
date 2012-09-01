//+------------------------------------------------------------------+
//|                                                 DT_transform.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_icons.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
#include <WinUser32.mqh>
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  double tod = WindowTimeOnDropped();
  string sel_name = getSelectedLine( tod, WindowPriceOnDropped(), true );

  if( sel_name != "" && ObjectType( sel_name ) == OBJ_TREND ){
    string name, desc, type, time_frame;
    color c;
    int width, cmd_id, style;
    double time = TimeLocal();
    if( StringSubstr( sel_name, 7, 5 ) == "Line_" ){
			name = "Trendline " + DoubleToStr( time, 0 );
      c = RosyBrown;
      width = 1;
      desc = TimeToStr( time, TIME_DATE|TIME_SECONDS);
    }else{
			
			cmd_id = MessageBox( "ZigZag line or Channel line?", "Select type", MB_YESNOCANCEL|MB_ICONQUESTION );
		
			if( cmd_id == IDYES ){
				type = "zLine";
				style = STYLE_SOLID;
				if( Period() == PERIOD_H4 ){
					time_frame = "H4";
					width = 1;
				}else if( Period() == PERIOD_D1 ){
					time_frame = "D1";
					width = 2;
				}else{
					cmd_id = MessageBox( "Period Hour 4 or Daily?", "Select period", MB_YESNOCANCEL|MB_ICONQUESTION );
					if( cmd_id == IDYES ){
						time_frame = "H4";
						width = 1;
					}else if( cmd_id == IDNO ){
						time_frame = "D1";
						width = 2;
					}else if( cmd_id == IDCANCEL ){
						return (0);
					}
				}
				
			}else if( cmd_id == IDNO ){
				type = "cLine";
				style = STYLE_DASH;
				time_frame = "H4";
				width = 1;
			}else if( cmd_id == IDCANCEL ){
				return (0);
			}
      
      c = CornflowerBlue;
      desc = TimeToStr( time, TIME_DATE|TIME_SECONDS);
			name = StringConcatenate( "DT_GO_", type, "_", time_frame, "_sig_", DoubleToStr( time, 0 ) );
    }

    ObjectCreate( name, OBJ_TREND, 0, ObjectGet( sel_name,OBJPROP_TIME1 ), ObjectGet( sel_name,OBJPROP_PRICE1 ), ObjectGet( sel_name,OBJPROP_TIME2 ), ObjectGet( sel_name,OBJPROP_PRICE2 ) );
    ObjectSet( name, OBJPROP_RAY, true );
    ObjectSet( name, OBJPROP_COLOR, c );
    ObjectSet( name, OBJPROP_STYLE, style );
    ObjectSet( name, OBJPROP_BACK, true );
    ObjectSet( name, OBJPROP_WIDTH, width );
    ObjectSetText( name, desc, 8 );

    ObjectDelete( sel_name );
  }
  return( errorCheck("DT_transform") );
}
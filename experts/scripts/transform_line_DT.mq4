//+------------------------------------------------------------------+
//|                                            transform_line_DT.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  double tod = WindowTimeOnDropped();
  string sel_name = getSelectedLine( tod, WindowPriceOnDropped(), true );

  if( sel_name != "" ){
    string name;
    color c;
    int o_type;
    
    double p1, t1, p2, t2, time = TimeLocal();
    t1 = NormalizeDouble( ObjectGet( sel_name, OBJPROP_TIME1 ), 0 );
    p1 = NormalizeDouble( ObjectGet( sel_name, OBJPROP_PRICE1 ), Digits );
    t2 = NormalizeDouble( ObjectGet( sel_name, OBJPROP_TIME2 ), 0 );
    p2 = NormalizeDouble( ObjectGet( sel_name, OBJPROP_PRICE2 ), Digits );
    o_type = ObjectType( sel_name );
    
    if( StringSubstr( sel_name, 5, 7 ) == "_tLine_"){
      if( o_type == OBJ_TREND ){
        name = "Trendline " + DoubleToStr( time, 0 );
      }else{
        name = "Horizontal Line " + DoubleToStr( time, 0 );
      }
      c = RosyBrown;
      addComment( sel_name + " transformed to normal line!", 2 );
    }else{
      c = CornflowerBlue;
			name = StringConcatenate( "DT_GO_tLine_sig_", DoubleToStr( time, 0 ) );
      
      if( o_type == OBJ_TREND ){
        if( !(NormalizeDouble(iCustom( Symbol(), PERIOD_H4, "ZigZag", 12, 5, 3, 0, iBarShift( NULL, PERIOD_H4, t1 ) ), Digits) == p1 || NormalizeDouble(iCustom( Symbol(), PERIOD_D1, "ZigZag", 12, 5, 3, 0, iBarShift( NULL, PERIOD_D1, t1 ) ), Digits) == p1) ){
          addComment( StringConcatenate( "Line P1 val not match to ZZ: ", p1, " name:", name ), 1 );
          return (0);
        }

        if( !(NormalizeDouble(iCustom( Symbol(), PERIOD_H4, "ZigZag", 12, 5, 3, 0, iBarShift( NULL, PERIOD_H4, t2 ) ), Digits) == p2 || NormalizeDouble(iCustom( Symbol(), PERIOD_D1, "ZigZag", 12, 5, 3, 0, iBarShift( NULL, PERIOD_D1, t2 ) ), Digits) == p2) ){
          addComment( StringConcatenate("Line P2 val not match to ZZ: ", p2, " name:", name ), 1 );
          return (0);
        }
      }
      addComment( sel_name + " transformed to tLine!", 2 );
    }
    
    int width;
    if( Period() == PERIOD_W1 ){
      width = 3;
    }else if( Period() == PERIOD_D1 ){
      width = 2;
    }else{
      width = 1;
    }
    
    ObjectCreate( name, o_type, 0, t1, p1, t2, p2 );
    ObjectSet( name, OBJPROP_RAY, true );
    ObjectSet( name, OBJPROP_COLOR, c );
    ObjectSet( name, OBJPROP_BACK, true );
    ObjectSet( name, OBJPROP_WIDTH, width );
    ObjectSetText( name, TimeToStr( time, TIME_DATE|TIME_SECONDS), 8 );
    ObjectDelete( sel_name );
  }else{
    addComment( "Line not found!", 1 );
  }
  return( errorCheck("DT_transform") );
}

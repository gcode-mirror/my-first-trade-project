//+------------------------------------------------------------------+
//|                                                    h_line_DT.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_functions.mqh>

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  double pod = WindowPriceOnDropped();
  int nr = 0, i = 0, j, len = ObjectsTotal();
  string name;
  double fibo_levels[6] = { 1, 0.618, 0.5, 0.382, 0.236, 0 };
  double res[1000], p1, p2, min_dist = 99999999.9, time = TimeLocal(), tmp, max_dist = ( WindowPriceMax(0) - WindowPriceMin(0) ) / 30;
  
  for( ; i < len; i++ ){
    name = ObjectName(i);
    if( ObjectType( name ) == OBJ_FIBO ){
      p1 = ObjectGet( name, OBJPROP_PRICE1 );
      p2 = ObjectGet( name, OBJPROP_PRICE2 );
      for( j = 0; j < 6; j++ ){
        res[nr] = NormalizeDouble( MathMin( p1, p2 ) + (MathAbs( p1 - p2 ) * fibo_levels[j]), Digits );
        nr++;
      }
    }
  }
  
  p1 = 0.0;
  if( nr > 0 ){
    for( i = 0; i < nr; i++ ){
      tmp = MathAbs( res[i] - pod );
      if( tmp < min_dist && tmp < max_dist ){
        min_dist = tmp;
        p1 = res[i];
      }
    }
    if( p1 == 0.0 ){
      p1 = pod;
    }
  }else{
    p1 = pod;
  }
  
  name = "DT_GO_tLine_sig_" + DoubleToStr( time, 0 );
  ObjectCreate( name, OBJ_HLINE, 0, 0, p1 );
  ObjectSet( name, OBJPROP_COLOR, CornflowerBlue );
  ObjectSet( name, OBJPROP_RAY, false );
  ObjectSet( name, OBJPROP_BACK, true );
  ObjectSetText( name, TimeToStr( time, TIME_DATE|TIME_SECONDS), 8 );
  
  return(0);
}
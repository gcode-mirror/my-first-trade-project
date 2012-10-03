//+------------------------------------------------------------------+
//|                                                     DT_ruler.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#define RULER_STEP 80 

void startRuler(){
  static int st_timer = 0;
  static string st_switch = "-1";
  static double st_p_min = 0.0;
  static double st_p_max = 0.0;
	static int icon_id = -1;
  
  if( GetTickCount() > st_timer ){
    st_timer = GetTickCount() + 2000;
    
    if( st_switch == "-1" ){
      st_switch = getGlobal("RULER_SWITCH");
			icon_id = showIcon( 3, 1, "G", "Wingdings 3", st_switch, "RULER_SWITCH" );
    }
    
    if( st_switch != getGlobal("RULER_SWITCH") ){
      st_switch = getGlobal("RULER_SWITCH");
      if( st_switch == "0" ){
        deInitRuler();
        addComment( "Switch OFF Ruler." );
        return;
      }
			addComment( "Turn ON Ruler." );
    }
    
    if( st_switch == "0" ){
      return;
    }
    
    if( st_p_min == WindowPriceMin(0) && st_p_max == WindowPriceMax(0) ){
      return;
    }
    
    removeObjects("ruler");
    
    st_p_min = WindowPriceMin(0);
    st_p_max = WindowPriceMax(0);

    int prec;
    double step, tmp = NormalizeDouble( (st_p_max - st_p_min) / RULER_STEP, Digits );
    if( tmp < 1.0 ){
      tmp = tmp * MathPow( 10, ( Digits ));
      prec = (Digits - StringLen(DoubleToStr(tmp, 0))) * (-1);
    }else{
      prec = StringLen(DoubleToStr(tmp, 0));
    }
    step = MathPow( 10, prec );
    
    double lv2 = step * 10;
    double lv3 = step * 100;
    double t1, t2, t3, t4;
    string name, label;
    
    int shift = WindowBarsPerChart() * 0.082;
    t1 = Time[0] + ( Period() * 60 * shift );
    t2 = t1 + ( Period() * 60 );
    t3 = t2 + ( Period() * 60 );
    t4 = t3 + ( Period() * 60 ) * 2;
    
    name = "DT_BO_ruler_vsep";
    ObjectCreate( name, OBJ_VLINE, 0, t1, 0);
    ObjectSet( name, OBJPROP_COLOR, Black );
    
    name = "DT_BO_ruler_yest";
    ObjectCreate( name, OBJ_TREND, 0, t1, iHigh( Symbol(), PERIOD_D1, 1 ), t1, iLow( Symbol(), PERIOD_D1, 1 ) );
    ObjectSet( name, OBJPROP_COLOR, Blue );
    ObjectSet( name, OBJPROP_RAY, false );
    ObjectSet( name, OBJPROP_WIDTH, 2 );
    
    double i = round_up( st_p_min, prec * (-1) );
    int lv_idx = i * MathPow( 10, prec * (-1) );
    
    for( ; i < st_p_max; i = i + step ){
      name = StringConcatenate( "DT_BO_ruler_step_", lv_idx );
      if( lv_idx % 100 == 0 ){
        ObjectCreate( name, OBJ_TREND, 0, t1, i, t3, i );
        ObjectSet( name, OBJPROP_WIDTH, 2 );
        
        label = StringConcatenate( "DT_BO_ruler_label_", lv_idx );
        ObjectCreate( label, OBJ_TEXT, 0, t4, i );
        ObjectSetText( label, DoubleToStr( i, (prec * (-1)) - 2 ), 7, "Arial Black", Black );

      }else if( lv_idx % 10 == 0 ){
        ObjectCreate( name, OBJ_TREND, 0, t1, i, t3, i );
        ObjectSet( name, OBJPROP_WIDTH, 1 );
        
        label = StringConcatenate( "DT_BO_ruler_label_", lv_idx );
        ObjectCreate( label, OBJ_TEXT, 0, t4, i );
        ObjectSetText( label, DoubleToStr( i, (prec * (-1)) - 1 ), 7, "Arial", Black );
      
      }else{
        ObjectCreate( name, OBJ_TREND, 0, t1, i, t2, i );
        ObjectSet( name, OBJPROP_WIDTH, 1 );
      }
      
      ObjectSet( name, OBJPROP_COLOR, Black );             
      ObjectSet( name, OBJPROP_RAY, false );
      
      lv_idx++;
    }
  }
}

void deInitRuler(){
  removeObjects("ruler");
}

double round_up( double value, int precision ){ 
  double pow = MathPow ( 10, precision ); 
  return (NormalizeDouble(( MathCeil( pow * value ) + MathCeil( pow * value - MathCeil( pow * value ) ) ) / pow, precision)); 
}

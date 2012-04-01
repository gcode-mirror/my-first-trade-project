//+------------------------------------------------------------------+
//|                                                        ruler.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

double MIN_PRICE_RULER = 0, MAX_PRICE_RULER = 0;
int    ROUND_NR_STEP   = 80;
double YH, YL, YC, P, R1, R2, R3, S1, S2, S3, MR1, MR2, MR3, MS1, MS2, MS3, L_61, L_32, L32, LH50, H_32, H32, H61;

bool initRuler(string isOn){
	setAppStatus(APP_ID_RULER, isOn);
  if(isOn == "0"){    
    return (false);
  }
	if(Period() < PERIOD_D1){

		YH = iHigh(Symbol(),PERIOD_D1,1);
		YL = iLow(Symbol(),PERIOD_D1,1);
		YC = iClose(Symbol(),PERIOD_D1,1);

		P = (YH + YL + YC) / 3;
		R1 = (2*P)-YL;
		R2 = P+(YH - YL);
		R3 = (2*P)+(YH-(2*YL));
		S1 = (2*P)-YH;
		S2 = P-(YH - YL);
		S3 = (2*P)-((2* YH)-YL);
/*		
		MR1 = (P+R1)/2;
		MR2 = (R1+R2)/2;
		MR3 = (R2+R3)/2;
		MS1 = (P+S1)/2;
		MS2 = (S1+S2)/2;
		MS3 = (S2+S3)/2;
		
		double q = (YH - YL);
		L_61 = YL-q*0.618;
		L_32 = YL-q*0.382;
		L32 = YL+q*0.382;
		LH50 = YL+q*0.5;
		H_32 = YH-q*0.382;
		H32 = YH+q*0.382;
		H61 = YH-q*0.618;
*/		
	}
  return (errorCheck("initRuler"));
}

bool startRuler(string isOn){
	if(isAppStatusChanged(APP_ID_RULER, isOn)){
    if(isOn == "1"){
      initRuler("1");
    }else{    
      deInitRuler();
      return (false);
    }    
  } 
  
	if(isOn == "0"){return (false);}
	if(delayTimer(APP_ID_RULER, 1000)){return (false);}
	if(MIN_PRICE_RULER == WindowPriceMin(0) && MAX_PRICE_RULER == WindowPriceMax(0)){return (false);}
  
  MIN_PRICE_RULER = WindowPriceMin(0);
  MAX_PRICE_RULER = WindowPriceMax(0);
  removeObjects("ruler");
    
  int x_5, x_2, x1, x2, x3, x4, x5, x6, peri, lv0, prec = Digits;
  string str_price;
  double i, points = MathPow( 10,( Digits-1 ));
	double diff = MAX_PRICE_RULER-MIN_PRICE_RULER;
	double offset = 1/MathPow( 10,( Digits )); 
	
  while(true){
		prec = prec-1;
		offset = offset*10;
		if(diff/offset<ROUND_NR_STEP){
			break;
		}
  }
	
  peri = getUnitInSec();
  x1 = Time[0]+(peri*6);
  
	x_5 = x1-(Period()*300);  
	x_2 = x1-(Period()*120);
  x2 = x1+(Period()*60);
  x3 = x1+(Period()*120);
  x4 = x1+(Period()*180);
  x5 = x1+(Period()*300);
  x6 = x1+(Period()*360);

  ObjectCreate("DT_BO_ruler_vsep", OBJ_VLINE, 0, x1, 0);
  ObjectSet("DT_BO_ruler_vsep", OBJPROP_COLOR, Black);

  i=MathCeil(MIN_PRICE_RULER*MathPow(10,prec))/MathPow(10,prec);
	lv0 = MathMod(i*MathPow(10,prec),1000);
	
  for(; i<=MAX_PRICE_RULER; i=i+offset){
    if( lv0 % 100 == 0 ){
      str_price = myFloor(i,prec-2);
      ObjectCreate("DT_BO_ruler_step_"+lv0, OBJ_TREND, 0, x1, i, x3, i);
      ObjectSet("DT_BO_ruler_step_"+lv0, OBJPROP_WIDTH, 2);
    
      ObjectCreate("DT_BO_ruler_label_"+lv0, OBJ_TEXT, 0, x4, i);
      ObjectSetText("DT_BO_ruler_label_"+lv0, str_price,7,"Arial", Black);
    }else{
       if( lv0 % 10 == 0 ){
          str_price = myFloor(i,prec-1);
          ObjectCreate("DT_BO_ruler_step_"+lv0, OBJ_TREND, 0, x1, i, x3, i);
        
          ObjectCreate("DT_BO_ruler_label_"+lv0, OBJ_TEXT, 0, x4, i);
          ObjectSetText("DT_BO_ruler_label_"+lv0, str_price,7,"Arial", Black);
        
       }else{
          str_price = myFloor(i,prec);
          ObjectCreate("DT_BO_ruler_step_"+lv0, OBJ_TREND, 0, x1, i, x2, i);
       }
       ObjectSet("DT_BO_ruler_step_"+lv0, OBJPROP_WIDTH, 1);
    }      
            
    ObjectSet("DT_BO_ruler_step_"+lv0, OBJPROP_COLOR, Black);             
    ObjectSet("DT_BO_ruler_step_"+lv0, OBJPROP_RAY, false);      
    ObjectSetText("DT_BO_ruler_step_"+lv0, str_price, 10);
		lv0++;
  }
	
	if(Period() < PERIOD_D1){
/*
	 addPivotLine("YH", YH, x1, x5, x6, Silver, STYLE_DOT, 6);
	 addPivotLine("YL", YL, x1, x5, x6, Silver, STYLE_DOT, 6);
	 addPivotLine("YC", YC, x1, x5, x6, Silver, STYLE_DOT, 6);
*/ 
	 
	 addPivotLine("Pivot", P, x1, x5, x6, Magenta);
	 addPivotLine("R1", R1, x1, x5, x6, Red);
	 addPivotLine("R2", R2, x1, x5, x6, Red);
	 addPivotLine("R3", R3, x1, x5, x6, Red);
	 addPivotLine("S1", S1, x1, x5, x6, Blue);
	 addPivotLine("S2", S2, x1, x5, x6, Blue);
	 addPivotLine("S3", S3, x1, x5, x6, Blue);

/*	 
	 addPivotLine("MR1", MR1, x_5, x1, x_5, Gray, STYLE_DOT, 6);
	 addPivotLine("MR2", MR2, x_5, x1, x_5, Gray, STYLE_DOT, 6);
	 addPivotLine("MR3", MR3, x_5, x1, x_5, Gray, STYLE_DOT, 6);
	 addPivotLine("MS1", MS1, x_5, x1, x_5, Gray, STYLE_DOT, 6);
	 addPivotLine("MS2", MS2, x_5, x1, x_5, Gray, STYLE_DOT, 6);
	 addPivotLine("MS3", MS3, x_5, x1, x_5, Gray, STYLE_DOT, 6);
	                   
	 addPivotLine("L_61", L_61, x_2, x1, x_2, Goldenrod, STYLE_SOLID, 6, false);
	 addPivotLine("L_32", L_32, x_2, x1, x_2, Goldenrod, STYLE_SOLID, 6, false);
	 addPivotLine("L32", L32, x_2, x1, x_2, Goldenrod, STYLE_SOLID, 6, false);
	 addPivotLine("LH50", LH50, x_2, x1, x_2, Goldenrod, STYLE_SOLID, 6, false);
	 addPivotLine("H_32", H_32, x_2, x1, x_2, Goldenrod, STYLE_SOLID, 6, false);
	 addPivotLine("H32", H32, x_2, x1, x_2, Goldenrod, STYLE_SOLID, 6, false);
	 addPivotLine("H61", H61, x_2, x1, x_2, Goldenrod, STYLE_SOLID, 6, false);
*/	 
	}

  WindowRedraw();
  return (errorCheck("startRuler"));
}

bool deInitRuler(){
  removeObjects("ruler");
  return (errorCheck("deInitRuler"));
}

bool addPivotLine(string name, double y, double x1, double x2, double lx, color c, int style = STYLE_SOLID, int text_size = 7, bool text_needed = true){
	string n = "DT_BO_ruler_pivot_line_"+name;
	ObjectCreate(n, OBJ_TREND, 0, x1, y, x2, y);
	ObjectSet(n, OBJPROP_COLOR, c);             
	ObjectSet(n, OBJPROP_RAY, false);
	ObjectSet(n, OBJPROP_STYLE, style);
	ObjectSetText(n, name, 8);
	if(text_needed){
		n = "DT_BO_ruler_pivot_label_"+name;
		ObjectCreate(n, OBJ_TEXT, 0, lx, y);
		ObjectSetText(n, name, text_size, "Arial", c);
	}
}
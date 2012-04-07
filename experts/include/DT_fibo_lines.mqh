//+------------------------------------------------------------------+
//|                                                DT_Fibo_lines.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#define FIBO_NR 6

double FIBO_BASE_X1 = 1, FIBO_BASE_Y1 = 1, FIBO_BASE_X2 = 1, FIBO_BASE_Y2 = 1;
int FIBO_LINE_VISIBLE_BAR = 0;

string LINE_FIBOS_STR[FIBO_NR]={"0.000","0.236","0.382","0.500","0.618","0.764"}; 
double LINE_FIBOS[FIBO_NR]={0.000,0.236,0.382,0.500,0.618,0.764}; 
color FIBO_COLORS[FIBO_NR]={Red,Black,Blue,Tan,Tan,Tan};
color LEVEL_COLORS[FIBO_LV_NR]={C'255,189,199',C'237,230,167',C'245,174,116',LightGreen,C'132,158,236',Yellow,Purple};
string LEVEL_NAMES[FIBO_LV_NR]={"23","38","50","55","61","68","76"};

bool initFiboLines(string isOn){
  setAppStatus(APP_ID_FIBO_LINES, isOn);
  if(isOn == "0"){        
    return (false);    
  }
  
  int i;
  if(ObjectFind("DT_GO_FiboLines_FIBO_BASE") != -1){  
    //startFiboLines(isOn);
    return (false);
  }
  deInitFiboLines();
  
  double f_time1, f_time2;
  double f_price1 = getZigZag(0, 12, 5, 3, 1, f_time1);
  double f_price2 = getZigZag(0, 12, 5, 3, 0, f_time2);
 
  ObjectCreate("DT_GO_FiboLines_FIBO_BASE", OBJ_FIBO, 0, f_time1, f_price1, f_time2, f_price2);
  ObjectSet("DT_GO_FiboLines_FIBO_BASE",OBJPROP_FIBOLEVELS,2);
  ObjectSet("DT_GO_FiboLines_FIBO_BASE",OBJPROP_FIRSTLEVEL+0,1);   
  ObjectSetFiboDescription("DT_GO_FiboLines_FIBO_BASE",0,"100");
  ObjectSet("DT_GO_FiboLines_FIBO_BASE",OBJPROP_FIRSTLEVEL+1,1.618);   
  ObjectSetFiboDescription("DT_GO_FiboLines_FIBO_BASE",1,"161.8");
  ObjectSet("DT_GO_FiboLines_FIBO_BASE",OBJPROP_RAY,true);
  ObjectSet("DT_GO_FiboLines_FIBO_BASE",OBJPROP_BACK,true);
  ObjectSet("DT_GO_FiboLines_FIBO_BASE",OBJPROP_LEVELCOLOR,Tan);
  ObjectSet("DT_GO_FiboLines_FIBO_BASE", OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M5|OBJ_PERIOD_M15|OBJ_PERIOD_M30|OBJ_PERIOD_H1|OBJ_PERIOD_H4);
  
  for(i=0;i<FIBO_LV_NR;i++){
    createLevel(StringConcatenate("DT_GO_FiboLines_RECT_lv",i), LEVEL_COLORS[i], LEVEL_NAMES[i]);
  }
  
  for(i=0;i<FIBO_NR;i++){    
    createFiboLine(StringConcatenate("DT_GO_FiboLines_",i), LINE_FIBOS_STR[i], FIBO_COLORS[i]);
  }
  
  return (errorCheck("initTradeLines"));
}

bool startFiboLines(string isOn){
  if(isAppStatusChanged(APP_ID_FIBO_LINES, isOn)){
    if(isOn == "1"){    
      initFiboLines("1");
    }else{    
      deInitFiboLines();
      return (false);
    }    
  }
  
	if(isOn == "0"){return (false);}
	if(delayTimer(APP_ID_FIBO_LINES, 800)){return (false);}
	
	updateFibo();
	
	int visible_bar = WindowFirstVisibleBar();
	if(visible_bar != FIBO_LINE_VISIBLE_BAR){  
		FIBO_LINE_VISIBLE_BAR = visible_bar;
		double x = Time[(visible_bar-WindowLastVisibleBar())/2];
		for(int i=0;i<FIBO_NR;i++){
			ObjectSet(StringConcatenate("DT_GO_FiboLines_",i,"_label"), OBJPROP_TIME1, x);
		}
	}
  return (0);
}

bool deInitFiboLines(){
  removeObjects("FiboLines", "GO");
  return (errorCheck("deInitFiboLines"));
}

bool updateFibo(){
  double cur_x1 = ObjectGet("DT_GO_FiboLines_FIBO_BASE",OBJPROP_TIME1);
  double cur_y1 = ObjectGet("DT_GO_FiboLines_FIBO_BASE",OBJPROP_PRICE1);
  double cur_x2 = ObjectGet("DT_GO_FiboLines_FIBO_BASE",OBJPROP_TIME2);
  double cur_y2 = ObjectGet("DT_GO_FiboLines_FIBO_BASE",OBJPROP_PRICE2);
  
  if(cur_x1 != FIBO_BASE_X1 || cur_y1 != FIBO_BASE_Y1 || cur_x2 != FIBO_BASE_X2 || cur_y2 != FIBO_BASE_Y2){
    
    double line_fibo_0 = StrToDouble(ObjectDescription("DT_GO_FiboLines_0"));  //0.000
    double line_fibo_23 = StrToDouble(ObjectDescription("DT_GO_FiboLines_1")); //0.236
    double line_fibo_38 = StrToDouble(ObjectDescription("DT_GO_FiboLines_2")); //0.382
    double line_fibo_50 = StrToDouble(ObjectDescription("DT_GO_FiboLines_3")); //0.500
    double line_fibo_61 = StrToDouble(ObjectDescription("DT_GO_FiboLines_4")); //0.618
    double line_fibo_76 = StrToDouble(ObjectDescription("DT_GO_FiboLines_5")); //0.764
    
    double level_fibo_0_0 = line_fibo_0-0.009; //-0.009
    double level_fibo_0_1 = line_fibo_23+0.014; //0.250
    
    double level_fibo_1_0 = line_fibo_23-0.036; //0.200
    double level_fibo_1_1 = line_fibo_38-0.010; //0.372
    
    double level_fibo_2_0 = level_fibo_1_1;     //0.372
    double level_fibo_2_1 = line_fibo_50-0.011; //0.489
    
    double level_fibo_3_0 = level_fibo_2_1;     //0.489
    double level_fibo_3_1 = line_fibo_50+0.052; //0.552
    
    double level_fibo_4_0 = level_fibo_3_1;     //0.552
    double level_fibo_4_1 = line_fibo_61-0.011; //0.607
    
    double level_fibo_5_0 = level_fibo_4_1;     //0.607
    double level_fibo_5_1 = line_fibo_61+0.062; //0.680
    
    double level_fibo_6_0 = level_fibo_5_1;     //0.681
    double level_fibo_6_1 = line_fibo_76-0.011; //0.753
    
    double lot = StrToDouble(getGlobal("LOT"));
    double dif = cur_y1-cur_y2;
    double open_price = cur_y2+dif*level_fibo_0_1;
    ObjectSet("DT_GO_FiboLines_1", OBJPROP_PRICE1, line_fibo_23);
    ObjectSet("DT_GO_FiboLines_1_label", OBJPROP_PRICE1, line_fibo_23);
    updateOpenFiboLine((cur_y2+dif*line_fibo_23), lot, (cur_y2+dif*level_fibo_0_1), (cur_y2+dif*level_fibo_1_0), (line_fibo_23!=LINE_FIBOS[1]));
       
    updateFiboLine(0, (cur_y2+dif*line_fibo_0), lot, open_price, (cur_y2+dif*level_fibo_0_0), (line_fibo_0!=LINE_FIBOS[0]));
    updateFiboLine(2, (cur_y2+dif*line_fibo_38), lot, open_price, (cur_y2+dif*level_fibo_1_1), (line_fibo_38!=LINE_FIBOS[2]));
    updateFiboLine(3, (cur_y2+dif*line_fibo_50), lot, open_price, (cur_y2+dif*level_fibo_2_1), (line_fibo_50!=LINE_FIBOS[3]));
    updateFiboLine(4, (cur_y2+dif*line_fibo_61), lot, open_price, (cur_y2+dif*level_fibo_4_1), (line_fibo_61!=LINE_FIBOS[4]));
    updateFiboLine(5, (cur_y2+dif*line_fibo_76), lot, open_price, (cur_y2+dif*level_fibo_6_1), (line_fibo_76!=LINE_FIBOS[5]));

    double rect_width = Time[0]+(getUnitInSec()*20);
    updateLevel("DT_GO_FiboLines_RECT_lv0", cur_x1, (cur_y2+dif*level_fibo_0_0), rect_width, (cur_y2+dif*level_fibo_0_1));
    updateLevel("DT_GO_FiboLines_RECT_lv1", cur_x1, (cur_y2+dif*level_fibo_1_0), rect_width, (cur_y2+dif*level_fibo_1_1));
    updateLevel("DT_GO_FiboLines_RECT_lv2", cur_x1, (cur_y2+dif*level_fibo_2_0), rect_width, (cur_y2+dif*level_fibo_2_1));
    updateLevel("DT_GO_FiboLines_RECT_lv3", cur_x1, (cur_y2+dif*level_fibo_3_0), rect_width, (cur_y2+dif*level_fibo_3_1));
    updateLevel("DT_GO_FiboLines_RECT_lv4", cur_x1, (cur_y2+dif*level_fibo_4_0), rect_width, (cur_y2+dif*level_fibo_4_1));
    updateLevel("DT_GO_FiboLines_RECT_lv5", cur_x1, (cur_y2+dif*level_fibo_5_0), rect_width, (cur_y2+dif*level_fibo_5_1));
    updateLevel("DT_GO_FiboLines_RECT_lv6", cur_x1, (cur_y2+dif*level_fibo_6_0), rect_width, (cur_y2+dif*level_fibo_6_1));
    
    FIBO_BASE_X1 = cur_x1;
    FIBO_BASE_Y1 = cur_y1;
    FIBO_BASE_X2 = cur_x2;
    FIBO_BASE_Y2 = cur_y2;
    errorCheck("updateFiboLines");
    return (true);
  }else{
    return (false);
  }
}

bool updateFiboLine(int fibo_id, double y, double lot, double open_price, double close_level_y, bool is_custom){
  string name = StringConcatenate("DT_GO_FiboLines_",fibo_id);
  string label = name+"_label";
  
  ObjectSet(name, OBJPROP_PRICE1, y);
  ObjectSet(label, OBJPROP_PRICE1, y);
  
  double diff = MathAbs(y-open_price);  
  double usd = (diff/Point)*lot*MarketInfo(Symbol(),MODE_TICKVALUE);
  double huf =MarketInfo("USDHUF-Pro", MODE_BID)*usd;
  string is_cust = "";
  
  if(is_custom){
    is_cust = "CUST ";
  }
  
  ObjectSetText(label, StringConcatenate(is_cust,DoubleToStr(diff*MathPow(10,Digits),0)," pip  ",DoubleToStr(usd,1)," USD  ",DoubleToStr(huf,0)," HUF | ",DoubleToStr(close_level_y,Digits)), 7);  
  return (errorCheck("updateFiboLine ("+name+")"));
}
  
bool updateOpenFiboLine(double y, double lot, double close_level1_y, double close_level2_y, bool is_custom){
  string name = "DT_GO_FiboLines_1";
  string label = name+"_label", is_cust;
  ObjectSet(name, OBJPROP_PRICE1, y);
  ObjectSet(label, OBJPROP_PRICE1, y);
  if(is_custom){
    is_cust = "CUST ";
  }
  ObjectSetText(label, StringConcatenate(is_cust,DoubleToStr(lot,2)," lot |  /\ ",DoubleToStr(MathMax(close_level1_y,close_level2_y),Digits),"  \/ ",DoubleToStr(MathMin(close_level1_y,close_level2_y),Digits)));
  return (errorCheck("updateOpenFiboLine"));
}
  

bool createFiboLine(string name, string value, color c, bool show_all_frame = false){
  string label = name+"_label";
  ObjectCreate(name, OBJ_HLINE, 0, 0, 0);
	ObjectSet(name, OBJPROP_COLOR, c);
	ObjectSet(name, OBJPROP_RAY, true);
  ObjectSetText(name, value, 7);
	ObjectCreate(label, OBJ_TEXT, 0, 0, 0);
  ObjectSet(label, OBJPROP_COLOR, c);
  ObjectSetText(label, "",7,"Arial", c);
  if(show_all_frame){
    ObjectSet(name, OBJPROP_TIMEFRAMES, 0);
    ObjectSet(label, OBJPROP_TIMEFRAMES, 0);
  }else{
    ObjectSet(name, OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M5|OBJ_PERIOD_M15|OBJ_PERIOD_M30|OBJ_PERIOD_H1|OBJ_PERIOD_H4);
    ObjectSet(label, OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M5|OBJ_PERIOD_M15|OBJ_PERIOD_M30|OBJ_PERIOD_H1|OBJ_PERIOD_H4);
  }
  return (errorCheck("createFiboLine ("+name+")"));
}

bool createLevel(string name, color c, string text){
  ObjectCreate(name, OBJ_RECTANGLE, 0, 0, 0, 0, 0);
  ObjectSet(name, OBJPROP_BACK, true);
  ObjectSet(name, OBJPROP_COLOR,c);
  ObjectSet(name, OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M5|OBJ_PERIOD_M15|OBJ_PERIOD_M30|OBJ_PERIOD_H1|OBJ_PERIOD_H4);
  ObjectSetText(name, StringConcatenate("Fibo ",text));
  return (errorCheck("createLevels ("+name+")"));
}

bool updateLevel(string name, double x1, double y1, double x2, double y2){
  ObjectSet(name, OBJPROP_TIME1, x1);
  ObjectSet(name, OBJPROP_PRICE1, y1);
  ObjectSet(name, OBJPROP_TIME2, x2);
  ObjectSet(name, OBJPROP_PRICE2, y2);        
  return (errorCheck("updateLevel ("+name+")"));  
}



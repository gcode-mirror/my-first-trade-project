//+------------------------------------------------------------------+
//|                                                   DT_compare.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

double COMPARE_Y;
double COMPARE_ROW_NR = 0;

string COMPARE_CUR_1[];
bool COMPARE_POS_1[];
string COMPARE_CUR_2[];
bool COMPARE_POS_2[];

bool initCompare(string isOn){
  setAppStatus(APP_ID_COMPARE, isOn);
  
  if(isOn == "0"){        
    return (false);    
  }
  
  COMPARE_Y = 70;
  findComparedCurrencies("cur1",StringSubstr(Symbol(),0,3),COMPARE_CUR_1, COMPARE_POS_1);
  
  COMPARE_Y = COMPARE_Y+10;
  findComparedCurrencies("cur2",StringSubstr(Symbol(),3,3),COMPARE_CUR_2, COMPARE_POS_2);
  return (errorCheck("initCompare"));
}

bool startCompare(string isOn){
  if(isAppStatusChanged(APP_ID_COMPARE, isOn)){
    if(isOn == "1"){
      initCompare("1");
    }else{
      deinitCompare();
      return (false);
    }
  } 
  if(isOn == "0"){return (false);}
	if(delayTimer(APP_ID_COMPARE, 2000)){return (false);}
  
  updateCompareView();
  
  return (errorCheck("startCompare"));  
}

bool deinitCompare(){
  removeObjects("compare");
  return (errorCheck("deinitCompare"));
}

bool updateCompareView(){
  int len, i;
  len = ArraySize(COMPARE_CUR_1);
  for(i = 0; i < len; i++){
    ObjectSetText(StringConcatenate("DT_BO_compare_cur1_",i,"_3"),getMovment(COMPARE_CUR_1[i], PERIOD_H1, 3, MODE_LWMA, PRICE_CLOSE, COMPARE_POS_1[i]));
  }
  
  len = ArraySize(COMPARE_CUR_2);
  for(i = 0; i < len; i++){
    ObjectSetText(StringConcatenate("DT_BO_compare_cur2_",i,"_3"),getMovment(COMPARE_CUR_2[i], PERIOD_H1, 3, MODE_LWMA, PRICE_CLOSE, COMPARE_POS_2[i]));
  }
}

bool findComparedCurrencies(string name,string currency, string& cur_array[], bool& pos_array[]){
  createCompareRow(StringConcatenate("DT_BO_compare_head_",currency),StringConcatenate(currency,"  |   H1   |   D1"), true, RoyalBlue, White);
  //createCompareSeparator();
  int i = 0, from, idx = 0;
  int len = ArraySize(ALL_SYMBOLS_STR);
  string cur_pair;
  for(;i < len; i++){
    from = StringFind(ALL_SYMBOLS_STR[i], currency);
    if(from != -1){
      ArrayResize(cur_array, idx+1);
      ArrayResize(pos_array, idx+1);
      cur_array[idx] = ALL_SYMBOLS_STR[i];
      if(from == 0){
        cur_pair = StringSubstr(ALL_SYMBOLS_STR[i],3,3);
        pos_array[idx] = false;
      }else{
        cur_pair = StringSubstr(ALL_SYMBOLS_STR[i],0,3);
        pos_array[idx] = true;
      }
      createCompareRow(StringConcatenate("DT_BO_compare_",name,"_",idx),StringConcatenate(cur_pair," |"), false);
      idx++;
    }
  }
}

bool createCompareRow(string name, string text, bool is_head, color bg_color = Gainsboro, color content_color = Blue){
  string bg = StringConcatenate(name,"_1");
  string cur_pair = StringConcatenate(name,"_2");
  string content = StringConcatenate(name,"_3");

	ObjectCreate(bg, OBJ_LABEL, 0, 0, 0);
  ObjectSet(bg, OBJPROP_CORNER, 0);
  ObjectSet(bg, OBJPROP_XDISTANCE, 3);
  ObjectSet(bg, OBJPROP_YDISTANCE, COMPARE_Y);
  ObjectSet(bg, OBJPROP_BACK, false);
  ObjectSetText(bg,"ggggggg",12,"Webdings",bg_color);
	
  ObjectCreate(cur_pair, OBJ_LABEL, 0, 0, 0);
  ObjectSet(cur_pair, OBJPROP_CORNER, 0);
  ObjectSet(cur_pair, OBJPROP_XDISTANCE, 6);
  ObjectSet(cur_pair, OBJPROP_YDISTANCE, COMPARE_Y+2);
  ObjectSet(cur_pair, OBJPROP_BACK, false);
  ObjectSetText(cur_pair,text,9,"Arial",content_color);
  
  if(!is_head){
    ObjectCreate(content, OBJ_LABEL, 0, 0, 0);
    ObjectSet(content, OBJPROP_CORNER, 0);
    ObjectSet(content, OBJPROP_XDISTANCE, 42);
    ObjectSet(content, OBJPROP_YDISTANCE, COMPARE_Y+2);
    ObjectSet(content, OBJPROP_BACK, false);
    ObjectSetText(content,"",9,"Arial",content_color);  
  }
  
  COMPARE_ROW_NR++;
  COMPARE_Y = COMPARE_Y+17;
  return (errorCheck("createCompareRow ("+content+")"));
}

bool createCompareSeparator(color col = Black){
  string sep = StringConcatenate("DT_BO_compare_sep_",COMPARE_ROW_NR);
  ObjectCreate(sep, OBJ_LABEL, 0, 0, 0);
  ObjectSet(sep, OBJPROP_CORNER, 0);
  ObjectSet(sep, OBJPROP_XDISTANCE, 3);
  ObjectSet(sep, OBJPROP_YDISTANCE, COMPARE_Y-9);
  ObjectSet(sep, OBJPROP_BACK, false);
  ObjectSetText(sep,"---------------------------------------",10,"Arial Black",col);
  COMPARE_ROW_NR++;
  //COMPARE_Y = COMPARE_Y+3;
}

string getMovment(string sym, int timeframe, int period, int method, int applied_price, bool is_second_cur){
  double p0 = iMA( sym, timeframe, period, 0, method, applied_price, 0);
  double p1 = p0;
  double p2 = iMA( sym, timeframe, period, 0, method, applied_price, 1);
  double i = 1;
  string dir = "";
  
  if(p1 == p2){ //EQUAL
    return (0); 
  }
  
  if( p0 - p2 > 0){ //UP
    if(is_second_cur){
      dir = "-";
    }
    while(true){
      if(p1 < p2 || i==50){        
        return (StringConcatenate(dir,DoubleToStr((p0-p1)*MathPow(10,MarketInfo(sym,MODE_DIGITS)),0),"/",i));
      }else{
        i++;
        p1 = p2;
        p2 = iMA( sym, timeframe, period, 0, method, applied_price, i);
      } 
    }
  }else{ //DOWN
    if(!is_second_cur){
      dir = "-";
    }
    while(true){
      if(p1 > p2 || i==50){
        return (StringConcatenate(dir,DoubleToStr((p1-p0)*MathPow(10,MarketInfo(sym,MODE_DIGITS)),0),"/",i));
      }else{
        i++;
        p1 = p2;
        p2 = iMA( sym, timeframe, period, 0, method, applied_price, i);
      } 
    }
  }
}
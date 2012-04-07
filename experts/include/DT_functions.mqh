//+------------------------------------------------------------------+
//|                                                 DT_functions.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

bool errorCheck(string text = "unknown function"){
  int e = GetLastError();
  if(e != 0){
    string err = "unknown ";
    switch(e){
      case 4202: err = "Object does not exist."; break;
      case 4066: err = "Requested history data in updating state."; return (0); break;
      case 4099: err = "End of file."; return (0); break;
      case 4107: err = "Invalid price."; break;
      case 4054: err = "Incorrect series array using."; break;
      case 4055: err = "Custom indicator error."; break;
      case 4200: err = "Object exists already."; break;
      case 4009: err = "Not initialized string in array."; break;
      case 4002: err = "Array index is out of range."; break;
      case 4058: err = "Global variable not found."; return (0); break;
      default: err = err+e; break;      
    }
    
    Alert(StringConcatenate("Error in ",text,": ",err," (", Symbol(), ")"));
    return (false);
  }else{
    return (true);
  }
}

int APP_DELAY[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
bool delayTimer(int nth_array, int delay){
  if(GetTickCount()<APP_DELAY[nth_array]){
    return (true);
  }else{
    APP_DELAY[nth_array] = GetTickCount()+ delay;
    return (false);
  }
}

string APP_STATUS[16] = {"0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0"};
bool setAppStatus(int nth_array, string status){
  APP_STATUS[nth_array] = status;
  return (true);
}

bool isAppStatusChanged(int nth_array, string status){
  if(APP_STATUS[nth_array] == status){
    return (false);
  }else{
    APP_STATUS[nth_array] = status;
    return (true);
  }
}

bool createGlobal(string name, string value){
  string n = "DT_GO_"+name; 
  if(ObjectFind(n) == -1){
    ObjectCreate(n, OBJ_TREND, 0, 0, 0, Time[0], 0.01);
    ObjectSet(n, OBJPROP_RAY, false);
    ObjectSetText(n,value,10);
  }
  return (errorCheck("createGlobal ("+name+")"));
}

bool setGlobal(string name, string value){
  ObjectSetText("DT_GO_"+name, value);
  return (1);
}

string getGlobal(string name){
  return (ObjectDescription("DT_GO_"+name));
}


bool removeObjects(string filter = "", string type = "BO"){
  int j, obj_total= ObjectsTotal();
  string name;
  
  if(filter == ""){    
    for (j= obj_total-1; j>=0; j--) {
       name= ObjectName(j);
       if (StringSubstr(name,3,2)==type){
          ObjectDelete(name);
       }
    }  
  }else{    
    filter = type+"_"+filter;   
    int len = StringLen(filter);
    for (j= obj_total-1; j>=0; j--) {
      name= ObjectName(j);
      if (StringSubstr(name,3,len)==filter){
        ObjectDelete(name);
      }
    }
  }
  return (errorCheck("removeObjects (filter:"+filter+")"));
}

bool destroyDexTrade(){
  int j;
  string name;       
  for (j= ObjectsTotal()-1; j>=0; j--) {
    name= ObjectName(j);
    if (StringSubstr(name,0,3)=="DT_"){
     ObjectDelete(name);
    }
  }  
  return (0);
}

int getObjectNr(string filter, string type = "BO"){
	filter = type+"_"+filter;
	string name;
	int len = StringLen(filter), nr = 0, j;
	for (j= ObjectsTotal()-1; j>=0; j--) {
    name= ObjectName(j);
		if (StringSubstr(name,3,len)==filter){
			nr++;
		}
	}
	return (nr);
}

bool selectFirstOpenPosition(string symb){
  for (int i = 0; i < OrdersTotal(); i++) {      
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {        
      if (OrderSymbol() == symb) {
        return (true);        
      }
    }
  }
  return (false);
}

int getOpenPositionTicket(string symb){
  for (int i = 0; i < OrdersTotal(); i++) {      
    if (OrderSelect(i, SELECT_BY_POS)) {        
      if (OrderSymbol() == symb) {
        return (OrderTicket());
        break;
      }
    }
  }
  return (0);
}

double selectLastPositionTime(string symb){
  double time = 0;
  for (int i = 0; i < OrdersHistoryTotal(); i++) {      
    if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {        
      if (OrderSymbol() == symb) {
        time = MathMax (time, OrderCloseTime());        
      }
    }
  }
  return (time);
}

int getMoveAngle(string sym, int graph_period, int ma_period, double examined_period){
  double p1 = iMA( sym, graph_period, ma_period, 0, 0, 6, 0);
  double p2 = iMA( sym, graph_period, ma_period, 0, 0, 6, examined_period-1);
  double min = WindowPriceMin();
  double max = WindowPriceMax();
  
  
  
  if( p1 - p2 > 0){ //UP
  
    Alert(p1+"-"+p2+"="+(p1-p2));
  Alert(max+"-"+min+"="+(max-min));
  Alert("(p2-p1)/(max-min)="+((p1-p2)/(max-min)));
  Alert("examined_period/WindowBarsPerChart() "+WindowBarsPerChart()+" = "+(examined_period/WindowBarsPerChart()));
  Alert("(examined_period/WindowBarsPerChart())/((p2-p1)/(max-min)) "+" = "+(examined_period/WindowBarsPerChart())/((p1-p2)/(max-min)));
  
  return (90-MathArctan(MathTan(((p1-p2)/(WindowPriceMax()- WindowPriceMin()))/(examined_period/WindowBarsPerChart())))*180/3.14); 
  
   // return (90-(MathRound(MathArctan(((p1-p2)/(max-min))/(examined_period/WindowBarsPerChart()))*180/3.14)));
  }else{ //DOWN
  
  
  
    return ((MathRound(MathArctan((examined_period/WindowBarsPerChart())/((p2-p1)/(WindowPriceMax()-WindowPriceMin())))*180/3.14))-90);
  }
}

int getUnitInSec(){
  return (WindowBarsPerChart()*Period()*60/100);
}

int Explode(string str, string delimiter, string& arr[]){
  int i = 0;
  int pos = StringFind(str, delimiter);
  while(pos != -1){
    if(pos == 0){
      arr[i] = "";
    }else{
      arr[i] = StringSubstr(str, 0, pos);
    }
    i++;
    str = StringSubstr(str, pos+StringLen(delimiter));
    pos = StringFind(str, delimiter);
    if(pos == -1 || str == "") break;
  }
  arr[i] = str;
  return(i+1);
}

string toUpper(string sText) {  
  int iLen=StringLen(sText), i, iChar;
  for(i=0; i < iLen; i++) {
    iChar=StringGetChar(sText, i);
    if(iChar >= 97 && iChar <= 122) sText=StringSetChar(sText, i, iChar-32);
  }
  return(sText);
}

string stringReplaceAll(string str, string toFind, string toReplace) {
  int len = StringLen(toFind);
  int pos;
  string leftPart, rightPart, result = str;
  while (true) {
      pos = StringFind(result, toFind);
      if (pos == -1) {
          break;
      }
      if (pos == 0) {
          leftPart = "";
      } else {
          leftPart = StringSubstr(result, 0, pos);
      }
      rightPart = StringSubstr(result, pos + len); 
      result = leftPart + toReplace + rightPart;
  }    
  return (result);
}

double getMySpread(){
  int len = ArraySize(SYMBOLS_STR);
  for(int i=0; i < len; i++) {
    if(SYMBOLS_STR[i] == Symbol()){
      return (SPREAD[i]);
    }
  }
  return (0.0);
}

double getZigZag(double tf, int deph, int dev, int backstep, int nr, double& time){
  int found=0, i=0;
  double tmp=0;
  while(i < 100){
    tmp = iCustom(Symbol(),tf,"ZigZag",deph,dev,backstep,0,i);
    if( tmp != 0 ){
      if(found == nr){
        time = Time[i];
        return (tmp);
      }
      found++;
    }
    i++;
  }
}

string myFloor(double num, int prec){
  double tmp = MathPow(10,prec);
	if(prec<0){
		prec = 0;
	}
	return (DoubleToStr(MathFloor(num*tmp)/tmp, prec));
}

string getTPLevel(double& price){
  for(int i=FIBO_LV_NR-1;i>0;i--){
    if(ObjectGet("DT_GO_FiboLines_RECT_lv"+i,OBJPROP_TIMEFRAMES) != -1){
      price = NormalizeDouble(ObjectGet("DT_GO_FiboLines_RECT_lv"+i, OBJPROP_PRICE2), Digits);
      return (ObjectDescription("DT_GO_FiboLines_RECT_lv"+i));
    }
  }
  return (0);
}

bool menuControl(int index){
  switch(index){
    case 0:
			if(getGlobal("RULER_SWITCH") == "1"){
        setGlobal("RULER_SWITCH", "0");
        changeIcon("DT_BO_icon_round", "0");
        addComment("Switch Ruler to OFF.");
      }else{
        setGlobal("RULER_SWITCH", "1");
        changeIcon("DT_BO_icon_round", "1");
        addComment("Switch Ruler to ON.");
      }
    break;    
    case 1:
      if(getGlobal("MONITOR_SWITCH") == "1"){
        setGlobal("MONITOR_SWITCH", "0");
        changeIcon("DT_BO_icon_monitor", "0");
        addComment("Switch Monitor to OFF.",2);
      }else{
        if(Symbol() != "EURUSD-Pro"){
          addComment("Switch ON Monitor only allow in EURUSD-Pro!",1);
          return (false);
        }
        setGlobal("MONITOR_SWITCH", "1");
        changeIcon("DT_BO_icon_monitor", "1");
        addComment("Switch Monitor to ON.");
      }
    break;    
    case 2:
      if(getGlobal("TRADE_LINES_SWITCH") == "1"){
        setGlobal("TRADE_LINES_SWITCH", "0");
        changeIcon("DT_BO_icon_trade_lines", "0");
        addComment("Switch Trade lines to OFF.");
      }else{
        setGlobal("TRADE_LINES_SWITCH", "1");
        changeIcon("DT_BO_icon_trade_lines", "1");
        addComment("Switch Trade lines to ON.");
      }
    break;    
    case 3:
      if(getGlobal("CHANNEL_SWITCH") == "1"){
        setGlobal("CHANNEL_SWITCH", "0");
        changeIcon("DT_BO_icon_channel", "0");
        addComment("Switch Channel collision to OFF.");
      }else{
        setGlobal("CHANNEL_SWITCH", "1");
        changeIcon("DT_BO_icon_channel", "1");
        addComment("Switch Channel collision to ON.");
      }
    break;
    case 4:
      if(getGlobal("ARCHIVE_SWITCH") == "1"){
        setGlobal("ARCHIVE_SWITCH", "0");
        changeIcon("DT_BO_icon_archive", "0");
        addComment("Switch Archive to OFF.");
      }else{
        setGlobal("ARCHIVE_SWITCH", "1");
        changeIcon("DT_BO_icon_archive", "1");
        addComment("Switch Archive to ON.");
      }
    break; 
    case 5:
      if(getGlobal("NEWS_SWITCH") == "1"){
        setGlobal("NEWS_SWITCH", "0");
        changeIcon("DT_BO_icon_news", "0");
        addComment("Switch News to OFF.");
      }else{
        setGlobal("NEWS_SWITCH", "1");
        changeIcon("DT_BO_icon_news", "1");
        addComment("Switch News to ON.");
      }
    break;
    case 6:
      // if(getGlobal("FIBO_LINES_SWITCH") == "1"){
        // setGlobal("FIBO_LINES_SWITCH", "0");
        // changeIcon("DT_BO_icon_fibo_lines", "0");
        // addComment("Switch Fibo lines to OFF.");
      // }else{
        // setGlobal("FIBO_LINES_SWITCH", "1");
        // changeIcon("DT_BO_icon_fibo_lines", "1");
        // addComment("Switch Fibo lines to ON.");
      // }
    break;
    case 7:
      // if(getGlobal("BOUNDARY_SWITCH") == "1"){
        // setGlobal("BOUNDARY_SWITCH", "0");
        // changeIcon("DT_BO_icon_boundary", "0");
        // addComment("Switch Boundary to OFF.");
      // }else{
        // setGlobal("BOUNDARY_SWITCH", "1");
        // changeIcon("DT_BO_icon_boundary", "1");
        // addComment("Switch Boundary to ON.");
      // }
    break;
    default:
      addComment("mellé",2);
  }
  return (errorCheck("menuControl"));
}

int WindowLastVisibleBar(){
  int nr = WindowFirstVisibleBar()-WindowBarsPerChart();
  if(nr < 0){
    return (0);
  }else{
    return (nr);
  }
}

int renameChannelLine(string sel_name){
  string name;
  if ( StringSubstr(sel_name,6,6) == "t_line"){
    if( StringSubstr(sel_name,13,1) == "s" ){
      name = "DT_GO_t_line_"+StringSubstr(sel_name, StringLen(sel_name)-10, 10);
      ObjectCreate(name, OBJ_TREND, 0, ObjectGet(sel_name,OBJPROP_TIME1), ObjectGet(sel_name,OBJPROP_PRICE1), ObjectGet(sel_name,OBJPROP_TIME2), ObjectGet(sel_name,OBJPROP_PRICE2));
      ObjectSet(name, OBJPROP_COLOR, CornflowerBlue);
    }else{
      name = "DT_GO_t_line_s_"+StringSubstr(sel_name, StringLen(sel_name)-10, 10);
      ObjectCreate(name, OBJ_TREND, 0, ObjectGet(sel_name,OBJPROP_TIME1), ObjectGet(sel_name,OBJPROP_PRICE1), ObjectGet(sel_name,OBJPROP_TIME2), ObjectGet(sel_name,OBJPROP_PRICE2));
      ObjectSet(name, OBJPROP_COLOR, DeepPink);
    }
    ObjectSet(name, OBJPROP_RAY, false);
    ObjectSet(name, OBJPROP_BACK, true);
    ObjectSet(name, OBJPROP_WIDTH, ObjectGet(sel_name,OBJPROP_WIDTH));
    ObjectSet(name, OBJPROP_TIMEFRAMES, ObjectGet(sel_name,OBJPROP_TIMEFRAMES));
  }else{
    if( StringSubstr(sel_name,13,1) == "s" ){
      name = "DT_GO_h_line_"+StringSubstr(sel_name, StringLen(sel_name)-10, 10);
      ObjectCreate(name, OBJ_HLINE, 0, 0, ObjectGet(sel_name,OBJPROP_PRICE1));
      ObjectSet(name, OBJPROP_COLOR, Peru);
      
    }else{
      name = "DT_GO_h_line_s_"+StringSubstr(sel_name, StringLen(sel_name)-10, 10);
      ObjectCreate(name, OBJ_HLINE, 0, 0, ObjectGet(sel_name,OBJPROP_PRICE1));
      ObjectSet(name, OBJPROP_COLOR, DeepPink);
    }
    ObjectSet(name, OBJPROP_RAY, false);
    ObjectSet(name, OBJPROP_BACK, true);
    ObjectSet(name, OBJPROP_WIDTH, ObjectGet(sel_name,OBJPROP_WIDTH));
    ObjectSet(name, OBJPROP_TIMEFRAMES, ObjectGet(sel_name,OBJPROP_TIMEFRAMES));
  }
  ObjectDelete(sel_name);
}
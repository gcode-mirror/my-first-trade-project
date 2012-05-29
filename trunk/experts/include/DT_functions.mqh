//+------------------------------------------------------------------+
//|                                                 DT_functions.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#define CLINE_STATE_SIG 100
#define CLINE_STATE_ALL 102
#define CLINE_STATE_SUP 103
#define CLINE_STATE_RES 104

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
      case 130: err = "Invalid stops."; break;
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

int getOpenPositionByMagic(string symb, int magic){
  int i = 0, len = OrdersTotal();
  for (; i < len; i++) {      
    if (OrderSelect(i, SELECT_BY_POS)) {        
      if (OrderSymbol() == symb) {
        if( OrderMagicNumber() == magic ){
          return (OrderTicket());
        }
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
      if(getGlobal("SESSION_SWITCH") == "1"){
        setGlobal("SESSION_SWITCH", "0");
        changeIcon("DT_BO_icon_session", "0");
        addComment("Switch sessions to OFF.");
      }else{
        setGlobal("SESSION_SWITCH", "1");
        changeIcon("DT_BO_icon_session", "1");
        addComment("Switch sessions to ON.");
      }
    break;
    case 7:
      if(getGlobal("ZOOM_SWITCH") != "0"){
        setGlobal("ZOOM_SWITCH", "0");
        changeIcon("DT_BO_icon_zoom", "0");
        addComment("Switch zoom to OFF.");
      }else{
        setGlobal("ZOOM_SWITCH", Period());
        changeIcon("DT_BO_icon_zoom", "1");
        addComment("Switch zoom to ON.");
      }
    break;
    default:
      addComment("mell�",2);
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

bool renameChannelLine( string sel_name, string state = "", int group = -1 ){
  string name, desc;
  if( group == -1 ){
    group = getCLineProperty( sel_name, "group" );
  }
  
  if( state == "" ){
    state = StringSubstr( sel_name, 15, 3 );
  }
  
  name = StringConcatenate( "DT_GO_cLine_g", group , "_", state, "_", StringSubstr(sel_name, StringLen(sel_name)-10, 11) );
  
  if( ObjectFind(name) != -1 ){
    addComment( name+" is already exist!", 1 );
    return ( false );
  }
  
  ObjectCreate( name, ObjectType(sel_name), 0, ObjectGet(sel_name,OBJPROP_TIME1), ObjectGet(sel_name,OBJPROP_PRICE1), ObjectGet(sel_name,OBJPROP_TIME2), ObjectGet(sel_name,OBJPROP_PRICE2) );
  ObjectSet( name, OBJPROP_STYLE, ObjectGet( sel_name, OBJPROP_STYLE ) );
  ObjectSet( name, OBJPROP_RAY, ObjectGet(sel_name,OBJPROP_RAY) );
  ObjectSet( name, OBJPROP_BACK, true );
  ObjectSet( name, OBJPROP_WIDTH, ObjectGet(sel_name,OBJPROP_WIDTH) );
  ObjectSet( name, OBJPROP_TIMEFRAMES, ObjectGet(sel_name,OBJPROP_TIMEFRAMES) );
  
  desc = ObjectDescription( sel_name );
  if( desc == "" ){
    desc = StringConcatenate(TimeToStr( TimeLocal(), TIME_DATE|TIME_SECONDS)," G",group);
  }
  
  if( state == "res" ){
    ObjectSet( name, OBJPROP_COLOR, DeepPink);
    ObjectSetText(name, StringConcatenate(StringSubstr(desc, 0, 19)," G", group, " \\/ \\/ \\/ \\/ \\/" ));
    
    
  }else if( state == "sup" ){
    ObjectSet( name, OBJPROP_COLOR, LimeGreen);
    ObjectSetText(name, StringConcatenate(StringSubstr(desc, 0, 19)," G", group, " /\\ /\\ /\\ /\\ /\\" ));
  
  }else if( state == "all" ){
    ObjectSet( name, OBJPROP_COLOR, Magenta);
    ObjectSetText(name, StringConcatenate(StringSubstr(desc, 0, 19)," G", group, " /\\ \\/ /\\ \\/ /\\" ));
    
  }else{
    ObjectSet( name, OBJPROP_COLOR, CornflowerBlue );
    ObjectSetText(name, StringConcatenate(StringSubstr(desc, 0, 19)," G", group));
  }
  
  ObjectDelete(sel_name);
  return ( true );
}

string getSelectedLine( double time_cord, double price_cord, bool search_all = false ){
  int j, obj_total= ObjectsTotal(), type;
  string name, sel_name = "";
  double price, ts, t1, t2, dif, sel_dif = 999999, max_dist = ( WindowPriceMax(0) - WindowPriceMin(0) ) / 10;
  
  for (j= obj_total-1; j>=0; j--) {
    name = ObjectName(j);
    if( (search_all || StringSubstr( name, 5, 7 ) == "_cLine_") && ObjectGet( name, OBJPROP_TIMEFRAMES ) != -1 ){
      type = ObjectType( name );
      if( type == OBJ_TREND ){
        t1 = ObjectGet(name,OBJPROP_TIME1);
        t2 = ObjectGet(name,OBJPROP_TIME2);
        price = ObjectGetValueByShift( name, iBarShift( NULL, 0, time_cord ));
        if( price != 0.0 ){
          dif = MathAbs( price - price_cord );         
          if( dif < sel_dif && dif < max_dist ){
            sel_dif = dif;
            sel_name = name;
          }
        }else{
          GetLastError();
        }
      }else if( type == OBJ_HLINE ){
        price = ObjectGet(name, OBJPROP_PRICE1);
        dif = MathAbs( price - price_cord );
        if( dif < sel_dif ){
          sel_dif = dif;
          sel_name = name;
        }
      }
    }
  }
  errorCheck("getSelectedLine");
  return (sel_name);
}

bool getFibo100( double fibo_0, double& fibo_100, double& time ){
  double time1, time2, zz0, zz1;
  zz0 = getZigZag( PERIOD_M15, 12, 5, 3, 0, time1 );
  zz1 = getZigZag( PERIOD_M15, 12, 5, 3, 1, time2 );
  
  if( MathMax(zz0, zz1) > fibo_0 && MathMin(zz0, zz1) < fibo_0 ){
    fibo_100 = zz0;
    time = time1;
  }else if( MathAbs( zz0 - fibo_0 ) > MathAbs( zz1 - fibo_0 ) ){
    fibo_100 = zz0;
    time = time1;
  }else{
    fibo_100 = zz1;
    time = time2;
  }
  errorCheck("getFibo100");
}

double getFibo23Dif(double fibo_0, double& fibo_100, double min_time = 0.0, double min_dist = 0.0, double max_dist = 0.0){
  if( fibo_100 == 0.0 ){
    double time1, time2;
    double zz0 = getZigZag( PERIOD_M15, 12, 5, 3, 0, time1 );
    double zz1 = getZigZag( PERIOD_M15, 12, 5, 3, 1, time2 );
    
    if( MathMax(zz0, zz1) > fibo_0 && MathMin(zz0, zz1) < fibo_0 ){
      fibo_100 = zz0;
    }else if( MathAbs( zz0 - fibo_0 ) > MathAbs( zz1 - fibo_0 ) ){
      fibo_100 = zz0;
    }else{
      fibo_100 = zz1;
      time1 = time2;
    }
    
    if( min_dist != 0.0 ){
      if( MathAbs( fibo_100 - fibo_0 ) < min_dist ){
        // Alert(Symbol()+" Fibo DISTANCE is too SMALL! MINDIST: "+min_dist+" DIST:"+(fibo_100 - fibo_0));
        return (0.0);
      }
    }
    
    if( max_dist != 0.0 ){
      if( MathAbs( fibo_100 - fibo_0 ) > max_dist ){
        Alert(Symbol()+" Fibo DISTANCE is too BIG! MAXDIST: "+max_dist+" DIST:"+(fibo_100 - fibo_0));
        return ( -1.0 * iBarShift( NULL , 0, time1 ) );
      }
    }
    
    if( min_time != 0.0 ){
      if( Time[0] - time1 < min_time ){
        //Alert(Symbol()+" Fibo TIME is too SMALL! "+(Time[0] - time1));
        return ( -1.0 * iBarShift( NULL , 0, time1 ) );
      }
    }
  }

  Alert(Symbol()+" time: "+(Time[0] - time1)+" dist:"+(fibo_100 - fibo_0));  
  return ( (MathMax(fibo_0, fibo_100) - MathMin(fibo_0, fibo_100)) * 0.23 ); // 0.236
}

int getPositionByDaD(double price_cord, string symb = ""){
  int i = 0, len = OrdersTotal(), ticket = 0;
  double o, dif = 999999;

  if( symb == ""){
    symb = Symbol();
  }
  
  for (; i < len; i++) {      
    if (OrderSelect(i, SELECT_BY_POS)) {        
      if (OrderSymbol() == symb) {
        o = OrderOpenPrice();
        if( MathAbs( o - price_cord ) < dif ){
          dif = MathAbs( o - price_cord );
          ticket = OrderTicket();
        }
      }
    }
  }
  return (ticket);
}

string getPeriodName( int peri ){
  switch( peri ){
    case 1: return ("Min 1 ");
    case 5: return ("Min 5 ");
    case 15: return ("Min 15");
    case 30: return ("Min 30");
    case 60: return ("Hour 1");
    case 240: return ("Hour 4");
    case 1440: return ("Daily ");
    case 10080: return ("Weekly");
    case 43200: return ("Month ");
    default: return ("error");
  }
}

int getPeriodSibling(int curr_peri, string dir){
  int period_val[8] = {0,1,5,15,30,60,240,1440};
  
  int len = ArraySize(period_val);
  for( int i=0; i < len; i++ ) {
    if( period_val[i] == curr_peri ){
      if( dir == "next" ){
        if( i >= len ){
          return ( period_val[1] );
        }else{
          return ( period_val[i+1] );
        }
      }else{
        if( i < 1 ){
          return ( period_val[7] );
        }else{
          return ( period_val[i-1] );
        }
      }
    }
  }
  return ( 0 );
}

bool toggleObjects( string filter, int status, string type = "BO" ){
  int i, len, total;
  string name;  
  total= ObjectsTotal();

  filter = type + "_" + filter;
  len = StringLen(filter);
  for( i= total - 1 ; i >= 0; i-- ) {
    name= ObjectName(i);
    if( StringSubstr( name, 3, len ) == filter ){
      ObjectSet( name, OBJPROP_TIMEFRAMES, status );
    }
  }
  return (errorCheck( StringConcatenate("toggleObjects (filter:",filter," status:", status,")") ));
}

double getScaleNumber( double p1, double p2, string sym ){
  return ( NormalizeDouble((MathAbs( p1 - p2 ) / MarketInfo( sym, MODE_POINT )) * MarketInfo( sym, MODE_TICKVALUE ), 1) );
}

int getCLineProperty( string name, string attr_name ){
  if( attr_name == "group" ){
    string g_id = StringSubstr( name, 13, 1 );
    if( IsNumeric(g_id) ){
      return ( StrToInteger(g_id) );
    }
  }else if( attr_name == "state" ){
    string state = StringSubstr( name, 15, 3 );
    if( state == "sig" ){
      return ( CLINE_STATE_SIG );
      
    }else if( state == "sup" ){
      return ( CLINE_STATE_SUP );
      
    }else if( state == "res" ){
      return ( CLINE_STATE_RES );
    
    }else if( state == "all" ){
      return ( CLINE_STATE_ALL );
    }
  }else if( attr_name == "ts" ){
    string ts = StringSubstr( name, 19, 10 );
    if( IsNumeric(ts) ){
      return ( StrToInteger(ts) );
    }
  }
  Alert( "Input fail getCLineProperty name: "+name+" attribute: "+attr_name );
  return ( -1 );
}

bool IsNumeric(string c){
  int i = StringGetChar( c, 0 );
  return( i >= 48 && i <= 57 );
}

double getClineValueByShift( string name, int shift = 0 ){
  if( ObjectType( name ) == OBJ_TREND ){
    return ( ObjectGetValueByShift( name, shift ) );
  }else{
    return ( ObjectGet( name, OBJPROP_PRICE1 ) );
  }
}
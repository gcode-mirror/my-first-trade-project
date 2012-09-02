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
      case 4066: err = "Requested history data in updating state."; return (true);
      case 4099: err = "End of file."; return (true);
      case 4107: err = "Invalid price."; break;
      case 4054: err = "Incorrect series array using."; break;
      case 4055: err = "Custom indicator error."; break;
      case 4200: err = "Object exists already."; break;
      case 4009: err = "Not initialized string in array."; break;
      case 4002: err = "Array index is out of range."; break;
      case 4058: err = "Global variable not found."; break;
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
    filter = StringConcatenate( type, "_" ,filter, "_" );   
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
    if( tmp != 0.0 ){
      if( found == nr ){
        time = iTime( NULL, tf, i );
        return ( tmp );
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
    // case 3:
      // if(getGlobal("CHANNEL_SWITCH") == "1"){
        // setGlobal("CHANNEL_SWITCH", "0");
        // changeIcon("DT_BO_icon_channel", "0");
        // addComment("Switch Channel collision to OFF.");
      // }else{
        // setGlobal("CHANNEL_SWITCH", "1");
        // changeIcon("DT_BO_icon_channel", "1");
        // addComment("Switch Channel collision to ON.");
      // }
    // break;
    case 3:
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
    case 4:
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
    case 5:
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
    case 6:
      if( isVisibleThisTimeframe( getGlobal("ZIGZAG_SWITCH") ) == "1" ){
        setGlobal( "ZIGZAG_SWITCH", removeTimeframeFromStr( getGlobal("ZIGZAG_SWITCH"), Period() ) );
        changeIcon( "DT_BO_icon_zigzag", "0" );
        addComment( "Switch OFF ZigZag at "+getPeriodName( Period() )+" period." );
      }else{
        setGlobal( "ZIGZAG_SWITCH", getGlobal("ZIGZAG_SWITCH")+" "+Period() );
        changeIcon( "DT_BO_icon_zigzag", "1" );
        addComment( "Switch ON ZigZag at "+getPeriodName( Period() )+" period." );
      }
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

bool renameChannelLine( string sel_name, string state = "" ){
  string name, desc;
  if( state == "" ){
    state = "sig";
  }
  
  name = StringConcatenate( StringSubstr(sel_name, 0, 15), state, "_", getCLineProperty(sel_name, "ts") );
  
  if( ObjectFind(name) != -1 ){
    ObjectDelete(name);
  }
  
	ObjectCreate( name, ObjectType(sel_name), 0, ObjectGet(sel_name,OBJPROP_TIME1), ObjectGet(sel_name,OBJPROP_PRICE1), ObjectGet(sel_name,OBJPROP_TIME2), ObjectGet(sel_name,OBJPROP_PRICE2) );
  ObjectSet( name, OBJPROP_STYLE, ObjectGet( sel_name, OBJPROP_STYLE ) );
  ObjectSet( name, OBJPROP_RAY, ObjectGet(sel_name,OBJPROP_RAY) );
  ObjectSet( name, OBJPROP_BACK, true );
  ObjectSet( name, OBJPROP_WIDTH, ObjectGet(sel_name,OBJPROP_WIDTH) );
  ObjectSet( name, OBJPROP_TIMEFRAMES, ObjectGet(sel_name,OBJPROP_TIMEFRAMES) );
  
  desc = StringSubstr(ObjectDescription( sel_name ), 0, 19);
  if( desc == "" ){
    desc = TimeToStr( TimeLocal(), TIME_DATE|TIME_SECONDS);
  }
  
  if( state == "res" ){
    ObjectSet( name, OBJPROP_COLOR, DeepPink);
    ObjectSetText(name, StringConcatenate( desc, " \\/ \\/ \\/ \\/ \\/" ) );
    
  }else if( state == "sup" ){
    ObjectSet( name, OBJPROP_COLOR, LimeGreen);
    ObjectSetText(name, StringConcatenate( desc, " /\\ /\\ /\\ /\\ /\\" ) );
  
  }else if( state == "all" ){
    ObjectSet( name, OBJPROP_COLOR, Magenta);
    ObjectSetText(name, StringConcatenate( desc, " /\\ \\/ /\\ \\/ /\\" ) );
    
  }else{
    ObjectSet( name, OBJPROP_COLOR, CornflowerBlue );
    ObjectSetText(name, desc);
  }
  
	ObjectDelete(sel_name);
  return ( true );
}

string getSelectedLine( double time_cord, double price_cord, bool search_all = false, int accuracy = 10 ){
  int j, obj_total= ObjectsTotal(), type;
  string name, sel_name = "";
  double price, ts, t1, t2, dif, sel_dif = 999999, max_dist = ( WindowPriceMax(0) - WindowPriceMin(0) ) / accuracy;
  
  for (j= obj_total-1; j>=0; j--) {
    name = ObjectName(j);
    if( (search_all || StringSubstr( name, 7, 5 ) == "Line_") && ObjectGet( name, OBJPROP_TIMEFRAMES ) != -1 ){
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
    }
  }
  errorCheck("getSelectedLine");
  return (sel_name);
}

bool getFibo100( int peri, double fibo_0, double& fibo_100, double& time ){
  double time1, time2, zz0, zz1;
  zz0 = getZigZag( peri, 12, 5, 3, 0, time1 );
  zz1 = getZigZag( peri, 12, 5, 3, 1, time2 );
  
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

string getCLineProperty( string name, string attr_name ){
  if( attr_name == "tf" ){
    return (StringSubstr( name, 12, 2 ));
  }else if( attr_name == "type" ){
		return ( StringSubstr( name, 6, 5 ) );
  }else if( attr_name == "state" ){
		return ( StringSubstr( name, 15, 3 ) );
  }else if( attr_name == "ts" ){
		return ( StringSubstr( name, 19, 10 ) );
  }
  Alert( "Input fail getCLineProperty name: "+name+" attribute: "+attr_name );
  return ( "" );
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

string PadString(string toBePadded, string paddingChar, int paddingLength){
  while(StringLen(toBePadded) <  paddingLength){
    toBePadded = StringConcatenate(paddingChar,toBePadded);
  }
  return (toBePadded);
}

int getClineOpenPosition(){
  int i = 0, len = OrdersTotal();
  string symb = Symbol();
  for( ; i < len; i++ ) {
    if( OrderSelect( i, SELECT_BY_POS ) ) {
      if( OrderSymbol() == symb ) {
        if( OrderMagicNumber() > 1000 ){
          return (OrderTicket());
        }
      }
    }
  }
  return (0);
}

bool splitStr( string str, string sep, string &arr[] ){
	if( str == "" || str == sep ){
		return (false);
	}
	str = str + sep;
	int nr = 0, i = 0, len = StringLen( str ), sep_len = StringLen( sep ), last_i = 0;
	string part;
	for( ; i < len; i++ ){
		if( StringSubstr( str, i, sep_len ) == sep ){
			part = StringSubstr( str, last_i, i - last_i );
			if( i == last_i || part == "" || part == sep ){
				continue;
			}
			ArrayResize( arr, nr + 1 );
			arr[nr] = part;
			nr++;
			last_i = i + sep_len;
			i = i + sep_len - 1;
		}
	}
	return (true);
}

string isVisibleThisTimeframe( string appIsOn ){
	string arr[0], peri = Period();
	splitStr( appIsOn, " ", arr );
	int len = ArraySize(arr);
	for( int i = 0; i < len; i++){
		if( arr[i] == peri ){
			return ("1");
		}
	}
	return ("0");
}

string removeTimeframeFromStr( string tf, string peri ){
	string arr[0], res = "0";
	splitStr( tf, " ", arr );
	int len = ArraySize(arr);
	
	for( int i = 0; i < len; i++){
		if( arr[i] == peri || arr[i] == "0" ){
			continue;
		}else{
			res = res + " " + arr[i];
		}
	}
	return ( res );
}

string getPeriodSortName( int peri ){
  switch( peri ){
    case 1: return ("M1");
    case 5: return ("M5");
    case 15: return ("M15");
    case 30: return ("M30");
    case 60: return ("H1");
    case 240: return ("H4");
    case 1440: return ("D1");
    case 10080: return ("W1");
    case 43200: return ("MO");
    default: return ("error");
  }
}

string checkPriceIsZZ( string name ){
	string tf = getCLineProperty( name, "tf" );
	int peri;
	if( tf == "H4" ){
		peri = PERIOD_H4;
	}else if( tf == "D1" ){
		peri = PERIOD_D1;
	}else{
		return ("Wrong tf:" + tf);
	}
	
	double p1 = ObjectGet( name, OBJPROP_PRICE1 );
	double p2 = ObjectGet( name, OBJPROP_PRICE2 );
	
	int i = 0;
	double zz_price;
	while( i < Bars ){
		if( p1 == -1.0 && p2 == -1.0 ){
			break;
		}
    zz_price = iCustom( Symbol(), peri, "ZigZag", 12, 5, 3, 0, i );
    if( zz_price != 0.0 ){
			if( zz_price == p1 ){
				p1 = -1.0;
			}
			if( zz_price == p2 ){
				p2 = -1.0;
			}
    }
    i++;
  }
	if( p1 == -1.0 && p2 == -1.0 ){
		return ("ok");
	}else{
		return ("Not FIT to ZZ in " + tf + ": " + name +"!" );
	}
}
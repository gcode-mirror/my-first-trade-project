//+------------------------------------------------------------------+
//|                                                      DT_news.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#import "wininet.dll"
int InternetAttemptConnect (int x);
int InternetOpenA(string sAgent, int lAccessType,string sProxyName = "", string sProxyBypass = "",int lFlags = 0);
int InternetOpenUrlA(int hInternetSession, string sUrl,string sHeaders = "", int lHeadersLength = 0,int lFlags = 0, int lContext = 0);
int InternetReadFile(int hFile, int& sBuffer[], int lNumBytesToRead, int& lNumberOfBytesRead[]);
int InternetCloseHandle(int hInet);

#define NEWS_TIME 0
#define NEWS_CURRENCY 1
#define NEWS_DESC 2
#define NEWS_PRIO  3
#define NEWS_ACT 4
#define NEWS_FORC 5
#define NEWS_PREV 6
#define NEWS_UNIT 7
#define NEWS_REL 8
string NEWS_DATA[1][9];

string NEWS_FILE_NAMES[];
double MIN_PRICE_NEWS = 0, MAX_PRICE_NEWS = 0, LAST_UPDATE_ID = 0.0;
int NEWS_DOWNLOAD_TIMER = 0;


bool initNews(string isOn){
  setAppStatus(APP_ID_NEWS, isOn);
  if(isOn == "0" || Period() > PERIOD_H4){        
    return (false);    
  }

  newsFileName();
      
  if(doFileDownLoad()){
    downLoadWebPageToFile();
  }else if( GlobalVariableGet( "NEWS_update_id" )+60 < TimeCurrent() ){
    downLoadWebPageToFile();
  }
  NEWS_DOWNLOAD_TIMER = GetTickCount() + 60000;
  
  csvNewsFileToArray();
  
  ObjectCreate( "DT_BO_icon_news_3", OBJ_LABEL, 0, 0, 0);
  ObjectSet( "DT_BO_icon_news_3", OBJPROP_CORNER, 0);
  ObjectSet( "DT_BO_icon_news_3", OBJPROP_XDISTANCE, ObjectGet( "DT_BO_icon_news_1", OBJPROP_XDISTANCE) + 15 );
  ObjectSet( "DT_BO_icon_news_3", OBJPROP_YDISTANCE, ObjectGet( "DT_BO_icon_news_1", OBJPROP_YDISTANCE) + 11 );
  ObjectSet( "DT_BO_icon_news_3", OBJPROP_BACK, false);
  ObjectSetText( "DT_BO_icon_news_3", getGlobal("PAST_NEWS"), 8, "Arial Black", Blue );
  
  return (errorCheck("initNews"));
}

bool startNews(string isOn){
  if(isAppStatusChanged(APP_ID_NEWS, isOn)){
    if(isOn == "1"){
      initNews("1");
    }else{
      deinitNews();
      return (false);
    }    
  }
	if(isOn == "0" || Period() > PERIOD_H4){return (false);}
	if(delayTimer(APP_ID_NEWS, 1000)){return (false);}

  if(Symbol() == "EURUSD-Pro"){
    if( GetTickCount() > NEWS_DOWNLOAD_TIMER ){
      NEWS_DOWNLOAD_TIMER = GetTickCount() + 60000;
      downLoadWebPageToFile();   
    }
  }
  
  if( LAST_UPDATE_ID != GlobalVariableGet( "NEWS_update_id" ) ){
    LAST_UPDATE_ID = GlobalVariableGet( "NEWS_update_id" );
    csvNewsFileToArray();
    displayNews();
  
  }else if(MIN_PRICE_NEWS != WindowPriceMin(0) || MAX_PRICE_NEWS != WindowPriceMax(0)){
    displayNews();
  }
  return (true);
}

bool deinitNews(){
  removeObjects("news");
  return (errorCheck("deinitNews"));
}

bool displayNews(){
  removeObjects("news");
  MAX_PRICE_NEWS = WindowPriceMax(0);
  MIN_PRICE_NEWS = WindowPriceMin(0);
  
  double pip, item_size, gap, p1 ,p2, time, prev_top_price, prev_bottom_price;
  int position, i, len = ArrayRange(NEWS_DATA,0), time_shift, prev_top_time_shift = -1, prev_bottom_time_shift = -1;
  string desc;

  pip = 1 / MathPow(10,Digits);
  item_size = NormalizeDouble( (MAX_PRICE_NEWS-MIN_PRICE_NEWS)/80, Digits );
  if( item_size < pip ){
    item_size = 6 * pip;
  }
  
  gap = NormalizeDouble( (MAX_PRICE_NEWS-MIN_PRICE_NEWS)/300, Digits );
  if( gap < pip ){
    gap = 2 * pip;
  }
  
  for( i=0; i < len; i++){
    position = StringFind( Symbol(), NEWS_DATA[i][NEWS_CURRENCY]);
    if(position != -1){
      time = StrToDouble(NEWS_DATA[i][NEWS_TIME]);
      time = time - MathMod( time, (Period() * 60) );
      desc = StringConcatenate("[",NEWS_DATA[i][NEWS_ACT],"|",NEWS_DATA[i][NEWS_FORC],"|",NEWS_DATA[i][NEWS_PREV],"]",NEWS_DATA[i][NEWS_UNIT]," ",NEWS_DATA[i][NEWS_DESC]," ",TimeHour(time),":",TimeMinute(time));
      time_shift = iBarShift( NULL, 0, time - 604800 );
      
      if(position == 0){
        if( prev_top_time_shift == time_shift ){
          p1 = prev_top_price - gap;
        }else{
          p1 = MAX_PRICE_NEWS;
        }
        p2 = p1 - item_size;
        prev_top_price = p2;
        prev_top_time_shift = time_shift;
      }else{
        if( prev_bottom_time_shift == time_shift ){
          p2 = prev_bottom_price + gap;
        }else{
          p2 = MIN_PRICE_NEWS;
        }
        p1 = p2 + item_size;
        prev_bottom_price = p1;
        prev_bottom_time_shift = time_shift;
      }
      createNewsLine(StringConcatenate("DT_BO_news_",NEWS_DATA[i][NEWS_CURRENCY],"_",i), time, p1, p2, desc, NEWS_DATA[i][NEWS_PRIO],StrToDouble(NEWS_DATA[i][NEWS_REL]));
    }
  }
  
  return (errorCheck("displayNews"));
}

bool createNewsLine(string name, double t, double p1, double p2, string text, string prio, double width){
  color c = Green;
  if(prio == "HIGH"){ c = Red;
  }else if(prio == "MEDIUM"){c = Orange;
  }else if(prio == "LOW"){c = Blue; }
  
	ObjectCreate(name, OBJ_TREND, 0, t, p1, t, p2);
	ObjectSet(name, OBJPROP_COLOR, c);             
	ObjectSet(name, OBJPROP_RAY, false);
	ObjectSet(name, OBJPROP_STYLE, STYLE_SOLID);
	ObjectSet(name, OBJPROP_WIDTH, width);
	ObjectSetText(name, text, 8);
}

bool csvNewsFileToArray(){
  int handle, i, j, line_idx = 0, col_idx, len = ArraySize( NEWS_FILE_NAMES );
  string data, prio;
  
  for( i = 0; i < len; i++ ){
    handle = FileOpen( NEWS_FILE_NAMES[i], FILE_READ, "," );
    if( handle < 1 ){
      if( GetLastError() == 4103 && i != 0 ){
        addComment( NEWS_FILE_NAMES[i]+" ("+( i + 1 )+") doesn't exist!", 1 );
        setGlobal( "PAST_NEWS", i );
        ArrayResize( NEWS_FILE_NAMES, i );
      }
      FileClose(handle);
      return (0);
    }
    
    j = 0;
    while( j < 9 && !FileIsEnding(handle) ){ //skip first row
      FileReadString(handle);
      j++;      
    }
    
    col_idx = 0;
    while(!FileIsEnding(handle)){
      data = stringReplaceAll(FileReadString(handle), "¥", "Y");
      data = stringReplaceAll(data, "£", "P");
            
      if(col_idx == 9){
        if(data == ""){
          break;
        }           
        line_idx++;
        ArrayResize( NEWS_DATA, line_idx + 1 );
        col_idx = 0;              
      }
      
      if(col_idx == 0){
        NEWS_DATA[line_idx][NEWS_TIME] = getTSdate(data, FileReadString(handle));
        col_idx++;
      }else if(col_idx == 3){
        NEWS_DATA[line_idx][NEWS_CURRENCY] = toUpper(data);
      }else if(col_idx == 4){
        NEWS_DATA[line_idx][NEWS_DESC] = StringSubstr( data, 4, StringLen(data)-4 );
      }else if(col_idx == 5){
        prio = toUpper(StringTrimRight(StringTrimLeft(data)));       
        if(prio == "HIGH" || prio == "MEDIUM" || prio == "LOW"){
          NEWS_DATA[line_idx][NEWS_PRIO] = prio;         
        }else{        
          NEWS_DATA[line_idx][NEWS_DESC] = NEWS_DATA[line_idx][NEWS_DESC] + ","+data;
          col_idx--;
        }        
        NEWS_DATA[line_idx][NEWS_PRIO] = prio;
      }else if(col_idx == 6){
        if(data == ""){data = "-";}      
        assortNumbers(data);
        NEWS_DATA[line_idx][NEWS_ACT] = data;
      }else if(col_idx == 7){
        if(data == ""){data = "-";}
        NEWS_DATA[line_idx][NEWS_UNIT] = assortNumbers(data);
        NEWS_DATA[line_idx][NEWS_FORC] = data;
        NEWS_DATA[line_idx][NEWS_REL] = setNewsRelevance(NEWS_DATA[line_idx][NEWS_ACT], NEWS_DATA[line_idx][NEWS_FORC]);
      }else if(col_idx == 8){        
        if(data == ""){data = "-";}
        assortNumbers(data);
        NEWS_DATA[line_idx][NEWS_PREV] = data;
      }
      col_idx++; 
    }    
    FileClose(handle);
  }
  return (errorCheck("csvNewsFileToArray"));
}

string setNewsRelevance(string act, string forc){
  if(act == "-" || forc == "-"){
    return ("1");
  }  
  double max = MathMax(StrToDouble(act),StrToDouble(forc)), min = MathMin(StrToDouble(act),StrToDouble(forc));
  double dif = max-min, multi;
  min = MathAbs(min);
  if(min == 0.0){
    multi = MathAbs(max);
  }else{
    multi = dif/min;
  }
// Alert("act:"+StrToDouble(act)+" forc:"+StrToDouble(forc)+" dif:"+dif+" multi:"+multi+" iii:"+min);
  
  if(multi>3){
    return ("3");
  }else if(multi < 1){
    return ("1");
  }else{    
    return (DoubleToStr(MathRound(multi),0));
  }  
  return ("1");
}

string assortNumbers(string& str){
  int code;
  string tmp = "", tmp2 = "";
  for (int i = 0; i < StringLen(str); i++) {
    code= StringGetChar(str, i);
    if ((code >= 48 && code <= 57) || code == 45 || code == 46) {
      tmp = tmp + StringSetChar(" ", 0, code);
    }else{    
      tmp2 = tmp2 + StringSetChar(" ", 0, code);
    }
  }
  str = tmp;
  return (tmp2);
}

string getTSdate(string date, string time){
  string tmp[3], mon;    
  Explode(date, " ", tmp);
  
  if(tmp[1] == "Jan"){mon = "1";
  }else if(tmp[1] == "Feb"){mon = "2";
  }else if(tmp[1] == "Mar"){mon = "3";
  }else if(tmp[1] == "Apr"){mon = "4";
  }else if(tmp[1] == "May"){mon = "5";
  }else if(tmp[1] == "Jun"){mon = "6";
  }else if(tmp[1] == "Jul"){mon = "7";
  }else if(tmp[1] == "Aug"){mon = "8";
  }else if(tmp[1] == "Sep"){mon = "9";
  }else if(tmp[1] == "Oct"){mon = "10";
  }else if(tmp[1] == "Nov"){mon = "11";
  }else if(tmp[1] == "Dec"){mon = "12";
  }else{ mon = "";}
    
  if(mon != ""){
    date = Year()+"."+mon+"."+tmp[2]+" ";
  }else{
    date = "";
  } 
  return (StrToTime(date+time));
}

bool doFileDownLoad(){ 
 int handle=FileOpen(NEWS_FILE_NAMES[0], FILE_READ);
 if(handle>0){
   FileClose(handle);
   return(false);   
 }
 GetLastError(); // File does not exist if FileOpen return -1 or if GetLastError = ERR_CANNOT_OPEN_FILE (4103) 
 return(true); 
}

bool newsFileName(){
  int i, nr_of_weeks = StrToInteger( getGlobal("PAST_NEWS") );
  datetime date;
  
  ArrayResize( NEWS_FILE_NAMES, nr_of_weeks );
  for( i = 0; i < nr_of_weeks; i++ ){
    date = TimeLocal() - (TimeDayOfWeek(TimeLocal()) * 86400 ) - ( i * 604800 );
    NEWS_FILE_NAMES[i] = StringConcatenate("Calendar-", PadString(DoubleToStr(TimeMonth(date),0),"0",2),"-",PadString(DoubleToStr(TimeDay(date),0),"0",2),"-",TimeYear(date),".csv");
  }
  return ( errorCheck("newsFileName") );
}

bool downLoadWebPageToFile(){
  string url = StringConcatenate( "http://www.dailyfx.com/files/", NEWS_FILE_NAMES[0] );  
  if(!IsDllsAllowed())   {
    Alert("Please allow DLL imports");
    return(false);
  }

  int result = InternetAttemptConnect(0);
  if(result != 0){
    Alert("Cannot connect to internet - InternetAttemptConnect()");
    return(false);
  }

  int hInternetSession = InternetOpenA("Microsoft Internet Explorer", 0, "", "", 0);
  if(hInternetSession <= 0){
    Alert("Cannot open internet session - InternetOpenA()");
    return(false);         
  }
  int hURL = InternetOpenUrlA(hInternetSession, url, "", 0, 0, 0);
  if(hURL <= 0){
    Alert("Cannot open URL ", url, " - InternetOpenUrlA() "+Symbol());
    InternetCloseHandle(hInternetSession);
    return(false);         
  }
       
  int cBuffer[256];
  int dwBytesRead[1]; 
  string fileContents = "";
  while(!IsStopped()){
    for(int i = 0; i<256; i++) cBuffer[i] = 0;
    bool bResult = InternetReadFile(hURL, cBuffer, 1024, dwBytesRead);
    if(dwBytesRead[0] == 0) break;
    string text = "";   
    for(i = 0; i < 256; i++){
       text = text + CharToStr(cBuffer[i] & 0x000000FF);
       if(StringLen(text) == dwBytesRead[0]) break;
       text = text + CharToStr(cBuffer[i] >> 8 & 0x000000FF);
       if(StringLen(text) == dwBytesRead[0]) break;
       text = text + CharToStr(cBuffer[i] >> 16 & 0x000000FF);
       if(StringLen(text) == dwBytesRead[0]) break;
       text = text + CharToStr(cBuffer[i] >> 24 & 0x000000FF);   
    }
    fileContents = fileContents + text;
    //Sleep(1);
  }
  InternetCloseHandle(hInternetSession);

  // Save to text file  
  int handle;
  handle=FileOpen( NEWS_FILE_NAMES[0], FILE_CSV|FILE_WRITE, ';');
  if(handle>0){
   FileWrite(handle, fileContents);
   FileClose(handle);
  }
  GlobalVariableSet( "NEWS_update_id", TimeCurrent() );
  return (errorCheck("downLoadWebPageToFile"));
}
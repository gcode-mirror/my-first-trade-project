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

string NEWS_FILE_NAME;
double MIN_PRICE_NEWS = 0, MAX_PRICE_NEWS = 0, NEWS_RELOAD_TIMER;

bool initNews(string isOn){
  setAppStatus(APP_ID_NEWS, isOn);
  if(isOn == "0" || Period() > PERIOD_H4){        
    return (false);    
  }

  NEWS_RELOAD_TIMER = TimeLocal()+300;  
  NEWS_FILE_NAME = newsFileName();
      
  if(doFileDownLoad()){
    setGlobal("NEWS_UPLOAD_TIME", DoubleToStr(TimeLocal()+500,0));
    downLoadWebPageToFile();
  }
  csvNewsFileToArray();  
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

  if(Symbol() == "EURUSD-Pro" && StrToDouble(getGlobal("NEWS_UPLOAD_TIME")) < TimeLocal()){
    setGlobal("NEWS_UPLOAD_TIME", DoubleToStr(TimeLocal()+500,0));
    downLoadWebPageToFile();   
  }
  
  if(NEWS_RELOAD_TIMER < TimeLocal()){
    NEWS_RELOAD_TIMER = TimeLocal()+300;
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
  
  double y1;
  double size = (MAX_PRICE_NEWS-MIN_PRICE_NEWS)*0.015;
  int len = ArrayRange(NEWS_DATA,0);
  int news_same_time_up = 0, news_same_time_down = 0, position;
  string desc;
  double y2, time, round_time, prev_time = 0;
  
  for(int i=0;i<len;i++){
    position = StringFind( Symbol(), NEWS_DATA[i][NEWS_CURRENCY]);
    if(position != -1){
      time = StrToDouble(NEWS_DATA[i][NEWS_TIME]);
      desc = StringConcatenate("[",NEWS_DATA[i][NEWS_ACT],"|",NEWS_DATA[i][NEWS_FORC],"|",NEWS_DATA[i][NEWS_PREV],"]",NEWS_DATA[i][NEWS_UNIT]," ",NEWS_DATA[i][NEWS_DESC],"|",TimeHour(time),":",TimeMinute(time));
      round_time = MathFloor(time/(Period()*60.0));
      
      if(position == 0){
        y1 = MAX_PRICE_NEWS;
        y2 = y1-size;
        if(round_time == prev_time){
          y1 = y1-(size*news_same_time_up)-(size/3*news_same_time_up);
          y2 = y2-(size*news_same_time_up)-(size/3*news_same_time_up);
          news_same_time_up++;
        }else{
          news_same_time_up = 0;
        }      
      }else{
        y1 = MIN_PRICE_NEWS;
        y2 = y1+size;
        if(round_time == prev_time){
          y1 = y1+(size*news_same_time_down)+(size/3*news_same_time_down);
          y2 = y2+(size*news_same_time_down)+(size/3*news_same_time_down);
          news_same_time_down++;
        }else{
          news_same_time_down = 0;
        }  
      }
      
      createNewsLine("DT_BO_news_"+i, time, y1, y2, desc, NEWS_DATA[i][NEWS_PRIO],StrToDouble(NEWS_DATA[i][NEWS_REL]));
      
      prev_time = round_time;
    }    
  }
  return (errorCheck("displayNews"));
}

bool createNewsLine(string name, double x, double y1, double y2, string text, string prio, double width){
  color c = Green;
  if(prio == "HIGH"){ c = Red;
  }else if(prio == "MEDIUM"){c = Orange;
  }else if(prio == "LOW"){c = Blue; }
  
	ObjectCreate(name, OBJ_TREND, 0, x, y1, x, y2);
	ObjectSet(name, OBJPROP_COLOR, c);             
	ObjectSet(name, OBJPROP_RAY, false);
	ObjectSet(name, OBJPROP_STYLE, STYLE_SOLID);
	ObjectSet(name, OBJPROP_WIDTH, width);
	ObjectSetText(name, text, 8);
}

bool csvNewsFileToArray(){
  int handle = FileOpen(NEWS_FILE_NAME,FILE_READ,",");
  int i = 0, line_idx = 0, col_idx = 0;
  string data, prio;
  
  if(handle>0){
    while(i < 9 && !FileIsEnding(handle)){ //skip first row
      FileReadString(handle);
      i++;      
    } 
    
    while(!FileIsEnding(handle)){
      data = stringReplaceAll(FileReadString(handle), "¥", "Y");
      data = stringReplaceAll(data, "£", "P");
            
      if(col_idx == 9){
        if(data == ""){
          break;
        }           
        line_idx++;
        ArrayResize(NEWS_DATA, line_idx+1);
        col_idx = 0;              
      }
      if(col_idx == 0){
        NEWS_DATA[line_idx][NEWS_TIME] = getTSdate(data, FileReadString(handle));
        col_idx++;
      }else if(col_idx == 3){
        NEWS_DATA[line_idx][NEWS_CURRENCY] = toUpper(data);
      }else if(col_idx == 4){
        NEWS_DATA[line_idx][NEWS_DESC] = data;
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
  }
 /* string p = "";
  for(i=0;i<ArrayRange(NEWS_DATA,0);i++){
    p = "";
    for(int j=0;j<ArrayRange(NEWS_DATA,1);j++){
      p = p+StringConcatenate(NEWS_DATA[i][j]," | ");
    }
    Alert(p);
   // Alert(NEWS_DATA[i][NEWS_TIME]+"|"+NEWS_DATA[i][NEWS_CURRENCY]+"|"+NEWS_DATA[i][NEWS_DESC]+"|"+NEWS_DATA[i][NEWS_PRIO]+"|"+NEWS_DATA[i][NEWS_ACT]+"|"+NEWS_DATA[i][NEWS_FORC]+"|"+NEWS_DATA[i][NEWS_PREV]);
  }*/
  FileClose(handle);
  return (errorCheck("csvNewsFileToArray"));
}

string setNewsRelevance(string act, string forc){
  if(act == "-" || forc == "-"){
    return ("1");
  }  

  double max = MathMax(StrToDouble(act),StrToDouble(forc)), min = MathMin(StrToDouble(act),StrToDouble(forc));
  double dif = max-min, multi;
  min = MathAbs(min);
  if(min == 0){
    multi = MathAbs(max);
  }else{
    multi = dif/min;
  }
  
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
 int handle=FileOpen(NEWS_FILE_NAME, FILE_READ);
 if(handle>0){
   FileClose(handle);
   return(false);   
 }
 GetLastError(); // File does not exist if FileOpen return -1 or if GetLastError = ERR_CANNOT_OPEN_FILE (4103) 
 return(true); 
}

string newsFileName(){   
  datetime date =  TimeLocal() - (TimeDayOfWeek(TimeLocal())  * 86400);  
  return (StringConcatenate("Calendar-", PadString(DoubleToStr(TimeMonth(date),0),"0",2),"-",PadString(DoubleToStr(TimeDay(date),0),"0",2),"-",TimeYear(date),".csv"));  
}

string PadString(string toBePadded, string paddingChar, int paddingLength){
   while(StringLen(toBePadded) <  paddingLength){
      toBePadded = StringConcatenate(paddingChar,toBePadded);
   }
   return (toBePadded);
}

bool downLoadWebPageToFile(){
  string url = StringConcatenate("http://www.dailyfx.com/files/",NEWS_FILE_NAME);  
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
    Alert("Cannot open URL ", url, " - InternetOpenUrlA()");
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
  handle=FileOpen(NEWS_FILE_NAME, FILE_CSV|FILE_WRITE, ';');
  if(handle>0){
   FileWrite(handle, fileContents);
   FileClose(handle);
  }
  return (errorCheck("downLoadWebPageToFile"));
}
//+------------------------------------------------------------------+
//|                                                      DT_news.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#define NEWS_CURRENCY 1
#define NEWS_TIME 1
#define NEWS_DESC1 2
#define NEWS_PRIO 3
#define NEWS_GOODEF 4
#define NEWS_POWER 5
#define NEWS_DESC2 6

#import "Shell32.dll"
  int ShellExecuteA( int hwnd, string lpOperation, string lpFile, string lpParameters, int lpDirectory, int nShowCmd );
#import

string NEWS_FILE_NAMES[];

bool initNews(string isOn){
  setAppStatus(APP_ID_NEWS, isOn);
  if(isOn == "0" || Period() > PERIOD_H4){        
    return (false);    
  }

  newsFileName();
  
  ObjectCreate( "DT_BO_icon_news_3", OBJ_LABEL, 0, 0, 0);
  ObjectSet( "DT_BO_icon_news_3", OBJPROP_CORNER, 0);
  ObjectSet( "DT_BO_icon_news_3", OBJPROP_XDISTANCE, ObjectGet( "DT_BO_icon_news_1", OBJPROP_XDISTANCE) + 15 );
  ObjectSet( "DT_BO_icon_news_3", OBJPROP_YDISTANCE, ObjectGet( "DT_BO_icon_news_1", OBJPROP_YDISTANCE) + 11 );
  ObjectSet( "DT_BO_icon_news_3", OBJPROP_BACK, false);
  ObjectSetText( "DT_BO_icon_news_3", getGlobal("PAST_NEWS"), 8, "Arial Black", Blue );
  
  return (errorCheck("initNews"));
}

bool startNews(string isOn){ return (0);
	static double win_min = 0.0;
	static double win_max = 0.0;
	static string news_data[0][7];
	static int last_file_size = 0;
	
  if(isAppStatusChanged(APP_ID_NEWS, isOn)){
    if(isOn == "1"){
      initNews("1");
    }else{
      deinitNews();
      return (false);
    }    
  }
	if(isOn == "0" || Period() > PERIOD_H4){return (false);}
	if(delayTimer(APP_ID_NEWS, 1500)){return (false);}

	int handle;
	if( ArrayRange( news_data, 0 ) == 0 ){
		handle = FileOpen( NEWS_FILE_NAMES[0], FILE_READ );
    if( handle < 1 ){
      if( GetLastError() == 4103 ){
				FileClose(handle);
				// downloadCalendar();
      }
			errorCheck("startNews file noe exist");
      return (0);
    }else{
			FileClose(handle);
			loadCSVfile( news_data );
			displayNews( news_data );
		}
	}else{
		if( hasRecentNews() ){
			// downloadCalendar();
			handle = FileOpen( NEWS_FILE_NAMES[0], FILE_READ );
			int size = FileSize(handle);
			
			if( Symbol() == "EURUSD-Pro" ){
		Alert("sds: "+size);
	}
			FileClose(handle);
			if( last_file_size != size ){
				last_file_size = size;
				loadCSVfile( news_data );
				displayNews( news_data );
				return (0);
			}
		} 
		
		if( win_min != WindowPriceMin(0) || win_max != WindowPriceMax(0)){
			win_min = WindowPriceMin(0);
			win_max = WindowPriceMax(0);
			displayNews( news_data );
			
		}
	}
  
  return (true);
}

bool deinitNews(){
  removeObjects("news");
  return (errorCheck("deinitNews"));
}

void displayNews( string& news_data[][] ){
if( Symbol() == "EURUSD-Pro" ){
		Alert("sds");
	}

	double max = WindowPriceMax(0), min = WindowPriceMin(0);
  int i, item_size = GlobalVariableGet("DT_window_width") * (10 / (max - min));
	int position, len = ArrayRange( news_data,0 ), time_shift, prev_top_price, prev_bottom_price, prev_top_time_shift = -1, prev_bottom_time_shift = -1;
	string sym = Symbol(), name;
	double time, chart_time, p1;
	min = min + item_size;
	
	for( i = 0; i < len; i++ ){
		position = StringFind( Symbol(), news_data[i][NEWS_CURRENCY]);
		if( position != -1 ){
			time = StrToDouble( news_data[i][NEWS_TIME] );
			chart_time = time - MathMod( time, (Period() * 60) );
			time_shift = iBarShift( NULL, 0, chart_time - 604800 );
			
			if( position == 0 ){
        if( prev_top_time_shift == time_shift ){
          p1 = prev_top_price - item_size;
        }else{
          p1 = max;
        }
        prev_top_price = p1;
        prev_top_time_shift = time_shift;
      }else{
        if( prev_bottom_time_shift == time_shift ){
          p1 = prev_bottom_price + item_size;
        }else{
          p1 = min;
        }
        prev_bottom_price = p1;
        prev_bottom_time_shift = time_shift;
      }
			name = StringConcatenate("DT_BO_n_",news_data[i][NEWS_DESC1]);
			ObjectCreate( name, OBJ_TEXT, 0, chart_time, p1 );
      ObjectSetText( name, "I", 10, "GulimChe", Red );
		
		}
	}
}

bool hasRecentNews(){
	return (true);
}

void downloadCalendar(){
	if( Symbol() != "EURUSD-Pro" ){
		return;
	}
	if( GlobalVariableGet( "NEWS_update_id" ) > TimeCurrent() ){
		return;
	}
	ShellExecuteA(0, "Open", "dnews.bat", "", "", 0);
	GlobalVariableSet( "NEWS_update_id", TimeCurrent() + 30 );
}

void loadCSVfile( string& news_data[][] ){
	int i, handle, len = ArraySize( NEWS_FILE_NAMES ), col, nr = 0;
	string header, tmp;
	ArrayResize( news_data, 0 );
	
	for( i = 0; i < len; i++ ){
		handle = FileOpen( NEWS_FILE_NAMES[i], FILE_READ, ";" );
		if( handle < 1 ){
			if( GetLastError() == 4103 && i != 0 ){
        addComment( NEWS_FILE_NAMES[i]+" ("+( i + 1 )+") doesn't exist!", 1 );
        setGlobal( "PAST_NEWS", i );
        ArrayResize( NEWS_FILE_NAMES, i );
      }
      FileClose(handle);
      return (0);
		}
		
		header = FileReadString(handle);
		if( header != "ok" ){
			Alert( NEWS_FILE_NAMES[i]+": "+header );
			FileClose(handle);
			return (0);
		}
		col = 0;
		while( !FileIsEnding(handle) ){
			switch( col ){
				case 0: 
					ArrayResize( news_data, nr + 1 );    
					news_data[nr][NEWS_CURRENCY] = FileReadString(handle); break;
				case 1: 
					news_data[nr][NEWS_TIME] = FileReadString(handle); break;
				case 2: 
					news_data[nr][NEWS_DESC1] = FileReadString(handle); break;
				case 3: 
					news_data[nr][NEWS_PRIO] = FileReadString(handle);	break;
				case 4: 
					news_data[nr][NEWS_GOODEF] = FileReadString(handle); break;
				case 5: 
					news_data[nr][NEWS_POWER] = FileReadString(handle); break;
				case 6: 
					news_data[nr][NEWS_DESC2] = FileReadString(handle); col = -1; nr++; break;
			}
			col++;
		}
		FileClose(handle);
	}

}

void newsFileName(){
  int i, nr_of_weeks = StrToInteger( getGlobal("PAST_NEWS") );
  datetime date;
  
  ArrayResize( NEWS_FILE_NAMES, nr_of_weeks );
  for( i = 0; i < nr_of_weeks; i++ ){
    date = TimeLocal() - (TimeDayOfWeek(TimeLocal()) * 86400 ) - ( i * 604800 );
    NEWS_FILE_NAMES[i] = StringConcatenate("Calendar-", TimeYear(date), "-", PadString(DoubleToStr(TimeMonth(date),0),"0",2),"-",PadString(DoubleToStr(TimeDay(date),0),"0",2),".csv");
  }
  errorCheck("newsFileName");
}


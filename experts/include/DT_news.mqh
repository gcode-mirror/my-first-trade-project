//+------------------------------------------------------------------+
//|                                                      DT_news.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#define NEWS_CURRENCY 0
#define NEWS_TIME 1
#define NEWS_DESC1 2
#define NEWS_PRIO 3
#define NEWS_GOODEF 4
#define NEWS_POWER 5
#define NEWS_DESC2 6

#define NEWS_UPDATE_ZONE 900 // 15 min

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

bool startNews(string isOn){ //return (0);
	static double win_min = 0.0;
	static double win_max = 0.0;
	static string news_data[0][7];
	
  if(isAppStatusChanged(APP_ID_NEWS, isOn)){
    if(isOn == "1"){
      initNews("1");
    }else{
      deinitNews();
      return (false);
    }    
  }
	if(isOn == "0" || Period() > PERIOD_H4){return (false);}
	if(delayTimer(APP_ID_NEWS, 2200)){return (false);}
	if( ArrayRange( news_data, 0 ) == 0 ){
		if( loadCSVfile( news_data ) ){
			displayNews( news_data, win_min, win_max );
		}
	}else{
		if( hasRecentNews( news_data ) ){
			if( loadCSVfile( news_data ) ){
				displayNews( news_data, win_min, win_max );
			}
			return (0);
		} 
		if( win_min != WindowPriceMin(0) || win_max != WindowPriceMax(0)){
			displayNews( news_data, win_min, win_max );
		}
	}
  
  return (errorCheck("startNews"));
}

bool deinitNews(){
  deleteNewsItems();
  return (errorCheck("deinitNews"));
}

void displayNews( string& news_data[][], double& win_min, double& win_max ){
	deleteNewsItems();
	win_max = WindowPriceMax(0);
	win_min = WindowPriceMin(0);
  int i, peri = Period();
	int position, len = ArrayRange( news_data,0 ), time_shift, prev_top_time_shift = -1, prev_bottom_time_shift = -1;
	string sym = Symbol(), name, icon = "", font = "";
	double prev_top_price, prev_bottom_price, min, time, chart_time, p1, item_size = (win_max - win_min) * (24 / GlobalVariableGet("DT_window_width") );
	color c;
	min = win_min + (item_size * 1.3);
	
	for( i = 0; i < len; i++ ){
		position = StringFind( sym, news_data[i][NEWS_CURRENCY]);
		if( position != -1 ){
			time = StrToDouble( news_data[i][NEWS_TIME] );
			chart_time = time - MathMod( time, (peri * 60) );
			time_shift = iBarShift( NULL, 0, chart_time - 604800 );
			
			if( position == 0 ){
        if( prev_top_time_shift == time_shift ){
          p1 = prev_top_price - item_size;
        }else{
          p1 = win_max;
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

			if( news_data[i][NEWS_PRIO] == "0" ){
				c = Green;
				icon = "}";
			}else{	
				getIconAndFont( news_data[i][NEWS_POWER], news_data[i][NEWS_GOODEF], position, icon, font );
				
				if( news_data[i][NEWS_PRIO] == "3" ){
					c = Red;
				}else if( news_data[i][NEWS_PRIO] == "2" ){
					c = Orange;
				}else{
					c = Blue;
				}
			}
			
			name = StringConcatenate( news_data[i][NEWS_DESC1], " #", news_data[i][NEWS_CURRENCY], " ",TimeToStr( time, TIME_MINUTES ));
			if( ObjectFind(name) != -1 ){
				name = StringConcatenate( news_data[i][NEWS_DESC1], " #", news_data[i][NEWS_CURRENCY], i, " ",TimeToStr( time, TIME_MINUTES ));
			}
			ObjectCreate( name, OBJ_TEXT, 0, chart_time, p1 );
      ObjectSetText( name, icon, 8, font, c );
			errorCheck("displayNews "+name);
		}
	}
			// p("oo");
	errorCheck("displayNews");
}

bool getIconAndFont( string power, string good_effect, int& position, string& icon, string& font ){
	if( power == "0" ){
		icon = "?";
		font = "Arial";
	}else{
		if( good_effect == "A>F" ){
			if( position == 0 ){
				if( power == "3" ){
					icon = "q";
					font = "Wingdings 3";
				}else if( power == "2" ){
					icon = "¤";
					font = "Wingdings 3";
				}else{
					icon = "i";
					font = "Wingdings 3";
				}
			}else{
				if( power == "3" ){
					icon = "p";
					font = "Wingdings 3";
				}else if( power == "2" ){
					icon = "—";
					font = "Wingdings 3";
				}else{
					icon = "h";
					font = "Wingdings 3";
				}
			}
		}else if( good_effect == "A<F" ){
			if( position == 0 ){
				if( power == "3" ){
					icon = "p";
					font = "Wingdings 3";
				}else if( power == "2" ){
					icon = "—";
					font = "Wingdings 3";
				}else{
					icon = "h";
					font = "Wingdings 3";
				}
			}else{
				if( power == "3" ){
					icon = "q";
					font = "Wingdings 3";
				}else if( power == "2" ){
					icon = "¤";
					font = "Wingdings 3";
				}else{
					icon = "i";
					font = "Wingdings 3";
				}
			}
		}else{
			if( power == "3" ){
				icon = "I";
				font = "Arial Black";
			}else if( power == "2" ){
				icon = "ó";
				font = "Wingdings 3";
			}else{
				icon = "I";
				font = "Arial";
			}
		}
	}
}

bool deleteNewsItems(){
	int j, obj_total= ObjectsTotal();
	string name;
	for ( j = obj_total - 1; j >= 0; j-- ){
		name= ObjectName(j);
		if ( StringSubstr( name, 0, 1 ) == "(" ){
			ObjectDelete( name );
		}
	}
}

bool hasRecentNews( string& news_data[][] ){
	int i, len = ArrayRange( news_data, 0 );
	double time, max = TimeCurrent(), min;
	min = max - NEWS_UPDATE_ZONE;
	string sym = Symbol();
	for ( i = 0; i < len; i++ ){
		time = StrToDouble( news_data[i][NEWS_TIME] );
		if( time > min && time < max && StringFind( sym, news_data[i][NEWS_CURRENCY] ) != -1 ){
			return (true);
		}
	}
	return (false);
}

void downloadCalendar(){
	if( Symbol() != "EURUSD-Pro" ){
		return;
	}
	if( GlobalVariableGet( "NEWS_update_id" ) > TimeCurrent() ){
		return;
	}
	Alert("download");
	ShellExecuteA(0, "Open", "dnews.bat", "", 0, 0);
	GlobalVariableSet( "NEWS_update_id", TimeCurrent() + 30 );
	errorCheck("downloadCalendar");
}

bool loadCSVfile( string& news_data[][] ){
	int i, handle, len = ArraySize( NEWS_FILE_NAMES ), col, nr = 0;
	string header, tmp;
	static string last_error = "";
	ArrayResize( news_data, 0 );
	
	for( i = 0; i < len; i++ ){
		handle = FileOpen( NEWS_FILE_NAMES[i], FILE_READ, ";" );
		if( handle < 1 ){
			if( GetLastError() == 4103 ){
				if( i == 0 ){
					downloadCalendar();
				}else{
					addComment( NEWS_FILE_NAMES[i]+" ("+( i + 1 )+") doesn't exist!", 1 );
					setGlobal( "PAST_NEWS", i );
					ArrayResize( NEWS_FILE_NAMES, i );
				}
      }
      // FileClose(handle);
      return (false);
		}
		
		header = FileReadString(handle);
		if( header != "ok" ){
			if( last_error != header ){
				Alert( Symbol()+" "+NEWS_FILE_NAMES[i]+": "+header );
				last_error = header;
			}
			FileClose(handle);
			return (false);
		}
		col = 0;
		while( !FileIsEnding(handle) ){
			switch( col ){
				case 0: 
					tmp = FileReadString(handle);
					if( tmp != "" ){
						ArrayResize( news_data, nr + 1 );    
						news_data[nr][NEWS_CURRENCY] = tmp; break;
					}else{
						FileClose(handle);
						return (true);
					}
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
	return (errorCheck("loadCSVfile"));
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

void p(string p){
if( Symbol() == "EURUSD-Pro" ){
	Alert(p);
}
}

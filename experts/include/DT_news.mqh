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
#define NEWS_DISPLAY_ZONE 21600 // 6 hour

void startNews(){
	static double win_min = 0.0;
	static double win_max = 0.0;
	static string news_data[0][7];
	static int icon_id = -1;
	static string icon_extension = "";
	
  static int st_timer = 0;
  static string st_switch = "-1";
  
  if( GetTickCount() < st_timer ){
    return;
  }
  
  if( st_switch == "-1" ){
    st_switch = getGlobal("NEWS_SWITCH");
		icon_id = showIcon( 1, 1, "ü", "Webdings", st_switch, "NEWS_SWITCH" ); 
		
		icon_extension = StringConcatenate( "DT_BO_icon_" , icon_id, "_w_extension" );
		ObjectCreate( icon_extension, OBJ_LABEL, 0, 0, 0);
		ObjectSet( icon_extension, OBJPROP_CORNER, 0);
		ObjectSet( icon_extension, OBJPROP_XDISTANCE, ObjectGet( StringConcatenate( "DT_BO_icon_" , icon_id, "_background" ), OBJPROP_XDISTANCE) + 15 );
		ObjectSet( icon_extension, OBJPROP_YDISTANCE, ObjectGet( StringConcatenate( "DT_BO_icon_" , icon_id, "_background" ), OBJPROP_YDISTANCE) + 11 );
		ObjectSet( icon_extension, OBJPROP_BACK, false);
		ObjectSetText( icon_extension, EXT_WEEDS_OF_NEWS+"", 8, "Arial Black", Blue );
  }
  
  st_timer = GetTickCount() + 2200;
  
  if( st_switch != getGlobal("NEWS_SWITCH") ){
    st_switch = getGlobal("NEWS_SWITCH");
    if( st_switch == "0" ){
      deleteNewsItems();
			addComment( "Switch OFF News." );
      return;
    }
    addComment( "Turn ON News." );
  }
  
  if( st_switch == "0" || Period() > PERIOD_H4 || StringLen(Symbol()) < 6 ){
    return;
  }
	if( ArrayRange( news_data, 0 ) == 0 ){
		downloadCalendar();
		if( loadCSVfile( news_data ) ){
			displayNews( news_data, win_min, win_max );
		}
	}else{
		int res = hasRecentNews( news_data );
		if( res == 2 ){
			downloadCalendar();
		}
		if( res > 0 ){
			if( loadCSVfile( news_data ) ){
				displayNews( news_data, win_min, win_max );
			}
			return;
		}
		if( win_min != WindowPriceMin(0) || win_max != WindowPriceMax(0)){
			displayNews( news_data, win_min, win_max );
		}
	}
}

void displayNews( string& news_data[][], double& win_min, double& win_max ){
	deleteNewsItems();
	win_max = WindowPriceMax(0);
	win_min = WindowPriceMin(0);
  int trade_power, i, peri = Period(), offset = 3;
	int position, len = ArrayRange( news_data,0 ), time_shift, prev_top_time_shift = -1, prev_bottom_time_shift = -1;
	string sym = Symbol(), name, icon = "", font = "";
	double trade_val, prev_top_price, prev_bottom_price, min, time, chart_time, p1, item_size = (win_max - win_min) * (24 / GlobalVariableGet("DT_window_width") ), disp_max, disp_min;
	bool no_separator = true;
	disp_min = TimeCurrent() - NEWS_DISPLAY_ZONE;
	disp_max = TimeCurrent() + NEWS_DISPLAY_ZONE;
	color c;
	min = win_min + (item_size * 1.3);
	// static string NEWS_TRADE = StringConcatenate( StringSubstr( sym, 0, 6 ), "_news_trade" );

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
				font = "Wingdings 3";
			}else{
				getIconAndFont( news_data[i][NEWS_POWER], news_data[i][NEWS_GOODEF], position, icon, font );
				// getIconAndFont( news_data[i][NEWS_POWER], news_data[i][NEWS_GOODEF], position, icon, font, trade_power );

				if( news_data[i][NEWS_PRIO] == "3" ){
					c = Red;
				}else if( news_data[i][NEWS_PRIO] == "2" ){
					c = Orange;
				}else{
					c = Blue;
				}
			}

			name = StringConcatenate( news_data[i][NEWS_DESC1], " ", news_data[i][NEWS_DESC2], " ",TimeMinute( time ));
			if( ObjectFind(name) != -1 ){
				name = StringConcatenate( news_data[i][NEWS_DESC1], i, " ", news_data[i][NEWS_DESC2], " ",TimeMinute( time ));
			}
			name = StringSubstr( name, 0, 61 );

			ObjectCreate( name, OBJ_TEXT, 0, chart_time, p1 );
			ObjectSetText( name, icon, 8, font, c );

			if( time > disp_min && time < disp_max ){
				if( time > TimeCurrent() && no_separator ){
					name = "(news separator)";
					ObjectCreate( name, OBJ_LABEL, 0, 0, 0);
					ObjectSet( name, OBJPROP_CORNER, 2 );
					ObjectSet( name, OBJPROP_XDISTANCE, 5 );
					ObjectSet( name, OBJPROP_YDISTANCE, offset - 4 );
					ObjectSet( name, OBJPROP_BACK, true );
					ObjectSetText( name, "=============================================", 8, "Arial", Black );
					offset = offset + 7;
					no_separator = false;
				}
			
				// p(news_data[i][NEWS_DESC1]);
				name = StringSubstr( StringConcatenate( news_data[i][NEWS_DESC1], " icon_",i ), 0, 61 );
				ObjectCreate( name, OBJ_LABEL, 0, 0, 0);
				ObjectSet( name, OBJPROP_CORNER, 2 );
				ObjectSet( name, OBJPROP_XDISTANCE, 5 );
				ObjectSet( name, OBJPROP_YDISTANCE, offset );
				ObjectSet( name, OBJPROP_BACK, true );
				ObjectSetText( name, icon, 10, font, c );

				name = StringConcatenate( "(desc", i , ") | ", news_data[i][NEWS_DESC2] );
				if( news_data[i][NEWS_GOODEF] != "-" ){
					name = StringConcatenate( name, news_data[i][NEWS_GOODEF] );
				}
				name = StringSubstr( name, 0, 61 );
    
				ObjectCreate( name, OBJ_LABEL, 0, 0, 0);
				ObjectSet( name, OBJPROP_CORNER, 2 );
				ObjectSet( name, OBJPROP_XDISTANCE, 20 );
				ObjectSet( name, OBJPROP_YDISTANCE, offset );
				ObjectSet( name, OBJPROP_BACK, true );
				ObjectSetText( name, StringConcatenate( TimeToStr( time + 3600, TIME_MINUTES ), " ", news_data[i][NEWS_CURRENCY], " ", news_data[i][NEWS_DESC1], " ", news_data[i][NEWS_DESC2]), 8, "Arial", Black );

				offset = offset + 16;
			}
		}
	}
}

void getIconAndFont( string power, string good_effect, int& position, string& icon, string& font){
	int pow;
	if( power == "" ){
		icon = "?";
		font = "Arial";
	}else{
		pow = StrToInteger( power );

		if( position != 0 ){
		 pow = pow * (-1);
		}

		if( good_effect == "A>F" || good_effect == "A<F" ){
			if( pow == 3 ){
				icon = "p";
				font = "Wingdings 3";
			}else if( pow == 2 ){
				icon = "—";
				font = "Wingdings 3";
			}else if( pow == 1 ){
				icon = "h";
				font = "Wingdings 3";
			}else if( pow == -3 ){
				icon = "q";
				font = "Wingdings 3";
			}else if( pow == -2 ){
				icon = "¤";
				font = "Wingdings 3";
			}else if( pow == -1 ){
				icon = "i";
				font = "Wingdings 3";
			}
		}else{
		 if( pow == 3 ){
					icon = "t";
					font = "Wingdings";
				}else if( pow == 2 ){
					icon = "I";
					font = "Arial Black";
				}else{
					icon = "I";
					font = "Arial";
				}
		}
 }
}

void deleteNewsItems(){
	int j, obj_total= ObjectsTotal();
	string name;
	for ( j = obj_total - 1; j >= 0; j-- ){
		name= ObjectName(j);
		if ( StringSubstr( name, 0, 1 ) == "(" ){
			ObjectDelete( name );
		}
	}
  errorCheck("deleteNewsItems");
}

int hasRecentNews( string& news_data[][] ){
	int i, len = ArrayRange( news_data, 0 ), res = 0;
	double time, max = TimeCurrent(), min;
	min = max - NEWS_UPDATE_ZONE;
	string sym = Symbol();
  bool need_download = ( sym == "EURUSD-Pro" );
	for ( i = 0; i < len; i++ ){
		time = StrToDouble( news_data[i][NEWS_TIME] );
		if( time > min && time < max ){
			if( need_download ){
				if( StringFind( sym, news_data[i][NEWS_CURRENCY] ) != -1 ){
					return (2);
				}else{
					res = 1;
				}
			}else if( StringFind( sym, news_data[i][NEWS_CURRENCY] ) != -1 ){
				return (1);
			}
		}
	}
	return (res);
}

void downloadCalendar(){
	if( !EXT_BOSS ){
		return;
	}
	if( GlobalVariableGet( "NEWS_update_id" ) > TimeCurrent() ){
		return;
	}
	ShellExecuteA(0, "Open", TerminalPath()+"\script\dnews.bat", "", 0, 0);
	GlobalVariableSet( "NEWS_update_id", TimeCurrent() + 30 );
	errorCheck("downloadCalendar");
}

bool loadCSVfile( string& news_data[][] ){
  static string news_file_names[0];

	int i, handle, len = ArraySize( news_file_names ), col, nr = 0;
	string header, tmp;
	static string last_error = "";
	ArrayResize( news_data, 0 );
  
  if( len == 0 ){
    newsFileName( news_file_names );
  }

	for( i = 0; i < len; i++ ){
		handle = FileOpen( news_file_names[i], FILE_READ, ";" );
		if( handle < 1 ){
			if( GetLastError() == 4103 ){
				if( i > 0 ){
					addComment( news_file_names[i]+" ("+( i + 1 )+") doesn't exist!", 1 );
					EXT_WEEDS_OF_NEWS = i;
					ArrayResize( news_file_names, i );
					break;
				}
      }
      return (false);
		}

		header = FileReadString(handle);
		if( header != "ok" ){
			if( last_error != header ){
				Alert( Symbol()+" "+news_file_names[i]+": "+header );
				last_error = header;
			}
			FileClose(handle);
			return (false);
		}
		col = 0;
		while( !FileIsEnding(handle) ){
			if( col == 0 ){
				tmp = FileReadString(handle);
				if( tmp == "" ){
					break;
				}else{
					ArrayResize( news_data, nr + 1 );
					news_data[nr][NEWS_CURRENCY] = tmp;
				}
			}else if( col == 1 ){
				news_data[nr][NEWS_TIME] = FileReadString(handle);
			}else if( col == 2 ){
				news_data[nr][NEWS_DESC1] = FileReadString(handle);
			}else if( col == 3 ){
				news_data[nr][NEWS_PRIO] = FileReadString(handle);
			}else if( col == 4 ){
				news_data[nr][NEWS_GOODEF] = FileReadString(handle);
			}else if( col == 5 ){
				news_data[nr][NEWS_POWER] = FileReadString(handle);
			}else if( col == 6 ){
				news_data[nr][NEWS_DESC2] = FileReadString(handle); 
				col = -1;
				nr++;
			}
			col++;
		}
		FileClose(handle);
	}
	return (errorCheck("loadCSVfile"));
}

void newsFileName( string& arr[] ){
  int i;
  datetime date;

  ArrayResize( arr, EXT_WEEDS_OF_NEWS );
  for( i = 0; i < EXT_WEEDS_OF_NEWS; i++ ){
    date = TimeLocal() - (TimeDayOfWeek(TimeLocal()) * 86400 ) - ( i * 604800 );
    arr[i] = StringConcatenate("Calendar-", TimeYear(date), "-", PadString(DoubleToStr(TimeMonth(date),0),"0",2),"-",PadString(DoubleToStr(TimeDay(date),0),"0",2),".csv");
  }
}

string PadString(string toBePadded, string paddingChar, int paddingLength){
  while(StringLen(toBePadded) <  paddingLength){
    toBePadded = StringConcatenate(paddingChar,toBePadded);
  }
  return (toBePadded);
}

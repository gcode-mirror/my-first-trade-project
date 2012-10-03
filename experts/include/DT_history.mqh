//+------------------------------------------------------------------+
//|                                                   DT_history.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+

void startHistory(){
  static int st_timer = 0;
  if( GetTickCount() < st_timer ){
    return;
  }
  
  st_timer = GetTickCount() + 2000;
  
  static double selected = -1;
  static string global_name = "";
  
  static string st_tLine_ref_names[0];
  static double st_tLine_ref_data[0][4];
  static double st_tLine_hist_data[0][6]; // 0 = t1, 1 = p1, 2 = t2, 3 = p2, 4 = ref line id, 5 = hist nr
  static double st_tLine_hist_index[0][2]; // 0 = ref line id, 1 = hist nr
  
  int i, j, k, idx = 0, idx2, len = ArraySize( st_tLine_ref_names ), len2, removed = 0, hist_nr;
  double tmp;
  bool is_new, has_change = false;
  string name;
  
  // init 
  if( selected == -1 ){
    ArrayResize( st_tLine_ref_names, 30 );
    ArrayResize( st_tLine_ref_data, 30 );
    ArrayResize( st_tLine_hist_data, 30 );
    for ( i = ObjectsTotal() - 1; i >= 0; i-- ){
      name = ObjectName(i);
      if( StringSubstr( name, 5, 7 ) == "_tLine_" ){
        st_tLine_ref_names[idx] = name;
        st_tLine_ref_data[idx][0] = ObjectGet( name, OBJPROP_TIME1 );
        st_tLine_ref_data[idx][1] = NormalizeDouble( ObjectGet( name, OBJPROP_PRICE1 ) ,Digits );
        st_tLine_ref_data[idx][2] = ObjectGet( name, OBJPROP_TIME2 );
        st_tLine_ref_data[idx][3] = NormalizeDouble( ObjectGet( name, OBJPROP_PRICE2 ) ,Digits );
        
        st_tLine_hist_data[idx][0] = st_tLine_ref_data[idx][0];
        st_tLine_hist_data[idx][1] = st_tLine_ref_data[idx][1];
        st_tLine_hist_data[idx][2] = st_tLine_ref_data[idx][2];
        st_tLine_hist_data[idx][3] = st_tLine_ref_data[idx][3];
        st_tLine_hist_data[idx][4] = idx;
        st_tLine_hist_data[idx][5] = 0;
        idx++;
      }
    }
    
    ArrayResize( st_tLine_ref_names, idx );
    ArrayResize( st_tLine_ref_data, idx );
    ArrayResize( st_tLine_hist_data, idx );
    
    selected = 0.0;
    global_name = StringConcatenate( getSymbol(), "_History" );
    GlobalVariableSet( global_name, 0.0 );
    
    removeObjects("history");
    int xpos = 15 * nrOfIcons();
    name = "DT_BO_history_hud";
    ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
    ObjectSet( name, OBJPROP_CORNER, 0 );
    ObjectSet( name, OBJPROP_XDISTANCE,  xpos );
    ObjectSet( name, OBJPROP_YDISTANCE, 15 );
    ObjectSetText( name, "Histrory: 0/0", 9, "Consolas", Blue );
    has_change = true;
  }
	
  // has new
  for ( i = ObjectsTotal() - 1; i >= 0; i-- ){
    name = ObjectName(i);
    if( StringSubstr( name, 5, 7 ) == "_tLine_" ){
      is_new = true;
      for ( j = 0; j < len; j++ ){
        if( name == st_tLine_ref_names[j] ){
          is_new = false;
          break;
        }
      }
      
      if( is_new ){
        idx = ArraySize( st_tLine_ref_names );
        ArrayResize( st_tLine_ref_names, idx + 1 );
        ArrayResize( st_tLine_ref_data, idx + 1 );
        st_tLine_ref_names[idx] = name;
        st_tLine_ref_data[idx][0] = ObjectGet( name, OBJPROP_TIME1 );
        st_tLine_ref_data[idx][1] = NormalizeDouble( ObjectGet( name, OBJPROP_PRICE1 ) ,Digits );
        st_tLine_ref_data[idx][2] = ObjectGet( name, OBJPROP_TIME2 );
        st_tLine_ref_data[idx][3] = NormalizeDouble( ObjectGet( name, OBJPROP_PRICE2 ) ,Digits );
        
        idx2 = ArrayRange( st_tLine_hist_data, 0 );
        ArrayResize( st_tLine_hist_data, idx2 + 1 );
        st_tLine_hist_data[idx2][0] = st_tLine_ref_data[idx][0];
        st_tLine_hist_data[idx2][1] = st_tLine_ref_data[idx][1];
        st_tLine_hist_data[idx2][2] = st_tLine_ref_data[idx][2];
        st_tLine_hist_data[idx2][3] = st_tLine_ref_data[idx][3];
        st_tLine_hist_data[idx2][4] = idx;
        st_tLine_hist_data[idx2][5] = 0;
        has_change = true;
      }
    }
  }
  
  // is modified or deleted
  double t1, p1, t2, p2;
  for( i = 0; i < len; i++ ){
    if( ObjectFind( st_tLine_ref_names[i]) == -1 ){ //remove
      // remove line from ref array
      for( j = i + 1; j < len; j++ ){
        st_tLine_ref_names[j-1] = st_tLine_ref_names[j];
        st_tLine_ref_data[j-1][0] = st_tLine_ref_data[j][0];
        st_tLine_ref_data[j-1][1] = st_tLine_ref_data[j][1];
        st_tLine_ref_data[j-1][2] = st_tLine_ref_data[j][2];
        st_tLine_ref_data[j-1][3] = st_tLine_ref_data[j][3];
      }
      len = len - 1;
      ArrayResize( st_tLine_ref_names, len );
      ArrayResize( st_tLine_ref_data, len );
      
      // remove line from hist array
      len2 = ArrayRange( st_tLine_hist_data, 0 );
      removed = 0;
      for( j = 0; j < len2; j++ ){
        if( st_tLine_hist_data[j][4] == i ){
          for( k = j + 1; k < len2; k++ ){
            st_tLine_hist_data[k-1][0] = st_tLine_hist_data[k][0];
            st_tLine_hist_data[k-1][1] = st_tLine_hist_data[k][1];
            st_tLine_hist_data[k-1][2] = st_tLine_hist_data[k][2];
            st_tLine_hist_data[k-1][3] = st_tLine_hist_data[k][3];
            st_tLine_hist_data[k-1][4] = st_tLine_hist_data[k][4];
            st_tLine_hist_data[k-1][5] = st_tLine_hist_data[k][5];
          }
          j--;
          removed++;
        }
      }
      ArrayResize( st_tLine_hist_data, len2 - removed );
      
      // remove line from hist idx array
      len2 = ArrayRange( st_tLine_hist_index, 0 );
      removed = 0;
      for( j = 0; j < len2; j++ ){
        if( st_tLine_hist_index[j][0] == i ){
          for( k = j + 1; k < len2; k++ ){
            st_tLine_hist_index[k-1][0] = st_tLine_hist_index[k][0];
            st_tLine_hist_index[k-1][1] = st_tLine_hist_index[k][1];
          }
          if( selected != 0 && j < selected ){
            selected--;
          }
          j--;
          removed++;
        }
      }
      GlobalVariableSet( global_name, selected );
      ArrayResize( st_tLine_hist_index, len2 - removed );
      ObjectSetText( "DT_BO_history_hud", StringConcatenate( "Histrory: ", (len2 - removed), "/", DoubleToStr(selected, 0) ), 9, "Consolas", Blue );
      has_change = true;
			
    }else{ // modified
      t1 = ObjectGet( st_tLine_ref_names[i], OBJPROP_TIME1 );
      p1 = NormalizeDouble( ObjectGet( st_tLine_ref_names[i], OBJPROP_PRICE1 ) ,Digits );
      t2 = ObjectGet( st_tLine_ref_names[i], OBJPROP_TIME2 );
      p2 = NormalizeDouble( ObjectGet( st_tLine_ref_names[i], OBJPROP_PRICE2 ) ,Digits );
      if( st_tLine_ref_data[i][0] != t1 || st_tLine_ref_data[i][1] != p1 || st_tLine_ref_data[i][2] != t2 || st_tLine_ref_data[i][3] != p2 ){
        len2 = ArrayRange( st_tLine_hist_data, 0 );
        if( selected < len2 - 1 ){
          len2 = selected + 1;
        }
				
				st_tLine_ref_data[i][0] = t1;
        st_tLine_ref_data[i][1] = p1;
        st_tLine_ref_data[i][2] = t2;
        st_tLine_ref_data[i][3] = p2;
        
        ArrayResize( st_tLine_ref_data, len2 + 1 );
        st_tLine_hist_data[len2][0] = t1;
        st_tLine_hist_data[len2][1] = p1;
        st_tLine_hist_data[len2][2] = t2;
        st_tLine_hist_data[len2][3] = p2;
        st_tLine_hist_data[len2][4] = i;
        
				// due to modification save line new position
        hist_nr = 0;
        for( j = 0; j < len2; j++ ){
          if( st_tLine_hist_data[j][4] == i ){
            if( st_tLine_hist_data[j][5] > hist_nr ){
              hist_nr = st_tLine_hist_data[j][5];
            }
          }
        }
        hist_nr++;
        st_tLine_hist_data[len2][5] = hist_nr;
        
				// set new position index to hist_index
        len2 = ArrayRange( st_tLine_hist_index, 0 );
        ArrayResize( st_tLine_hist_index, len2 + 1 );
        st_tLine_hist_index[len2][0] = i;
        st_tLine_hist_index[len2][1] = hist_nr;
        ObjectSetText( "DT_BO_history_hud", StringConcatenate( "Histrory: ", (len2 + 1), "/", (len2 + 1)), 9, "Consolas", Blue );
        selected = selected + 1.0;
				GlobalVariableSet( global_name, selected );
				has_change = true;
      }
    }
  }
  
  // is selected changed
  tmp = GlobalVariableGet( global_name );
  if( selected != tmp ){
    len = ArrayRange( st_tLine_hist_index, 0 );
    len2 = ArrayRange( st_tLine_hist_data, 0 );
    if( selected < tmp ){ // Undo
      for( i = selected; i <= tmp && tmp < len; i++ ){
        for( j = 0; j < len2; j++ ){
          if( st_tLine_hist_data[j][4] == st_tLine_hist_index[i][0] && st_tLine_hist_data[j][5] == st_tLine_hist_index[i][1] ){
            k = st_tLine_hist_data[j][4];
            ObjectSet( st_tLine_ref_names[k], OBJPROP_TIME1, st_tLine_hist_data[j][0] );
            ObjectSet( st_tLine_ref_names[k], OBJPROP_PRICE1, st_tLine_hist_data[j][1] );
            ObjectSet( st_tLine_ref_names[k], OBJPROP_TIME2, st_tLine_hist_data[j][2] );
            ObjectSet( st_tLine_ref_names[k], OBJPROP_PRICE2, st_tLine_hist_data[j][3] );
						
						st_tLine_ref_data[k][0] = st_tLine_hist_data[j][0];
						st_tLine_ref_data[k][1] = st_tLine_hist_data[j][1];
						st_tLine_ref_data[k][2] = st_tLine_hist_data[j][2];
						st_tLine_ref_data[k][3] = st_tLine_hist_data[j][3];
          }                                            
        }
      }
    }else{ // Redo
      for( i = selected; i > 0 && i >= tmp; i-- ){
        for( j = 0; j < len2; j++ ){
          if( st_tLine_hist_data[j][4] == st_tLine_hist_index[i][0] && st_tLine_hist_data[j][5] == st_tLine_hist_index[i][1] - 1.0 ){
            k = st_tLine_hist_data[j][4];
            ObjectSet( st_tLine_ref_names[k], OBJPROP_TIME1, st_tLine_hist_data[j][0] );
            ObjectSet( st_tLine_ref_names[k], OBJPROP_PRICE1, st_tLine_hist_data[j][1] );
            ObjectSet( st_tLine_ref_names[k], OBJPROP_TIME2, st_tLine_hist_data[j][2] );
            ObjectSet( st_tLine_ref_names[k], OBJPROP_PRICE2, st_tLine_hist_data[j][3] );
						
						st_tLine_ref_data[k][0] = st_tLine_hist_data[j][0];
						st_tLine_ref_data[k][1] = st_tLine_hist_data[j][1];
						st_tLine_ref_data[k][2] = st_tLine_hist_data[j][2];
						st_tLine_ref_data[k][3] = st_tLine_hist_data[j][3];
          }
        }
      }
    }
    selected = tmp;
    has_change = true;
  }
  
  if( has_change ){
		syncTradeCharts( st_tLine_ref_names, st_tLine_ref_data );
  }
}

void syncTradeCharts( string& line_name[], double &line_data[][4] ){
	static string file_name = "";
	static string global_name = "";
	if( file_name == "" ){
		file_name = StringConcatenate( getSymbol(), "_tLines.csv" );
		global_name = StringConcatenate( getSymbol(), "_tLines_lastMod.csv" );
	}
	int i = 0, len = ArraySize( line_name );
	string out = "";
	for( ; i < len; i++ ){
		out = StringConcatenate(out, line_name[i], ";", DoubleToStr(line_data[i][0],0), ";", DoubleToStr(line_data[i][1],Digits), ";", DoubleToStr(line_data[i][2],0), ";", DoubleToStr(line_data[i][3],Digits), ";", ObjectGet(line_name[i],OBJPROP_COLOR), ";", ObjectType(line_name[i]),"\r\n" );
	}
	
	if( ObjectFind("DT_GO_trade_timing") != -1 ){
    out = StringConcatenate(out,"DT_GO_trade_timing;",DoubleToStr(ObjectGet("DT_GO_trade_timing", OBJPROP_TIME1), 0 ),";0;0;0;",ObjectGet( "DT_GO_trade_timing", OBJPROP_COLOR ),";",ObjectType( "DT_GO_trade_timing" ),"\r\n");
  }
	
	int handle = FileOpen( file_name, FILE_BIN|FILE_WRITE );
  if( handle > 0 ){
    FileWriteString( handle, out, StringLen(out) );
    FileClose( handle );
  }
  GlobalVariableSet( global_name, TimeLocal() );
	errorCheck( "syncTradeCharts" );
// Alert("saved "+Symbol())  ;
}
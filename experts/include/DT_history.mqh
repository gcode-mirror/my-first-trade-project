//+------------------------------------------------------------------+
//|                                                   DT_history.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+

void startHistory(){
  static int st_timer = 0;
  // if( !EXT_BOSS ){
    // return;
  // }
  if( GetTickCount() < st_timer ){
    return;
  }

  st_timer = GetTickCount() + 2000;

  static double selected = -1;
  static string global_name = "";

  static string st_tLine_ref_str[0][2];
  static double st_tLine_ref_data[0][4];
  static double st_tLine_hist_from[0][5]; // 0 = line_id, 1 = t1, 2 = p1, 3 = t2, 4 = p2
  static double st_tLine_hist_to[0][5]; // 0 = line_id, 1 = t1, 2 = p1, 3 = t2, 4 = p2

  int idx = 0, i, len = ObjectsTotal(), j, len2, len3;
  bool is_new, has_change = false;
  double t1, p1, t2, p2;
  string name;

  // init
  if( selected == -1 ){
    selected = 0.0;
    global_name = StringConcatenate( getSymbol(), "_History" );
    GlobalVariableSet( global_name, 0.0 );

    ArrayResize( st_tLine_ref_str, 30 );
    ArrayResize( st_tLine_ref_data, 30 );

    for( i = 0; i < len; i++ ){
      name = ObjectName(i);
      if( StringSubstr( name, 5, 7 ) == "_tLine_" ){
        st_tLine_ref_str[idx][0] = name;
        st_tLine_ref_str[idx][1] = StringSubstr( name, 16, 10 );
        st_tLine_ref_data[idx][0] = ObjectGet( name, OBJPROP_TIME1 );
        st_tLine_ref_data[idx][1] = NormalizeDouble( ObjectGet( name, OBJPROP_PRICE1 ) ,Digits );
        st_tLine_ref_data[idx][2] = ObjectGet( name, OBJPROP_TIME2 );
        st_tLine_ref_data[idx][3] = NormalizeDouble( ObjectGet( name, OBJPROP_PRICE2 ) ,Digits );
        idx++;
      }
    }

    ArrayResize( st_tLine_ref_str, idx );
    ArrayResize( st_tLine_ref_data, idx );

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

  len2 = ArrayRange( st_tLine_ref_str, 0 );
  for( i = 0; i < len; i++ ){
    name = ObjectName(i);
    if( StringSubstr( name, 5, 7 ) == "_tLine_" ){
      is_new = true;
      for( j = 0; j < len2; j++ ){
        if( name == st_tLine_ref_str[j][0] ){
          idx = j;
          is_new = false;
          break;
        }
      }

      t1 = ObjectGet( name, OBJPROP_TIME1 );
      p1 = NormalizeDouble( ObjectGet( name, OBJPROP_PRICE1 ) ,Digits );
      t2 = ObjectGet( name, OBJPROP_TIME2 );
      p2 = NormalizeDouble( ObjectGet( name, OBJPROP_PRICE2 ) ,Digits );

      if( is_new ){   // has new
        ArrayResize( st_tLine_ref_str, len2 + 1 );
        ArrayResize( st_tLine_ref_data, len2 + 1 );
        st_tLine_ref_str[len2][0] = name;
        st_tLine_ref_str[len2][1] = StringSubstr( name, 16, 10 );
        st_tLine_ref_data[len2][0] = t1;
        st_tLine_ref_data[len2][1] = p1;
        st_tLine_ref_data[len2][2] = t2;
        st_tLine_ref_data[len2][3] = p2;

        len2++;
        has_change = true;

      }else{   // modified
        if( st_tLine_ref_data[idx][0] != t1 || st_tLine_ref_data[idx][1] != p1 || st_tLine_ref_data[idx][2] != t2 || st_tLine_ref_data[idx][3] != p2 ){
          len3 = ArrayRange( st_tLine_hist_from, 0 );
          if( selected < len3 - 1 ){
            len3 = selected;
          }
          
          // Alert( StringConcatenate(st_tLine_ref_data[idx][0]," ",t1," ",st_tLine_ref_data[idx][1]," ",p1 ," ",st_tLine_ref_data[idx][2]," ",t2," ",st_tLine_ref_data[idx][3]," ",p2) );
          
          ArrayResize( st_tLine_hist_from, len3 + 1 );
          ArrayResize( st_tLine_hist_to, len3 + 2 );

          st_tLine_hist_from[len3][0] = StrToDouble( StringSubstr( name, 16, 10 ) );
          st_tLine_hist_from[len3][1] = st_tLine_ref_data[idx][0];
          st_tLine_hist_from[len3][2] = st_tLine_ref_data[idx][1];
          st_tLine_hist_from[len3][3] = st_tLine_ref_data[idx][2];
          st_tLine_hist_from[len3][4] = st_tLine_ref_data[idx][3];

          st_tLine_hist_to[len3 + 1][0] = st_tLine_hist_from[len3][0];
          st_tLine_hist_to[len3 + 1][1] = t1;
          st_tLine_hist_to[len3 + 1][2] = p1;
          st_tLine_hist_to[len3 + 1][3] = t2;
          st_tLine_hist_to[len3 + 1][4] = p2;

          st_tLine_ref_data[idx][0] = t1;
          st_tLine_ref_data[idx][1] = p1;
          st_tLine_ref_data[idx][2] = t2;
          st_tLine_ref_data[idx][3] = p2;

          ObjectSetText( "DT_BO_history_hud", StringConcatenate( "Histrory: ", (len3 + 1), "/", (len3 + 1)), 9, "Consolas", Blue );
          selected = selected + 1.0;
          GlobalVariableSet( global_name, selected );
          has_change = true;
        }
      }
    }
  }

  len = ArrayRange( st_tLine_ref_str, 0 );
  for( i = 0; i < len; i++ ){
    if( ObjectFind( st_tLine_ref_str[i][0] ) == -1 ){ //remove
      len = removeItem( selected, st_tLine_ref_str, st_tLine_ref_str, st_tLine_ref_data, st_tLine_ref_data, st_tLine_hist_from, st_tLine_hist_from, st_tLine_hist_to, st_tLine_hist_to, st_tLine_ref_str[i][0], StrToDouble( st_tLine_ref_str[i][1] ) );
      if( i > 0 ){
        i++;
      }

      GlobalVariableSet( global_name, selected );
      ObjectSetText( "DT_BO_history_hud", StringConcatenate( "Histrory: ", DoubleToStr(selected, 0), "/", ArrayRange( st_tLine_hist_to, 0 ) ), 9, "Consolas", Blue );
      has_change = true;
    }
  }
  
  // is selected changed
  int tmp = GlobalVariableGet( global_name );
  if( selected != tmp ){
    if( tmp < selected ){ // Undo
      idx = getHistLineName( st_tLine_ref_str, DoubleToStr(st_tLine_hist_from[tmp][0], 0) );
      ObjectSet( st_tLine_ref_str[idx][0], OBJPROP_TIME1, st_tLine_hist_from[tmp][1] );
      ObjectSet( st_tLine_ref_str[idx][0], OBJPROP_PRICE1, st_tLine_hist_from[tmp][2] );
      ObjectSet( st_tLine_ref_str[idx][0], OBJPROP_TIME2, st_tLine_hist_from[tmp][3] );
      ObjectSet( st_tLine_ref_str[idx][0], OBJPROP_PRICE2, st_tLine_hist_from[tmp][4] );
      
      st_tLine_ref_data[idx][0] = st_tLine_hist_from[tmp][1];
      st_tLine_ref_data[idx][1] = st_tLine_hist_from[tmp][2];
      st_tLine_ref_data[idx][2] = st_tLine_hist_from[tmp][3];
      st_tLine_ref_data[idx][3] = st_tLine_hist_from[tmp][4];
    }else{ // Redo
      idx = getHistLineName( st_tLine_ref_str, DoubleToStr(st_tLine_hist_to[tmp][0], 0) );
      ObjectSet( st_tLine_ref_str[idx][0], OBJPROP_TIME1, st_tLine_hist_to[tmp][1] );
      ObjectSet( st_tLine_ref_str[idx][0], OBJPROP_PRICE1, st_tLine_hist_to[tmp][2] );
      ObjectSet( st_tLine_ref_str[idx][0], OBJPROP_TIME2, st_tLine_hist_to[tmp][3] );
      ObjectSet( st_tLine_ref_str[idx][0], OBJPROP_PRICE2, st_tLine_hist_to[tmp][4] );
      
      st_tLine_ref_data[idx][0] = st_tLine_hist_to[tmp][1];
      st_tLine_ref_data[idx][1] = st_tLine_hist_to[tmp][2];
      st_tLine_ref_data[idx][2] = st_tLine_hist_to[tmp][3];
      st_tLine_ref_data[idx][3] = st_tLine_hist_to[tmp][4];
    }                                              
    
    ObjectSetText( "DT_BO_history_hud", StringConcatenate( "Histrory: ", tmp, "/", ArrayRange( st_tLine_hist_from, 0 )), 9, "Consolas", Blue );
    selected = tmp;
    has_change = true;
  }

  if( has_change ){
    syncTradeCharts( st_tLine_ref_str, st_tLine_ref_data );
  }

  errorCheck("history");
}

int getHistLineName( string& ref_str[][2], string id ){
  int i = 0, len = ArrayRange( ref_str, 0 );
  for( ; i< len; i++ ){
    if( ref_str[i][1] == id ){
      return ( i );
    }
  }
  return ( -1 );
}

int removeItem( double& selected, string& orig_ref_str[][2], string copy_ref_str[][2], double& orig_ref_data[][4], double copy_ref_data[][4], double& orig_hist_from[][5], double copy_hist_from[][5], double& orig_hist_to[][5], double copy_hist_to[][5], string name, double id ){
  int i = 0, len = ArrayRange( copy_hist_from, 0 ), nr = 0;
  for( ; i < len; i++ ){
    if( copy_hist_from[i][0] != id ){
      orig_hist_from[nr][0] = copy_hist_from[i][0];
      orig_hist_from[nr][1] = copy_hist_from[i][1];
      orig_hist_from[nr][2] = copy_hist_from[i][2];
      orig_hist_from[nr][3] = copy_hist_from[i][3];
      orig_hist_from[nr][4] = copy_hist_from[i][4];

      nr++;

      orig_hist_to[nr][0] = copy_hist_to[i + 1][0];
      orig_hist_to[nr][1] = copy_hist_to[i + 1][1];
      orig_hist_to[nr][2] = copy_hist_to[i + 1][2];
      orig_hist_to[nr][3] = copy_hist_to[i + 1][3];
      orig_hist_to[nr][4] = copy_hist_to[i + 1][4];

    }else{
      if( selected != 0 && i < selected ){
        selected--;
      }
    }
  }
  ArrayResize( orig_hist_from, nr );
  ArrayResize( orig_hist_to, nr + 1 );

  len = ArrayRange( copy_ref_str, 0 );
  nr = 0;
  for( i = 0; i < len; i++ ){
    if( copy_ref_str[i][0] != name ){
      orig_ref_str[nr][0] = copy_ref_str[i][0];
      orig_ref_str[nr][1] = copy_ref_str[i][1];

      orig_ref_data[nr][0] = copy_ref_data[i][0];
      orig_ref_data[nr][1] = copy_ref_data[i][1];
      orig_ref_data[nr][2] = copy_ref_data[i][2];
      orig_ref_data[nr][3] = copy_ref_data[i][3];

      nr++;
    }
  }
  ArrayResize( orig_ref_str, nr );
  ArrayResize( orig_ref_data, nr );
  return ( nr );
}

void syncTradeCharts( string& line_str[][2], double &line_data[][4] ){
	static string file_name = "";
	static string global_name = "";
	if( file_name == "" ){
		file_name = StringConcatenate( getSymbol(), "_tLines.csv" );
		global_name = StringConcatenate( getSymbol(), "_tLines_lastMod.csv" );
	}
	int i, j, len = ArrayRange( line_str, 0 );
	string out = "";
	for( i = 0; i < len; i++ ){
    for( j = i + 1; j < len; j++ ){
      if( line_str[i][0] == line_str[j][0] && line_str[i][1] == line_str[j][1] && line_str[i][2] == line_str[j][2] && line_str[i][3] == line_str[j][3] ){
        ObjectDelete( line_str[j][0] );
        Alert( Symbol()+" error duplicated line removed: "+line_str[i][0] );
        return;
      }
    }
		out = StringConcatenate(out, line_str[i][0], ";", DoubleToStr(line_data[i][0],0), ";", DoubleToStr(line_data[i][1],Digits), ";", DoubleToStr(line_data[i][2],0), ";", DoubleToStr(line_data[i][3],Digits), ";", ObjectGet(line_str[i][0],OBJPROP_COLOR), ";", ObjectType(line_str[i][0]),"\r\n" );
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
}
//+------------------------------------------------------------------+
//|                                                      DT_fade.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

void initFade(){
  if( !GlobalVariableCheck( "DT_window_fade" ) ){
    GlobalVariableSet( "DT_window_fade", 0.0 );
  }
  
  ObjectCreate( "DT_BO_w0_fade_main", OBJ_LABEL, 0, 0, 0 );
  ObjectSet( "DT_BO_w0_fade_main", OBJPROP_CORNER, 0 );
  ObjectSet( "DT_BO_w0_fade_main", OBJPROP_XDISTANCE, 0 );
  ObjectSet( "DT_BO_w0_fade_main", OBJPROP_YDISTANCE, 12 );
  ObjectSet( "DT_BO_w0_fade_main", OBJPROP_BACK, false );
  ObjectSet( "DT_BO_w0_fade_main", OBJPROP_TIMEFRAMES, -1 );
  ObjectSetText( "DT_BO_w0_fade_main", "g", 1120, "Webdings", White );
}

void startFade(){
  static double st_switch = -1.0;
  
  if( st_switch == -1.0 ){
    st_switch = GlobalVariableGet("DT_window_fade");
    initFade();
    if( st_switch == 1.0 ){
      showFade();
    }
  }
  
  if( st_switch != GlobalVariableGet("DT_window_fade") ){
    st_switch = GlobalVariableGet("DT_window_fade");
    if( st_switch == 0.0 ){
      if( ObjectGet( "DT_BO_w0_fade_main", OBJPROP_TIMEFRAMES ) == 0 ){
        ObjectSet( "DT_BO_w0_fade_main", OBJPROP_TIMEFRAMES, -1 );
      }
      removeObjects("w0_fade_txt");
    }else{
      showFade();
    }
  }
}

void showFade(){
  if( ObjectGet( "DT_BO_w0_fade_main", OBJPROP_TIMEFRAMES ) == -1 ){
    ObjectSet( "DT_BO_w0_fade_main", OBJPROP_TIMEFRAMES, 0 );
    if( ObjectFind( "DT_BO_w1_hud_fade_txt_0" ) == -1 ){
      printRandomText();
    }
  }
} 

bool printRandomText(){
  string name; 
  static string random_txt[] = {
    "  // constants",
    "  tshark_exe   = '\'C:\\Program Files\\Wireshark\\tshark.exe\'';",
    "  c_temp_dir   = 'C:\\Temp\\';",
    "  cap_file     = detectLstName() + postfix + '.cap';",
    " ",
    "  // determining capture type",
    "  capture_type = 'capture filter';",
    "  filter = strtrim(filter, TRIM_LEADING_SPACE|TRIM_TRAILING_SPACE);",
    " ",
    "  strfetch(detectLstName(),'1-5',fnnum);",
    "  logprint('UPRstartTshark(): log %s \n',fnnum);",
    " ",
    "  // connecting to 'wireshark_pc'",
    "  if (NOT deviceopen('wireshark_pc'))",
    "    logprint('HIT Analysis Verdict: FAILED, reason: UPRstartTshark(), deviceopen(\'wireshark_pc\') failed, tshark.exe was not started.\n');",
    "    return FALSE;",
    "  endif",
    " ",
    "  // get the prompt, as it does not always appear for some unknown reason",
    "  send('\r\n\r\n');",
    " ",
    "  // try if sending in a command works",
    "  tx('echo \'****** %s: UPRstartTshark() is starting tshark.exe for TC %s ******\'', getpctime(3), detectLstName());",
    " ",
    "  // starting the capturing",
    "  if (capture_type == 'capture filter')",
    "    if (filter == strtrim(WIRESHARK_FILTER, TRIM_LEADING_SPACE|TRIM_TRAILING_SPACE))",
    "      logprint('UPRstartTshark(): starting tshark.exe on Wireshark PC (using capture filter = WIRESHARK_FILTER)...\n');",
    "    else",
    "      logprint('UPRstartTshark(): starting tshark.exe on Wireshark PC (using capture filter = \'%s\')...\n', filter);",
    "    endif",
    " ",
    "    promptcheck(BEFORE);",
    " ",
    "    // this is the point!!!",
    "    tx_with_more(strprint('%s -i %s -f \'%s\' -w %s', tshark_exe, WIRESHARK_INTERFACE_ID, filter, c_temp_dir+cap_file));",
    "    promptcheck(BOTH);",
    " ",
    "    delay(1000);  // wait for the printout",
    "    if (getline(line, ''Capturing on ':1-13'))",   
  };
  
  int i, j, space, len = ArraySize(random_txt), cha;
  color c = Black;
  for( i = 0; i < len; i++ ){
    space = 0;
    for( j = 0; j < StringLen(random_txt[i]); j++ ){
      cha = StringGetChar(random_txt[i], j);
      if( cha == 32 || cha == 9 ){
        space++;
      }else if( cha == 47 ){  
        c = C'0,128,250';
        break;
      }else{
        c = Black;
        break;
      }
    }
    name = "DT_BO_w0_fade_txt_"+i;
    ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
    ObjectSet( name, OBJPROP_CORNER, 0 );
    ObjectSet( name, OBJPROP_XDISTANCE, ( space * 40 ) );
    ObjectSet( name, OBJPROP_YDISTANCE, 20 + ( i * 19 ) );
    ObjectSet( name, OBJPROP_BACK, false );
    ObjectSetText( name, StringTrimLeft(random_txt[i]), 10, "Lucida Console", c );
  }
}
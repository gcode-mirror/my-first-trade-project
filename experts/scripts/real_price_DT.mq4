//+------------------------------------------------------------------+
//|                                          real_price_level_DT.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+

#include <DT_defaults.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
#include <WinUser32.mqh>

#import "user32.dll"
  void keybd_event(int bVk,int bScan,int dwFlags,int dwExtraInfo);
#import

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  double tod = WindowTimeOnDropped();
  int i, cmd_id, len = ObjectsTotal(), shift, nr = 0, used_peri = -1;
  string name, rpl_name, title = "";
  int preis[5] = { 1, 5, 15, 30, 60 }, available_peris[3] = { 0, 0, 0 };
  string preis_name[5] = {"M1", "M5", "M15", "M30", "H1"};

  for( i = 0; i < len; i++ ){
    name = ObjectName(i);
    if( StringSubstr( name, 0, 17 ) == "DT_GO_real_price_" ){
      if( ObjectFind( "DT_GO_RP_prev_time" ) != -1 ){
        scrollTo(StrToInteger(ObjectDescription( "DT_GO_RP_prev_time" )));
        ObjectDelete( "DT_GO_RP_prev_time" );
        return (0);
      }
      removeObjects( "real_price", "GO" );
      if( ObjectFind( "DT_GO_RULER_SWITCH" ) == -1 ){
        for( i = 0; i < len; i++ ){
          name = ObjectName(i);
          ObjectSet( name, OBJPROP_TIMEFRAMES, 0 );
        }
      }
      if( tod == 0.0 ){
        return (0);
      }
    }
  }
  
  if( tod != 0.0 ){
    for( i = 0; i < 5 && nr < 3; i++ ){
      if( iBars( NULL, preis[i] ) - 1 != iBarShift( NULL, preis[i], tod ) ){
        title = StringConcatenate( title ,preis_name[i], "      ");
        available_peris[nr] = preis[i];
        nr++;
      }
    }
    
    cmd_id = MessageBox( title, "Which timeframe?", MB_YESNOCANCEL|MB_ICONQUESTION );
    if( cmd_id == IDYES ){
      if( available_peris[0] == 0 ){
        return (0);
      }
      used_peri = available_peris[0];
    }else if( cmd_id == IDNO ){
      if( available_peris[1] == 0 ){
        return (0);
      }
      used_peri = available_peris[1];
    }else if( cmd_id == IDCANCEL ){
      if( available_peris[2] == 0 ){
        return (0);
      }
      used_peri = available_peris[2];
    }
    
    if(ObjectFind( "DT_GO_RP_prev_time" ) == -1 ){
      ObjectCreate( "DT_GO_RP_prev_time", OBJ_TREND, 0, 0, 0, Time[0], 0.01 );
      ObjectSet( "DT_GO_RP_prev_time", OBJPROP_RAY, false );
    }
    ObjectSetText( "DT_GO_RP_prev_time", ""+iBarShift( NULL, used_peri, tod ), 10 );
    
  }else{
    if( Period() < PERIOD_H4 ){
      used_peri = Period();
    }
  }
  
  if( used_peri != -1 ){
    if(ObjectFind( "DT_GO_RP_prev_id" ) == -1 ){
      ObjectCreate( "DT_GO_RP_prev_id", OBJ_TREND, 0, 0, 0, Time[0], 0.01 );
      ObjectSet( "DT_GO_RP_prev_id", OBJPROP_RAY, false );
    }
    ObjectSetText( "DT_GO_RP_prev_id", ""+getPeriodWHID( used_peri ), 10 );
    PostMessageA( WindowHandle( Symbol(), Period() ), WM_COMMAND, 33136, 0 );
    keybd_event(18, 0, 0, 0); // ALT down
    keybd_event(82, 0, 0, 0); // R down
    keybd_event(82, 0, 2, 0); // R up
    keybd_event(18, 0, 2, 0); // ALT up
    return (0);
  }
  
  double p;
  int bars = Bars - 1, idx = 0;
  string lines[50][2];
  
  for( i = 0; i < len; i++ ){
    name = ObjectName(i);
    if( ObjectType( name ) == OBJ_TREND ){
      if( ObjectGet( name, OBJPROP_TIMEFRAMES ) != -1 ){
        if( StringSubstr( name, 5, 7 ) == "_tLine_" ){
          lines[idx][1] = StringConcatenate( "DT_GO_real_price_", StringSubstr( name, 16, 10 ), "_" );
        }else if( StringSubstr( name, 0, 9 ) == "Trendline" ){
          lines[idx][1] = StringConcatenate( "DT_GO_real_price_", StringSubstr( name, 10 ), "_" );
        }else{
          continue;
        }
        lines[idx][0] = name;
        if( ObjectFind( "DT_GO_RULER_SWITCH" ) == -1 ){
          ObjectSet( name, OBJPROP_TIMEFRAMES, -1 );
        }
        idx++;
      }
    }
  }
  
  for( i = 0; i < idx; i++ ){
    shift = iBarShift( NULL, 0, ObjectGet( lines[i][0], OBJPROP_TIME2 ) );
    while( shift >= 0 ){
      if( shift >= bars ){
        shift = bars - 1;
      }
      
      rpl_name = StringConcatenate( lines[i][1], shift );
      p = ObjectGetValueByShift( lines[i][0], shift );
      if( shift == 0 ){
        ObjectCreate( rpl_name, OBJ_TREND, 0, Time[shift], p, Time[shift] + (Period() * 60), p );
      }else{
        ObjectCreate( rpl_name, OBJ_TREND, 0, Time[shift], p, Time[shift - 1], p );
      }
      ObjectSet( rpl_name, OBJPROP_COLOR, ObjectGet(lines[i][0], OBJPROP_COLOR) );
      ObjectSet( rpl_name, OBJPROP_WIDTH, 1 );
      ObjectSet( rpl_name, OBJPROP_BACK, true );
      ObjectSet( rpl_name, OBJPROP_RAY, false);
      ObjectSetText( rpl_name, ObjectDescription( lines[i][0] ) );
      
      shift--;
    }
  }
  
  if( ObjectFind( "DT_GO_RP_prev_id" ) != -1 ){
    int tmp = StrToInteger( ObjectDescription( "DT_GO_RP_prev_id" ));
    ObjectDelete( "DT_GO_RP_prev_id" );
    MessageBox( "Please press OK!", "Waiting...", MB_OK );
    PostMessageA( WindowHandle( Symbol(), Period() ), WM_COMMAND, tmp, 0 );
    if( ObjectFind( "DT_GO_RP_prev_time" ) != -1 ){
      keybd_event(18, 0, 0, 0); // ALT down
      keybd_event(82, 0, 0, 0); // R down
      keybd_event(82, 0, 2, 0); // R up
      keybd_event(18, 0, 2, 0); // ALT up
    }
  }
  return (0);
}

int getPeriodWHID( int peri ){
  switch( peri ){
    case 1: return (33137);
    case 5: return (33138);
    case 15: return (33139);
    case 30: return (33140);
    case 60: return (35400);
  }
}

bool scrollTo( int shift ){
  if( shift < Bars ){
    if( shift > WindowFirstVisibleBar() ){
      while( WindowFirstVisibleBar() <= shift ){
        keybd_event(33, 0, 0, 0); 
        keybd_event(33, 0, 2, 0);
        Sleep(10);
      }
    }else if( shift < WindowFirstVisibleBar()-WindowBarsPerChart() ){
      while( WindowFirstVisibleBar()-WindowBarsPerChart()-1 > shift ){
        keybd_event(34, 0, 0, 0); 
        keybd_event(34, 0, 2, 0);
        Sleep(10);
      }
    }
  }
  
  int shift2 = shift + (WindowBarsPerChart() / 2);
  if( shift2 < WindowBarsPerChart() ){
    shift2 = WindowBarsPerChart();
  }
  
  if( shift2 < Bars ){
    if( shift2 > WindowFirstVisibleBar() ){
      while( shift2 >= WindowFirstVisibleBar() ){
        keybd_event(38, 0, 0, 0); 
        keybd_event(38, 0, 2, 0);
        Sleep(10);
      }
    }else if( shift2 < WindowFirstVisibleBar() ){
      while( shift2 < WindowFirstVisibleBar() ){
        keybd_event(40, 0, 0, 0); 
        keybd_event(40, 0, 2, 0);
        Sleep(10);
      }
    }
  }
  
}
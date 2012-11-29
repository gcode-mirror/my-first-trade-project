//+------------------------------------------------------------------+
//|                                                      DT_zoom.mqh |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <WinUser32.mqh>
#import "user32.dll"
   bool GetCursorPos(int& Pos[2]);
	 bool GetWindowRect(int h, int& pos[4]);
   void mouse_event(int dwFlags,int& dx,int& dy,int dwData,int dwExtraInfo);
   bool GetAsyncKeyState(int nVirtKey);
   void keybd_event(int bVk,int bScan,int dwFlags,int dwExtraInfo);
#import

void startZoom(){
  static int period_keys[9][2] = {
    1,      33137,
    5,      33138,
    15,     33139,
    30,     33140,
    60,     35400,
    240,    33136,
    1440,   33134,
    10080,  33141,
    43200,  33334
  };
  if( getGlobal("ZOOM") != 0.0 ){
    double gv_ctrl = getGlobal("ZOOM");
    int i, tmp, period_key, aim_peri, aim_shift;
    
    if( gv_ctrl == -0.1 || gv_ctrl == 0.1 ){
      if( gv_ctrl == -0.1 ){
        period_key = getPrevPeriKeyID( period_keys, Period(), aim_peri );
      }else{
        period_key = getNextPeriKeyID( period_keys, Period(), aim_peri );
      }
      
      if( period_key == -1 ){
        setGlobal( "ZOOM", 0.0 );
        addComment( "No more timeframe!" ,1 );
        return;
      }
      
      aim_shift = iBarShift( NULL, aim_peri, Time[getShiftOverCursor()] );
      if( aim_shift < 1 ){
        aim_shift = 1;
      }
      
      if( iBars( NULL, aim_peri ) - 1 == aim_shift ){
        setGlobal( "ZOOM", 0.0 );
        addComment( "Run out of history bars" ,1 );
        return;
      }
      
      setGlobal( "ZOOM", aim_shift );
      PostMessageA( WindowHandle( Symbol(), Period() ), WM_COMMAND, period_key, 0 );
      return;
      
    }else if( gv_ctrl == 0.3 ){
      keybd_event(35, 0, 0, 0);
      keybd_event(35, 0, 2, 0);
      setGlobal( "ZOOM", 0.0 );
      return;
      
    }else{
      setGlobal( "ZOOM", 0.0 );
      aim_shift = gv_ctrl;
      
      bool is_alt_pressed = false;
      if( GetAsyncKeyState(18) ){
        keybd_event(18, 0, 2, 0);
        is_alt_pressed = true;
      }
      
      if( WindowFirstVisibleBar() < (WindowBarsPerChart() * 0.9) ){
        keybd_event(35, 0, 0, 0);
        keybd_event(35, 0, 2, 0);
      }else{
        int curr_shift = getShiftOverCursor();
        
        if( curr_shift - aim_shift > 0 ){
          tmp = ( curr_shift - aim_shift ) / 4;
          for( i = 0; i < tmp; i++ ){
            keybd_event(39, 0, 0, 0);
            keybd_event(39, 0, 2, 0);
          }
        }else{
          tmp = ( aim_shift - curr_shift ) / 4;
          for( i = 0; i < tmp; i++ ){
            keybd_event(37, 0, 0, 0);
            keybd_event(37, 0, 2, 0);
          }
        }
      }
      
      if( is_alt_pressed ){
        keybd_event(18, 0, 0, 0);
      }
      
      mouse_event(MOUSEEVENTF_LEFTDOWN,0,0,0,0);
      mouse_event(MOUSEEVENTF_LEFTUP,0,0,0,0);
      
      return;
    }
  }
}

void autoScroll(){
	if( WindowFirstVisibleBar() - WindowBarsPerChart() <= 0 ){
    if( getGlobal("ZOOM") == 0.0 ){
      setGlobal( "ZOOM", 0.3 );
    }
  }
}

int getShiftOverCursor(){
	int CursorPoint[2];
	GetCursorPos(CursorPoint);
	
	int WindowDims[4];
	GetWindowRect( WindowHandle( Symbol(), Period() ), WindowDims );
	int window_width = WindowDims[2] - WindowDims[0] - 47;
	double tmp = CursorPoint[0] - WindowDims[0] - 5;
  int res = WindowFirstVisibleBar() - MathRound( WindowBarsPerChart() * ( tmp / window_width ) );
  if( res < 0 ){
    res = 0;
  }
	return ( res );
}

int getPrevPeriKeyID( int& period_keys[][], int peri, int& aim_peri ){
	for( int i = 1; i < ArrayRange( period_keys, 0 ); i++ ){
		if( peri == period_keys[i][0] ){
      aim_peri = period_keys[i - 1][0];
			return ( period_keys[i - 1][1] );
		}
	}
	return (-1);
}

int getNextPeriKeyID( int& period_keys[][], int peri, int& aim_peri ){
	for( int i = 0; i < ArrayRange( period_keys, 0 ) - 1; i++ ){
		if( peri == period_keys[i][0] ){
      aim_peri = period_keys[i + 1][0];
			return ( period_keys[i + 1][1] );
		}
	}
	return (-1);
}

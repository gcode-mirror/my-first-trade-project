//+------------------------------------------------------------------+
//|                                                  DT_sessions.mq4 |
//|                                                              Dex |
//|                                                                  |
#property copyright "Dex"
#property link      ""

#define SYDNEY 0
#define TOKYO 1
#define HONGKONG 2
#define FRANKFURT 3
#define LONDON 4
#define NEWYORK 5
#define CHICAGO 6
#define MOSCOW 7
#define MADRID 8

#define START 0
#define STOP 1

double TIMEZONES[7][4];
string ZONENAMES[7];

bool initSession( string isOn ){
  setAppStatus( APP_ID_SESSION, isOn );
  if( isOn == "0" ){        
    return (false);    
  }
  
  deinitSession();
  
  ZONENAMES[SYDNEY] = "Sydney";
  TIMEZONES[SYDNEY][START] = 23;
  TIMEZONES[SYDNEY][STOP] = 7;

  ZONENAMES[TOKYO] = "Tokyo";
  TIMEZONES[TOKYO][START] = 1;
  TIMEZONES[TOKYO][STOP] = 9;

  ZONENAMES[HONGKONG] = "Hongkong";
  TIMEZONES[HONGKONG][START] = 2;
  TIMEZONES[HONGKONG][STOP] = 10;

  ZONENAMES[FRANKFURT] = "Frankfurt";
  TIMEZONES[FRANKFURT][START] = 8;
  TIMEZONES[FRANKFURT][STOP] = 17;

  ZONENAMES[LONDON] = "London";
  TIMEZONES[LONDON][START] = 9;
  TIMEZONES[LONDON][STOP] = 18;

  ZONENAMES[NEWYORK] = "NewYork";
  TIMEZONES[NEWYORK][START] = 14;
  TIMEZONES[NEWYORK][STOP] = 22;

  ZONENAMES[CHICAGO] = "Chicago";
  TIMEZONES[CHICAGO][START] = 15;
  TIMEZONES[CHICAGO][STOP] = 23;  
	
  return (errorCheck("initSession"));
}

bool startSession( string isOn ){
  if(isAppStatusChanged( APP_ID_SESSION, isOn )){
    if(isOn == "1"){
      initSession("1");
    }else{
      deinitSession();
      return (false);
    }    
  }
	if( isOn == "0" ){return (false);}
	if( delayTimer(APP_ID_SESSION, 3100)) {return (false);}
  
  double time = TimeCurrent();
  int len = ArrayRange( TIMEZONES, 0 );
  int i, h, m, nr = 1, left_h, left_m;
  string time_left = "", name_label, time_label;
  color c;
  h = TimeHour(time);
  m = TimeMinute(time);
  
  for(i = 0; i < len; i++){
    time_left = "";
    if( TIMEZONES[i][START] > TIMEZONES[i][STOP] ){
      if( h >= TIMEZONES[i][START] ){
        left_h = 23 - h + TIMEZONES[i][STOP];
        left_m = 59 - m;        
      
      }else if( h < TIMEZONES[i][STOP] ){      
        left_h = TIMEZONES[i][STOP] - 1 - h;
        left_m = 59 - m;        
      
      }else{
        continue;
      }
    }else{
      if( h >= TIMEZONES[i][START] && h < TIMEZONES[i][STOP] ){
        left_h = TIMEZONES[i][STOP] - 1 - h;
        left_m = 59 - m;        
      }else{
        continue;
      }     
    }
    
    time_left = getTimeFormated( left_h, left_m );
    name_label = StringConcatenate( "DT_BO_session_name",nr );
    time_label = StringConcatenate( "DT_BO_session_time",nr );
    if( h == 0 ){
      c = Red;
    }else{
      c = Black;
    }
    
    if( ObjectFind( name_label ) == -1 ){
      ObjectCreate( name_label, OBJ_LABEL, 0, 0, 0 );
      ObjectSet( name_label, OBJPROP_CORNER, 0 );
      ObjectSet( name_label, OBJPROP_XDISTANCE, 5 );
      ObjectSet( name_label, OBJPROP_YDISTANCE, 47 + (nr * 20) );
      ObjectSet( name_label, OBJPROP_BACK, true);
      
      
      ObjectCreate( time_label, OBJ_LABEL, 0, 0, 0 );
      ObjectSet( time_label, OBJPROP_CORNER, 0 );
      ObjectSet( time_label, OBJPROP_XDISTANCE, 70 );
      ObjectSet( time_label, OBJPROP_YDISTANCE, 47 + (nr * 20) );
      ObjectSet( time_label, OBJPROP_BACK, true);      
    }
    
    ObjectSetText( name_label, ZONENAMES[i], 10, "Arial", c );
    ObjectSetText( time_label, time_left, 10, "Arial", c );
    nr++;
     
  }
  
  if( nr > 1 ){
    if( ObjectFind( "DT_BO_session_head_1" ) == -1 ){
      ObjectCreate( "DT_BO_session_head_1", OBJ_LABEL, 0, 0, 0 );
      ObjectSet( "DT_BO_session_head_1", OBJPROP_CORNER, 0 );
      ObjectSet( "DT_BO_session_head_1", OBJPROP_XDISTANCE, 3 );
      ObjectSet( "DT_BO_session_head_1", OBJPROP_YDISTANCE, 45 );
      ObjectSet( "DT_BO_session_head_1", OBJPROP_BACK, true);
	    ObjectSetText( "DT_BO_session_head_1", "Current Sessions:", 12, "Arial", Black );
    }
  }

  return (errorCheck("startSession"));  
}

bool deinitSession(){
  removeObjects("session");
  return (errorCheck("deinitSession"));
}

string getTimeFormated( int hour, int min ){
  string result = "| ";
  if( hour < 10 ){
    result = result + StringConcatenate( "0", hour, ":" );
  }else{
    result = result + StringConcatenate( hour, ":" );
  }
  
  if( min < 10 ){
    result = result + StringConcatenate( "0", min );
  }else{
    result = result + min;
  }
  return (result);
}
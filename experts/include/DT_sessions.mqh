//+------------------------------------------------------------------+
//|                                                  DT_sessions.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
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

int SESS_Y_POS = 45;

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
	
	string name;
	int i, len = ArrayRange( TIMEZONES, 0 );
	for(i = 0; i < len; i++){
    name = "DT_BO_session_curr_name_"+i;
    ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
    ObjectSet( name, OBJPROP_CORNER, 0 );      
    ObjectSet( name, OBJPROP_BACK, true);
    ObjectSet( name, OBJPROP_XDISTANCE, 5 );    

    name = "DT_BO_session_curr_time_"+i;
    ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
    ObjectSet( name, OBJPROP_CORNER, 0 );      
    ObjectSet( name, OBJPROP_BACK, true);
    ObjectSet( name, OBJPROP_XDISTANCE, 70 );  
    
    name = "DT_BO_session_come_name_"+i;
    ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
    ObjectSet( name, OBJPROP_CORNER, 0 );      
    ObjectSet( name, OBJPROP_BACK, true);
    ObjectSet( name, OBJPROP_XDISTANCE, 5 ); 
    
    name = "DT_BO_session_come_time_"+i;
    ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
    ObjectSet( name, OBJPROP_CORNER, 0 );      
    ObjectSet( name, OBJPROP_BACK, true);
    ObjectSet( name, OBJPROP_XDISTANCE, 70 );  
	}
	
  name = "DT_BO_session_curr_head";
  ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
  ObjectSet( name, OBJPROP_CORNER, 0 );      
  ObjectSet( name, OBJPROP_BACK, true);
  ObjectSet( name, OBJPROP_XDISTANCE, 5 );
  ObjectSet( name, OBJPROP_YDISTANCE, SESS_Y_POS - 15 );
	ObjectSetText( name, "Current Sessions:", 8, "Verdana", 0x5b5f60 );

	
	name = "DT_BO_session_come_head";
  ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
  ObjectSet( name, OBJPROP_CORNER, 0 );      
  ObjectSet( name, OBJPROP_BACK, true);
  ObjectSet( name, OBJPROP_XDISTANCE, 5 );
	ObjectSetText( name, "Coming Sessions:", 8, "Verdana", 0x5b5f60 );

    
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
  int i, h, m, left_h, curr_nr = 0, come_nr = 0, ydist;
  string label_name, label_time;
  color c;
  h = TimeHour(time);
  m = TimeMinute(time);
  
  for(i = 0; i < len; i++){
    if( h == TIMEZONES[i][START]-1 ){
      ObjectSetText( "DT_BO_session_come_name_"+come_nr, ZONENAMES[i], 9, "Arial", C'228,15,26' );
      ObjectSetText( "DT_BO_session_come_time_"+come_nr, getTimeFormated(0, 59 - m, ""), 9, "Arial", C'228,15,26' );
      come_nr++;
    }else if( TIMEZONES[i][START] > TIMEZONES[i][STOP] ){
      if( h >= TIMEZONES[i][START] ){
        left_h = 23 - h + TIMEZONES[i][STOP];
        if( left_h == 0 ){
          c = C'228,15,26';
        }else{
          c = 0x333638;
        } 
        
        ObjectSetText( "DT_BO_session_curr_name_"+curr_nr, ZONENAMES[i], 9, "Arial", c );
        ObjectSetText( "DT_BO_session_curr_time_"+curr_nr, getTimeFormated(left_h, 59 - m), 9, "Arial", c );
        curr_nr++;       
      
      }else if( h < TIMEZONES[i][STOP] ){      
        left_h = TIMEZONES[i][STOP] - 1 - h;        
        if( left_h == 0 ){
          c = C'228,15,26';
        }else{
          c = 0x333638;
        } 
        
        ObjectSetText( "DT_BO_session_curr_name_"+curr_nr, ZONENAMES[i], 9, "Arial", c );
        ObjectSetText( "DT_BO_session_curr_time_"+curr_nr, getTimeFormated(left_h, 59 - m), 9, "Arial", c );
        curr_nr++;     
      
      }else{
        continue;
      }
    }else{
      if( h >= TIMEZONES[i][START] && h < TIMEZONES[i][STOP] ){
        left_h = TIMEZONES[i][STOP] - 1 - h;
        if( left_h == 0 ){
          c = C'228,15,26';
        }else{
          c = 0x333638;
        }        
        ObjectSetText( "DT_BO_session_curr_name_"+curr_nr, ZONENAMES[i], 9, "Arial", c );
        ObjectSetText( "DT_BO_session_curr_time_"+curr_nr, getTimeFormated(left_h, 59 - m), 9, "Arial", c );
        curr_nr++;      
      }else{
        continue;
      }     
    }
  }  
	
	if( curr_nr == 0){  
		ObjectSet( "DT_BO_session_curr_head", OBJPROP_TIMEFRAMES, -1 );
	}else{
		ObjectSet( "DT_BO_session_curr_head", OBJPROP_TIMEFRAMES, 0 );
	}
	
	if( come_nr == 0){  
		ObjectSet( "DT_BO_session_come_head", OBJPROP_TIMEFRAMES, -1 );
	}else{
		ObjectSet( "DT_BO_session_come_head", OBJPROP_TIMEFRAMES, 0 );
		ObjectSet( "DT_BO_session_come_head", OBJPROP_YDISTANCE, SESS_Y_POS + (curr_nr * 17) + 6 );
	}
    
	for(i = 0; i < len; i++){
		label_name = "DT_BO_session_curr_name_"+i;
		label_time = "DT_BO_session_curr_time_"+i;
		if( i < curr_nr ){
			ydist = SESS_Y_POS + (i * 17);
			ObjectSet( label_name, OBJPROP_YDISTANCE, ydist );
			ObjectSet( label_name, OBJPROP_TIMEFRAMES, 0 );
			ObjectSet( label_time, OBJPROP_YDISTANCE, ydist );
			ObjectSet( label_time, OBJPROP_TIMEFRAMES, 0 );
		}else{
			ObjectSet( label_name, OBJPROP_TIMEFRAMES, -1 );
			ObjectSet( label_time, OBJPROP_TIMEFRAMES, -1 );
		}
		
		label_name = "DT_BO_session_come_name_"+i;
		label_time = "DT_BO_session_come_time_"+i;
		if( i < come_nr ){
			ydist = SESS_Y_POS + (curr_nr * 17) + 20 +(i * 17);
			ObjectSet( label_name, OBJPROP_YDISTANCE, ydist );
			ObjectSet( label_name, OBJPROP_TIMEFRAMES, 0 );
			ObjectSet( label_time, OBJPROP_YDISTANCE, ydist );
			ObjectSet( label_time, OBJPROP_TIMEFRAMES, 0 );
		}else{
			ObjectSet( label_name, OBJPROP_TIMEFRAMES, -1 );
			ObjectSet( label_time, OBJPROP_TIMEFRAMES, -1 );
		}      
	}
  return (errorCheck("startSession"));  
}

bool deinitSession(){
  removeObjects("session");
  return (errorCheck("deinitSession"));
}

string getTimeFormated( int hour, int min, string sign = "- " ){
  string result = StringConcatenate("| ", sign);
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
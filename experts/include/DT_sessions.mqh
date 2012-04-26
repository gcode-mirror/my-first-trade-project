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
	if( delayTimer(APP_ID_SESSION, 2100)) {return (false);}
  
  double time = TimeCurrent();
  int len = ArrayRange( TIMEZONES, 0 );
  int i, h = TimeHour(time);
  
  for(i = 0; i < len; i++){
    if( TIMEZONES[i][START] > TIMEZONES[i][STOP] ){
      if( h >= TIMEZONES[i][START] || h < TIMEZONES[i][STOP] ){
        // Alert(ZONENAMES[i]);
      }
    }else{
      if( h >= TIMEZONES[i][START] && h < TIMEZONES[i][STOP] ){
        // Alert(ZONENAMES[i]);
      }
    }
  }
 
  return (errorCheck("startSession"));  
}

bool deinitSession(){
  removeObjects("session");
  return (errorCheck("deinitSession"));
}

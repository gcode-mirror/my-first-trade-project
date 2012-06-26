//+------------------------------------------------------------------+
//|                                              trend_finder_DT.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_icons.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
#include <WinUser32.mqh>

#define ZZ_DEPH 12
#define ZZ_DEV 5
#define ZZ_BACKSTEP	3

#define M15_FACTOR 1.0
#define H1_FACTOR 3.0
#define H4_FACTOR 4.0
#define D1_FACTOR 6.0
#define W1_FACTOR 8.0

double ZIGZAG[0][4];

int start(){
  // double tod = WindowTimeOnDropped();
  // int mb_id == IDCANCEL;

  // if( ObjectFind( "DT_GO_trend_finder_limit" ) == -1 ){
    // mb_id = MessageBox( "Search trend from Forward(D&D => Time[0]) or Backward(Line <= D&D)?", "Trend finder", MB_YESNOCANCEL|MB_ICONQUESTION );
    // if( mb_id == IDCANCEL ){
      // return (0);
    // }
  // }

  // if( mb_id == IDNO ){
    // ObjectCreate( "DT_GO_trend_finder_limit", OBJ_VLINE, 0, tod, 0 );
    // ObjectSet( "DT_GO_trend_finder_limit", OBJPROP_COLOR, Red );
    // ObjectSet( "DT_GO_trend_finder_limit", OBJPROP_BACK, true );
    // ObjectSet( "DT_GO_trend_finder_limit", OBJPROP_WIDTH, 2 );
    // return (0);
  // }

  // double start_time, end_time;
  // if( ObjectFind( "DT_GO_trend_finder_limit" ) == -1 ){
    // start_time = tod;
    // end_time = Time[0];
  // }else{
    // double h, l;
    // int idx = iBarShift( NULL , 0, tod );
    // h = High[idx];
    // l = Low[idx];
  // }
  
  ObjectCreate( "DT_BO_trend_finder_hud", OBJ_LABEL, 0, 0, 0 );
  ObjectSet( "DT_BO_trend_finder_hud", OBJPROP_CORNER, 0 );
  ObjectSet( "DT_BO_trend_finder_hud", OBJPROP_XDISTANCE, 600 );
  ObjectSet( "DT_BO_trend_finder_hud", OBJPROP_YDISTANCE, 0 );
  ObjectSet( "DT_BO_trend_finder_hud", OBJPROP_BACK, true);
  ObjectSetText( "DT_BO_trend_finder_hud", "0%", 11, "Arial", Red );
  
	double from = iBarShift( NULL , PERIOD_M15, ObjectGet( "DT_GO_trend_finder_limit", OBJPROP_TIME1 ) );
	double to = 0;

  ArrayResize( ZIGZAG, from + 1 );
  ArrayInitialize( ZIGZAG, 0.0 );
  
	setZigZagArr( PERIOD_M15, iBarShift( NULL , PERIOD_M15, ObjectGet( "DT_GO_trend_finder_limit", OBJPROP_TIME1 )), to, M15_FACTOR );
	setZigZagArr( PERIOD_H1, iBarShift( NULL , PERIOD_H1, ObjectGet( "DT_GO_trend_finder_limit", OBJPROP_TIME1 )), to, H1_FACTOR );
	// setZigZagArr( PERIOD_H4, iBarShift( NULL , PERIOD_H4, ObjectGet( "DT_GO_trend_finder_limit", OBJPROP_TIME1 )), to, H4_FACTOR );
	// setZigZagArr( PERIOD_D1, iBarShift( NULL , PERIOD_D1, ObjectGet( "DT_GO_trend_finder_limit", OBJPROP_TIME1 )), to, D1_FACTOR );
	// setZigZagArr( PERIOD_W1, iBarShift( NULL , PERIOD_W1, ObjectGet( "DT_GO_trend_finder_limit", OBJPROP_TIME1 )), to, W1_FACTOR );
  
  
  
  string name = "DT_GO_tf";
  ObjectCreate(name, OBJ_TREND, 0, 0, 0, 0, 0);
  ObjectSet(name, OBJPROP_RAY, true);
       
  int nr = -1, i, j, k, m, prop1_from = from, prop2_to = 0, zz_len = ArrayRange( ZIGZAG, 0 );
  int prop1_to = prop1_from - (prop1_from / 3), prop2_from = prop1_from / 3;
  bool prop1_low = false, prop2_low = false;
  double percent, res[][7], p1, p2, price, hl_offset = 20 / MarketInfo(Symbol(),MODE_TICKVALUE) * Point, zz_offset = 60 / MarketInfo(Symbol(),MODE_TICKVALUE) * Point;

  // for( i = 0; i < from; i++ ){
    // Alert(i+" "+ZIGZAG[i][0]+" "+ZIGZAG[i][1]+" "+ZIGZAG[i][2]+" "+ZIGZAG[i][3]);
  // }
    // return (0);
  for( i = prop1_from; i >= prop1_to; i-- ){
    if( prop1_low ){
      p1 = Low[i];
      prop1_low = false;
    }else{
      p1 = High[i];
      prop1_low = true;
    }
      
    for( j = prop2_from; j >= prop2_to; j-- ){
      if( prop2_low ){
        p2 = Low[j];
        prop2_low = false;
      }else{
        p2 = High[j];
        prop2_low = true;
      }
      
      nr++;
      ArrayResize( res, nr + 1 );
      res[nr][0] = Time[i];
      res[nr][1] = p1;
      res[nr][2] = Time[j];
      res[nr][3] = p2;
      res[nr][4] = 0.0;
      res[nr][5] = 0.0;
      res[nr][6] = 0.0;
      
      ObjectSet( name, OBJPROP_TIME1, Time[i] );
      ObjectSet( name, OBJPROP_PRICE1, p1 );
      ObjectSet( name, OBJPROP_TIME2, Time[j] );
      ObjectSet( name, OBJPROP_PRICE2, p2 );

      for( k = i; k >= prop2_to; k-- ){
        price = ObjectGetValueByShift( name, k );
        if( MathAbs( price - Low[k] ) < hl_offset ){
          res[nr][4] = res[nr][4] + 1;
        }
        
        if( MathAbs( price - High[k] ) < hl_offset ){
          res[nr][4] = res[nr][4] + 1;
        }
// Alert( k+" "+MathAbs( price - Low[k] )+" "+(MathAbs( price - Low[k] ) < hl_offset)+" "+ MathAbs( price - High[k] )+" "+(MathAbs( price - High[k] ) < hl_offset));
// Sleep(1000);
// continue;
        if( ZIGZAG[k][0] != 0.0 ){
        // Alert(k+" || "+ZIGZAG[k][2]);
          if( MathAbs( price - ZIGZAG[k][1] ) < zz_offset ){
            if( ZIGZAG[k][3] == 1 ){
              res[nr][5] = res[nr][5] + ZIGZAG[k][2];
            }else{
              res[nr][6] = res[nr][6] + ZIGZAG[k][2];
            }
          }
        }
      }
    }
    percent = prop1_from - i;
    percent = ( percent / (prop1_from - prop1_to) ) * 100;
    ObjectSetText( "DT_BO_trend_finder_hud", StringConcatenate( DoubleToStr( percent, 0), "%" ), 11 );
  }
	
  int len = ArrayRange( res, 0 ), hl_max_id, zz_max_id;
  double tmp, hl_max = 0, zz_max = 0;
  
	for( i = 0; i < len; i++ ){
    if( res[i][4] > hl_max ){
      hl_max = res[i][4];
      hl_max_id = i;
    }
    
    tmp = res[i][5] + res[i][6] + res[i][4];
    if( tmp > zz_max ){
      zz_max = tmp;
      zz_max_id = i;
    }
  }
  
  ObjectSet( name, OBJPROP_TIME1, res[hl_max_id][0] );
  ObjectSet( name, OBJPROP_PRICE1, res[hl_max_id][1] );
  ObjectSet( name, OBJPROP_TIME2, res[hl_max_id][2] );
  ObjectSet( name, OBJPROP_PRICE2, res[hl_max_id][3] );

  ObjectCreate(name+"_zz", OBJ_TREND, 0, res[zz_max_id][0], res[zz_max_id][1], res[zz_max_id][2], res[zz_max_id][3]);
  ObjectSet( name+"_zz", OBJPROP_TIME1, res[zz_max_id][0] );
  ObjectSet( name+"_zz", OBJPROP_PRICE1, res[zz_max_id][1] );
  ObjectSet( name+"_zz", OBJPROP_TIME2, res[zz_max_id][2] );
  ObjectSet( name+"_zz", OBJPROP_PRICE2, res[zz_max_id][3] );
  ObjectSet(name+"_zz", OBJPROP_RAY, true);
  
  Alert("HL max:"+hl_max+"/"+hl_max_id+" ZZ max:"+zz_max+"/"+zz_max_id);
  
  return (0);
}

void setZigZagArr( int tf, int from, int to, double factor ){
  int i = from, j, step;
  string sym = Symbol();
  double price;
  
  for( ;i >= to; i-- ){
    price = iCustom( sym, tf, "ZigZag", ZZ_DEPH, ZZ_DEV, ZZ_BACKSTEP, 0, i );
    if( price != 0.0 ){
      if( tf != PERIOD_M15 ){
        j = iBarShift( NULL , PERIOD_M15, iTime( NULL, tf, i ) );
        step = j - (tf / PERIOD_M15);
        for( ;j >= step; j-- ){
          if( ZIGZAG[j][1] == price ){
            ZIGZAG[j][2] = ZIGZAG[j][2] + factor;
          }
        }
      }else{
        ZIGZAG[i][0] = iTime( NULL, tf, i );
        ZIGZAG[i][1] = price;
        ZIGZAG[i][2] = factor;
        if( iHigh( NULL, PERIOD_M15, i ) == price ){
          ZIGZAG[i][3] = 1;
        }else{
          ZIGZAG[i][3] = -1;
        }
      }
    }
  }
}
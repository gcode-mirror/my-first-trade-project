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
	double from = Time[0];
	double to = Time[WindowFirstVisibleBar()];

	setZigZagArr( PERIOD_M15, from, to, M15_FACTOR );
	setZigZagArr( PERIOD_H1, from, to, H1_FACTOR );
	setZigZagArr( PERIOD_H4, from, to, H4_FACTOR );
	setZigZagArr( PERIOD_D1, from, to, D1_FACTOR );
	setZigZagArr( PERIOD_W1, from, to, W1_FACTOR );
       
  string name = "DT_GO_tf";
  ObjectCreate(name, OBJ_TREND, 0, 0, 0, 0, 0);
  ObjectSet(name, OBJPROP_RAY, true);
       
  int nr = 0, i, j, k, m, prop1_from = WindowFirstVisibleBar(), prop2_to = 0, zz_len = ArrayRange( ZIGZAG, 0 );
  int prop1_to = prop1_from - (prop1_from / 3), prop2_from = prop1_from / 3;
  bool prop1_low = false, prop2_low = false;
  double res[][7], p1, p2, price, hl_offset = 0.5 / MarketInfo(Symbol(),MODE_TICKVALUE) * Point, zz_offset = 0.5 / MarketInfo(Symbol(),MODE_TICKVALUE) * Point;
  
  for( i = prop1_from; i > prop1_to; i-- ){
    if( prop1_low ){
      p1 = Low[j];
      prop1_low = false;
    }else{
      p1 = High[j];
      prop1_low = true;
    }
      
    for( j = prop2_from; j > prop2_to; j-- ){
      if( prop2_low ){
        p2 = Low[j];
        prop2_low = false;
      }else{
        p2 = High[j];
        prop2_low = true;
      }
  
      ArrayResize( res, nr + 1 );
      res[nr][0] = Time[i];
      res[nr][1] = p1;
      res[nr][2] = Time[j];
      res[nr][3] = p2;
      res[nr][4] = 0;
      res[nr][5] = 0;
      res[nr][6] = 0;
      
      ObjectSet( name, OBJPROP_TIME1, Time[i] );
      ObjectSet( name, OBJPROP_PRICE1, p1 );
      ObjectSet( name, OBJPROP_TIME2, Time[j] );
      ObjectSet( name, OBJPROP_PRICE2, p2 );
      
      for( k = i; k > prop2_to; k-- ){
        price = ObjectGetValueByShift( name, k );
        if( MathAbs( price - Low[j] ) < hl_offset ){
          res[nr][4] = res[nr][4] + 1;
        }
        
        if( MathAbs( price - High[j] ) < hl_offset ){
          res[nr][4] = res[nr][4] + 1;
        }
        
        for( m = 0; m < zz_len; m++ ){
          if( Time[i] == ZIGZAG[m][0] ){
            if( MathAbs( price - ZIGZAG[m][1] ) < zz_offset ){
              if( ZIGZAG[m][3] == 1 ){
                res[nr][5] = res[nr][5] + ZIGZAG[m][2];
              }else{
                res[nr][6] = res[nr][6] + ZIGZAG[m][2];
              }
            }
          }
        }
      }
    }
  }
	
  int len = ArrayRange( res, 0 ), hl_max_id, zz_max_id;
  double tmp, hl_max = 0, zz_max = 0;
  
	for( i = 0; i < len; i++ ){
    if( res[nr][4] > hl_max ){
      hl_max = res[nr][4];
      hl_max_id = i;
    }
    
    tmp = res[nr][5] + res[nr][6];
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
  ObjectSet(name+"_zz", OBJPROP_RAY, true);
  
  Alert("HL max:"+hl_max+" ZZ max:"+zz_max);
  
  return (0);
}

void setZigZagArr( int tf, double from, double to, double factor ){
  int i = iBarShift( NULL, tf, MathMax(from, to) ), limit = iBarShift( NULL, tf, MathMin(from, to) ), len = ArrayRange( ZIGZAG, 0 );
	double prev, price = 0.0, tmp;
	string sym = Symbol();

	prev = getZigZag( tf, ZZ_DEPH, ZZ_DEV, ZZ_BACKSTEP, i + 1, tmp );
  while( i < limit ){
		price = iCustom( sym, tf, "ZigZag", ZZ_DEPH, ZZ_DEV, ZZ_BACKSTEP, 0, i );
		if( price != 0.0 ){
			ArrayResize( ZIGZAG, len + 1 );
			ZIGZAG[len][0] = iTime( NULL, tf, i );
			ZIGZAG[len][1] = price;
			ZIGZAG[len][2] = factor;
			if( prev < price ){
				ZIGZAG[len][3] = 1;
			}else{
				ZIGZAG[len][3] = -1;
			}
			prev = price;
			len++;
		}
		i++;
	}
}

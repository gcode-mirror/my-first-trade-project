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
                                 
	int i = 0, j, nr = 0, len = WindowFirstVisibleBar(), zz_len = ArrayRange( ZIGZAG, 0 );
	double h, l, offset = 2.5 / MarketInfo(Symbol(),MODE_TICKVALUE) * Point;

	for( ; i < len; i++ ){
		h = High[i];
		l = Low[i];
		for( j = 0; j < zz_len; j++ ){
			if( Time[i] == ZIGZAG[j][0] ){
				if( MathAbs( h - ZIGZAG[j][1] ) < offset ){
					ArrayResize( tmp_arr, nr + 1 );

				}
			}
		}
	}

	Alert(ArrayRange( ZIGZAG, 0 ));
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

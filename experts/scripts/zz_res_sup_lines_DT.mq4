//+------------------------------------------------------------------+
//|                                          zz_res_sup_lines_DT.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_icons.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
	int i, len = ObjectsTotal();
  string name;
  for ( i = 0; i < len; i++) {
    name = ObjectName(i);
    if( StringSubstr( name, 5, 4 ) == "_dz_" ){
			removeObjects( "dz", "GO" );
			return (0);
		}
  }

	setTrendLines();
	return (0);
}


void setTrendLines(){
	double time, top[100][3], down[100][3], to_time = Time[WindowBarsPerChart()];
	double possible_dist = 3000 / MarketInfo(Symbol(),MODE_TICKVALUE) * Point;
	
	int j, k, i = 4, top_nr = 0, down_nr = 0;
  double zz_price = 0.0;
  while( i < Bars ){
    zz_price = iCustom( Symbol(), Period(), "ZigZag", 12, 5, 3, 0, i );
    if( zz_price != 0.0 ){
			time = Time[i];
			if( time < to_time ){
				break;
			}

			if( High[i] == zz_price ){
				top[top_nr][0] = zz_price;
				top[top_nr][1] = time;
				top[top_nr][2] = i;
				top_nr++;
			}else{
				down[down_nr][0] = zz_price;
				down[down_nr][1] = time;
				down[down_nr][2] = i;
				// Alert(zz_price+" "+TimeToStr( time, TIME_DATE|TIME_SECONDS));
				down_nr++;
			}
    }
    i++;
  }

	string helper = "DT_BO_dz_helper";
	ObjectCreate( helper, OBJ_TREND, 0, 0, 0, 0, 0);
	ObjectSet( helper, OBJPROP_RAY, true );

	bool all_ok;
	for( i = 0; i < top_nr; i++ ){
		ObjectSet( helper, OBJPROP_PRICE2, top[i][0] );
		ObjectSet( helper, OBJPROP_TIME2, top[i][1] );
		for( j = top_nr - 1; j > i; j-- ){
			ObjectSet( helper, OBJPROP_PRICE1, top[j][0] );
			ObjectSet( helper, OBJPROP_TIME1, top[j][1] );

			if( MathAbs( ObjectGetValueByShift( helper, 0 ) - Bid ) > possible_dist ){
				continue;
			}
			all_ok = true;
			for( k = j - 1; k >= 0; k-- ){
				if( top[k][0] > ObjectGetValueByShift( helper, top[k][2] ) ){
					all_ok = false;
					break;
				}
			}
			if( all_ok ){
				createTrendLine( top[j][1], top[j][0], top[i][1], top[i][0] );
			}
		}
	}

	for( i = 0; i < down_nr; i++ ){
		ObjectSet( helper, OBJPROP_PRICE2, down[i][0] );
		ObjectSet( helper, OBJPROP_TIME2, down[i][1] );
		for( j = down_nr - 1; j > i; j-- ){
			ObjectSet( helper, OBJPROP_PRICE1, down[j][0] );
			ObjectSet( helper, OBJPROP_TIME1, down[j][1] );

			if( MathAbs( ObjectGetValueByShift( helper, 0 ) - Bid ) > possible_dist ){
				continue;
			}
			all_ok = true;
			for( k = j - 1; k >= 0; k-- ){
				if( down[k][0] < ObjectGetValueByShift( helper, down[k][2] ) ){
					all_ok = false;
					break;
				}
			}
			if( all_ok ){
				createTrendLine( down[j][1], down[j][0], down[i][1], down[i][0] );
			}
		}
	}

	ObjectDelete( helper );
	errorCheck("setTrendLines");
}

void createTrendLine( double t1, double p1, double t2, double p2 ){
	string name = StringConcatenate( "DT_GO_dz_", getPeriodSortName( Period() ), "_", DoubleToStr( t1, 0 ) );

	ObjectCreate( name, OBJ_TREND, 0, t1, p1, t2, p2 );
  ObjectSet( name, OBJPROP_COLOR, Magenta );
  ObjectSet( name, OBJPROP_RAY, true );
  ObjectSet( name, OBJPROP_BACK, true );
	ObjectSet( name, OBJPROP_WIDTH, 1 );
	ObjectSet( name, OBJPROP_STYLE, STYLE_DOT );

	errorCheck(StringConcatenate( "createTrendLine ", name ));
}

string getPeriodSortName( int peri ){
  switch( peri ){
    case 1: return ("M1");
    case 5: return ("M5");
    case 15: return ("M15");
    case 30: return ("M30");
    case 60: return ("H1");
    case 240: return ("H4");
    case 1440: return ("D1");
    case 10080: return ("W1");
    case 43200: return ("MO");
    default: return ("error");
  }
}
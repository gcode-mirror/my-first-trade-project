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

#define HI_LOW_OFFSET 20
#define ZIGZAG_OFFSET 50

#define RES_CLOSENESS 70

#define TOP_NR 10

double ZIGZAG[0][4];

int start(){
  double pod = WindowPriceOnDropped();
  if( pod == 0.0 ){
    if( IDNO == MessageBox(StringConcatenate("Do you really want to remove Trend Finder? ", Symbol()), "Warning delete confirmation!", MB_YESNO|MB_ICONQUESTION ) ){
      return(0);
    }
    removeObjects( "TF_" );
    removeObjects( "TF_", "GO" );
    addComment( "Trend finder removed..." );
    
  }else{
    int time_unit = WindowBarsPerChart() / 10;
    if( setVline( "DT_GO_TF_from", WindowFirstVisibleBar() - time_unit, Blue , 0 ) ||
			setVline( "DT_GO_TF_from_limit", WindowFirstVisibleBar() - (time_unit * 3), Blue , 1 ) ||
			setVline( "DT_GO_TF_to_limit", WindowFirstVisibleBar() - ( time_unit * 7 ), Red , 1 ) ||
			setVline( "DT_GO_TF_to", WindowFirstVisibleBar() - ( time_unit * 9 ), Red , 0 ) ){
			addComment( "Trend finder prepared..." );
			return (0);
    }
    
    if( Period() != PERIOD_M15 ){
      MessageBox( StringConcatenate("You try to run Trend Finder in the wrong period! ", Symbol()), "Warning!", MB_OK );
      return(0);
    }
    
    if( ObjectFind( "DT_GO_TF_hud" ) != -1 ){
      if( IDNO == MessageBox(StringConcatenate("Do you want to overwrite the exist list? ", Symbol()), "Warning exist list!", MB_YESNO|MB_ICONQUESTION ) ){
        return(0);
      }
    }
    
    removeObjects( "TF_cLine", "GO" );
    removeObjects( "TF_list", "GO" );
    
    if( ObjectFind( "DT_GO_TF_hud" ) == -1 ){    
      ObjectCreate( "DT_GO_TF_hud", OBJ_LABEL, 0, 0, 0 );
      ObjectSet( "DT_GO_TF_hud", OBJPROP_CORNER, 0 );
      ObjectSet( "DT_GO_TF_hud", OBJPROP_XDISTANCE, 600 );
      ObjectSet( "DT_GO_TF_hud", OBJPROP_YDISTANCE, 0 );
      ObjectSet( "DT_GO_TF_hud", OBJPROP_BACK, true);
      ObjectSetText( "DT_GO_TF_hud", "0%", 11, "Arial", Red );
    }
    
    string helper = "DT_GO_TF_helper";
    if( ObjectFind( helper ) == -1 ){
      ObjectCreate( helper, OBJ_TREND, 0, 0, 0, 0, 0);
      ObjectSet( helper, OBJPROP_COLOR, Black );
      ObjectSet( helper, OBJPROP_RAY, true );
    }
    
    int from_shift, from_limit_shift, to_limit_shift, to_shift;
    from_shift = iBarShift( NULL , PERIOD_M15, ObjectGet( "DT_GO_TF_from", OBJPROP_TIME1 ) );
    from_limit_shift = iBarShift( NULL , PERIOD_M15, ObjectGet( "DT_GO_TF_from_limit", OBJPROP_TIME1 ) );
    to_limit_shift = iBarShift( NULL , PERIOD_M15, ObjectGet( "DT_GO_TF_to_limit", OBJPROP_TIME1 ) );
    to_shift = iBarShift( NULL , PERIOD_M15, ObjectGet( "DT_GO_TF_to", OBJPROP_TIME1 ) );
		
    ArrayResize( ZIGZAG, from_shift + 1 );
    ArrayInitialize( ZIGZAG, 0.0 );
    
    setZigZagArr( PERIOD_M15, from_shift,to_shift, M15_FACTOR );
    setZigZagArr( PERIOD_H1, iBarShift( NULL , PERIOD_H1, ObjectGet( "DT_GO_TF_from", OBJPROP_TIME1 )), iBarShift( NULL , PERIOD_H1, ObjectGet( "DT_GO_TF_to", OBJPROP_TIME1 )), H1_FACTOR );
    setZigZagArr( PERIOD_H4, iBarShift( NULL , PERIOD_H4, ObjectGet( "DT_GO_TF_from", OBJPROP_TIME1 )), iBarShift( NULL , PERIOD_H4, ObjectGet( "DT_GO_TF_to", OBJPROP_TIME1 )), H4_FACTOR );
    setZigZagArr( PERIOD_D1, iBarShift( NULL , PERIOD_D1, ObjectGet( "DT_GO_TF_from", OBJPROP_TIME1 )), iBarShift( NULL , PERIOD_D1, ObjectGet( "DT_GO_TF_to", OBJPROP_TIME1 )), D1_FACTOR );
    setZigZagArr( PERIOD_W1, iBarShift( NULL , PERIOD_W1, ObjectGet( "DT_GO_TF_from", OBJPROP_TIME1 )), iBarShift( NULL , PERIOD_W1, ObjectGet( "DT_GO_TF_to", OBJPROP_TIME1 )), W1_FACTOR );
    
    int nr = 0, i, j, k, l, m, close_p1_shift = 200;
    double percent, res[][7], p1, p2, price, hl_offset = HI_LOW_OFFSET / MarketInfo(Symbol(),MODE_TICKVALUE) * Point, zz_offset = ZIGZAG_OFFSET / MarketInfo(Symbol(),MODE_TICKVALUE) * Point;
		if( from_limit_shift < 200 ){
			close_p1_shift = from_limit_shift;
		}

// int t = GetTickCount();
		ArrayResize( res, 2 * (to_limit_shift - to_shift ) * 2 * (from_shift - from_limit_shift) );
    for( i = from_shift; i > from_limit_shift; i-- ){ // FROM area helper left side
    
      for( j = 2; j > 0; j-- ){
        if( j == 2 ){
          p1 = Low[i];
        }else{
          p1 = High[i];
        }
        
        for( k = to_limit_shift; k > to_shift; k-- ){  // TO area helper right side
        
          for( l = 2; l > 0; l-- ){
            if( l == 2 ){
              p2 = Low[k];
            }else{
              p2 = High[k];
            }

						ObjectSet( helper, OBJPROP_TIME1, Time[i] );
            ObjectSet( helper, OBJPROP_PRICE1, p1 );
            ObjectSet( helper, OBJPROP_TIME2, Time[k] );
            ObjectSet( helper, OBJPROP_PRICE2, p2 );
						
            res[nr][0] = Time[i];
            res[nr][1] = p1;
            res[nr][2] = ObjectGetValueByShift( helper, close_p1_shift );
            res[nr][3] = ObjectGetValueByShift( helper, 0 );
            res[nr][4] = 0.0;
            res[nr][5] = 0.0;
            res[nr][6] = 0.0;
            
            for( m = i; m > to_shift; m-- ){
              price = ObjectGetValueByShift( helper, m );
              if( MathAbs( price - Low[m] ) < hl_offset ){
                res[nr][4] = res[nr][4] + 1;
              }
              
              if( MathAbs( price - High[m] ) < hl_offset ){
                res[nr][4] = res[nr][4] + 1;
              }
              
              if( ZIGZAG[m][0] != 0.0 ){
                if( MathAbs( price - ZIGZAG[m][0] ) < zz_offset ){
                  if( ZIGZAG[m][2] == 1 ){
                    res[nr][5] = res[nr][5] + ZIGZAG[m][1];
                  }else{
                    res[nr][6] = res[nr][6] + ZIGZAG[m][1];
                  }
                }
              }
              
            }
						nr++;
          }
        }
      }
      percent = from_shift - i;
      ObjectSetText( "DT_GO_TF_hud", StringConcatenate( DoubleToStr( ( percent / (from_shift - from_limit_shift) ) * 100, 0), "%" ), 11 );
      // WindowRedraw();
    }
    ObjectSetText( "DT_GO_TF_hud", "Ready", 11 );
    ObjectDelete( helper );
// Alert((GetTickCount() - t)+" "+nr);
    
    // ============================ TOP 10 ============================
    int len = ArrayRange( res, 0 ), top_id = 0;
		bool not_close;
    double sum, top_val = 0.0, closeness = RES_CLOSENESS / MarketInfo(Symbol(),MODE_TICKVALUE) * Point, top_arr[TOP_NR][2];
		nr = 0;
		
    for( i = 0; ( i < len && nr < TOP_NR ); i++ ){
      for( j = 0; j < len; j++ ){
        sum = res[j][4] + res[j][5] + res[j][6];
				
        if( sum < top_val ){
					continue;
				}
				
				if( sum == 0.0 ){
					continue;
				}
			
				if( nr > 0 ){
					if( sum == top_val ){
						if( res[top_id][5] + res[top_id][6] > res[j][5] + res[j][6] ){
							continue;
						}
					}
				}
				
				not_close = true;
				for( k = 0; k < nr; k++ ){
					if( MathAbs( top_arr[k][0] - res[j][2] ) < closeness && MathAbs( top_arr[k][1] - res[j][3] ) < closeness ){
						not_close = false;
						break;
					}
				}
				if( not_close ){
					top_val = sum;
					top_id = j;
				}
      }
			
			if( top_val == 0.0 ){
				break;
			}
			
			setResult( res[top_id][0], res[top_id][1], Time[0], res[top_id][3], res[top_id][4], res[top_id][5], res[top_id][6] );
      res[top_id][4] = 0.0;
      res[top_id][5] = 0.0;
      res[top_id][6] = 0.0;
      top_val = 0.0;
			
			top_arr[nr][0] = res[top_id][2];
			top_arr[nr][1] = res[top_id][3];
			nr++;
      
    }
    ObjectSetText( "DT_GO_TF_hud", "Done", 11 );
		errorCheck("TF");
  }
}

void setResult( double t1, double p1, double t2, double p2, double hl_val, double zz_up_val, double zz_down_val ){
  static int idx = 10;
  string name = "DT_GO_TF_list_" + idx, txt = StringConcatenate( (idx - 10), ". HL:", DoubleToStr( hl_val, 0 ), "  ZZ Up:", DoubleToStr( zz_up_val, 0 ), "  ZZ Down:", DoubleToStr( zz_down_val, 0 ), "  Sum:", DoubleToStr( hl_val + zz_up_val + zz_down_val, 0 ) );
  ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
  ObjectSet( name, OBJPROP_CORNER, 0 );
  ObjectSet( name, OBJPROP_XDISTANCE, 7 );
  ObjectSet( name, OBJPROP_YDISTANCE, 100 + ((idx - 10) * 18) );
  ObjectSet( name, OBJPROP_BACK, false );
  ObjectSetText( name, txt, 10, "Arial", Red );
  if( idx > 10 ){
    ObjectSet( name, OBJPROP_COLOR, RoyalBlue );
  }else{
    ObjectSet( name, OBJPROP_COLOR, OrangeRed );
  }
  
  
  name = "DT_GO_TF_cLine_" + idx;
  ObjectCreate( name, OBJ_TREND, 0, t1, p1, t2, p2);
  ObjectSet( name, OBJPROP_COLOR, Magenta );
  ObjectSet( name, OBJPROP_RAY, true );
  ObjectSetText( name, txt, 11, "Arial", Red );
  if( idx > 10 ){
    ObjectSet( name, OBJPROP_TIMEFRAMES, -1 );
  }
  idx++;
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
          if( ZIGZAG[j][0] == price ){
            ZIGZAG[j][1] = ZIGZAG[j][1] + factor;
          }
        }
      }else{
        ZIGZAG[i][0] = price;
        ZIGZAG[i][1] = factor;
        if( iHigh( NULL, PERIOD_M15, i ) == price ){
          ZIGZAG[i][2] = 1;
        }else{
          ZIGZAG[i][2] = -1;
        }
      }
    }
  }
}

bool setVline( string name, int shift, color c = Blue , int style = 1 ){
  if( ObjectFind( name ) == -1 ){
    ObjectCreate( name, OBJ_VLINE, 0, Time[shift], 0 );
    ObjectSet( name, OBJPROP_COLOR, c );
    ObjectSet( name, OBJPROP_STYLE, style );
    return (true);
  }else{
    return (false);
  }
}
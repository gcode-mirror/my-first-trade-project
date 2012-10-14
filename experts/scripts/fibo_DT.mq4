//+------------------------------------------------------------------+
//|                                                      fibo_DT.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
#include <DT_fade.mqh>
#include <WinUser32.mqh>

#define PERI_NR 5

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
	double pod = WindowPriceOnDropped();
  double tmp, time_from, zz_price = 0.0, tod = WindowTimeOnDropped();
	int i, len, shift = iBarShift( NULL, PERIOD_H4, tod ) - 2;
  bool dir;
	
  if( shift < 0 ){
    shift = 0;
  }
  
	for( i = shift; i < Bars; i++ ){
    tmp = iCustom( Symbol(), PERIOD_H4, "ZigZag", 12, 5, 3, 0, i );
    if( tmp != 0.0 ){
      zz_price = tmp;
      if( i > 1 ){
        time_from = iTime( NULL, PERIOD_H4, i - 1 );
      }else{
        time_from = iTime( NULL, PERIOD_H4, 0 );
      }
      dir = ( zz_price == iHigh( NULL, PERIOD_H4, i ) );
      break;
    }
  }
  
  if( i > iBarShift( NULL, PERIOD_H4, tod ) + 2 ){
    if( dir ){
      zz_price = iLow( NULL, PERIOD_H4, iBarShift( NULL, PERIOD_H4, tod ) );
      dir = false;
    }else{
      zz_price = iHigh( NULL, PERIOD_H4, iBarShift( NULL, PERIOD_H4, tod ) );
      dir = true;
    }
    time_from = iTime( NULL, PERIOD_H4, iBarShift( NULL, PERIOD_H4, tod ) - 1 );
  }
  
	int mb_cmd;
	string new_fibo;
	if( ObjectFind("DT_GO_fibo_1") == -1 && ObjectFind("DT_GO_fibo_2") == -1 ){
		new_fibo = "DT_GO_fibo_1";
	}else if( ObjectFind("DT_GO_fibo_1") != -1 && ObjectFind("DT_GO_fibo_2") == -1 ){
		mb_cmd = MessageBox( "New F1                      New F2                      Cancel?", "Fibo create", MB_YESNOCANCEL|MB_ICONQUESTION );
		if( mb_cmd == IDYES ){
			new_fibo = "DT_GO_fibo_1";
			ObjectDelete( "DT_GO_fibo_1" );
		}else if( mb_cmd == IDNO ){
			new_fibo = "DT_GO_fibo_2";
		}else{
			return(0);
		}
	}else if( ObjectFind("DT_GO_fibo_1") == -1 && ObjectFind("DT_GO_fibo_2") != -1 ){
		mb_cmd = MessageBox( "New F1                      New F2                      Cancel?", "Fibo create", MB_YESNOCANCEL|MB_ICONQUESTION );
		if( mb_cmd == IDYES ){
			new_fibo = "DT_GO_fibo_1";
			ObjectDelete( "DT_GO_fibo_1" );
		}else if( mb_cmd == IDNO ){
			renameFibo( "DT_GO_fibo_2", "DT_GO_fibo_1" );
			new_fibo = "DT_GO_fibo_1";
		}else{
			return(0);
		}
	}else{
		mb_cmd = MessageBox( "New F1                      New F2                      Cancel?", "Fibo create", MB_YESNOCANCEL|MB_ICONQUESTION );
		if( mb_cmd == IDYES ){
			new_fibo = "DT_GO_fibo_1";
			ObjectDelete( "DT_GO_fibo_1" );
		}else if( mb_cmd == IDNO ){
			ObjectDelete( "DT_GO_fibo_2" );
			new_fibo = "DT_GO_fibo_2";
		}else{
			return(0);
		}
	}

	int j, peris[PERI_NR] = { 1440, 240, 60, 30, 15 };
	string out = "", peris_txt[PERI_NR] = { "D1", "H4", "H1", "M30", "M15" };
	double next_ZZ[PERI_NR][2];
  ArrayInitialize( next_ZZ, 0.0 );
  double res[PERI_NR][2];
  ArrayInitialize( res, 0.0 );
	bool start_search;
	
	// for( i = 0; i < 1; i++ ){
	for( i = 0; i < PERI_NR; i++ ){
		start_search = false;
		shift = iBarShift( NULL, peris[i], time_from );
    len = iBars( NULL, peris[i] );
          // Alert(shift+" "+TimeToStr(time_from,TIME_DATE|TIME_SECONDS) +" "+len);
		for( j = shift; j < len; j++ ){
			tmp = iCustom( Symbol(),  peris[i], "ZigZag", 12, 5, 3, 0, j );
			if( start_search ){
				if( tmp != 0.0 && tmp != zz_price ){
          if( (dir && iLow( NULL, peris[i], j ) == tmp ) || (!dir && iHigh( NULL, peris[i], j ) == tmp ) ){
            next_ZZ[i][0] = tmp;
            next_ZZ[i][1] = iTime( NULL, peris[i], j );
          }
					break;
				} 
			}
			
			if( iTime( NULL, peris[i], j ) < time_from ){
				start_search = true;
			}
		}
		out = StringConcatenate( out, peris_txt[i], ": ", getFiboLevel(next_ZZ[i][0], zz_price), "   |   " );
	}
  
  out = out + "\n";
  j = 0;
  i = 0;
  if( new_fibo == "DT_GO_fibo_2" ){
    i++;
  }
  for( ; i < PERI_NR && j < 3; i++ ){
    if(j == 0 && next_ZZ[i][0] != 0.0){
      res[j][0] = next_ZZ[i][0];
      res[j][1] = next_ZZ[i][1];
      out = StringConcatenate( out, peris_txt[i], ": ", getFiboLevel(res[j][0], zz_price), "                " );
      j++;
    }else if(j > 0){
      if( res[j-1][0] != next_ZZ[i][0] && next_ZZ[i][0] != 0.0 ){
        res[j][0] = next_ZZ[i][0];
        res[j][1] = next_ZZ[i][1];
        out = StringConcatenate( out, peris_txt[i], ": ", getFiboLevel(res[j][0], zz_price), "                " );
        j++;
      }
    } 
  
  }
  
  if( res[0][0] == 0.0 ){
    addComment( "Invalid fibo values!"+zz_price, 1 );
		return (0);
  }
  
  for( ; j < 3 ; j++ ){
    out = StringConcatenate( out, "skip                " );
  }
  
	mb_cmd = MessageBox( out, "Which period do you prefer?", MB_YESNOCANCEL|MB_ICONQUESTION );
  if( mb_cmd == IDYES ){
    createFibo( dir, new_fibo, time_from, zz_price, res[0][1], res[0][0] );
  }else if( mb_cmd == IDNO ){
    if( res[1][0] == 0.0 ){
      return (0);
    }
    createFibo( dir, new_fibo, time_from, zz_price, res[1][1], res[1][0] );
  }else{
    if( res[2][0] == 0.0 ){
      return (0);
    }
    createFibo( dir, new_fibo, time_from, zz_price, res[2][1], res[2][0] );
  }
  
  return(0);
}

double getFiboLevel( double p1, double p2, double level = 0.382 ){
	return ( NormalizeDouble( MathAbs( p1 - p2 ) * level * MathPow( 10, Digits ), 0) );
}

void createFibo( double dir, string name, double t1, double p1, double t2, double p2 ){
  if( dir ){ // from bottom to top
  }else{
    // ObjectCreate( name, OBJ_FIBO, 0, t1, p1, t2, p2);
  }
    ObjectCreate( name, OBJ_FIBO, 0, t2, p2, t1, p1);
  
  string prefix;
  if( name == "DT_GO_fibo_1" ){
    prefix = "F1";
  }else{
    prefix = "F2";
  }
  
  ObjectSet( name, OBJPROP_FIBOLEVELS, 6 );
  
  ObjectSet( name, OBJPROP_FIRSTLEVEL, 1 );   
  ObjectSetFiboDescription( name, 0, prefix+" 100 | " + DoubleToStr(getFiboLevel( p1, p2, 1 ), 0) );
  
  ObjectSet( name, OBJPROP_FIRSTLEVEL + 1, 0.618 );   
  ObjectSetFiboDescription( name, 1, prefix+" 61.8 | " + DoubleToStr(getFiboLevel( p1, p2, 0.618 ), 0) );
  
  ObjectSet( name, OBJPROP_FIRSTLEVEL + 2, 0.5 );   
  ObjectSetFiboDescription( name, 2, prefix+" 50 | "+ DoubleToStr(getFiboLevel( p1, p2, 0.5 ), 0) );
  
  ObjectSet( name, OBJPROP_FIRSTLEVEL + 3, 0.382 );   
  ObjectSetFiboDescription( name, 3, prefix+" 38.2 | "+ DoubleToStr(getFiboLevel( p1, p2, 0.382 ), 0) );
  
  ObjectSetFiboDescription( name, 4, prefix+" 23.6 | "+ DoubleToStr(getFiboLevel( p1, p2, 0.236 ), 0) );
  ObjectSet( name, OBJPROP_FIRSTLEVEL + 4, 0.236 );  

  ObjectSetFiboDescription( name, 5, prefix+" 0.0" );
  
  ObjectSet( name, OBJPROP_RAY, true );
  ObjectSet( name, OBJPROP_BACK, true );
  
  
  if( ObjectFind("DT_GO_fibo_1") != -1 ){
    ObjectSet( "DT_GO_fibo_1", OBJPROP_LEVELCOLOR, Goldenrod );
  }
  if( ObjectFind("DT_GO_fibo_2") != -1 ){
    ObjectSet( "DT_GO_fibo_2", OBJPROP_LEVELCOLOR, Navy );
  }
}

void renameFibo( string old_name, string new_name ){

}
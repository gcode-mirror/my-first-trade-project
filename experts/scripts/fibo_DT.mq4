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

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
	double pod = WindowPriceOnDropped();
  double time_from, zz_price, tod = WindowTimeOnDropped();
	int i, shift = iBarShift( NULL, 0, tod );
	
	for( i = shift + 2; i > 0 || i > shift -2; i-- ){
		zz_price = iCustom( Symbol(),  Period(), "ZigZag", 12, 5, 3, 0, i );
		if( zz_price != 0.0 ){
			time_from = iTime( NULL, 0, i - 1 );
			break;
		}
	}
	
	if( zz_price == 0.0 ){
		addComment( "Cannot find the peak!", 1 );
		return (0);
	}
	
	int mb_cmd;
/*	
	string new_fibo;
	if( ObjectFind("DT_GO_fibo_1") == -1 && ObjectFind("DT_GO_fibo_2") == -1 ){
		new_fibo = "DT_GO_fibo_1";
	}else if( ObjectFind("DT_GO_fibo_1") != -1 && ObjectFind("DT_GO_fibo_2") == -1 ){
		mb_cmd = MessageBox( "New F1                      Keep F1 and new F2                      Cancel?", "Fibo create", MB_YESNOCANCEL|MB_ICONQUESTION );
		if( mb_cmd == IDYES ){
			new_fibo = "DT_GO_fibo_1";
			ObjectDelete( "DT_GO_fibo_1" );
		}else if( mb_cmd == IDNO ){
			new_fibo = "DT_GO_fibo_2";
		}else{
			return(0);
		}
	}else if( ObjectFind("DT_GO_fibo_1") == -1 && ObjectFind("DT_GO_fibo_2") != -1 ){
		mb_cmd = MessageBox( "New F1                      Keep F1 and new F2                      Cancel?", "Fibo create", MB_YESNOCANCEL|MB_ICONQUESTION );
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

*/	
	int j, peris[4] = { 240, 60, 30, 15 };
	string out = "", peris_txt[4] = { "H4", "H1", "M30", "M15" };
	double next_ZZ[4];
	bool start_search;
	
	double tmp;
	for( i = 0; i < 4; i++ ){
		start_search = false;
		shift = iBarShift( NULL, peris[i], time_from );
		for( j = shift; j < shift + 200; j++ ){
			tmp = iCustom( Symbol(),  peris[i], "ZigZag", 12, 5, 3, 0, j );
			if( start_search ){
				if( tmp != 0.0 ){
					next_ZZ[i] = tmp;
					break;
				} 
			}
			
			if( tmp == zz_price ){
				start_search = true;
			}
		}
		// out = StringConcatenate( out, peris_txt[i], ":", getFibo38(next_ZZ[i], zz_price), "   |   " );
		out = StringConcatenate( out, peris_txt[i], ":", next_ZZ[i], "   |   " );
	}
	
	out = StringConcatenate( out, "\n\n", peris_txt[0], ":", getFibo38(next_ZZ[0], zz_price), "                " );
	tmp = next_ZZ[0];
	
	for( i = 1; i < 4; i++ ){
		if( next_ZZ[i] != tmp ){
			out = StringConcatenate( out, peris_txt[i], ":", getFibo38(next_ZZ[i], zz_price), "                " );
			tmp = next_ZZ[i];
		}
	}
	// mb_cmd = MessageBox( out, "Fibo create", MB_YESNOCANCEL|MB_ICONQUESTION );
	Alert(out);
  return(0);
}

double getFibo38( double p1, double p2 ){
	return ( NormalizeDouble( MathAbs( p1 - p2 ) * 0.382 * MathPow( 10, Digits ), 0) );
}
//+------------------------------------------------------------------+
//|                                                DT_save_lines.mq4 |
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

#import "Shell32.dll"
  int ShellExecuteA(int hwnd, string lpOperation, string lpFile, string lpParameters, int lpDirectory, int nShowCmd);
#import

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+

int start(){
  double pod = WindowPriceOnDropped();
  double tod = WindowTimeOnDropped();
  string out = "", in, file_name = StringSubstr(Symbol(), 0, 6) + "_test_cLines.csv";
	int handle;

  if( pod == 0.0 ){
    FileDelete( file_name );
		GetLastError();
		addComment(file_name+" deleted!", 1);

  }else{
		int len, msg_id = -1, i = 0, j = 1, from_shift = WindowFirstVisibleBar(), to_shift = iBarShift( NULL, 0, tod );
		string sel_name, file_data[][2];
		double price, label_prices[];
		bool add_to_file = true;

		removeObjects("test_line");

		handle = FileOpen( file_name, FILE_READ, CharToStr('A') );
		if( handle < 1 ){
			msg_id = MessageBox( "Would you like select all channel line in time on dropped?", "Select all cLine?", MB_YESNOCANCEL|MB_ICONQUESTION );
			if( msg_id == IDCANCEL ){
				return(0);
			}
			GetLastError();
		}

		if( msg_id == IDYES ){
			len = ObjectsTotal();
			for( ; i < len; i++ ){
				sel_name = ObjectName(i);
				if( StringSubstr( sel_name, 5, 7 ) == "_cLine_" ){
					price = getClineValueByShift( sel_name, to_shift );
					if( price != 0.0 ){
						out = StringConcatenate( out, getCLineData( sel_name, from_shift, to_shift ) );
						ArrayResize( label_prices, j );
						label_prices[j-1] = price;
						j++;
					}else{
						GetLastError();
					}
				}
			}
			addComment( "All channel line in time on dropped saved!" );

		}else{
			i = 1;
			while( !FileIsEnding(handle) ){
				in = FileReadString(handle);
				if( in == "" ){
					break;
				}

				ArrayResize( file_data, j );
				file_data[j-1][0] = StringSubstr( in, 19, 10 );
				file_data[j-1][1] = in + "\n";
				j++;
			}

			sel_name = getSelectedLine(tod, pod);
			if( sel_name != "" ){

				for( i = 0; i < ArrayRange( file_data, 0 ); i++ ){
					if( StringSubstr( sel_name, 19, 10 ) == file_data[i][0] ){
						file_data[i][1] = getCLineData( sel_name, from_shift, to_shift );
						add_to_file = false;
						addComment( sel_name+" line modified!" );
						break;
					}
				}

				if( add_to_file ){
					out = getCLineData( sel_name, from_shift, to_shift );
					len = ArrayRange( file_data, 0 );
					ArrayResize( file_data, len +1 );
					file_data[len][1] = sel_name;
					addComment( sel_name + " line added!" );
				}else{
					for( i = 0; i < ArrayRange( file_data, 0 ); i++ ){
						out = StringConcatenate( out, file_data[i][1] );
					}
				}

				j = 1;
				for( i = 0; i < ArrayRange( file_data, 0 ); i++ ){
					price = getClineValueByShift( StringSubstr( file_data[i][1], 0, 29 ), to_shift );
					if( price != 0.0 ){
						ArrayResize( label_prices, j );
						label_prices[j-1] = price;
						j++;
					}else{
						GetLastError();
					}
				}
			}else{
				addComment( "Select test line missed!", 1 );
			}
			FileClose(handle);
		}

		if( add_to_file ){
			handle = FileOpen( file_name, FILE_BIN|FILE_READ|FILE_WRITE );
			FileSeek(handle, 0, SEEK_END);
		}else{
			handle = FileOpen( file_name, FILE_BIN|FILE_WRITE );
		}
		if( handle<1){
			Alert( "spread write error" );
			return(0);
		}
		FileWriteString(handle, out, StringLen(out));
		FileClose(handle);

		string param = StringConcatenate( "/c copy /Y ", "\"", TerminalPath(),"\\experts\\files\\", file_name, "\"", " ", "\"",TerminalPath(), "\\tester\\files", "\"" );
		ShellExecuteA(0, "open", "cmd", param, 0, 0);

		for( i = 0; i < ArraySize( label_prices ); i++ ){
			ObjectCreate( StringConcatenate( "DT_BO_test_line_", i ), OBJ_TEXT, 0, tod, label_prices[i] );
      ObjectSetText( StringConcatenate( "DT_BO_test_line_", i ), "ë", 11, "Wingdings", Blue );
		}

		WindowRedraw();
    Sleep(3300);
    removeObjects( "test_line" );
  }
}

string getCLineData( string name, int from_shift, int to_shift ){
	double t1, p1, t2, p2;
	p1 = getClineValueByShift( name, from_shift );
	t1 = Time[from_shift];
	if( p1 == 0.0 ){
		p1 =  ObjectGet( name, OBJPROP_PRICE1 );
		t1 = ObjectGet( name, OBJPROP_TIME1 );
	}

	p2 = getClineValueByShift( name, to_shift );
	t2 = Time[to_shift];
	if( p2 == 0.0 ){
		p2 =  ObjectGet( name, OBJPROP_PRICE2 );
		t2 = ObjectGet( name, OBJPROP_TIME2 );
	}

	return (StringConcatenate(name,";",DoubleToStr( t1 ,0 ),";",DoubleToStr( p1 ,Digits ),";",DoubleToStr( t2 ,0 ),";",DoubleToStr( p2 ,Digits ),";",ObjectGet( name, OBJPROP_COLOR ),";",ObjectType( name ),"\r\n"));
}
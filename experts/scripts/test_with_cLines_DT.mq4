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
  string name, out = "", in, file_name = StringSubstr(Symbol(), 0, 6) + "_test_cLines.csv";
	int handle, cmd_id, len = ObjectsTotal(), i;

  if( pod == 0.0 ){
		cmd_id = MessageBox( "Save all Trade line or delete them?", "Save all or delete?", MB_YESNOCANCEL|MB_ICONQUESTION );
		if( cmd_id == IDYES ){
			for( i = 0; i < len; i++ ){
				name = ObjectName(i);
				if( StringSubstr( name, 7, 5 ) == "Line_" ){
					out = StringConcatenate( out, name,";",DoubleToStr( ObjectGet( name, OBJPROP_TIME1 ) ,0 ),";",DoubleToStr( ObjectGet( name, OBJPROP_PRICE1 ) ,Digits ),";",DoubleToStr( ObjectGet( name, OBJPROP_TIME2 ) ,0 ),";",DoubleToStr( ObjectGet( name, OBJPROP_PRICE2 ) ,Digits ),";",ObjectGet( name, OBJPROP_COLOR ),";",ObjectType( name ),"\r\n" );
				}
			}
			
			saveToFile( out );
			addComment( "All trade line saved!", 2 );
		}else if( cmd_id == IDNO ){
			FileDelete( file_name );
			GetLastError();
			addComment(file_name+" deleted!", 1);
			
		}else if( cmd_id == IDCANCEL ){
			return (0);
		}
  }else{
		string sel_name = getSelectedLine(tod, pod);
		
		if( sel_name == "" ){
			addComment("Can not find line!",1);
			return (0);
		}
		
		if( getCLineProperty(sel_name, "state") == "sig" ){
			addComment(sel_name+" is signal line!", 1);
			return (0);
		}
	
		handle = FileOpen( file_name, FILE_READ, CharToStr('A') );
		if( handle < 1 ){
			GetLastError();
		}
		
		i = 0;
		while( !FileIsEnding(handle) ){
			in = FileReadString(handle);
			if( in == "" ){
				break;
			}
			name = StringSubstr( in, 0, 29 );
			if( getCLineProperty( sel_name, "ts") != getCLineProperty( name, "ts") ){
				ObjectCreate( StringConcatenate( "DT_BO_test_line_", i ), OBJ_TEXT, 0, tod, getClineValueByShift( name, iBarShift( NULL, 0, tod ) ) );
				ObjectSetText( StringConcatenate( "DT_BO_test_line_", i ), "ë", 11, "Wingdings", Blue );
			}else{
				addComment( sel_name+" line already in test file!", 1 );
				removeObjects( "test_line" );
				return (0);
			}
			i++;
		}
		FileClose(handle);
		
		out = StringConcatenate( sel_name,";",DoubleToStr( ObjectGet( sel_name, OBJPROP_TIME1 ) ,0 ),";",DoubleToStr( ObjectGet( sel_name, OBJPROP_PRICE1 ) ,Digits ),";",DoubleToStr( ObjectGet( sel_name, OBJPROP_TIME2 ) ,0 ),";",DoubleToStr( ObjectGet( sel_name, OBJPROP_PRICE2 ) ,Digits ),";",ObjectGet( sel_name, OBJPROP_COLOR ),";",ObjectType( sel_name ),"\r\n" );

		saveToFile( out, true );
		addComment( sel_name + " added!", 2 );
		
		WindowRedraw();
    Sleep(3300);
    removeObjects( "test_line" );
  }
}

void saveToFile( string out, bool add_to_file = false ){
	int handle;
	string file_name = StringSubstr(Symbol(), 0, 6) + "_test_cLines.csv";
	if( add_to_file ){
		handle = FileOpen( file_name, FILE_BIN|FILE_READ|FILE_WRITE );
		FileSeek(handle, 0, SEEK_END);
	}else{
		handle = FileOpen( file_name, FILE_BIN|FILE_WRITE );
	}
	if( handle < 1 ){
		Alert( "spread write error" );
		return(0);
	}
	FileWriteString( handle, out, StringLen(out) );
	FileClose( handle );

	string param = StringConcatenate( "/c copy /Y ", "\"", TerminalPath(),"\\experts\\files\\", file_name, "\"", " ", "\"",TerminalPath(), "\\tester\\files", "\"" );
	ShellExecuteA(0, "open", "cmd", param, 0, 0);
}
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

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+

int start(){
  double pod = WindowPriceOnDropped();
  double tod = WindowTimeOnDropped();
  string out, in, file_name = StringSubstr(Symbol(), 0, 6) + "_test_cLines.csv";
  int handle = FileOpen( file_name, FILE_READ, ";" );

  if( pod == 0.0 ){
    FileDelete(file_name);
		GetLastError();
		addComment(file_name+" deleted!", 1);
		
  }else{
    string sel_name = getSelectedLine(tod, pod);
    if( sel_name != "" ){
			
      int from_shift = WindowFirstVisibleBar();
      int to_shift = iBarShift( NULL, 0, tod );
      double t1, p1, t2, p2;
      
      p1 = getClineValueByShift( sel_name, from_shift );
      t1 = Time[from_shift];
      if( p1 == 0.0 ){
        p1 =  ObjectGet( sel_name, OBJPROP_PRICE1 );
        t1 = ObjectGet( sel_name, OBJPROP_TIME1 );
      }
      
      p2 = getClineValueByShift( sel_name, to_shift );
      t2 = Time[to_shift];
      if( p2 == 0.0 ){
        p2 =  ObjectGet( sel_name, OBJPROP_PRICE2 );
        t2 = ObjectGet( sel_name, OBJPROP_TIME2 );
      }
			
			handle = FileOpen( file_name, FILE_BIN|FILE_READ|FILE_WRITE );
			if( handle<1){
				Alert( "spread write error" );
				return(0);
			}
      
      out = StringConcatenate(sel_name,";",DoubleToStr( t1 ,0 ),";",DoubleToStr( p1 ,Digits ),";",DoubleToStr( t2 ,0 ),";",DoubleToStr( p2 ,Digits ),";",ObjectGet( sel_name, OBJPROP_COLOR ),";",ObjectType( sel_name ),"\r\n");
			FileSeek(handle, 0, SEEK_END);
      FileWriteString(handle, out, StringLen(out));
      FileClose(handle);
      addComment(sel_name+" line added!");
    }
  }

}
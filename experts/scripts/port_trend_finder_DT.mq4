//+------------------------------------------------------------------+
//|                                         port_trend_finder_DT.mq4 |
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
  int DDx = WindowXOnDropped();
  int DDy = WindowYOnDropped();
  string name, list_name = "", out = "", file_name = StringSubstr(Symbol(), 0, 6) + "_TF_lines.csv";
  int y, i, obj_total = ObjectsTotal(), handle;
  
  if( DDx != -1 ){
    for( i = 0; i < obj_total; i++ ) {
      name = ObjectName(i);
      if( StringSubstr( name, 5, 9 ) == "_TF_list_" ){
        y = ObjectGet( name, OBJPROP_YDISTANCE );
        if( DDx < 250 && DDy > y && DDy < y + 16 ){
          list_name = name;
          break;
        }
      }
    }
    
    if( list_name != "" && StringSubstr( name, 5, 9 ) == "_TF_list_" ){
      string list_id = StringSubstr( list_name, 14, 2 );
      double time = TimeLocal();
      
      name = "DT_GO_TF_cLine_" + list_id;
      out = StringConcatenate( "DT_GO_cLine_g1_sig_",time,";",DoubleToStr( ObjectGet( name, OBJPROP_TIME1 ) ,0 ),";",DoubleToStr( ObjectGet( name, OBJPROP_PRICE1 ) ,Digits ),";",DoubleToStr( ObjectGet( name, OBJPROP_TIME2 ) ,0 ),";",DoubleToStr( ObjectGet( name, OBJPROP_PRICE2 ) ,Digits ),"\r\n");
      time = time + 1.0;
      for( i = 0; i< obj_total; i++ ) {
        name = ObjectName(i);
        if( StringSubstr( name, 0, 21 ) == "DT_GO_TF_cLine_sub_" + list_id ){
          out = StringConcatenate( out,"DT_GO_cLine_g1_sig_",time,";",DoubleToStr( ObjectGet( name, OBJPROP_TIME1 ) ,0 ),";",DoubleToStr( ObjectGet( name, OBJPROP_PRICE1 ) ,Digits ),";",DoubleToStr( ObjectGet( name, OBJPROP_TIME2 ) ,0 ),";",DoubleToStr( ObjectGet( name, OBJPROP_PRICE2 ) ,Digits ),"\r\n");
          time = time + 1.0;
        }
      }
      
      handle = FileOpen( file_name, FILE_BIN|FILE_WRITE );
      if( handle<1){
        Alert( "write error" );
        return(0);
      }
      FileWriteString(handle, out, StringLen(out));
      FileClose(handle);
      addComment("Trend Finder line saved!",2);
      
    }else{
      addComment("Can not find line!",1);
    }
    
    
  }else{
  
    string in, arr[5];
    int j = 0;
    
    handle = FileOpen( file_name, FILE_READ, ";" );
    if( handle<1){
			Alert( "read error" );
			return(0);
		}
    while( !FileIsEnding(handle) ){
      in = FileReadString(handle);

      arr[j] = in;
      j++;

      if( j == 5 ){
        ObjectCreate( arr[0], OBJ_TREND, 0, StrToDouble(arr[1]), StrToDouble(arr[2]), StrToDouble(arr[3]), StrToDouble(arr[4]) );
        ObjectSet( arr[0], OBJPROP_RAY, true );
        ObjectSet( arr[0], OBJPROP_COLOR, CornflowerBlue );
        ObjectSetText( arr[0], StringConcatenate(TimeToStr( StrToDouble(StringSubstr( arr[0], 19, 10 )), TIME_DATE|TIME_SECONDS)," G1"), 10 );
        j = 0;
      }
    }
    FileClose(handle);
    
  }
  errorCheck("port_trend_finder_DT");
  return(0);
}
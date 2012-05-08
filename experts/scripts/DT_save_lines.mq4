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
#define NAME 0
#define T1 1
#define P1 2
#define T2 3
#define P2 4
#define STYLE 5
#define COLOR 6

string DATA[1][7];

int start(){
  double pod = WindowPriceOnDropped();
  double tod = WindowTimeOnDropped();
  string in, file_name = Symbol()+"_lines.csv";
  int handle = FileOpen( file_name, FILE_READ, ";" );


  DATA[0][0] = "";
  
  int len, i = 1, j = 0;
  if( handle > 0 ){
    while( !FileIsEnding(handle) ){
      in = FileReadString(handle);
      if( in == "" ){
        break;
      }

      if( j == 7 ){
        j = 0;
        i++;
        ArrayResize( DATA, i );
      }

      DATA[i-1][j] = in;
      j++;
    }
  }
  FileClose(handle);

  if( pod == 0.0 ){
    len = ArrayRange( DATA, 0 );
    for( i = 0; i < len; i++ ){
      if( DATA[i][NAME] == "" ){
        Alert("There is no "+Symbol()+" line.cvs");
        return (0);
      }
      
      if( ObjectFind(DATA[i][NAME]) == -1 ){
        if( StringSubstr(DATA[i][NAME],6,2) == "t_"){
          ObjectCreate( DATA[i][NAME], OBJ_TREND, 0, StrToDouble(DATA[i][T1]), StrToDouble(DATA[i][P1]), StrToDouble(DATA[i][T2]), StrToDouble(DATA[i][P2]) );
        }else{
          ObjectCreate( DATA[i][NAME], OBJ_HLINE, 0, 0, StrToDouble(DATA[i][P1]) );
        }
      }
      
      ObjectSet( DATA[i][NAME], OBJPROP_RAY, true );
      ObjectSet( DATA[i][NAME], OBJPROP_STYLE, StrToInteger(DATA[i][STYLE]) );
      ObjectSet( DATA[i][NAME], OBJPROP_COLOR, StrToInteger(DATA[i][COLOR]) );
      
      errorCheck("open lines");
      
      // Alert(DATA[i][NAME]+" "+DATA[i][T1]+" "+DATA[i][P1]+" "+DATA[i][T2]+" "+DATA[i][P2]+" "+DATA[i][STYLE]+" "+DATA[i][COLOR]);
    }
  }else{
    string out = "";

    len = ArrayRange( DATA, 0 );
    for( i = 0; i < len; i++ ){
      if( DATA[i][NAME] == "" ){
        break;
      }
      out = out + StringConcatenate(DATA[i][NAME],";",DATA[i][T1],";",DATA[i][P1],";",DATA[i][T2],";",DATA[i][P2],";",DATA[i][STYLE],";",DATA[i][COLOR],"\r\n");
    }

    handle=FileOpen(file_name, FILE_BIN|FILE_WRITE);
    if(handle<1){
     Alert("spread write error");
     return(0);
    }

    string sel_name = getSelectedLine(tod, pod);
    if( sel_name != "" ){
      out = out + StringConcatenate(sel_name,";",DoubleToStr( ObjectGet( sel_name, OBJPROP_TIME1 ) ,0 ),";",DoubleToStr( ObjectGet( sel_name, OBJPROP_PRICE1 ) ,Digits ),";",DoubleToStr( ObjectGet( sel_name, OBJPROP_TIME2 ) ,0 ),";",DoubleToStr( ObjectGet( sel_name, OBJPROP_PRICE2 ) ,Digits ),";",ObjectGet( sel_name, OBJPROP_STYLE ),";",ObjectGet( sel_name, OBJPROP_COLOR ));
      FileWriteString(handle, out, StringLen(out));
      FileClose(handle);
      addComment(sel_name+" line added!");
    }
  }

}
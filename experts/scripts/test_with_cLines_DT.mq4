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
#define TYPE 7

string DATA[1][8];

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

      if( j == 8 ){
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
    removeObjects("cLine", "GO");
    
    len = ArrayRange( DATA, 0 );
    for( i = 0; i < len; i++ ){
      if( DATA[i][NAME] == "" ){
        Alert("There is no "+Symbol()+" line.cvs");
        return (0);
      }
      
      if( ObjectFind(DATA[i][NAME]) == -1 ){
        ObjectCreate( DATA[i][NAME], StrToInteger( DATA[i][TYPE] ), 0, StrToDouble(DATA[i][T1]), StrToDouble(DATA[i][P1]), StrToDouble(DATA[i][T2]), StrToDouble(DATA[i][P2]) );
      }
      
      ObjectSet( DATA[i][NAME], OBJPROP_RAY, true );
      ObjectSet( DATA[i][NAME], OBJPROP_STYLE, StrToInteger(DATA[i][STYLE]) );
      ObjectSet( DATA[i][NAME], OBJPROP_COLOR, StrToInteger(DATA[i][COLOR]) );
      
      errorCheck("open lines");
      
       // Alert(DATA[i][NAME]+" "+DATA[i][T1]+" "+DATA[i][P1]+" "+DATA[i][T2]+" "+DATA[i][P2]+" "+DATA[i][STYLE]+" "+DATA[i][COLOR]+" "+DATA[i][TYPE]);
    }
  }else{
    string out = "";

    len = ArrayRange( DATA, 0 );
    for( i = 0; i < len; i++ ){
      if( DATA[i][NAME] == "" ){
        break;
      }
      out = out + StringConcatenate(DATA[i][NAME],";",DATA[i][T1],";",DATA[i][P1],";",DATA[i][T2],";",DATA[i][P2],";",DATA[i][STYLE],";",DATA[i][COLOR],";",DATA[i][TYPE],"\r\n");
    }

    handle=FileOpen(file_name, FILE_BIN|FILE_WRITE);
    if(handle<1){
     Alert("spread write error");
     return(0);
    }

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
      
      out = out + StringConcatenate(sel_name,";",DoubleToStr( t1 ,0 ),";",DoubleToStr( p1 ,Digits ),";",DoubleToStr( t2 ,0 ),";",DoubleToStr( p2 ,Digits ),";",ObjectGet( sel_name, OBJPROP_STYLE ),";",ObjectGet( sel_name, OBJPROP_COLOR ),";",ObjectType( sel_name ));
      FileWriteString(handle, out, StringLen(out));
      FileClose(handle);
      addComment(sel_name+" line added!");
    }
  }

}
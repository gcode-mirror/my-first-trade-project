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
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+

double ZIGZAG[][2];

int start(){
  double tod = WindowTimeOnDropped();
  int mb_id == IDCANCEL;
  
  if( ObjectFind( "DT_GO_trend_finder_limit" ) == -1 ){
    mb_id = MessageBox( "Search trend from Forward(D&D => Time[0]) or Backward(Line <= D&D)?", "Trend finder", MB_YESNOCANCEL|MB_ICONQUESTION );
    if( mb_id == IDCANCEL ){
      return (0);
    }
  }
  
  if( mb_id == IDNO ){
    ObjectCreate( "DT_GO_trend_finder_limit", OBJ_VLINE, 0, tod, 0 );
    ObjectSet( "DT_GO_trend_finder_limit", OBJPROP_COLOR, Red );
    ObjectSet( "DT_GO_trend_finder_limit", OBJPROP_BACK, true );
    ObjectSet( "DT_GO_trend_finder_limit", OBJPROP_WIDTH, 2 );
    return (0);
  }
  
  double start_time, end_time;
  if( ObjectFind( "DT_GO_trend_finder_limit" ) == -1 ){
    start_time = tod;
    end_time = Time[0];
  }else{
    double h, l;
    int idx = iBarShift( NULL , 0, tod );
    h = High[idx];
    l = Low[idx];
    
    
    
  }
  
  return (0);
}

bool getZigZag( double from, double to ){
  int i;
  fo

}
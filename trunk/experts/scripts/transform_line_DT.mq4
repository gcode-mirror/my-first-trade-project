//+------------------------------------------------------------------+
//|                                                 DT_transform.mq4 |
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
int start(){
  double tod = WindowTimeOnDropped();
  string sel_name = getSelectedLine( tod, WindowPriceOnDropped(), true );

  if( sel_name != "" ){
    string name, desc;
    color c;
    int type, time_frames, width;
    bool was_cLine = false, ray = ObjectGet(sel_name,OBJPROP_RAY);
    double time = TimeLocal();

    if( StringSubstr( sel_name, 5, 7 ) == "_cLine_" ){
      if( ObjectType( sel_name ) == OBJ_TREND ){
        name = "Trendline " + DoubleToStr( time, 0 );
        type = OBJ_TREND;
      }else{
        name = "Horizontal Line " + DoubleToStr( time, 0 );
        type = OBJ_HLINE;
      }
      c = RosyBrown;
      time_frames = 0;
      width = 1;
      desc = TimeToStr( time, TIME_DATE|TIME_SECONDS);
      was_cLine = true;
      
    }else{
      name = "DT_GO_cLine_g0_sig_" + DoubleToStr( time, 0 );
      if( ObjectType( sel_name ) == OBJ_TREND ){
        type = OBJ_TREND;
      }else{
        type = OBJ_HLINE;
      }
      
      if( Period() > PERIOD_H4 ){
        time_frames = 0;
        width = 2;
      }else{
        time_frames = OBJ_PERIOD_M1|OBJ_PERIOD_M5|OBJ_PERIOD_M15|OBJ_PERIOD_M30|OBJ_PERIOD_H1|OBJ_PERIOD_H4;
        width = 1;
      }
      
      c = CornflowerBlue;
      desc = TimeToStr( time, TIME_DATE|TIME_SECONDS)+" G0 ";
    }

    ObjectCreate( name, type, 0, ObjectGet( sel_name,OBJPROP_TIME1 ), ObjectGet( sel_name,OBJPROP_PRICE1 ), ObjectGet( sel_name,OBJPROP_TIME2 ), ObjectGet( sel_name,OBJPROP_PRICE2 ) );
    ObjectSet( name, OBJPROP_RAY, ray );
    ObjectSet( name, OBJPROP_COLOR, c );
    ObjectSet( name, OBJPROP_BACK, true );
    ObjectSet( name, OBJPROP_WIDTH, width );
    ObjectSet( name, OBJPROP_TIMEFRAMES, time_frames );
    ObjectSetText( name, desc, 8 );

    ObjectDelete( sel_name );
    
    if( was_cLine ){
      return (0);
    }
    
// ##############################  GROUPS  ##################################
    int cur_group = getCLineProperty( name, "group" );
  
    int id = MessageBox( "Current Group Id is "+cur_group+", select Group 1 or Group 2 or reset to Group 0", "Select Group", MB_YESNOCANCEL|MB_ICONQUESTION );
    
    int group = 0;
    if( id == IDYES ){
      group = 1;
    }else if( id == IDNO ){
      group = 2;
    }else if( id == IDCANCEL ){
      group = 0;
    }else{
      return (0);
    }
    
    addComment( "Rename "+getCLineProperty( name, "ts" )+" g"+cur_group+" to g"+group );
    if( cur_group == group ){
      return (0);
    }
    
    renameChannelLine( name, "", group );
// #########################################################################    
    
    showCLineGroups();
  }

  return( errorCheck("DT_transform") );
}
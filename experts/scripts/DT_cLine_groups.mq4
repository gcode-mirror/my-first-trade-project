//+------------------------------------------------------------------+
//|                                              DT_cLine_groups.mq4 |
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
  string sel_name = getSelectedLine( WindowTimeOnDropped(), WindowPriceOnDropped() );
  if( sel_name != "" ){
    int cur_group = getCLineProperty( sel_name, "group" );
  
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
    
    addComment( "Rename "+getCLineProperty( sel_name, "ts" )+" g"+cur_group+" to g"+group );
    if( cur_group == group ){
      return (0);
    }
    
    renameChannelLine( sel_name, "", group );
  }
  return( errorCheck("DT_transform") );
}
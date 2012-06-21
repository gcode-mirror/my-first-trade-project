//+------------------------------------------------------------------+
//|                                            show_cLine_groups.mq4 |
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
  if( ObjectFind( "DT_BO_group_idx_0" ) == -1 ){
    showCLineGroups( 0.0, false );
  }else{
    removeObjects("group_idx");
  }
  return(0);
}

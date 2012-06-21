//+------------------------------------------------------------------+
//|                                      all_dir_select_cLine_DT.mq4 |
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
	double tod = WindowTimeOnDropped();
  string sel_name = getSelectedLine( tod, WindowPriceOnDropped() );
  
  if( sel_name != "" ){
    string status = "";
    if( getCLineProperty(sel_name, "state") == CLINE_STATE_SIG ){
      status = "all";
    }else{
      status = "sig";
    }
    renameChannelLine( sel_name, status );
    
    showCLineGroups( tod );
  }
  
  return(0);
}
//+------------------------------------------------------------------+
//|                                  list_handle_trend_finder_DT.mq4 |
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
  string sel_name = getSelectedLine( tod, pod, true );
  if( sel_name != "" && StringSubstr( name, 5, 9 ) == "_TF_list_") ){
    int tf_id, i, obj_total = ObjectsTotal(), type = "_TF_list_" + StringSubstr( sel_name, 14, StringLen(comment) - 14 ) + "_";
    
    if( ObjectGet( sel_name, OBJPROP_COLOR ) == OrangeRed ){
      ObjectSet( sel_name, OBJPROP_COLOR, RoyalBlue );
      tf_id
    }else{
      ObjectSet( sel_name, OBJPROP_COLOR, OrangeRed );
    }
    
    ObjectSet( sel_name, OBJPROP_TIMEFRAMES, 0 );
    for( i = 0; i< obj_total; i++ ) {
        name = ObjectName(i);
        if( ObjectFind( name, type ) ){
          ObjectSet( sel_name, OBJPROP_TIMEFRAMES, 0 );
        }
      }
    
  }else{
    addComment("Can not find line!",1);
  }
  
  return(0);
}
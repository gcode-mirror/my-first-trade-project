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
  int DDx = WindowXOnDropped();
  int DDy = WindowYOnDropped();
  string name, list_name = "";
  int y, i, obj_total = ObjectsTotal();
  
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
      int tf_id;
      string list_id = StringSubstr( list_name, 14, 2 );
      if( ObjectGet( list_name, OBJPROP_COLOR ) == OrangeRed ){
        ObjectSet( list_name, OBJPROP_COLOR, RoyalBlue );
        tf_id = -1;
      }else{
        ObjectSet( list_name, OBJPROP_COLOR, OrangeRed );
        tf_id = 0;
      }
      
      ObjectSet( "DT_GO_TF_cLine_" + list_id , OBJPROP_TIMEFRAMES, tf_id );
      for( i = 0; i< obj_total; i++ ) {
        name = ObjectName(i);
        if( StringSubstr( name, 0, 21 ) == "DT_GO_TF_cLine_sub_" + list_id ){
          ObjectSet( name, OBJPROP_TIMEFRAMES, tf_id );
        }
      }
      
    }else{
      addComment("Can not find line!",1);
    }
  }else{
    for( i = 0; i < obj_total; i++ ) {
      name = ObjectName(i);
      if( StringSubstr( name, 5, 9 ) == "_TF_list_" ){
        if( ObjectGet( name, OBJPROP_TIMEFRAMES ) == 0 ){
          ObjectSet( name, OBJPROP_TIMEFRAMES, -1 );
        }else{
          ObjectSet( name, OBJPROP_TIMEFRAMES, 0 );
        }
      }
    }
  }
  errorCheck("list_handle_trend_finder_DT");
  return(0);
}


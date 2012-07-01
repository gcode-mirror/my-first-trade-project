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
      if( ObjectGet( list_name, OBJPROP_COLOR ) == OrangeRed ){
				selectItem( list_name, -1 );
      }else{
				selectItem( list_name, 0 );
      }
      
      
    }else{
      addComment("Can not find line!",1);
    }
  }else{
		int select_nr = 0, visibility = 0;
    for( i = 0; i < obj_total; i++ ) {
      name = ObjectName(i);
      if( StringSubstr( name, 5, 9 ) == "_TF_list_" ){
        if( ObjectGet( name, OBJPROP_COLOR ) == OrangeRed ){
          select_nr++;
        }
      }
    }
		
		if( select_nr > 1 ){
			visibility = -1;
		}
		
		for( i = 0; i < obj_total; i++ ) {
      name = ObjectName(i);
      if( StringSubstr( name, 5, 9 ) == "_TF_list_" ){
				selectItem( name, visibility );
      }
    }
  }
  errorCheck("list_handle_trend_finder_DT");
  return(0);
}

bool selectItem( string list_name, int visibility ){
	string name;
  int i, obj_total = ObjectsTotal();
	string list_id = StringSubstr( list_name, 14, 2 );
	
	if( visibility == -1 ){
		ObjectSet( list_name, OBJPROP_COLOR, RoyalBlue );
	}else{
		ObjectSet( list_name, OBJPROP_COLOR, OrangeRed );
	}
	
	ObjectSet( "DT_GO_TF_cLine_" + list_id , OBJPROP_TIMEFRAMES, visibility );
	for( i = 0; i < obj_total; i++ ) {
		name = ObjectName(i);
		if( StringSubstr( name, 0, 21 ) == "DT_GO_TF_cLine_sub_" + list_id ){
			ObjectSet( name, OBJPROP_TIMEFRAMES, visibility );
		}
	}

}
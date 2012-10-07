//+------------------------------------------------------------------+
//|                                                     DT_icons.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

int showIcon( int x, int y, string text, string font, string isOn, string global_ref ){
  static int icon_nr = -1;
  static int icons_range = 6;
  static int icon_size = 23;
  static int icons_x_pos = 3;
  static int icons_y_pos = 2;
  icon_nr++;
  
  int next = icons_range + icon_size;
  int x_cord = icons_x_pos + ( next * icon_nr );
  int y_cord = icons_y_pos;
  
  color lb_color;
  string name = StringConcatenate( "DT_BO_icon_" , icon_nr, "_foreground", "_", global_ref );
	ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
  ObjectSet( name, OBJPROP_CORNER, 0);
  ObjectSet( name, OBJPROP_XDISTANCE, x_cord + x );
  ObjectSet( name, OBJPROP_YDISTANCE, y_cord + y );
  ObjectSet( name, OBJPROP_BACK, false);
  if( isOn != "0" ){ lb_color = White; }else{ lb_color = DarkGray; }
  ObjectSetText(name,text,16,font,lb_color);
	
	name = StringConcatenate( "DT_BO_icon_" , icon_nr, "_background" );
  ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
  ObjectSet(name, OBJPROP_CORNER, 0);
  ObjectSet(name, OBJPROP_XDISTANCE, x_cord);
  ObjectSet(name, OBJPROP_YDISTANCE, y_cord);
  ObjectSet(name, OBJPROP_BACK, false);
  if( isOn != "0" ){ lb_color = DeepSkyBlue; }else{ lb_color = Gainsboro; }
  ObjectSetText(name,"g",18,"Webdings",lb_color);  
  
	return ( icon_nr );
}

void changeIcon( int index ){
  string name, icon_name = "";
  for ( int i = ObjectsTotal() - 1; i >= 0; i-- ){
    name = ObjectName(i);
    if( StringSubstr( name, 0, 12 ) == "DT_BO_icon_"+index ){
			icon_name = name;
      break;
    }
  }
  if( icon_name == "" ){
    Alert( "Icon idx:"+index+" not found!" );
    return;
  }
  
  string gv_name = StringSubstr( name, 24 );
  if( getGlobal( gv_name ) == "0" ){
    setGlobal( gv_name, "1" );
    ObjectSet( icon_name, OBJPROP_COLOR, White );
    ObjectSet( StringConcatenate( "DT_BO_icon_" , index, "_background" ), OBJPROP_COLOR, DeepSkyBlue );
  }else{
    setGlobal( gv_name, "0" );
    ObjectSet( icon_name, OBJPROP_COLOR, DarkGray );
    ObjectSet( StringConcatenate( "DT_BO_icon_" , index, "_background" ), OBJPROP_COLOR, Gainsboro );
  }
}

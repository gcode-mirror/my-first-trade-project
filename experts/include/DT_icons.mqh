//+------------------------------------------------------------------+
//|                                                     DT_icons.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link       ""

void showIcon( string id, int x, int y, string text, string font, double isOn ){
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
  string name = StringConcatenate( "DT_BO_icon_" , id, "_foreground" );
  if( ObjectFind( name ) == -1 ){
    ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
  }
  ObjectSet( name, OBJPROP_CORNER, 0);
  ObjectSet( name, OBJPROP_XDISTANCE, x_cord + x );
  ObjectSet( name, OBJPROP_YDISTANCE, y_cord + y );
  ObjectSet( name, OBJPROP_BACK, false);
  if( isOn == 0.0 ){ lb_color = DarkGray; }else{ lb_color = White; }
  ObjectSetText( name, text, 16, font, lb_color );
	
	name = StringConcatenate( "DT_BO_icon_" , id, "_background" );
  if( ObjectFind( name ) == -1 ){
    ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
  }
  ObjectSet(name, OBJPROP_CORNER, 0);
  ObjectSet(name, OBJPROP_XDISTANCE, x_cord);
  ObjectSet(name, OBJPROP_YDISTANCE, y_cord);
  ObjectSet(name, OBJPROP_BACK, false);
  if( isOn == 0.0 ){ lb_color = Gainsboro; }else{ lb_color = DeepSkyBlue; }
  ObjectSetText(name,"g",18,"Webdings",lb_color );  
}

void changeIcon( string id, double isOn ){
  if( isOn == 0.0 ){
    ObjectSet( StringConcatenate( "DT_BO_icon_" , id, "_foreground" ), OBJPROP_COLOR, DarkGray );
    ObjectSet( StringConcatenate( "DT_BO_icon_" , id, "_background" ), OBJPROP_COLOR, Gainsboro );
  }else{
    ObjectSet( StringConcatenate( "DT_BO_icon_" , id, "_foreground" ), OBJPROP_COLOR, White );
    ObjectSet( StringConcatenate( "DT_BO_icon_" , id, "_background" ), OBJPROP_COLOR, DeepSkyBlue );
  }
}

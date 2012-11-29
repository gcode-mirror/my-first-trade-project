//+------------------------------------------------------------------+
//|                                                   DT_objects.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

void startObjects(){
  static bool setted = false;
  if( setted ){
    return;
  }
  
  bool H4_is_on = true, D1_is_on = true, W1_is_on = true, HL_is_on = true, FI_is_on = true;
  int i, len = ObjectsTotal(), width;
  string name;
  
  for( i = 0; i < len; i++ ){
    name = ObjectName(i);
    if( ObjectGet( name, OBJPROP_TIMEFRAMES ) == -1 ){
      if( ObjectType( name ) == OBJ_TREND || ObjectType( name ) == OBJ_HLINE ){
        if( StringSubstr( name, 5, 7 ) == "_tLine_" ){
          width = ObjectGet( name, OBJPROP_WIDTH );
          if( width == 3 ){
            W1_is_on = false;
          }else if( width == 2 ){
            D1_is_on = false;
          }else{
            H4_is_on = false;
          }
        }else{
          HL_is_on = false;
        }
      }else if( ObjectType( name ) == OBJ_FIBO ){
        FI_is_on = false;
      }
    }
  }
  
  createObjectsIcon( "HL", HL_is_on );
  createObjectsIcon( "FI", FI_is_on );
  createObjectsIcon( "H4", H4_is_on );
  createObjectsIcon( "D1", D1_is_on );
  createObjectsIcon( "W1", W1_is_on );
  
  setted = true;
}

void createObjectsIcon( string text, bool is_on = true ){
  static int icon_nr = 0;
  static int xpos = 0;
  if( icon_nr == 0 ){
    xpos = 14 * nrOfIcons() + (StringLen(ObjectDescription("DT_BO_hud_info")) * 7) + 270;
  }
  int x_cord = xpos + ( icon_nr * 20 );
  
  color c;
  string name = StringConcatenate( "DT_BO_objects_" , icon_nr, "_foreground" );
	ObjectCreate( name, OBJ_LABEL, 0, 0, 0);
  ObjectSet( name, OBJPROP_CORNER, 0);
  ObjectSet( name, OBJPROP_XDISTANCE, x_cord + 2 );
  ObjectSet( name, OBJPROP_YDISTANCE, 4 );
  ObjectSet( name, OBJPROP_BACK, false);
  if( is_on ){ c = DarkGray; }else{ c = White; }
  ObjectSetText( name, text, 9, "Consolas", c );
	
	name = StringConcatenate( "DT_BO_objects_" , icon_nr, "_background" );
  ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
  ObjectSet( name, OBJPROP_CORNER, 0 );
  ObjectSet( name, OBJPROP_XDISTANCE, x_cord );
  ObjectSet( name, OBJPROP_YDISTANCE, 0 );
  ObjectSet( name, OBJPROP_BACK, false );
  if( is_on ){ c = Gainsboro; }else{ c = DeepPink; }
  ObjectSetText( name, "g", 13, "Webdings", c );  
  
  icon_nr++;
}

void changeObjectsIcon( int id, bool is_on ){
  if( is_on ){
    ObjectSet( StringConcatenate( "DT_BO_objects_" , id, "_foreground" ), OBJPROP_COLOR, White );
    ObjectSet( StringConcatenate( "DT_BO_objects_" , id, "_background" ), OBJPROP_COLOR, DeepPink );
  }else{
    ObjectSet( StringConcatenate( "DT_BO_objects_" , id, "_foreground" ), OBJPROP_COLOR, DarkGray );
    ObjectSet( StringConcatenate( "DT_BO_objects_" , id, "_background" ), OBJPROP_COLOR, Gainsboro );
  }
}

void toggleRealPriceLines( string ts, int state ){
  int i, len = ObjectsTotal(), ts_len = StringLen( ts );
  string name;
  
  for( i = 0; i < len; i++ ){
    name = ObjectName(i);
    if( StringSubstr( name, 17, ts_len ) == ts ){
      ObjectSet( name, OBJPROP_TIMEFRAMES, state );
    }
  }
}
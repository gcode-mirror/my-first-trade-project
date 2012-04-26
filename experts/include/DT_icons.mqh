//+------------------------------------------------------------------+
//|                                                     DT_icons.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#define ICONS_X_POS 3
#define ICONS_Y_POS 2
#define ICON_SIZE 23
#define ICONS_RANGE 6

int ICON_NR = 0;

bool initIcons(){
  deinitIcons();
  showIcon("DT_BO_icon_round", 3, 1, "G", "Wingdings 3", getGlobal("RULER_SWITCH"));
  showIcon("DT_BO_icon_monitor", 2, 2, "N", "Webdings", getGlobal("MONITOR_SWITCH")); 
  showIcon("DT_BO_icon_trade_lines", 1, 2, "!", "Wingdings", getGlobal("TRADE_LINES_SWITCH"));
  showIcon("DT_BO_icon_channel", 6, 1, "/", "Wingdings 3", getGlobal("CHANNEL_SWITCH")); 
  showIcon("DT_BO_icon_archive", 2, 1, "Í", "Webdings", getGlobal("ARCHIVE_SWITCH")); 
  showIcon("DT_BO_icon_news", 1, 1, "ü", "Webdings", getGlobal("NEWS_SWITCH")); 
  showIcon("DT_BO_icon_session", 3, 2, "¸", "Wingdings", getGlobal("SESSION_SWITCH")); 
  // showIcon("DT_BO_icon_fibo_lines", 7, -2, "f", "Comic Sans MS", getGlobal("FIBO_LINES_SWITCH"));
  // showIcon("DT_BO_icon_boundary", 4, 1, ".", "Wingdings 3", getGlobal("BOUNDARY_SWITCH")); 
  return (errorCheck("initIcons"));
}

bool deinitIcons(){
  removeObjects("icon");
  return (errorCheck("deinitIcons"));
}

bool showIcon(string name, int x, int y, string text, string font, string appIsOn){
  int next = ICONS_RANGE+ICON_SIZE;
  int x_cord = ICONS_X_POS+(next*ICON_NR);
  int y_cord = ICONS_Y_POS;
  color lb_color;
  string bg_name = name+"_1";
  name = name+"_2";
	ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
  ObjectSet(name, OBJPROP_CORNER, 0);
  ObjectSet(name, OBJPROP_XDISTANCE, x_cord+x);
  ObjectSet(name, OBJPROP_YDISTANCE, y_cord+y);
  ObjectSet(name, OBJPROP_BACK, false);
  if(appIsOn == "1"){ lb_color = White; }else{ lb_color = DarkGray; }
  ObjectSetText(name,text,16,font,lb_color);
	
  ObjectCreate(bg_name, OBJ_LABEL, 0, 0, 0);
  ObjectSet(bg_name, OBJPROP_CORNER, 0);
  ObjectSet(bg_name, OBJPROP_XDISTANCE, x_cord);
  ObjectSet(bg_name, OBJPROP_YDISTANCE, y_cord);
  ObjectSet(bg_name, OBJPROP_BACK, false);
  if(appIsOn == "1" ){ lb_color = DeepSkyBlue; }else{ lb_color = Gainsboro; }
  ObjectSetText(bg_name,"g",18,"Webdings",lb_color);  
  
  ICON_NR++;
  return (errorCheck("showIcon ("+name+")"));
}

bool changeIcon(string name, string appIsOn){  
  string bg_name = name+"_1";
  name = name+"_2";
  if(appIsOn == "1"){ 
    ObjectSet(name, OBJPROP_COLOR, White);
    ObjectSet(bg_name, OBJPROP_COLOR, DeepSkyBlue);
  }else{
    ObjectSet(name, OBJPROP_COLOR, DarkGray);
    ObjectSet(bg_name, OBJPROP_COLOR, Gainsboro);  
  }
  return (errorCheck("changeIcon ("+name+")"));
}


int getIconIndex(){
  int x = WindowXOnDropped();
  int y = WindowYOnDropped();
  int len = getObjectNr("icon");
  int i, j;
  
  if(y>ICONS_Y_POS && y<ICONS_Y_POS+ICON_SIZE){
    j = ICONS_X_POS;
    for (i = 0; i < len; i++){
      if(x>j && x<j+ICON_SIZE){
        return (i);
      }
      j = j+ICON_SIZE+ICONS_RANGE;
    }
  }
  return (-1);
}

int getObjectNr(string filter, string type = "BO"){
	filter = type+"_"+filter;
	string name;
	int len = StringLen(filter), nr = 0, j;
	for (j= ObjectsTotal()-1; j>=0; j--) {
    name= ObjectName(j);
		if (StringSubstr(name,3,len)==filter){
			nr++;
		}
	}
	return (nr);
}
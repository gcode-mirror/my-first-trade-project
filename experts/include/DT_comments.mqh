//+------------------------------------------------------------------+
//|                                                  DT_comments.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

void startComments(){
  static int st_timer = 0;
  
  if( GetTickCount() > st_timer ){
    st_timer = GetTickCount() + 1000;
    
    int curr_time = TimeLocal();
    int time, j, obj_total= ObjectsTotal();
    string name;
    
    for (j = obj_total-1; j >= 0; j-- ){
      name = ObjectName(j);
      if (StringSubstr(name,3,11) == "BO_comment_" ){
        time = StrToInteger( StringSubstr(name, 14, 10) );
        if(curr_time>time){
          ObjectDelete(name);
        }
      }
    }  
  }
}

void addComment( string text, int prio = 2 ){
  int j, obj_total = ObjectsTotal(), curr_y;
  color c;
  int curr_time = TimeLocal();
  string name, curr_name = StringConcatenate( "DT_BO_comment_", (curr_time+7), "_", MathRand());
  
  if(prio == 1){
    c = Red;
    PlaySound( "alert2.wav" );
  }else{
    c = Black;
  }
  
  for ( j = obj_total-1; j >= 0; j-- ) {
    name = ObjectName(j);
    if(StringSubstr(name,3,11) == "BO_comment_" ){
      ObjectSet( name, OBJPROP_YDISTANCE, (ObjectGet(name, OBJPROP_YDISTANCE)+15) );
    }
  }
  
  ObjectCreate(curr_name, OBJ_LABEL, 0, 0, 0);
  ObjectSet(curr_name, OBJPROP_CORNER, 1);
  ObjectSet(curr_name, OBJPROP_XDISTANCE, 5);
  ObjectSet(curr_name, OBJPROP_YDISTANCE, 1);
  ObjectSet(curr_name, OBJPROP_BACK, true);  
  ObjectSetText(curr_name,text,9,"Arial",c);     
  
  startComments();
}
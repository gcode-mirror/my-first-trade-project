//+------------------------------------------------------------------+
//|                                                  DT_comments.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

bool startComments(){
	if(delayTimer(APP_ID_COMMENT, 1000)){return (false);}
  
  int curr_time = TimeLocal();
  int time, j, obj_total= ObjectsTotal();
  string name;
  
  for (j= obj_total-1; j>=0; j--) {
    name= ObjectName(j);
    if (StringSubstr(name,3,11)=="BO_comment_"){
      time = StrToInteger(StringSubstr(name,14,10));
      if(curr_time>time){
        ObjectDelete(name);
        //Alert(time+" "+curr_time+"del:"+name);
      }
    }
  }  
  return (errorCheck("startComments"));
}

bool deInitComment(){
  removeObjects("comment");
  return (errorCheck("deInitSpread"));
}

bool addComment(string text, int prio = 2){
  int j, obj_total= ObjectsTotal(), curr_y;
  color c;
  int curr_time = TimeLocal();
  string name, curr_name = "DT_BO_comment_"+(curr_time+7)+"_"+MathRand();
  
  if(prio == 1){
    c = Red;
  }else{
    c = Black;
  }
  
  for (j= obj_total-1; j>=0; j--) {
    name= ObjectName(j);
    if (StringSubstr(name,3,11)=="BO_comment_"){
      ObjectSet(name, OBJPROP_YDISTANCE, (ObjectGet(name, OBJPROP_YDISTANCE)+15));
    }
  }
  
  ObjectCreate(curr_name, OBJ_LABEL, 0, 0, 0);
  ObjectSet(curr_name, OBJPROP_CORNER, 1);
  ObjectSet(curr_name, OBJPROP_XDISTANCE, 5);
  ObjectSet(curr_name, OBJPROP_YDISTANCE, 1);
  ObjectSet(curr_name, OBJPROP_BACK, true);  
  ObjectSetText(curr_name,text,9,"Arial",c);     
  
  startComments();
  return (errorCheck("addComment"));
}
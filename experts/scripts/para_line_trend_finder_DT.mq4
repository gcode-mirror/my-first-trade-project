//+------------------------------------------------------------------+
//|                                  para_line_trend_finder_DT.mq4 |
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
  string sel_name = getSelectedLine( WindowTimeOnDropped(), WindowPriceOnDropped(), true );
  color c[25] = { Khaki, LightGreen, Aquamarine, LightSkyBlue, PaleGreen, DarkSalmon, BurlyWood, HotPink, Salmon, Violet, LightCoral, SkyBlue, LightSalmon, Thistle, PowderBlue, PaleGoldenrod, PaleTurquoise, LightSteelBlue, LightBlue, LightPink, Gainsboro, PeachPuff, Pink, Bisque, LightGoldenrod };
  
  if( sel_name != "" && StringSubstr( sel_name, 5, 10 ) == "_TF_cLine_" ){
    double offset = ( WindowPriceMax(0) - WindowPriceMin(0) ) / 10;
    string name, list_id;
    if( StringSubstr( sel_name, 14, 5 ) == "_sub_" ){
      list_id = StringSubstr( sel_name, 19, 2 );
    }else{
      list_id = StringSubstr( sel_name, 15, 2 );
    }
    
    name = "DT_GO_TF_cLine_sub_" + list_id + "_" + DoubleToStr( TimeLocal(), 0 );
    ObjectCreate(name, OBJ_TREND, 0, ObjectGet(sel_name,OBJPROP_TIME1), ObjectGet(sel_name,OBJPROP_PRICE1) + offset, ObjectGet(sel_name,OBJPROP_TIME2), ObjectGet(sel_name,OBJPROP_PRICE2) + offset );
    ObjectSet(name, OBJPROP_COLOR, c[StrToInteger(list_id)]);
    ObjectSet(name, OBJPROP_RAY, true);
    ObjectSet(name, OBJPROP_BACK, true);
    
  }else{
    addComment("Can not find line!",1);
  }
  
  errorCheck("para_line_trend_finder_DT");
  return(0);
}


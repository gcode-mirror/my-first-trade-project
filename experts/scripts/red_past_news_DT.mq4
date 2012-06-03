//+------------------------------------------------------------------+
//|                                             red_past_news_DT.mq4 |
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
  if( ObjectFind("DT_BO_icon_news_3") != -1 ){
    int news_nr = StrToInteger( getGlobal("PAST_NEWS") );
    if( news_nr > 1 ){
      news_nr--;
      setGlobal( "PAST_NEWS", ""+news_nr );
      ObjectSetText( "DT_BO_icon_news_3", ""+news_nr, 8, "Arial Black", Blue );
      addComment( "Show news "+news_nr+" weeks before", 2 );
    }else{
      addComment( "Minimum new displaying is 1!", 1 );
    }
  }
  return(0);
}

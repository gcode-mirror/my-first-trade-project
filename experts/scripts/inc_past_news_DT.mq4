//+------------------------------------------------------------------+
//|                                             inc_past_news_DT.mq4 |
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
    datetime date = TimeLocal() - (TimeDayOfWeek(TimeLocal()) * 86400 ) - ( (news_nr + 1) * 604800 );
    string file_name = StringConcatenate("Calendar-", TimeYear(date), "-", PadString(DoubleToStr(TimeMonth(date),0),"0",2),"-",PadString(DoubleToStr(TimeDay(date),0),"0",2),".csv");
    
    int handle;
    handle = FileOpen( file_name, FILE_CSV|FILE_READ, ';' );
    if( handle < 1 ){
      if( GetLastError() == 4103 ){
        addComment( "Inc fail: "+file_name+" ("+( news_nr + 1 )+") doesn't exist!", 1 );
      }
    }else{
      news_nr++;
      setGlobal( "PAST_NEWS", ""+news_nr );
      ObjectSetText( "DT_BO_icon_news_3", ""+news_nr, 8, "Arial Black", Blue );
      addComment( "Show news "+news_nr+" weeks before", 2 );
    }
    FileClose(handle);
  }
  return(0);
}

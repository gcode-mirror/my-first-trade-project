//+------------------------------------------------------------------+
//|                                                   DT_utility.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#property indicator_chart_window

#import "Shell32.dll"
  int ShellExecuteA( int hwnd, string lpOperation, string lpFile, string lpParameters, int lpDirectory, int nShowCmd );
#import

#import "user32.dll"
	bool GetWindowRect(int h, int& pos[4]);
#import

extern bool EXT_BOSS = false;
extern int EXT_WEEDS_OF_NEWS = 1;

#include <DT_defaults.mqh>
#include <DT_comments.mqh>
#include <DT_functions.mqh>
#include <DT_ruler.mqh>
#include <DT_icons.mqh>
#include <DT_hud.mqh>
#include <DT_sessions.mqh>
#include <DT_archive.mqh>
#include <DT_fade.mqh>
#include <DT_history.mqh>
#include <DT_news.mqh>
#include <DT_objects.mqh>

bool CONNECTION_FAIL = true;

int init(){
  if( MarketInfo( Symbol(), MODE_TICKVALUE ) == 0.0 ){
    CONNECTION_FAIL = true;
    return (0);
  }else{
    CONNECTION_FAIL = false;
  }
  
  createGlobal( "RULER_SWITCH", "1" );
  createGlobal( "ARCHIVE_SWITCH", "0" );
  createGlobal( "NEWS_SWITCH", "1" );
  createGlobal( "SESSION_SWITCH", "1" );
  createGlobal( "MONITOR_SWITCH", "0" );
  
  initSession();
  initArchive();
  initFade();
  
  errorCheck("global init");
  return(0);
}

int deinit(){
  removeObjects();
	deleteNewsItems();
  errorCheck("global deinit");
  return(0);
}

int start(){
  if( CONNECTION_FAIL ){
    init();
    return (0);
  }
  
  startComments();
  startRuler();
  startSession();
  startArchive();
  startFade();
  startNews();
  startHistory();
  startHud();
  startObjects();
  
  errorCheck("global start");
  return(0);
}



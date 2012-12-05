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

#import "user32.dll"
	bool GetWindowRect(int h, int& pos[4]);
  void keybd_event(int bVk,int bScan,int dwFlags,int dwExtraInfo);
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
#include <DT_zoom.mqh>
#include <DT_real_price.mqh>

bool CONNECTION_FAIL = true;

int init(){
  if( MarketInfo( Symbol(), MODE_TICKVALUE ) == 0.0 ){
    CONNECTION_FAIL = true;
    return (0);
  }else{
    CONNECTION_FAIL = false;
  }
  
  createGlobal( "RULER", 1.0 );
  createGlobal( "ARCHIVE", 0.0 );
  createGlobal( "NEWS", 1.0 );
  createGlobal( "SESSION", 1.0 );
  createGlobal( "ZOOM", 0.0 );
  createGlobal( "REAL_PRICE", 0.0 );
  
  if( getSymbol() == "EURUSD" && EXT_BOSS == false ){
    addComment( "EURUSD boss state is OFF!", 1 );
    EXT_BOSS = true;
  }
  
  errorCheck("global init");
  return(0);
}

int deinit(){
  autoScroll();
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
  startRealPrice();
  startHistory();
  startHud();
  startObjects();
  startZoom();
  
  errorCheck("global start");
  return(0);
}



//+------------------------------------------------------------------+
//|                                                   Dex Trader.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#import "user32.dll"
int GetWindowDC(int dc);
int ReleaseDC(int h, int dc);
bool GetWindowRect(int h, int& pos[4]);

#property indicator_chart_window

// #property indicator_buffers 4
 
// #property indicator_color1 Black
// #property indicator_color2 Black
// #property indicator_color3 SeaGreen
// #property indicator_color4 Crimson


//========================================== Defaults ========================================
#include <DT_defaults.mqh>


//========================================== Imports =========================================
#include <DT_ruler.mqh>
#include <DT_icons.mqh>
#include <DT_hud.mqh>
#include <DT_comments.mqh>
#include <DT_monitor.mqh>
#include <DT_trade_lines.mqh>
#include <DT_archive.mqh>
#include <DT_news.mqh>
#include <DT_functions.mqh>
#include <DT_channel.mqh>
#include <DT_sessions.mqh>
//#include <DT_zoom.mqh>

bool CONNECTION_FAIL = true;

//int k;
int init(){
  if( MarketInfo(Symbol(),MODE_TICKVALUE) == 0.0 ){
    CONNECTION_FAIL = true;
    return (0);
  }else{
    CONNECTION_FAIL = false;
  }
//k = GetTickCount();
//========================================== Globals =========================================
  createGlobal("RULER_SWITCH", "1");
  // createGlobal("RULER_SWITCH", "0");
  createGlobal("MONITOR_SWITCH", "0");
  createGlobal("TRADE_LINES_SWITCH", "0");
  createGlobal("ARCHIVE_SWITCH", "0");
  createGlobal("NEWS_SWITCH", "1");
  createGlobal("CHANNEL_SWITCH", "1");
  createGlobal("SESSION_SWITCH", "0");
 // createGlobal("ZOOM_SWITCH", "0");
  
  createGlobal( "LOT", "0.1" );
  createGlobal( "PAST_NEWS", "1" );
  
//=========================================== Init ===========================================
  initIcons();
  // initHud(getGlobal("RULER_SWITCH"));
  initRuler(getGlobal("RULER_SWITCH"));
  initTradeLines(getGlobal("TRADE_LINES_SWITCH"));	
  initArchive(getGlobal("ARCHIVE_SWITCH"));	
  initNews(getGlobal("NEWS_SWITCH"));	
  initChannel(/*getGlobal("CHANNEL_SWITCH")*/);	
  initMonitor(getGlobal("MONITOR_SWITCH"));	
  initSession(getGlobal("SESSION_SWITCH"));	
  //initZoom(getGlobal("ZOOM_SWITCH"));	
  initHud();
  
  return(0);
}

//========================================== Start ===========================================
int start(){
  if( CONNECTION_FAIL ){
    init();
    return (0);
  }
	// int nr_of_try = 1;
	// while( !IsConnected() || nr_of_try < 10 ){
		// Alert( StringConcatenate( Symbol()," wait for connection try: ", nr_of_try ) );
		// nr_of_try++;
		// Sleep(2000);
	// }

  // startHud(getGlobal("RULER_SWITCH"));	
  startComments();
	startRuler(getGlobal("RULER_SWITCH"));	
	startTradeLines(getGlobal("TRADE_LINES_SWITCH"));
	startArchive(getGlobal("ARCHIVE_SWITCH"));
	startNews(getGlobal("NEWS_SWITCH"));
  startChannel(/*getGlobal("CHANNEL_SWITCH")*/);
	startMonitor(getGlobal("MONITOR_SWITCH"));
	startSession(getGlobal("SESSION_SWITCH"));
	//startZoom(getGlobal("ZOOM_SWITCH"));
  startHud();
  
  
//	Alert(k-GetTickCount());  
  return(0);
}
  
//========================================= DeInit ===========================================
int deinit(){
  removeObjects();
  if(getGlobal("TRADE_LINES_SWITCH") == "0"){
    deInitTradeLines();
  }
  return(0);
}


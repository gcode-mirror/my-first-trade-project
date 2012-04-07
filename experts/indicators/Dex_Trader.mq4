//+------------------------------------------------------------------+
//|                                                   Dex Trader.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#property indicator_chart_window


//========================================== Defaults ========================================
#include <DT_defaults.mqh>


//========================================== Imports =========================================
#include <DT_hud.mqh>
#include <DT_ruler.mqh>
#include <DT_icons.mqh>
#include <DT_comments.mqh>
#include <DT_monitor.mqh>
#include <DT_trade_lines.mqh>
#include <DT_fibo_lines.mqh>
#include <DT_archive.mqh>
#include <DT_news.mqh>
#include <DT_functions.mqh>
#include <DT_channel.mqh>
// #include <DT_boundary.mqh>

//int k;
int init(){
//k = GetTickCount();
//========================================== Globals =========================================
  createGlobal("RULER_SWITCH", "1");
  createGlobal("MONITOR_SWITCH", "0");
  createGlobal("TRADE_LINES_SWITCH", "0");
  createGlobal("ARCHIVE_SWITCH", "0");
  createGlobal("NEWS_SWITCH", "1");
  createGlobal("CHANNEL_SWITCH", "1");
  // createGlobal("FIBO_LINES_SWITCH", "0");
  // createGlobal("BOUNDARY_SWITCH", "0");
  
  createGlobal("LOT", "0.1");
  createGlobal("NEWS_UPLOAD_TIME", "0.0");
//=========================================== Init ===========================================
  initIcons();
  initHud();
  initRuler(getGlobal("RULER_SWITCH"));
  initTradeLines(getGlobal("TRADE_LINES_SWITCH"));	
  initArchive(getGlobal("ARCHIVE_SWITCH"));	
  initNews(getGlobal("NEWS_SWITCH"));	
  initChannel(getGlobal("CHANNEL_SWITCH"));	
  initMonitor(getGlobal("MONITOR_SWITCH"));	
  // initFiboLines(getGlobal("FIBO_LINES_SWITCH"));	
  // initBoundary(getGlobal("BOUNDARY_SWITCH"));	
  
  return(0);
}

//========================================== Start ===========================================
int start(){
  errorCheck("start");
  startHud();
  startComments();
	startRuler(getGlobal("RULER_SWITCH"));	
	startTradeLines(getGlobal("TRADE_LINES_SWITCH"));
	startArchive(getGlobal("ARCHIVE_SWITCH"));
	startNews(getGlobal("NEWS_SWITCH"));
  startChannel(getGlobal("CHANNEL_SWITCH"));
	startMonitor(getGlobal("MONITOR_SWITCH"));
	// startBoundary(getGlobal("BOUNDARY_SWITCH"));
	// startFiboLines(getGlobal("FIBO_LINES_SWITCH"));
	
//	Alert(k-GetTickCount());  
  return(0);
}
  
//========================================= DeInit ===========================================
int deinit(){
  removeObjects();
  if(getGlobal("TRADE_LINES_SWITCH") == "0"){
    deInitTradeLines();
  }
  // if(getGlobal("FIBO_LINES_SWITCH") == "0"){
    // deInitFiboLines();
  // }
  // if(getGlobal("BOUNDARY_SWITCH") == "0"){
    // deInitBoundary();
  // }
  return(0);
}


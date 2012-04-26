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
#include <DT_archive.mqh>
#include <DT_news.mqh>
#include <DT_functions.mqh>
#include <DT_channel.mqh>
#include <DT_sessions.mqh>

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
  createGlobal("SESSION_SWITCH", "0");
  
  createGlobal("LOT", "0.1");
//=========================================== Init ===========================================
  initIcons();
  initHud();
  initRuler(getGlobal("RULER_SWITCH"));
  initTradeLines(getGlobal("TRADE_LINES_SWITCH"));	
  initArchive(getGlobal("ARCHIVE_SWITCH"));	
  initNews(getGlobal("NEWS_SWITCH"));	
  initChannel(getGlobal("CHANNEL_SWITCH"));	
  errorCheck("mon start");
  initMonitor(getGlobal("MONITOR_SWITCH"));	
  initSession(getGlobal("SESSION_SWITCH"));	
  errorCheck("start");
  
  return(0);
}

//========================================== Start ===========================================
int start(){
  startHud();
  startComments();
	startRuler(getGlobal("RULER_SWITCH"));	
	startTradeLines(getGlobal("TRADE_LINES_SWITCH"));
	startArchive(getGlobal("ARCHIVE_SWITCH"));
	startNews(getGlobal("NEWS_SWITCH"));
  startChannel(getGlobal("CHANNEL_SWITCH"));
	startMonitor(getGlobal("MONITOR_SWITCH"));
	startSession(getGlobal("SESSION_SWITCH"));
  
  
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


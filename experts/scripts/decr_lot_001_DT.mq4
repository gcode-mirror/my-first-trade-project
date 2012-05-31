//+------------------------------------------------------------------+
//|                                              DT_decr_lot_001.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_icons.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
#include <DT_hud.mqh>
#include <DT_trade_lines.mqh>
#include <DT_fibo_lines.mqh>
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  double lot = StrToDouble(getGlobal("LOT"))-0.01;
  string str_lot = DoubleToStr(lot,2);
  if( lot < 0.1 ){
    addComment("Lot must not decrease below 0.1!",1);
    return(0);
  }
  setGlobal("LOT", str_lot);  
  addComment("Decrease lot to "+str_lot,2);
  if(getGlobal("HUD_SWITCH") == "1"){
    updateHud();
  }
  if(getGlobal("FIBO_LINES_SWITCH") == "1"){
    updateFibo();
  }
  if(getGlobal("TRADE_LINES_SWITCH") == "1"){
    updateTradeLines();
  }
  return(0);
}


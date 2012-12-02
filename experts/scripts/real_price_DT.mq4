//+------------------------------------------------------------------+
//|                                          real_price_level_DT.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+

#include <WinUser32.mqh>
#include <DT_defaults.mqh>
#include <DT_comments.mqh>
#include <DT_icons.mqh>
#include <DT_functions.mqh>
#include <DT_real_price.mqh>


//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  showRealPrices();
  return (0);
}
//+------------------------------------------------------------------+
//|                                                  DT_defaults.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#define SPREAD 1
#define MIN_PROFIT 2
#define MAX_PROFIT 3
#define STOPLOSS 4

#define USED_SYM 6

string SYMBOL_DATA[USED_SYM][5] = {
// full name  | av. spread | min profit | max profit | Stop Loss
  "EURUSD-Pro",  "0.00008",  "0.00100",   "0.00750",   "0.00080",
  "USDJPY-Pro",    "0.009",  "0.00008",   "0.00008",   "0.00080",
  "EURJPY-Pro",    "0.014",  "0.00008",   "0.00008",   "0.00080",
  "GBPUSD-Pro",  "0.00014",  "0.00100",   "0.00750",   "0.00080",
  "AUDUSD-Pro",  "0.00015",  "0.00100",   "0.00750",   "0.00080",
  "EURUSD",       "0.0001",   "0.0018",    "0.0075",    "0.0008",
};                                             


//+------------------------------------------------------------------+
//|                                                  DT_defaults.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#define USED_SYM 8

// string SYMBOLS_STR[USED_SYM] = {"EURUSD-Pro","USDJPY-Pro","USDCHF-Pro","EURJPY-Pro","GBPUSD-Pro","AUDUSD-Pro","USDCAD-Pro","EURAUD-Pro","CADJPY-Pro","CHFJPY-Pro","AUDCHF-Pro","NZDUSD-Pro","NZDJPY-Pro","EURGBP-Pro","GBPJPY-Pro","XAGUSD-Pro","XAUUSD-Pro"};
// string SYMBOLS[USED_SYM] = {"EURUSD","USDJPY","USDCHF","EURJPY","GBPUSD","AUDUSD","USDCAD","EURAUD","CADJPY","CHFJPY","AUDCHF","NZDUSD","NZDJPY","EURGBP","GBPJPY","XAGUSD","XAUUSD"};
// double SPREAD[USED_SYM] =  { 0.00008, 0.009  , 0.00013, 0.014  , 0.00014, 0.00015, 0.00015, 0.00019, 0.019  , 0.019  , 0.00020, 0.00020, 0.021  , 0.00022, 0.023  , 0.038  , 0.680   };

string ALL_SYMBOLS_STR[27] = {"EURAUD-Pro","EURCAD-Pro","EURCHF-Pro","EURGBP-Pro","EURJPY-Pro","EURNZD-Pro","EURPLN-Pro","EURUSD-Pro","GBPAUD-Pro","GBPCAD-Pro","GBPCHF-Pro","GBPJPY-Pro","GBPNZD-Pro","GBPUSD-Pro","USDCAD-Pro","USDCHF-Pro","USDJPY-Pro","USDPLN-Pro","AUDCAD-Pro","AUDCHF-Pro","AUDJPY-Pro","AUDNZD-Pro","AUDUSD-Pro","CADJPY-Pro","CHFJPY-Pro","NZDJPY-Pro","NZDUSD-Pro","XAGUSD-Pro","XAUUSD-Pro"};
string ALL_SYMBOLS[27] = {"EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD","EURPLN","EURUSD","GBPAUD","GBPCAD","GBPCHF","GBPJPY","GBPNZD","GBPUSD","USDCAD","USDCHF","USDJPY","USDPLN","AUDCAD","AUDCHF","AUDJPY","AUDNZD","AUDUSD","CADJPY","CHFJPY","NZDJPY","NZDUSD","XAGUSD","XAUUSD"};

string SYMBOLS_STR[USED_SYM] = {"EURUSD-Pro","USDJPY-Pro","USDCHF-Pro","EURJPY-Pro","GBPUSD-Pro","AUDUSD-Pro","XAUUSD-Pro"};
string SYMBOLS[USED_SYM] = {"EURUSD","USDJPY","USDCHF","EURJPY","GBPUSD","AUDUSD","XAUUSD"};
double SPREAD[USED_SYM] =  { 0.00008, 0.009  , 0.00013, 0.014  , 0.00014, 0.00015, 0.00015, 0.680  };

#define APP_ID_HUD 0
#define APP_ID_RULER 1
#define APP_ID_COMMENT 2
#define APP_ID_MONITOR 3
#define APP_ID_TRADE_LINES 4
#define APP_ID_FIBO_LINES 5
#define APP_ID_ARCHIVE 6
#define APP_ID_NEWS 7
#define APP_ID_VOICE 8
#define APP_ID_CHANNEL 9
#define APP_ID_SESSION 10

#define FIBO_LV_NR 7

#define NEWS_TIME 0
#define NEWS_CURRENCY 1
#define NEWS_DESC 2
#define NEWS_PRIO  3
#define NEWS_ACT 4
#define NEWS_FORC 5
#define NEWS_PREV 6
#define NEWS_UNIT 7
#define NEWS_REL 8
string NEWS_DATA[1][9];


//string SYMBOLS[1] = {"USDJPY"};


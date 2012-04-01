//+------------------------------------------------------------------+
//|                                                   DT_monitor.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#define RSI 0
#define STATUS 1
#define DIRECTION 2
#define HI_LOW 3
#define HAS_REL_NEWS 4

#define HIGH_POINT 75
#define LOW_POINT 25
#define WARN_HIGH_POINT 68
#define WARN_LOW_POINT 32
#define TRADE_HIGH_POINT 55
#define TRADE_LOW_POINT 45

#define POS 0
#define BOUNDARY 1

int MON_INT_DATA[USED_SYM][5];
string MON_STR_DATA[USED_SYM][2];
int TIME_FRAME = PERIOD_H1;
double exp;

bool startMonitor(string isOn){
  if(isOn == "0"){return (false);}
	if(delayTimer(APP_ID_MONITOR, 5000)){return (false);}
  
  int RSI_curr, RSI_prev, j, i, hi_low, news_len, k;
  bool need_write = false;
  string out = "", symbol, news_switch = getGlobal("NEWS_SWITCH"), bound_name;
  double time, bound_top, bound_bottom, act_bid;

  for(i=0; i<USED_SYM; i++){
    symbol = SYMBOLS_STR[i];
    RSI_curr = MathRound(iRSI(symbol,TIME_FRAME, 10, 0, 0));
    RSI_prev = MathRound(iRSI(symbol,TIME_FRAME, 10, 0, 1));
		
    if(MON_INT_DATA[i][RSI] != RSI_curr){
      need_write = true;
			
			MON_STR_DATA[i][POS] = "-";
			MON_INT_DATA[i][HI_LOW] = 0;
			for (j = 0; j < OrdersTotal(); j++) {
        if (OrderSelect(j, SELECT_BY_POS)) {
          if (OrderSymbol() == symbol) {
            if(OrderType()<2){
              MON_STR_DATA[i][POS] = DoubleToStr(OrderProfit(),0);
            }else{
              exp = OrderExpiration()-TimeCurrent();
              MON_STR_DATA[i][POS] = TimeHour(exp)+":"+TimeMinute(exp);
            }
            break;
          }
        }
      }
			
			if(RSI_curr==RSI_prev){
				MON_INT_DATA[i][DIRECTION] = 0;
			}else{
				if(RSI_curr-RSI_prev>0){
					 MON_INT_DATA[i][DIRECTION] = 1;
				}else{
					 MON_INT_DATA[i][DIRECTION] = -1;
				}
			}
      
      hi_low = getHiLowVal(symbol, RSI_curr, RSI_prev, MON_INT_DATA[i][DIRECTION]);
      MON_INT_DATA[i][HI_LOW] = hi_low;
      
      if(hi_low != 0){
        MON_INT_DATA[i][STATUS] = 3;
      }else if(RSI_curr >= HIGH_POINT || RSI_curr <= LOW_POINT){
        MON_INT_DATA[i][STATUS] = 2;
      }else if(RSI_curr >= WARN_HIGH_POINT || RSI_curr <= WARN_LOW_POINT){
        MON_INT_DATA[i][STATUS] = 1;
      }else{
        MON_INT_DATA[i][STATUS] = 0;
      }
			MON_INT_DATA[i][RSI] = RSI_curr;
      
      
			MON_INT_DATA[i][HAS_REL_NEWS] = 0;
      if(news_switch == "1"){
        news_len = ArrayRange(NEWS_DATA,0);
        for(k=0;k<news_len;k++){
          if(StringFind( symbol, NEWS_DATA[k][NEWS_CURRENCY]) != -1){
            time = StrToDouble(NEWS_DATA[k][NEWS_TIME]);
            if(time > TimeCurrent() && time < TimeCurrent()+3600){
              if(NEWS_DATA[k][NEWS_TIME] == "HIGH" || NEWS_DATA[k][NEWS_TIME] == "MEDIUM"){ 
                if(NEWS_DATA[k][NEWS_REL] == "2" || NEWS_DATA[k][NEWS_REL] == "3"){
                  MON_INT_DATA[i][HAS_REL_NEWS] = MON_INT_DATA[i][HAS_REL_NEWS] + 1;
                }
              }
            }
          }
        }
      }
      
      MON_STR_DATA[i][BOUNDARY] = "-";
      bound_name = StringConcatenate(SYMBOLS[i],"_Boundary_Top");
      if(GlobalVariableCheck(bound_name)){
        bound_top = GlobalVariableGet(bound_name);
        bound_bottom = GlobalVariableGet(StringConcatenate(SYMBOLS[i],"_Boundary_Bottom"));
        act_bid = MarketInfo(symbol,MODE_BID);
        if(act_bid > bound_top){
          MON_STR_DATA[i][BOUNDARY] = DoubleToStr((act_bid-bound_top)*MathPow(10,MarketInfo(symbol,MODE_DIGITS)),0);
        }else if(act_bid < bound_bottom){
          MON_STR_DATA[i][BOUNDARY] = DoubleToStr((bound_bottom-act_bid)*MathPow(10,MarketInfo(symbol,MODE_DIGITS)),0);
        }else{
          MON_STR_DATA[i][BOUNDARY] = "-"+DoubleToStr(MathMin((MathAbs(bound_top-act_bid)),(MathAbs(bound_bottom-MarketInfo(symbol,MODE_BID))))*MathPow(10,MarketInfo(symbol,MODE_DIGITS)),0);
        }
      }
      
			out = StringConcatenate(out,SYMBOLS[i],";",MON_INT_DATA[i][HI_LOW],";",RSI_curr,";",MON_INT_DATA[i][DIRECTION],";",MON_INT_DATA[i][STATUS],";",MON_STR_DATA[i][POS],";",MON_INT_DATA[i][HAS_REL_NEWS],";",MON_STR_DATA[i][BOUNDARY],";","\r\n"); 
		}else{
			out = StringConcatenate(out,SYMBOLS[i],";",MON_INT_DATA[i][HI_LOW],";",MON_INT_DATA[i][RSI],";",MON_INT_DATA[i][DIRECTION],";",MON_INT_DATA[i][STATUS],";",MON_STR_DATA[i][POS],";",MON_INT_DATA[i][HAS_REL_NEWS],";",MON_STR_DATA[i][BOUNDARY],";","\r\n"); 
		}
	}
	
  if(need_write){
    int handle;   
    handle=FileOpen("result.bin", FILE_BIN|FILE_WRITE);
      if(handle<1){
       errorCheck("startMonitor (open file)");
       return(0);
      }
    FileWriteString(handle, out, StringLen(out));
    FileClose(handle); 
    
  }
 
//Alert(k-GetTickCount());
  return (errorCheck("startMonitor"));
}
int getHiLowVal(string sym, int p1, int p2, int dir){
  int i = 1;
  if(p1 > TRADE_HIGH_POINT && dir == -1){
    while(p2 >= p1 && i<15){		
      i++;
      p1 = p2;
      p2 = MathRound(iRSI(sym,TIME_FRAME, 10, 0, i));
    }
    if(p1 >= HIGH_POINT){
      return (p1);
    }
    
  }else if(p1 < TRADE_LOW_POINT && dir == 1){
    while(p2 <= p1 && i<15){
      i++;
      p1 = p2;
      p2 = MathRound(iRSI(sym,TIME_FRAME, 10, 0, i));
    }
    if(p1 <= LOW_POINT){
      return (p1);
    }
  }
  return (0);
}

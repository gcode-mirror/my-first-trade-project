//+------------------------------------------------------------------+
//|                                               DT_trade_lines.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

double TRADE_LINES_OP = 0;
double TRADE_LINES_TP = 0;
double TRADE_LINES_SL = 0;
int TRADE_LINE_VISIBLE_BAR = 0;

bool initTradeLines(string isOn){
  setAppStatus(APP_ID_TRADE_LINES, isOn);
  
  if(isOn == "0"){    
    return (false);
  }
  
  double tp_price, sl_price, open_price;
  if( selectFirstOpenPosition(Symbol())){
    //if( OrderMagicNumber() == 555 ){
      tp_price = OrderTakeProfit();
      sl_price = OrderStopLoss();
      open_price = OrderOpenPrice();
    //}  
  }else{
    string near_line_name = getSelectedLine( Time[0], Bid, true );
    
    if( near_line_name != "" ){
      open_price = NormalizeDouble( getClineValueByShift( near_line_name, 0 ), Digits );
      double fibo_23_dif, fibo_100_time, fibo_100, spread;
      getFibo100( open_price ,fibo_100, fibo_100_time );
      spread = getMySpread();
      fibo_23_dif = MathAbs( fibo_100 - open_price ) * 0.23; // 0.236
      
      if( fibo_100 > open_price ){
        open_price = open_price + spread;
        sl_price = open_price - fibo_23_dif;
        tp_price = open_price + fibo_23_dif;
      }else{
        sl_price = open_price + fibo_23_dif + spread;
        tp_price = open_price - fibo_23_dif + spread;
      }
      
    }else{
      double time1, time2;
      tp_price = getZigZag(0, 10, 5, 3, 1, time1);
      sl_price = getZigZag(0, 10, 5, 3, 0, time2);  
      open_price = tp_price+(sl_price-tp_price)/2;
    }
  }
  createLines("DT_GO_TradeLines_OP", open_price, Blue); 
  createLines("DT_GO_TradeLines_TP", tp_price, Green);
  createLines("DT_GO_TradeLines_SL", sl_price, Red);
  
  TRADE_LINE_VISIBLE_BAR = 0;
  
  return (errorCheck("initTradeLines"));
}

bool startTradeLines(string isOn){
  if(isAppStatusChanged(APP_ID_TRADE_LINES, isOn)){
    if(isOn == "1"){
      initTradeLines("1");
    }else{
      deInitTradeLines();
      return (false);
    }    
  }

	if(isOn == "0"){return (false);}
	
	if(delayTimer(APP_ID_TRADE_LINES, 700)){return (false);}
	
  updateTradeLines();

	int visible_bar = WindowFirstVisibleBar();
	if(visible_bar != TRADE_LINE_VISIBLE_BAR){  
		TRADE_LINE_VISIBLE_BAR = visible_bar;
		double x = Time[WindowBarsPerChart()/2];
		ObjectSet("DT_GO_TradeLines_TP_label", OBJPROP_TIME1, x);
		ObjectSet("DT_GO_TradeLines_SL_label", OBJPROP_TIME1, x);
		ObjectSet("DT_GO_TradeLines_OP_label", OBJPROP_TIME1, x);
	}
	
  return (errorCheck("startTradeLines"));    
}

bool deInitTradeLines(){
  removeObjects("TradeLines", "GO");
  return (errorCheck("deInitTradeLines"));
}

bool updateTradeLines(){
  if(ObjectFind("DT_GO_TradeLines_OP") == -1 || ObjectFind("DT_GO_TradeLines_TP") == -1 || ObjectFind("DT_GO_TradeLines_SL") == -1){
		return (false);
	}
	
	double op = ObjectGet("DT_GO_TradeLines_OP",OBJPROP_PRICE1);
	double tp = ObjectGet("DT_GO_TradeLines_TP",OBJPROP_PRICE1);
	double sl = ObjectGet("DT_GO_TradeLines_SL",OBJPROP_PRICE1);
	
	if(op == TRADE_LINES_OP && tp == TRADE_LINES_TP && sl == TRADE_LINES_SL){
		return (false);
	}
	
	string lot_str = getGlobal("LOT");
	double lot = StrToDouble(lot);
	string tmp;
	
	if(op != TRADE_LINES_OP){
		TRADE_LINES_OP = op;
		TRADE_LINES_TP = 0.1;
		TRADE_LINES_SL = 0.1;
		tmp = StringConcatenate(lot_str," lot");
		ObjectSetText("DT_GO_TradeLines_OP_label", tmp, 7);
		ObjectSetText("DT_GO_TradeLines_OP", tmp, 7);
		ObjectSet("DT_GO_TradeLines_OP_label", OBJPROP_PRICE1, op);
	}
	
	if(tp != TRADE_LINES_TP){
		TRADE_LINES_TP = tp;
		tmp = getLineText(op,tp);
    ObjectSetText("DT_GO_TradeLines_TP_label", tmp, 7);
		ObjectSetText("DT_GO_TradeLines_TP", tmp, 7);
		ObjectSet("DT_GO_TradeLines_TP_label", OBJPROP_PRICE1, tp);		 
	}
	
	if(sl != TRADE_LINES_SL){
		TRADE_LINES_SL = sl;
		tmp = getLineText(op,sl);
    ObjectSetText("DT_GO_TradeLines_SL_label", tmp, 7);
		ObjectSetText("DT_GO_TradeLines_SL", tmp, 7);
		ObjectSet("DT_GO_TradeLines_SL_label", OBJPROP_PRICE1, sl);
	}
	GetLastError();
	return (errorCheck("updateTradeLines"));
}

string getLineText(double price1, double price2){
  double diff = MathMax(price1,price2)-MathMin(price1,price2);
  double unit = (diff/Point)*MarketInfo(Symbol(),MODE_TICKVALUE);
  double usd = unit * StrToDouble(getGlobal("LOT"));
  double huf = MarketInfo("USDHUF-Pro", MODE_BID) * usd;
  return ( StringConcatenate( DoubleToStr(diff*MathPow(10,Digits),0), " pip  ", DoubleToStr(usd,1), " USD  ", DoubleToStr(huf,0), " HUF", "  ", DoubleToStr( unit * 0.1, 1), " unit"));
}

bool createLines(string name, double price, color c){
  string label = name+"_label";
  if(ObjectFind(name) == -1){
    ObjectCreate(name, OBJ_HLINE, 0, 0, price);
    ObjectSet(name, OBJPROP_COLOR, c);
    ObjectSet(name, OBJPROP_STYLE, STYLE_DASH);
    ObjectCreate(label, OBJ_TEXT, 0, 1, 0.1);
    ObjectSet(label, OBJPROP_COLOR, c);
	}
  return (errorCheck("createLines ("+name+", "+DoubleToStr(price,Digits)+")"));
}



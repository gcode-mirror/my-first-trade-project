//+------------------------------------------------------------------+
//|                                                DT_line_trade.mq4 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_icons.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
#include <WinUser32.mqh>

int start(){
  if(ObjectFind("DT_GO_TradeLines_OP") != -1 && ObjectFind("DT_GO_TradeLines_SL") != -1 && ObjectFind("DT_GO_TradeLines_TP") != -1){
    double op = NormalizeDouble(ObjectGet("DT_GO_TradeLines_OP", OBJPROP_PRICE1), Digits);
    double tp = NormalizeDouble(ObjectGet("DT_GO_TradeLines_TP", OBJPROP_PRICE1), Digits);
    double sl = NormalizeDouble(ObjectGet("DT_GO_TradeLines_SL", OBJPROP_PRICE1), Digits);
    bool has_pos = selectFirstOpenPosition(Symbol());
    
    if(has_pos && OrderMagicNumber() == 555){
      if(IDYES == MessageBox(StringConcatenate("Do you want modify an open position (",OrderTicket(),")?"), "Line trading", MB_YESNO|MB_ICONQUESTION )){
        if(OrderType() > OP_SELL){
          OrderModify(OrderTicket(), op, sl, tp, 0); 
        }else{
          OrderModify(OrderTicket(), OrderOpenPrice(), sl, tp, 0); 
        }        
        errorCheck("Line Trade (modify order)");
        return(0);
      }
    }
    
      double lots = StrToDouble(getGlobal("LOT"));
      int o_type;
      string o_text;
    
      RefreshRates();
      if(tp > op && op > sl){
        if(op > Bid){
          o_type = OP_BUYSTOP;
          o_text = "Buy Stop";
        }else{
          o_type = OP_BUYLIMIT;
          o_text = "Buy Limit";
        }      
      }else if(tp < op && op < sl){
        if(op > Bid){
          o_type = OP_SELLLIMIT;
          o_text = "Sell Limit";
        }else{
          o_type = OP_SELLSTOP;
          o_text = "Sell Stop";
        }
      }else{
        addComment("Invalid order request!",1);
        return(0);
      }
      
      int res = MessageBox(StringConcatenate("Are you should want instant order or  < ",o_text," >  trade with  < ",DoubleToStr(lots,2)," >  lots?"), "Line trading", MB_YESNOCANCEL|MB_ICONQUESTION );    
      if( res == IDYES ){
        int ticket;
        RefreshRates();
        
        if(tp > op){          
          ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, 3, 0, 0, ""+TimeCurrent(), 555);
          OrderSelect(ticket, SELECT_BY_TICKET);
          OrderModify(OrderTicket(), OrderOpenPrice(), sl, tp, 0);         
        }else{         
          ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, 3, 0, 0, ""+TimeCurrent(), 555);
          OrderSelect(ticket, SELECT_BY_TICKET);
          OrderModify(OrderTicket(), OrderOpenPrice(), sl, tp, 0);          
        }        
        errorCheck("Line Trade (new ins order) sl:"+sl+" tp:"+tp);
      }else if( res == IDNO ){
        OrderSend(Symbol(),o_type,lots,op,2,sl,tp, ""+TimeCurrent(),555,0);
        errorCheck("Line Trade (new order)");
      }
      
  }else{
    addComment("Trade lines missing!",1);
  }
  return(0);
}


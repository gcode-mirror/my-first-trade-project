//+------------------------------------------------------------------+
//|                                             DT_exit_position.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
#include <WinUser32.mqh>
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  int ticket = getPositionByDaD(WindowPriceOnDropped());
  
  if( ticket != 0 ){
    if(IDNO == MessageBox(StringConcatenate("Are you sure you want EXIT from position ID: (",ticket,") in ", Symbol()), "EXIT Positon!", MB_YESNO|MB_ICONQUESTION )){
      return(0);
    }
    
    double tp, spread;
    int o_type;
    OrderSelect( ticket, SELECT_BY_TICKET );
    o_type = OrderType();
    spread = getSymbolData( SPREAD );
    
    if( o_type == OP_BUY || o_type == OP_BUYLIMIT || o_type == OP_BUYSTOP ){
      tp = OrderOpenPrice() + spread;
    }else if( o_type == OP_SELL || o_type == OP_SELLLIMIT || o_type == OP_SELLSTOP ){
      tp = OrderOpenPrice() - ( spread * 2 );
    }
    
    OrderModify( ticket, OrderOpenPrice(), OrderStopLoss(), tp, 0 );
    
    if( errorCheck( "Exit Position, ticket:"+ticket+" Take Profit:"+tp ) ){
      addComment( "Position "+ticket+" will be exit at "+tp+"!", 2 ); 
    }
    
  }else{
    addComment( "Doesn't find open position!", 1 );
  }
  errorCheck( "Exit Position" );
  return(0);
}
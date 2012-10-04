//+------------------------------------------------------------------+
//|                                            DT_close_position.mq4 |
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
  int ticket = getPositionByDaD( WindowPriceOnDropped() );
  
  if( ticket != 0 ){
    if(IDNO == MessageBox(StringConcatenate("Are you sure you want CLOSE position ID:(",ticket,") in ", Symbol()), "CLOSE Positon!", MB_YESNO|MB_ICONQUESTION )){
      return(0);
    }
    double price, lots;
    int o_type;
    OrderSelect( ticket, SELECT_BY_TICKET );
    o_type = OrderType();
    RefreshRates();
    if( o_type < 2 ){
      if( o_type == OP_BUY ){
        price = Bid;
      }else if( o_type == OP_SELL ){
        price = Ask;
      }
      lots = OrderLots();
      
      OrderClose( ticket, lots, NormalizeDouble( price, Digits ), 2 );
      if( errorCheck( "Close Position, ticket:"+ticket+" Price:"+price+" Lot:"+lots ) ){
        addComment( "Position "+ticket+" closed!", 2 );
      }
      
    }else{
      OrderDelete( ticket );
      if( errorCheck( "Close Position, ticket:"+ticket ) ){
        addComment( "Position "+ticket+" closed!", 2 );
      }
    }
  }else{
    addComment( "Doesn't find open position!", 1 );
  }
  errorCheck( "Close Position" );
  return(0);
}
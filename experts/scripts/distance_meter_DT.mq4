//+------------------------------------------------------------------+
//|                                            DT_distance_meter.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_icons.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>

#include <WinUser32.mqh>
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  double tod = WindowTimeOnDropped();
  int shift = iBarShift( NULL , 0, tod );
  
  int mb_id = MessageBox( "Do you want to show distance for all line?", "Distance meter", MB_YESNOCANCEL|MB_ICONQUESTION );
  
  if( tod == 0.0 || mb_id == IDCANCEL ){
    removeObjects("distance_meter");
    return( errorCheck("distance_meter") );
  }
  
  if( ObjectFind("DT_BO_distance_meter_line") != -1 ){
    removeObjects("distance_meter");
  }
  
  int i, len = ObjectsTotal(), j = 1;
  double trade_line_price, line_price_arr[], middle_price, max = WindowPriceMax(0), min = WindowPriceMin(0);
  string name, scale_num;
  
  for( i = 0; i < len; i++ ){
    name = ObjectName(i);
    if( ( mb_id == IDYES && (StringSubstr( name, 0, 5 ) == "Trend" || StringSubstr( name, 0, 5 ) == "Horiz" || StringSubstr( name, 5, 7 ) == "_cLine_") ) || ( mb_id == IDNO && StringSubstr( name, 5, 7 ) == "_cLine_" ) ){
    
      trade_line_price = getClineValueByShift( name, shift );
      
      if( trade_line_price != 0.0 && trade_line_price > min && trade_line_price < max ){
        ArrayResize( line_price_arr, j );
        line_price_arr[j-1] = trade_line_price;
        j++;
      }else{
        GetLastError();
      }
    }
  }
  
  len = ArraySize(line_price_arr);
  if( len > 1 ){
    ArraySort( line_price_arr, WHOLE_ARRAY, 0, MODE_DESCEND );
    
    ObjectCreate( "DT_BO_distance_meter_line", OBJ_TREND, 0, tod, line_price_arr[0], tod, line_price_arr[len-1]);
    ObjectSet( "DT_BO_distance_meter_line", OBJPROP_STYLE, STYLE_DOT );
    ObjectSet( "DT_BO_distance_meter_line", OBJPROP_BACK, false);
    ObjectSet( "DT_BO_distance_meter_line", OBJPROP_COLOR, Indigo);
    ObjectSet( "DT_BO_distance_meter_line", OBJPROP_RAY, false);
  
    for( i = 0; i < len - 1; i++ ){
      scale_num = DoubleToStr( getScaleNumber( line_price_arr[i], line_price_arr[i+1], Symbol() ), 1 );
      middle_price = line_price_arr[i] - ((line_price_arr[i] - line_price_arr[i+1]) / 2);
      
      name = "DT_BO_distance_meter "+ scale_num;
      ObjectCreate( name, OBJ_TEXT, 0, tod, middle_price );
      ObjectSet( name, OBJPROP_BACK, false );
      ObjectSet( name, OBJPROP_COLOR, Indigo );
      ObjectSet( name, OBJPROP_ANGLE, 90 );
      ObjectSetText( name, scale_num, 8, "Arial", Black );
    }
  }else{
    addComment("Can not find cLines!",1);
  }
  
  return( errorCheck("distance_meter"+len) );
}
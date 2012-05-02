//+------------------------------------------------------------------+
//|                                                      DT_zoom.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""



double Buf_0[];     
double Buf_1[]; 
double Buf_2[];
double Buf_3[];

int Z_PERI;
string Z_NAME;

double I_T1 = 0.0, I_T2 = 0.0, I_P1 = 0.0, I_P2 = 0.0;
double Z_T1 = 0.0, Z_T2 = 0.0, Z_P1 = 0.0, Z_P2 = 0.0;

bool initZoom( string isOn ){
  setAppStatus( APP_ID_ZOOM, isOn );
  if( isOn == "0" ){        
    return (false);    
  }
  deinitZoom();
  
  Z_PERI = getPeriodSibling( StrToInteger( isOn ), "prev" );
  Z_NAME = getPeriodName( Z_PERI );
  
  SetIndexBuffer(0,Buf_0);         
  SetIndexStyle (0,DRAW_HISTOGRAM,0,1);

  SetIndexBuffer(1,Buf_1);         
  SetIndexStyle (1,DRAW_HISTOGRAM,0,1);

  SetIndexBuffer(2,Buf_2);         
  SetIndexStyle (2,DRAW_HISTOGRAM,0,2);

  SetIndexBuffer(3,Buf_3);         
  SetIndexStyle (3,DRAW_HISTOGRAM,0,2);
  
  SetIndexEmptyValue(0, 0.0);
  SetIndexEmptyValue(1, 0.0);
  SetIndexEmptyValue(2, 0.0);
  SetIndexEmptyValue(3, 0.0);
  
  double t1, t2, p1, p2;
  
  p1 = High[iHighest(NULL, 0, MODE_HIGH, 5, 0)];
  p2 = Low[iLowest(NULL, 0, MODE_LOW, 5, 0)];
  
  if( ObjectFind("DT_GO_zoom_Z_index") == -1 ){
    t1 = Time[5];
    t2 = Time[0] + (2 * Period() * 60);
  
    ObjectCreate("DT_GO_zoom_Z_index", OBJ_RECTANGLE, 0, t1, p1, t2, p2);
    ObjectSet("DT_GO_zoom_Z_index", OBJPROP_BACK, false);
    ObjectSet("DT_GO_zoom_Z_index", OBJPROP_COLOR,Black);
 }
  
  int dif = Period() / Z_PERI;
  int offset = WindowFirstVisibleBar() - (WindowBarsPerChart()/10);
  
  t1 = Time[offset];
  t2 = Time[offset-( 8 * dif)];
  
  ObjectCreate("DT_BO_zoom_Z_chart", OBJ_RECTANGLE, 0, t1, p1, t2, p2);
  ObjectSet("DT_BO_zoom_Z_chart", OBJPROP_BACK, false);
  ObjectSet("DT_BO_zoom_Z_chart", OBJPROP_COLOR,Black);
  ObjectSet("DT_BO_zoom_Z_chart", OBJPROP_WIDTH,2);
  
  ObjectCreate( "DT_BO_zoom_label", OBJ_TEXT, 0, t2, p2 );
  ObjectSetText( "DT_BO_zoom_label", Z_NAME, 7, "Arial", Black );
  
  return (errorCheck("initZoom"));
}

bool startZoom( string isOn ){
  if(isAppStatusChanged( APP_ID_ZOOM, isOn )){
    if(isOn != "0"){
      initZoom(isOn);
    }else{
      deinitZoom();
      ObjectDelete( "DT_GO_zoom_Z_index" );
      return (false);
    }    
  }
	if( isOn == "0" ){return (false);}
	if( delayTimer(APP_ID_ZOOM, 2800)) {return (false);}
  
  double cur_i_t1 = ObjectGet("DT_GO_zoom_Z_index",OBJPROP_TIME1);
  double cur_i_p1 = ObjectGet("DT_GO_zoom_Z_index",OBJPROP_PRICE1);
  double cur_i_t2 = ObjectGet("DT_GO_zoom_Z_index",OBJPROP_TIME2);
  double cur_i_p2 = ObjectGet("DT_GO_zoom_Z_index",OBJPROP_PRICE2);
  
  double cur_z_t1 = ObjectGet("DT_BO_zoom_Z_chart",OBJPROP_TIME1);
  double cur_z_p1 = ObjectGet("DT_BO_zoom_Z_chart",OBJPROP_PRICE1);
  double cur_z_t2 = ObjectGet("DT_BO_zoom_Z_chart",OBJPROP_TIME2);
  double cur_z_p2 = ObjectGet("DT_BO_zoom_Z_chart",OBJPROP_PRICE2);
  
  // if(cur_z_t1 != Z_T1 || cur_z_p1 != Z_P1 || cur_z_t2 != Z_T2 || cur_z_p2 != Z_P2 || cur_i_t1 != I_T1 || cur_i_p1 != I_P1 || cur_i_t2 != I_T2 || cur_i_p2 != I_P2){
  if(true){
    int i, idx, len, time_shift ,future_shift, dif = Period() / Z_PERI;
    double h, l, c, o, offset, middle;
    
    for( i = 0; i < WindowFirstVisibleBar(); i++ ){
      Buf_0[i] = EMPTY_VALUE;
      Buf_1[i] = EMPTY_VALUE;
      Buf_2[i] = EMPTY_VALUE;
      Buf_3[i] = EMPTY_VALUE;
    }
    
    removeObjects("zoom_obj");
    
    I_T1 = cur_i_t1;
    I_P1 = cur_i_p1;
    I_T2 = cur_i_t2;
    I_P2 = cur_i_p2;
    
    Z_T1 = cur_z_t1;
    if( cur_i_t2 > Time[0] ){
      future_shift = (cur_i_t2 - Time[0]) / (Period() * 60);
      time_shift = ( iBarShift( NULL, 0, I_T1 ) - iBarShift( NULL, 0, I_T2 ) + future_shift ) * dif;
    }else{
      time_shift = ( iBarShift( NULL, 0, I_T1 ) - iBarShift( NULL, 0, I_T2 ) ) * dif;
    }
    
    idx = iBarShift( NULL, 0, cur_z_t1 );
    Z_T2 = Time[ idx - time_shift ];
    
    Z_P1 = cur_z_p1;
    
    offset = cur_i_p1-cur_z_p1;
    Z_P2 = cur_i_p2 - ( offset );
    
    middle = Z_P1 + (( Z_P1 - Z_P2 ) / 2);
    Z_P1 = middle + ( (Z_P1 - middle) * 1.2 );
    Z_P2 = middle + ( (Z_P2 - middle) * 1.2 );
    
    ObjectSet( "DT_BO_zoom_Z_chart", OBJPROP_TIME1, Z_T1 );
    ObjectSet( "DT_BO_zoom_Z_chart", OBJPROP_PRICE1, Z_P1 );
    ObjectSet( "DT_BO_zoom_Z_chart", OBJPROP_TIME2, Z_T2 );
    ObjectSet( "DT_BO_zoom_Z_chart", OBJPROP_PRICE2, Z_P2 );
    
    ObjectSet( "DT_BO_zoom_label", OBJPROP_TIME1, Z_T2 );
    ObjectSet( "DT_BO_zoom_label", OBJPROP_PRICE1, Z_P2 );
    
    
    i = iBarShift( NULL, Z_PERI, cur_i_t1 );
    len = i - time_shift;
    for(; i > len; i--){
      h = iHigh(NULL, Z_PERI, i) - offset;
      l = iLow(NULL, Z_PERI, i) - offset;
      c = iClose(NULL, Z_PERI, i) - offset;
      o = iOpen(NULL, Z_PERI, i) - offset;
    
      h = middle + ( (h - middle) * 1.2 );
      l = middle + ( (l - middle) * 1.2 );
      c = middle + ( (c - middle) * 1.2 );
      o = middle + ( (o - middle) * 1.2 );
    
      if( l > Z_P1 ){
        idx++;
        continue;
      }else if( l < Z_P2 ){
        l = Z_P2;
      }
      
      if( h < Z_P2 ){
        idx++;
        continue;
      }else if( h > Z_P1 ){
        h = Z_P1;
      }
      
      if( o > Z_P1 ){
        o = Z_P1;
      }else if( o < Z_P2 ){
        o = Z_P2;
      }
      
      if( c > Z_P1 ){
        c = Z_P1;
      }else if( c < Z_P2 ){
        c = Z_P2;
      }
        
      Buf_0[idx] = h;
      Buf_1[idx] = l;
      
      Buf_2[idx] = c;
      Buf_3[idx] = o;
      idx--;
    }
    showOpenPositions(Z_T1, Z_T2, offset);
  }
  return (errorCheck("startZoom"));
}

bool deinitZoom(){
  removeObjects("zoom");
  
  int i;
  for( i = 0; i < ArraySize(Buf_0); i++ ){
    Buf_0[i] = EMPTY_VALUE;
    Buf_1[i] = EMPTY_VALUE;
    Buf_2[i] = EMPTY_VALUE;
    Buf_3[i] = EMPTY_VALUE;
  }
  
  return (errorCheck("deinitZoom"));
}

bool showOpenPositions(double t1, double t2, double offset){
  int i = 0, len = OrdersTotal();
  string name;
  double p;
  for ( ; i < len; i++ ) {      
    if ( OrderSelect(i, SELECT_BY_POS) ) {        
      if ( OrderSymbol() == Symbol() ) {
        name = "DT_BO_zoom_obj_tp_"+OrderTicket();
        p = OrderTakeProfit() - offset;
        ObjectCreate( name, OBJ_TREND, 0, t1, p, t2, p);
        ObjectSet( name, OBJPROP_COLOR, Red);
        ObjectSet( name, OBJPROP_STYLE, STYLE_DASHDOT);
        ObjectSet(name, OBJPROP_RAY, false);
        
        name = "DT_BO_zoom_obj_op_"+OrderTicket();
        p = OrderOpenPrice() - offset;
        ObjectCreate( name, OBJ_TREND, 0, t1, p, t2, p);
        ObjectSet( name, OBJPROP_COLOR, Green);
        ObjectSet( name, OBJPROP_STYLE, STYLE_DASHDOT);
        ObjectSet(name, OBJPROP_RAY, false);
        
        name = "DT_BO_zoom_obj_sl_"+OrderTicket();
        p = OrderStopLoss() - offset;
        ObjectCreate( name, OBJ_TREND, 0, t1, p, t2, p);
        ObjectSet( name, OBJPROP_COLOR, Red);
        ObjectSet( name, OBJPROP_STYLE, STYLE_DASHDOT);
        ObjectSet(name, OBJPROP_RAY, false);
      }
    }
  }
  return (0);
}

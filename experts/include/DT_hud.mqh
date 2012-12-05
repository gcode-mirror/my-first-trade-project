//+------------------------------------------------------------------+
//|                                                       DT_hud.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+


void initHud(){
  deinitHud();
  
  string name = "DT_BO_hud_info", txt;
  int xpos = 14 * nrOfIcons();
  
  ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
  ObjectSet( name, OBJPROP_CORNER, 0 );
  ObjectSet( name, OBJPROP_XDISTANCE, xpos );
  ObjectSet( name, OBJPROP_YDISTANCE, 1 );
  txt = StringConcatenate( Symbol() ," |Swap (Lg:"+DoubleToStr((MarketInfo(Symbol(),MODE_SWAPLONG)),2)," / Sh:",DoubleToStr((MarketInfo(Symbol(),MODE_SWAPSHORT)),2),") *lot |");
  ObjectSetText( name, txt, 9, "Consolas", Blue );

  name = "DT_BO_hud_spread";
	ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
  ObjectSet( name, OBJPROP_CORNER, 0 );
  ObjectSet( name, OBJPROP_XDISTANCE,  xpos + (StringLen(txt) * 7) );
  ObjectSet( name, OBJPROP_YDISTANCE, 1 );
  ObjectSetText( name, "Spread:0/0", 9, "Consolas", Blue );
  
  xpos = xpos + (StringLen(txt) * 7) + 120;
  
  name = "DT_BO_hud_expert_info";
  ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
  ObjectSet( name, OBJPROP_CORNER, 0 );
  ObjectSet( name, OBJPROP_XDISTANCE, xpos );
  ObjectSet( name, OBJPROP_YDISTANCE, 1 );
  ObjectSet( name, OBJPROP_BACK, true);
  
  name = "DT_BO_hud_expert_bg";
  ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
  ObjectSet( name, OBJPROP_CORNER, 0 );
  ObjectSet( name, OBJPROP_XDISTANCE, xpos - 14 );
  ObjectSet( name, OBJPROP_YDISTANCE, 0 );
  ObjectSet( name, OBJPROP_BACK, true);
  
  xpos = xpos + 127;
  
  name = "DT_BO_hud_used_tline_txt";
  ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
  ObjectSet( name, OBJPROP_CORNER, 0 );
  ObjectSet( name, OBJPROP_XDISTANCE, xpos );
  ObjectSet( name, OBJPROP_YDISTANCE, 2 );
  ObjectSet( name, OBJPROP_BACK, true);
  ObjectSetText( name, "0", 10, "Consolas", DarkGray );
  
  
  name = "DT_BO_hud_used_tline_bg";
  ObjectCreate( name, OBJ_LABEL, 0, 0, 0 );
  ObjectSet( name, OBJPROP_CORNER, 0 );
  ObjectSet( name, OBJPROP_XDISTANCE, xpos - 5 );
  ObjectSet( name, OBJPROP_YDISTANCE, 0 );
  ObjectSet( name, OBJPROP_BACK, true);
  ObjectSetText( name, "g", 13, "Webdings", Gainsboro );
}


void startHud(){
  static int st_timer = 0;
  if( GetTickCount() > st_timer ){
    st_timer = GetTickCount() + 2000;
    
    static double my_spread = -1.0;
    static string symb = "";
    
    if( my_spread == -1.0 ){
      my_spread = getSymbolData( SPREAD ) * MathPow( 10, Digits );
      symb = Symbol();
      initHud();
    }
    
    double spread = MarketInfo( Symbol(), MODE_SPREAD );
    color c;
    if( spread > my_spread ){
      c = Red;
    }else{
      c = Blue;
    }
    ObjectSetText( "DT_BO_hud_spread", StringConcatenate( "Spread: ",DoubleToStr( my_spread, 0 ), "/", DoubleToStr( spread, 0 ) ), 9, "Consolas", c );
    
    if( IsExpertEnabled() ){
      if( ObjectFind("DT_GO_trade_timing") != -1 ){
        if( ObjectGet( "DT_GO_trade_timing", OBJPROP_TIME1 ) < iTime( NULL, PERIOD_M1, 0) ){
          ObjectSetText( "DT_BO_hud_expert_info", "Trading Stopped!", 10, "Consolas", Maroon );
          ObjectSetText( "DT_BO_hud_expert_bg", "ggggggggg", 12, "Webdings", LightPink );
        }else{
          ObjectSetText( "DT_BO_hud_expert_info", "Trading is ON", 10, "Consolas", DarkSlateGray );
          ObjectSetText( "DT_BO_hud_expert_bg", "gggggggg", 12, "Webdings", PaleGreen );
        }
      }else{
        ObjectSetText( "DT_BO_hud_expert_info", "Trading is ON", 10, "Consolas", DarkSlateGray );
        ObjectSetText( "DT_BO_hud_expert_bg", "gggggggg", 12, "Webdings", PaleGreen );
      }
    }else{
      ObjectSetText( "DT_BO_hud_expert_info", "Trading is OFF", 10, "Consolas", DimGray );
      ObjectSetText( "DT_BO_hud_expert_bg", "gggggggg", 12, "Webdings", Gainsboro );
    }
  
    int i = 0, len = OrdersHistoryTotal(), j, len2 = ObjectsTotal(), magic, prev_magic = 0, nr = 0;
    string name, tmp;
    for( ; i < len; i++ ) {
      if( OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) {
        if( OrderSymbol() == symb ) {
          magic = OrderMagicNumber();
          if( magic > 1000 ){
            tmp = ""+magic;
            for( j = 0; j < len2; j++ ){
              name = ObjectName(j);
              if( StringSubstr( name, 16, 10 ) == tmp ){
                if( ObjectGet( name, OBJPROP_COLOR ) != Black && ObjectGet( name, OBJPROP_COLOR ) != DarkOrange ){
                  ObjectSet( name, OBJPROP_COLOR, Black );
                }
                if( magic != prev_magic ){
                  nr++;
                  prev_magic = magic;
                }
              }
            }
          }
        }
      }
    }
    
    if( nr > 0 ){
      ObjectSetText( "DT_BO_hud_used_tline_txt", ""+nr, 10, "Consolas", White );
      ObjectSetText( "DT_BO_hud_used_tline_bg", "g", 13, "Webdings", Red );
    }else{
      ObjectSetText( "DT_BO_hud_used_tline_txt", "0", 10, "Consolas", DarkGray );
      ObjectSetText( "DT_BO_hud_used_tline_bg", "g", 13, "Webdings", Gainsboro );
    }
  }
}

void deinitHud(){
  removeObjects("hud");
}

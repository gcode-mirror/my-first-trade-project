//+------------------------------------------------------------------+
//|                                          real_price_level_DT.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+

#include <DT_defaults.mqh>
#include <DT_icons.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
	double tod = WindowTimeOnDropped();
	removeObjects("real_price", "GO");
	if( tod == 0.0 ){
		addComment("Real price level helpers removed.",2);
		return(0);
	}
	
  string sel_name = getSelectedLine( tod, WindowPriceOnDropped(), true );

  if( sel_name != "" && ObjectType( sel_name ) == OBJ_TREND ){
		string name, vline = "AA_GO_real_price_level_vline";
		int nr = 20;
		int shift = iBarShift( NULL, 0, tod ) + ( nr / 2 );
		double t1, t2, line_price;
		
		ObjectCreate( vline, OBJ_VLINE, 0, tod, 0);
		ObjectSet( vline, OBJPROP_COLOR, Orange);
		ObjectSet(vline, OBJPROP_BACK, true);
		
		while( nr > 0 && shift >= 0 ){
			name = "DT_GO_real_price_level_hline_" + nr;
			line_price = ObjectGetValueByShift( sel_name, shift );
			t1 = Time[shift];
      if( shift == 0 ){
        t2 = t1 + (Period() * 60);
      }else{
        t2 = Time[shift - 1];
      }
			ObjectCreate( name, OBJ_TREND, 0, t1, line_price, t2, line_price );
			ObjectSet( name, OBJPROP_COLOR, Orange );
			ObjectSet( name, OBJPROP_BACK, true );
			ObjectSet( name, OBJPROP_RAY, false);
			shift--;
			nr--;
		}
    
    if( ObjectGet( sel_name, OBJPROP_TIME1) < Time[Bars - 1] ){
      Alert( "Line run out from chart!" );
      return (0);
    }
    
    shift = iBarShift( NULL, 0, tod );
    double next_zz, prev_zz = prevZigZag( shift );
    double op = ObjectGetValueByShift( sel_name, shift ), h, l;
    double tp = SYMBOLS_TP[getSymbolID()];
    double sl = SYMBOLS_SL[getSymbolID()];
    // double sl = 0.00110;
    double threshold = getMySpread() * 0.5;
    int to, i = iBarShift( NULL, PERIOD_M1, tod ), last_high = -1;
    double max_tp = 0.0, closest = 9999999999.0, loss = 0.0, max_loss = 0.0;
    bool pos_opened = false, win = false, fail = false;
    string type;
    
    if( i + 1 == iBars(NULL, PERIOD_M1) ){
      Alert("M1 bar info missing");
      return (0);
    }
    if( i - 240 > 0 ){
      to = i - 240;
    }else{
      to = 0;
    }
    
    if( Open[shift + 1] > op ){ // buy
      next_zz = nextZigZag( shift, 1 );
      type = "buy";
      while( ( !pos_opened && i > to ) || ( pos_opened && i >= 0 ) ){
        l = iLow( NULL, PERIOD_M1, i );
        h = iHigh( NULL, PERIOD_M1, i );
        
        if( pos_opened ){
          if( h > ( op + tp ) ){
            if( !fail ){
              win = true;
            }
          }
          
          if( ( h - op ) > max_tp ){
            max_tp = ( h - op );
            last_high = i;
          }
        }
        
        if( !pos_opened ){
          if( h >= op && l <= op ){
            pos_opened = true;
          }else if( ( l - op ) < closest ){
            closest = l - op;
          }
        }
        
        if( pos_opened ){
          if( l < (op - sl) ){
            if( !win ){
              fail = true;
            }
            loss = sl;
            break;
          }
          
          if( ( op - l ) > loss ){
            if( ( op - l ) > (MarketInfo(Symbol(),MODE_TICKSIZE) * 300) ){
              break;
            }
            if( !win ){
              loss = ( op - l );
            }
          }
          
          if( h == next_zz || l == next_zz){
            break;
          }
        }
        i--;
      }
    }else{ // sell
      type = "sell";
      next_zz = nextZigZag( shift, -1 );
      while( ( !pos_opened && i > to ) || ( pos_opened && i >= 0 ) ){
        l = iLow( NULL, PERIOD_M1, i );
        h = iHigh( NULL, PERIOD_M1, i );
        
        if( pos_opened ){
          if( l < ( op - tp ) ){
            if( !fail ){
              win = true;
            }
          }
          
          if( ( op - l ) > max_tp ){
            max_tp = ( op - l );
            last_high = i;
          }
        }
        
        if( !pos_opened ){
          if( h >= op && l <= op ){
            pos_opened = true;
          }else if( ( op - h ) < closest ){
            closest = op - h;
          }
        }
        
        if( pos_opened ){
          if( h > (op + sl) ){
            if( !win ){
              fail = true;
            }
            
            loss = sl;
            break;
          }
          
          if( ( h - op ) > loss ){
            if( ( h - op ) > (MarketInfo(Symbol(),MODE_TICKSIZE) * 300) ){
              break;
            }
            if( !win ){
              loss  = ( h - op );
            }
          }
          
          if( h == next_zz || l == next_zz){
            break;
          }
        }
        i--;
      }
    }
    
    if( win ){
      if( last_high >= 0 ){
        for( i = iBarShift( NULL, PERIOD_M1, tod ); i > last_high; i-- ){
          if( Open[shift + 1] > op ){ //buy
            l = iLow( NULL, PERIOD_M1, i );
            if( ( op - l ) > max_loss ){
              max_loss = ( op - l );
            }
          }else{ //sell
            h = iHigh( NULL, PERIOD_M1, i );
            if( ( h - op ) > max_loss ){
              max_loss = ( h - op );
            }
          }
        
        }
      }
    }else{
      max_loss = loss;
    }
    
    string out = "";
    max_tp = max_tp * MathPow( 10, Digits );
    loss = loss * MathPow( 10, Digits );
    max_loss = max_loss * MathPow( 10, Digits );
    closest = closest * MathPow( 10, Digits );
    
    if( fail ){
      // out = out + "fail  "+type+"  SL: "+DoubleToStr( loss, 0 )+"  max_TP: "+DoubleToStr( max_tp, 0 )+"  max_loss: "+DoubleToStr( max_loss, 0 );
      out = StringSubstr(Symbol(), 0, 6)+"\t"+type+"\t"+DoubleToStr( max_loss, 0 )+"\t"+DoubleToStr( max_tp, 0 )+"\t-\tlost";
    }else{
      if( win ){
        out = StringSubstr(Symbol(), 0, 6)+"\t"+type+"\t"+DoubleToStr( max_loss, 0 )+"\t"+DoubleToStr( max_tp, 0 )+"\t-\twin";
        // out = out + "win  "+type+"  SL: "+DoubleToStr( loss, 0 )+"  max_TP: "+DoubleToStr( max_tp, 0 )+"  max_loss: "+DoubleToStr( max_loss, 0 );
      }else{
        // out = out + "missed  "+type+" closest: "+DoubleToStr( closest, 0 );
        out = StringSubstr(Symbol(), 0, 6)+"\t"+type+"\t-\t-\t"+DoubleToStr( closest, 0 )+"\tmissed";
      }
    }
    Alert(out);
		
		addComment(sel_name+" marked.",2);
  }else{
    addComment("Can not find line!",1);
  }
  return(0);
}

double prevZigZag( int from ){
  int i = from + 1;
  double tmp;
  while( i < from + 300 ){
    tmp = iCustom( Symbol(), Period(), "ZigZag", 12, 5, 3, 0, i );
    if( tmp != 0.0 ){
      return ( tmp );
    }
    i++;
  }
  return (-1.0);
}

double nextZigZag( int from, int pos ){
  int i = from;
  double tmp;
  while( i > 0 ){
    tmp = iCustom( Symbol(), Period(), "ZigZag", 12, 5, 3, 0, i );
    if( tmp != 0.0 ){
      if( pos == 1 ){
        if( High[i] == tmp ){
          return ( tmp );
        }
      }else{
        if( Low[i] == tmp ){
          return ( tmp );
        }
      }
    }
    i--;
  }
  return (0.0);
}
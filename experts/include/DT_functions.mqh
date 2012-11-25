//+------------------------------------------------------------------+
//|                                                 DT_functions.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#import "user32.dll"
	int RegisterWindowMessageA(string lpString);
	int PostMessageA(int hWnd,int Msg,int wParam,int lParam);
#import

bool errorCheck( string text = "unknown function" ){
  int e = GetLastError();
  if( e != 0 ){
    string err = "unknown ";
    switch(e){
      case 4202: err = "Object does not exist."; break;
      case 4066: err = "Requested history data in updating state."; return (true);
      case 4099: err = "End of file."; return (true);
      case 4107: err = "Invalid price."; break;
      case 4054: err = "Incorrect series array using."; break;
      case 4055: err = "Custom indicator error."; break;
      case 4200: err = "Object exists already."; break;
      case 4009: err = "Not initialized string in array."; break;
      case 4002: err = "Array index is out of range."; break;
      case 4058: err = "Global variable not found."; break;
      case 130: err = "Invalid stops."; break;
      default: err = err + e; break;      
    }
    
    Alert( StringConcatenate( "Error in ",text,": ",err," (", Symbol(), ")" ) );
    return (false);
  }else{
    return (true);
  }
}

void createGlobal( string name, string value ){
  name = "DT_GO_"+name; 
  if( ObjectFind( name ) == -1 ){
    ObjectCreate( name, OBJ_TREND, 0, 0, 0, Time[0], 0.01 );
    ObjectSet( name, OBJPROP_RAY, false );
    ObjectSetText( name, value, 10 );
  }
}

void setGlobal( string name, string value ){
  ObjectSetText("DT_GO_"+name, value);
}

string getGlobal(string name){
  return (ObjectDescription("DT_GO_"+name));
}

bool removeObjects( string filter = "", string type = "BO" ){
  int j = ObjectsTotal() - 1;
  string name;
  
  if( filter == "" ){
    for ( ; j >= 0; j-- ) {
      name = ObjectName(j);
      if( StringSubstr( name, 3, 2 ) == type ){
        ObjectDelete( name );
      }
    }  
  }else{    
    filter = StringConcatenate( type, "_" ,filter, "_" );   
    int len = StringLen(filter);
    for ( ; j >= 0; j-- ) {
      name = ObjectName(j);
      if( StringSubstr( name, 3, len ) == filter ){
        ObjectDelete(name);
      }
    }
  }
  return ( errorCheck( StringConcatenate("removeObjects (filter:", filter ,")") ) );
}

string getSymbol(){
  return ( StringSubstr(Symbol(), 0, 6) );
}

double getSymbolData( int idx ){
  int len = ArrayRange( SYMBOL_DATA, 0 );
  string sym = Symbol();
  for( int i = 0; i < len; i++ ){
    if( SYMBOL_DATA[i][0] == sym ){
      return ( StrToDouble(SYMBOL_DATA[i][idx]) );
    }
  }
  return (-1.0);
}

int nrOfIcons(){
  int nr = 0, j = ObjectsTotal() - 1;
  string name;
  for ( ; j >= 0; j-- ){
    name = ObjectName(j);
    if( StringSubstr( name, 3, 8 ) == "BO_icon_" ){
      nr++;
    }
  }
  return (nr);
}

double getTLineValueByShift( string name, int shift = 0 ){
  if( ObjectType( name ) == OBJ_TREND ){
    return ( ObjectGetValueByShift( name, shift ) );
  }else{
    return ( ObjectGet( name, OBJPROP_PRICE1 ) );
  }
}

string getSelectedLine( double time_cord, double price_cord, bool search_all = false, int accuracy = 10 ){
  int j, obj_total= ObjectsTotal(), type, shift = iBarShift( NULL, 0, time_cord );
  string name, sel_name = "";
  double price, ts, t1, t2, dif, sel_dif = 999999, max_dist = ( WindowPriceMax(0) - WindowPriceMin(0) ) / accuracy;
  
  for (j= obj_total-1; j>=0; j--) {
    name = ObjectName(j);
    if( ( ObjectType( name ) == OBJ_TREND || ObjectType( name ) == OBJ_HLINE ) && (search_all || StringSubstr( name, 5, 7 ) == "_tLine_") && ObjectGet( name, OBJPROP_TIMEFRAMES ) != -1 ){
			t1 = ObjectGet(name,OBJPROP_TIME1);
			t2 = ObjectGet(name,OBJPROP_TIME2);
			price = getTLineValueByShift( name, shift);
			if( price != 0.0 ){
				dif = MathAbs( price - price_cord );         
				if( dif < sel_dif && dif < max_dist ){
					sel_dif = dif;
					sel_name = name;
				}
			}else{
				GetLastError();
			}
    }
  }
  errorCheck("getSelectedLine");
  return (sel_name);
}

int getPositionByDaD(double price_cord, string symb = ""){
  int i = 0, len = OrdersTotal(), ticket = 0;
  double o, dif = 999999;

  if( symb == ""){
    symb = Symbol();
  }
  
  for (; i < len; i++) {      
    if (OrderSelect(i, SELECT_BY_POS)) {        
      if (OrderSymbol() == symb) {
        o = OrderOpenPrice();
        if( MathAbs( o - price_cord ) < dif ){
          dif = MathAbs( o - price_cord );
          ticket = OrderTicket();
        }
      }
    }
  }
  return (ticket);
}

void autoScroll( bool set = false ){
	if( set ){
		if( WindowFirstVisibleBar() - WindowBarsPerChart() <= 0 ){
			GlobalVariableSet( StringConcatenate( getSymbol(), "_autoScroll" ), 1.0 );
		}
	}else{
		if( GlobalVariableGet( StringConcatenate( getSymbol(), "_autoScroll" ) ) == 1.0 ){
			GlobalVariableSet( StringConcatenate( getSymbol(), "_autoScroll" ), 0.0 );
			keybd_event(35, 0, 0, 0); // End
			keybd_event(35, 0, 2, 0);
		}
	}
}

void fakeTick(){
	PostMessageA(WindowHandle(Symbol(), Period()), RegisterWindowMessageA("MetaTrader4_Internal_Message"), 2, 1);
}
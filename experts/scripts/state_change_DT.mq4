//+------------------------------------------------------------------+
//|                                              state_change_DT.mq4 |
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
  double pod = WindowPriceOnDropped();
  double tod = WindowTimeOnDropped();
  string sel_name = getSelectedLine( tod, pod );
  
  if( sel_name != "" ){
    string state = StringSubstr( sel_name, 12, 3 );
    int width = ObjectGet(sel_name, OBJPROP_WIDTH);
    color c = ObjectGet(sel_name, OBJPROP_COLOR);
    ObjectSet( sel_name, OBJPROP_WIDTH, 2 );
    ObjectSet( sel_name, OBJPROP_COLOR, DarkOrange );
    WindowRedraw();
    
    
    double price = ObjectGetValueByShift( sel_name, iBarShift( NULL, 0, tod) );
    int cmd_id;
    
    if( ObjectType( sel_name ) == OBJ_TREND ){
      if( iBars( NULL, PERIOD_H4 ) - 1 == iBarShift( NULL, PERIOD_H4, ObjectGet( sel_name, OBJPROP_TIME1 ) ) ){
        addComment( "Line out of H4 chart!", 1 );
        ObjectSet( sel_name, OBJPROP_WIDTH, width );
        ObjectSet( sel_name, OBJPROP_COLOR, c );
        return (0);
      }
    }
    
    if( ObjectGet( sel_name, OBJPROP_COLOR ) == Black ){
      cmd_id = MessageBox( "renew                      sig                      Cancel?", "TLine status change?", MB_YESNOCANCEL|MB_ICONQUESTION );
      if( cmd_id == IDYES ){
        changeTLineState( sel_name, state, width );
      }else if( cmd_id == IDNO ){
        changeTLineState( sel_name, "sig", width );
      }else if( cmd_id == IDCANCEL ){
        ObjectSet( sel_name, OBJPROP_WIDTH, width );
        ObjectSet( sel_name, OBJPROP_COLOR, c );
        return (0);
      }
    }else if( state == "sml" ){
      cmd_id = MessageBox( "big                      sig                      Cancel?", "TLine status change?", MB_YESNOCANCEL|MB_ICONQUESTION );
      if( cmd_id == IDYES ){
        changeTLineState( sel_name, "big", width );
      }else if( cmd_id == IDNO ){
        changeTLineState( sel_name, "sig", width );
      }else if( cmd_id == IDCANCEL ){
        ObjectSet( sel_name, OBJPROP_WIDTH, width );
        ObjectSet( sel_name, OBJPROP_COLOR, c );
        return (0);
      }
    }else if( state == "big" ){
      cmd_id = MessageBox( "sml                      sig                      Cancel?", "TLine status change?", MB_YESNOCANCEL|MB_ICONQUESTION );
      if( cmd_id == IDYES ){
        changeTLineState( sel_name, "sml", width );
      }else if( cmd_id == IDNO ){
        changeTLineState( sel_name, "sig", width );
      }else if( cmd_id == IDCANCEL ){
        ObjectSet( sel_name, OBJPROP_WIDTH, width );
        ObjectSet( sel_name, OBJPROP_COLOR, c );
        return (0);
      }
    }else if( state == "sig" ){
      cmd_id = MessageBox( "sml                      big                      Cancel?", "TLine status change?", MB_YESNOCANCEL|MB_ICONQUESTION );
      if( cmd_id == IDYES ){
        changeTLineState( sel_name, "sml", width );
      }else if( cmd_id == IDNO ){
        changeTLineState( sel_name, "big", width );
      }else if( cmd_id == IDCANCEL ){
        ObjectSet( sel_name, OBJPROP_WIDTH, width );
        ObjectSet( sel_name, OBJPROP_COLOR, c );
        return (0);
      }
    }else{
      ObjectSet( sel_name, OBJPROP_WIDTH, width );
      ObjectSet( sel_name, OBJPROP_COLOR, c );
    }
  }else{
    addComment( "Line not found!", 1 );
  }
  return( errorCheck("state_change") );
}

void changeTLineState( string sel_name, string state, int width ){
  string name, old_state = StringSubstr( sel_name, 12, 3 );
  double time = TimeLocal();
  
  if( ObjectGet( sel_name, OBJPROP_COLOR ) == Black  || old_state == state ){
    name = StringConcatenate( "DT_GO_tLine_", state, "_", DoubleToStr( time, 0 ) );
  }else{
    name = StringConcatenate( "DT_GO_tLine_", state, "_", StringSubstr( sel_name, 16, 10 ) );
  }
  
  ObjectCreate( name, ObjectType( sel_name ), 0, ObjectGet( sel_name, OBJPROP_TIME1 ), ObjectGet( sel_name, OBJPROP_PRICE1 ), ObjectGet( sel_name, OBJPROP_TIME2 ), ObjectGet( sel_name, OBJPROP_PRICE2 ) );
  
  if( state == "big" ){
    ObjectSet( name, OBJPROP_COLOR, DeepPink );
    
  }else if( state == "sml" ){
    ObjectSet( name, OBJPROP_COLOR, Magenta );
  
  }else{
    ObjectSet( name, OBJPROP_COLOR, CornflowerBlue );
  }
  
  ObjectSet( name, OBJPROP_STYLE, ObjectGet( sel_name, OBJPROP_STYLE ) );
  ObjectSet( name, OBJPROP_RAY, ObjectGet(sel_name, OBJPROP_RAY) );
  ObjectSet( name, OBJPROP_BACK, true );
  ObjectSet( name, OBJPROP_WIDTH, width );
  ObjectSet( name, OBJPROP_TIMEFRAMES, ObjectGet(sel_name, OBJPROP_TIMEFRAMES) );
  ObjectSetText( name, TimeToStr( time, TIME_DATE|TIME_SECONDS) );
  
  ObjectDelete( sel_name );
  
  addComment( sel_name + " state changed to " + state, 2 );
}

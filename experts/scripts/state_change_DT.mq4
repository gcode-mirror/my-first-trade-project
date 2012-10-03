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
    double price = ObjectGetValueByShift( sel_name, iBarShift( NULL, 0, tod) );
    int cmd_id;
    
    if( state == "sig" ){
      cmd_id = MessageBox( "Sup-Res                      All                      Cancel?", "TLine status change?", MB_YESNOCANCEL|MB_ICONQUESTION );
      if( cmd_id == IDYES ){
        if( pod > price ){
          changeTLineState( sel_name, "sup" );
        }else{
          changeTLineState( sel_name, "res" );
        }
      }else if( cmd_id == IDNO ){
        changeTLineState( sel_name, "all" );
      }else if( cmd_id == IDCANCEL ){
        return (0);
      }

    }else if( state == "all" ){
      cmd_id = MessageBox( "Sup-Res                      Sig                      Cancel?", "TLine status change?", MB_YESNOCANCEL|MB_ICONQUESTION );
      if( cmd_id == IDYES ){
        if( pod > price ){
          changeTLineState( sel_name, "sup" );
        }else{
          changeTLineState( sel_name, "res" );
        }
      }else if( cmd_id == IDNO ){
        changeTLineState( sel_name, "sig" );
      }else if( cmd_id == IDCANCEL ){
        return (0);
      }
    
    }else if( state == "res" || state == "sup" ){
      cmd_id = MessageBox( "All                      Sig                      Cancel?", "TLine status change?", MB_YESNOCANCEL|MB_ICONQUESTION );
      if( cmd_id == IDYES ){
        changeTLineState( sel_name, "all" );
      }else if( cmd_id == IDNO ){
        changeTLineState( sel_name, "sig" );
      }else if( cmd_id == IDCANCEL ){
        return (0);
      }
    }

  }else{
    addComment( "Line not found!", 1 );
  }
  return( errorCheck("state_change") );

}

void changeTLineState( string sel_name, string state ){
  string name = StringConcatenate( "DT_GO_tLine_", state, "_", StringSubstr( sel_name, 16, 10 ) );
  
  ObjectCreate( name, ObjectType( sel_name ), 0, ObjectGet( sel_name, OBJPROP_TIME1 ), ObjectGet( sel_name, OBJPROP_PRICE1 ), ObjectGet( sel_name, OBJPROP_TIME2 ), ObjectGet( sel_name, OBJPROP_PRICE2 ) );
  
  string desc = StringSubstr(ObjectDescription( sel_name ), 0, 19);
  if( desc == "" ){
    desc = TimeToStr( TimeLocal(), TIME_DATE|TIME_SECONDS);
  }
  
  if( state == "res" ){
    ObjectSet( name, OBJPROP_COLOR, DeepPink );
    ObjectSetText( name, StringConcatenate( desc, " \\/ \\/ \\/ \\/ \\/" ) );
    
  }else if( state == "sup" ){
    ObjectSet( name, OBJPROP_COLOR, LimeGreen );
    ObjectSetText( name, StringConcatenate( desc, " /\\ /\\ /\\ /\\ /\\" ) );
  
  }else if( state == "all" ){
    ObjectSet( name, OBJPROP_COLOR, Magenta);
    ObjectSetText( name, StringConcatenate( desc, " /\\ \\/ /\\ \\/ /\\" ) );
    
  }else{
    ObjectSet( name, OBJPROP_COLOR, CornflowerBlue );
    ObjectSetText( name, desc );
  }
  
  ObjectSet( name, OBJPROP_STYLE, ObjectGet( sel_name, OBJPROP_STYLE ) );
  ObjectSet( name, OBJPROP_RAY, ObjectGet(sel_name, OBJPROP_RAY) );
  ObjectSet( name, OBJPROP_BACK, true );
  ObjectSet( name, OBJPROP_WIDTH, ObjectGet(sel_name, OBJPROP_WIDTH) );
  ObjectSet( name, OBJPROP_TIMEFRAMES, ObjectGet(sel_name, OBJPROP_TIMEFRAMES) );
  
  ObjectDelete( sel_name );
  
  addComment( sel_name + " state changed to " + state, 2 );
}

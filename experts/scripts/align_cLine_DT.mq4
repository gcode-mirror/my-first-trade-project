//+------------------------------------------------------------------+
//|                                               align_cLine_DT.mq4 |
//|                                                              Dex |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Dex"
#property link      ""

#include <DT_defaults.mqh>
#include <DT_icons.mqh>
#include <DT_functions.mqh>
#include <DT_comments.mqh>
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start(){
  double dif, pod = WindowPriceOnDropped();
  double tod = WindowTimeOnDropped();
  int i = 0, len = ObjectsTotal();
  string name, sel_name = "", para_line = "";
  color c = C'245,57,255';
  
  for( ; i < len; i++ ) {
    name = ObjectName(i);
    if( StringSubstr( name, 5, 7 ) == "_cLine_" ){
      if( ObjectGet( name, OBJPROP_COLOR ) == c ){
        sel_name = name;
      }
    }
  }
  
  if( pod == 0.0 ){
    if( sel_name != "" ){
      renameChannelLine( sel_name );
    }
  }else{
    if( sel_name == "" ){
      sel_name = getSelectedLine( tod, pod, true, 12 );
      ObjectSet( sel_name, OBJPROP_COLOR, c );
    }else{
      para_line = getSelectedLine( tod, pod, false, 15 );
      if( para_line != "" ){
        dif = ObjectGet( sel_name, OBJPROP_PRICE1 ) - getLineValAtTime(para_line, ObjectGet( sel_name, OBJPROP_TIME1 ));
        ObjectSet( name, OBJPROP_PRICE2, getLineValAtTime(para_line, ObjectGet( sel_name, OBJPROP_TIME2 )) - dif );
        
        addComment("Line: "+getCLineProperty( sel_name, "ts" )+" setted paralel to: "+getCLineProperty( name, "ts" ));
      }else{
        double h, l;
        int shift = iBarShift( NULL, 0, tod );
        h = High[shift];
        l = Low[shift];
        
        if( MathAbs( pod - h ) < MathAbs( pod - l ) ){
          dif = getLineValAtTime( sel_name, tod ) - h;
          ObjectSet( sel_name, OBJPROP_PRICE2, ObjectGet( name,OBJPROP_PRICE2 ) - dif );
          ObjectSet( sel_name, OBJPROP_PRICE1, h );
          addComment("Line: "+getCLineProperty( sel_name, "ts" )+" align to bar High: "+DoubleToStr( h, Digits ));
        }else{
          dif = l - getLineValAtTime( sel_name, tod );
          ObjectSet( sel_name, OBJPROP_PRICE2, ObjectGet( name,OBJPROP_PRICE2 ) + dif );
          ObjectSet( sel_name, OBJPROP_PRICE1, l );
          addComment("Line: "+getCLineProperty( sel_name, "ts" )+" align to bar Low: "+DoubleToStr( l, Digits ));
        }
      }
    }
  
  }
}

double getLineValAtTime( string name, double time ){
  if( ObjectType(name) == OBJ_TREND ){
    return ( ObjectGet( name, OBJPROP_PRICE1 ) );
  }

  double t1, t2, p1 ,p2, val;
  t1 = ObjectGet( name,OBJPROP_TIME1 );
  p1 = ObjectGet( name,OBJPROP_PRICE1 );
  t2 = ObjectGet( name,OBJPROP_TIME2 );
  p2 = ObjectGet( name,OBJPROP_PRICE2 );
  ObjectSet( name, OBJPROP_RAY, true );
  
  if( (t1 < t2 && time < t1) || (t1 > t2 && time > t1) ){
    ObjectSet( name, OBJPROP_TIME1, t2 );
    ObjectSet( name, OBJPROP_PRICE1, p2 );
    ObjectSet( name, OBJPROP_TIME2, t1 );
    ObjectSet( name, OBJPROP_PRICE2, p1 );
    val = ObjectGetValueByShift( name, iBarShift( NULL, 0, time ) );
    
    ObjectSet( name, OBJPROP_TIME1, t1 );
    ObjectSet( name, OBJPROP_PRICE1, p1 );
    ObjectSet( name, OBJPROP_TIME2, t2 );
    ObjectSet( name, OBJPROP_PRICE2, p2 );
    
    return (val);
  }else{
    return (ObjectGetValueByShift( name, iBarShift( NULL, 0, time ) ));
  }
  
}


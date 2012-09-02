//+------------------------------------------------------------------+
//|                                             sup_res_cLine_DT.mq4 |
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
  double pod = WindowPriceOnDropped();
  double tod = WindowTimeOnDropped();
  string sel_name = getSelectedLine(tod, pod);
  if( sel_name != "" ){
    double price = ObjectGetValueByShift( sel_name, iBarShift( NULL, 0, tod) );
		
		string res = checkPriceIsZZ( sel_name );
		if( res != "ok" ){
			addComment( res, 1 );
			return (0);
		}
		
		string state;
    if( pod > price ){
      state = "sup";
    }else{
      state = "res";
    }
		renameChannelLine( sel_name, state );
    
		addComment( sel_name + " changed to "+ state +" line", 2 );
  }else{
    addComment("Can not find line!",1);
  }
  
  return(0);
}
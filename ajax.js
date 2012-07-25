var obj =  $("div.calendar_detail");	
var len = obj.length;
var index = 0;
var nr, timer = setInterval(ajaxHack, 500);
function ajaxHack() {
	obj.eq(index).mouseenter().mouseleave().click();
	index++;
	if (index >= len) {
		clearInterval(timer);
		console.log("len: "+len );
		setTimeout(init, 2000);
	}
}

function init(){
	obj = null;
	obj = $("table.tborder.thinborder a span:contains('More')");
	len = obj.length;
	console.log("len: "+len );
	nr = 0;
	index = 0;
	chechHistory();
}

function chechHistory(){
	if( index >= len ) {
		if( nr == 0 ){
			alert("ok");
			return;
		}else{
			setTimeout(init, 1000);
			return;
		}
	}

	console.log("id: "+index+"state: "+obj.eq(index).parent().css('visibility') );
	if( obj.eq(index).parent().css('visibility') == 'visible' ){
		obj.eq(index++).click();
		nr++;
		setTimeout(chechHistory, 400);
	}else{
		index++;
		chechHistory();
	}
}

//--------------------------------------------------------
//our $X = 0;
//our $HISTORY_DATA = {
$X++ =>{
    CURRENCY => 'USD',
    IMPACT => 'Low',
    DESC => 'Wholesale Inventories m/m',
    GOODEFFECT => 'A<F',
    UNIT => '%',
    HISTORY => {
      0 => {
        DATE => 'Jan 9, 2009',
        ACT => '-0.6',
        FORC => '-0.8',
        PREV => '-1.2',
      },
      1 => {
        DATE => 'Feb 10, 2009',
        ACT => '-1.4',
        FORC => '-0.8',
        PREV => '-0.9',

      },
    },
  },
};
1;
//};
//1;

//--------------------------------------------------------



var obj;	
var len = obj.length;
var index = 0;
var nr, timer;
function chechHistory(){
	console.log("id: "+index+"state: "+obj.eq(index).parent().css('visibility') );
	if( obj.eq(index).parent().css('visibility') == 'visible' ){
		obj.eq(index).click();
		nr++;
	}else{
		clearInterval(timer);
		timer = setInterval(chechHistory, 400);
	}
	index++;
	
	if( index >= len ) {
		clearInterval(timer);
		if( nr == 0 ){
			alert("ok");
		}else{
			setTimeout(init, 1000);
		}
	}
}
function init(){
	obj = null;
	obj = $("table.tborder.thinborder a span:contains('More')");
	len = obj.length;
	console.log("len: "+len );
	nr = 0;
	index = 0;
	timer = setInterval(chechHistory, 400);
}
init();
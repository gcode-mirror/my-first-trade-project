#!/usr/bin/perl -w
#use strict;
use Tkx;
use Cwd;
use Win32::Sound;
Win32::Sound::Volume('100%');

# ======================================================= GLOBALS =================================================================
our $INPUT_FILE = getcwd."/experts/files/notify.bin";
our $ALERT_SOUND = getcwd."/Sounds/alert2.wav";
our $LAST_MOD = 0;

our $BASE_WINDOW;
our $BASE_WINDOW_GEO1 = "-110+-20";
our $BASE_WINDOW_GEO2 = "-110+-20";

our $NOTIFY_LABEL;
our $NOTIFY_LABEL_TXT = 0;

our $PROFIT_LABEL;
our $PROFIT_LABEL_TXT = 0;

our $FLIP_WINDOW = 0;

our @WIDGETS;
our @DATA;

# ======================================================== STYLE ==================================================================
Tkx::ttk__style_configure('sep.TFrame', -background => "#F3F3F3");

Tkx::ttk__style_configure('odd.TLabel', -background => "#eee");
Tkx::ttk__style_configure('even.TLabel', -background => "white");

Tkx::ttk__style_configure('none.TLabel', -background => "#ccc", -foreground => "#555");
Tkx::ttk__style_configure('has.TLabel', -background => "red", -foreground => "white");

# ====================================================== FUNCTIONS ================================================================
sub init{
  my @lines = read_file($INPUT_FILE);
  my @arr;
  
  $BASE_WINDOW = Tkx::widget->new(".");
	$BASE_WINDOW->g_wm_attributes(-topmost=> 1, -alpha => 1, -toolwindow => 1);
	$BASE_WINDOW->g_wm_resizable(0,0);
	$BASE_WINDOW->g_wm_geometry($BASE_WINDOW_GEO1);
	$BASE_WINDOW->g_wm_minsize(12,12);
	$BASE_WINDOW->g_wm_maxsize(200,150);
  $BASE_WINDOW->g_bind("<2>",sub {Tkx::destroy($BASE_WINDOW);});
  
  $BASE_WINDOW->g_bind("<Enter>", [sub{toggleWindow(1,$_[0]);},Tkx::Ev("%d")]);
  $BASE_WINDOW->g_bind("<Leave>", [sub{toggleWindow(0,$_[0]);},Tkx::Ev("%d")]);
  
  $BASE_WINDOW->g_bind("<Alt-1>", sub {resetData();});
  $BASE_WINDOW->g_bind("<Alt-3>", sub {flipWindow();});
  
  my $frame = $BASE_WINDOW->new_ttk__frame( -borderwidth => 0, -width => 1, -padding =>"0 0 0 0");
  $frame -> g_grid(-row => 0, -column => 0, -sticky => "nwes");
  
    $NOTIFY_LABEL = $frame->new_ttk__label(-textvariable => \$NOTIFY_LABEL_TXT, -style =>'none.TLabel', -anchor=> 'center', -font => "verdana 6 bold", -padding =>"2 -2 2 -2");
    $NOTIFY_LABEL->g_grid(-row => 0, -column => 0, -sticky => "nwes");
    
    @arr = split(/;/, $lines[$#lines]);
    $PROFIT_LABEL = $frame->new_ttk__label(-textvariable => \$PROFIT_LABEL_TXT, -background => "white", -foreground => "#333", -anchor=> 'center', -font => "verdana 5 bold", -padding =>"0 -3 0 -2");
    $PROFIT_LABEL->g_grid(-row => 1, -column => 0, -sticky => "nwes");
    
    if( $arr[0] == 1){
      $PROFIT_LABEL_TXT = $arr[1];
    }else{
      $PROFIT_LABEL -> g_grid_remove();
    }
   
  $frame->g_grid_columnconfigure(0, -weight => 1);
  $frame->g_grid_rowconfigure(0, -weight => 1);
   
  $BASE_WINDOW->g_grid_columnconfigure(0, -weight => 1);
  $BASE_WINDOW->g_grid_rowconfigure(0, -weight => 1);
  
  for(my $i = 0, $len = $#lines; $i < $len; $i++) {
    @arr = split(/;/, $lines[$i]);
    
    $WIDGETS[$i][0] = $BASE_WINDOW->new_ttk__frame( -borderwidth => 0, -relief => "flat", -padding =>(($i == 0)?'0 2':'0 0').' 0 0', -style =>(($i == 0)?'sep.TFrame':''));
		$WIDGETS[$i][0]->g_grid(-row => $i+1, -column => 0, -sticky => "nwes");
    
      $WIDGETS[$i][1] = $WIDGETS[$i][0]->new_ttk__label(-text => getShortName($arr[0]), -font => "verdana 7 bold", -foreground => "black", -borderwidth => 0, -padding => "1 -1 1 -1", -style => (($i % 2 == 1)?'even.TLabel':'odd.TLabel'));
      $WIDGETS[$i][1]->g_grid(-row => 0, -column => 0, -sticky => "nwes");
      $WIDGETS[$i][1]->g_bind("<1>",[sub {setAsVisited($_[0]);},$i]);
      
      $WIDGETS[$i][3] = '!';
      $WIDGETS[$i][2] = $WIDGETS[$i][0]->new_ttk__label(-textvariable => \$WIDGETS[$i][3], -width => 1, -borderwidth => 1, -anchor=> 'center', -relief => 'solid' ,-font => "verdana 7 bold", -foreground => "black", -borderwidth => 0, -padding => "1 -1 1 -1", -background => (($i % 2 == 1)?'#eee':'white'));
      $WIDGETS[$i][2]->g_grid(-row => 0, -column => 1, -sticky => "nwes");
      $WIDGETS[$i][2]->g_bind("<1>",[sub {changeState($_[0]);},$i]);
      
    $WIDGETS[$i][0]->g_grid_columnconfigure(0, -weight => 1);
    $WIDGETS[$i][0]->g_grid_columnconfigure(1, -weight => 1);
    $WIDGETS[$i][0]->g_grid_remove(); 
    
    $DATA[$i] = 0;
  }
  
  start();
	infiniteLoop();
}

sub start{
  my @lines = read_file($INPUT_FILE);
  my @arr;
  my $nr_of_notified = 0;
  for(my $i = 0, $len = $#lines; $i < $len; $i++) {
    @arr = split(/;/, $lines[$i]);
    
    if($WIDGETS[$i][3] eq '-'){
      next;
    }elsif($WIDGETS[$i][3] eq '?'){
      if($DATA[$i] == $arr[1] || $arr[1] == 0){
        next;
      }else{
        $WIDGETS[$i][3] = '!';
      }
    }
    
    if($arr[1] == 0){
      if($DATA[$i] != 0){
        $nr_of_notified++;
        $WIDGETS[$i][1] -> configure(-background =>'yellow', -foreground =>'black');
      }
    }else{
      $nr_of_notified++;
      $WIDGETS[$i][1] -> configure(-background =>'red', -foreground =>'white');
      $DATA[$i] = $arr[1];
    }
  }
  
  @arr = split(/;/, $lines[$#lines]);
  if( $arr[0] == 1){
    $PROFIT_LABEL -> g_grid(); 
    $PROFIT_LABEL_TXT = $arr[1];
  }else{
    $PROFIT_LABEL->g_grid_remove();
  }
  
  if($nr_of_notified == 0){
    $NOTIFY_LABEL->configure(-style =>'none.TLabel');
  }else{
    $NOTIFY_LABEL->configure(-style =>'has.TLabel');
  }
  
  if($NOTIFY_LABEL_TXT != $nr_of_notified){
    if($nr_of_notified > $NOTIFY_LABEL_TXT){
      Win32::Sound::Stop();
      Win32::Sound::Play($ALERT_SOUND,SND_ASYNC);
    }
    $NOTIFY_LABEL_TXT = $nr_of_notified;
  }

}

sub flipWindow{
  if($FLIP_WINDOW == 0){
    for($i = 0; $i <= $#WIDGETS; $i++){
      $WIDGETS[$i][0]->g_grid(-row => 0, -column => $i+1);
      $WIDGETS[$i][2]->g_grid(-row => 1, -column => 0);
      
      $WIDGETS[$i][0] -> configure(-padding =>(($i == 0)?'2':'0').' 0 0 0');
      $WIDGETS[$i][1] -> configure(-padding => "0 -3 0 -2");
      $WIDGETS[$i][2] -> configure(-padding => "0 -3 0 -2");
    }
    $NOTIFY_LABEL -> g_grid_remove();
    $FLIP_WINDOW = 1;
  }else{
    for($i = 0; $i <= $#WIDGETS; $i++){
      $WIDGETS[$i][0]->g_grid(-row => $i+1, -column => 0);
      $WIDGETS[$i][2]->g_grid(-row => 0, -column => 1);
      
      $WIDGETS[$i][0] -> configure(-padding =>(($i == 0)?'0 2':'0 0').' 0 0');
      $WIDGETS[$i][1] -> configure(-padding => "1 -2 1 -1");
      $WIDGETS[$i][2] -> configure(-padding => "0 -2 0 -2");
    }
    $NOTIFY_LABEL -> g_grid();
    $FLIP_WINDOW = 0;
  }
}

sub resetData{
  for(my $i = 0, $len = $#DATA; $i <= $len; $i++) {
    $DATA[$i] = 0;
    setAsVisited($i);
  }
  start();
}

sub setAsVisited{
  if($WIDGETS[$_[0]][1] -> cget(-background) eq 'yellow'){
    $WIDGETS[$_[0]][1] -> configure(-background =>'', -foreground =>''); 
    $DATA[$_[0]] = 0;
    $NOTIFY_LABEL_TXT--;
    if( $NOTIFY_LABEL_TXT == 0){
      $NOTIFY_LABEL->configure(-style =>'none.TLabel');
    }
  }
}

sub changeState{
  if($WIDGETS[$_[0]][3] eq '!'){
    $WIDGETS[$_[0]][3] = '?';
    $WIDGETS[$_[0]][1] -> configure(-background =>'#aaa', -foreground =>'#ddd');
  }elsif($WIDGETS[$_[0]][3] eq '?'){
    $WIDGETS[$_[0]][3] = '-';
    $WIDGETS[$_[0]][1] -> configure(-background =>'#aaa', -foreground =>'#ddd');
  }else{
    $WIDGETS[$_[0]][3] = '!';
    $WIDGETS[$_[0]][1] -> configure(-background =>'', -foreground =>'');
  }
  start();
}

sub toggleWindow{
  my $i;
  if( $FLIP_WINDOW == 1 || $_[1] ne 'NotifyVirtual' ){
    return;
  }else{
    if($_[0] == 1){
      for($i = 0; $i <= $#WIDGETS; $i++){
        $WIDGETS[$i][0]->g_grid(); 
      }
    }else{
      for($i = 0; $i <= $#WIDGETS; $i++){
        $WIDGETS[$i][0]->g_grid_remove(); 
      }
      $BASE_WINDOW->g_wm_geometry($BASE_WINDOW_GEO1);
    }
  }
}

sub getShortName{
  if($_[0] eq "EURUSD"){
    return "EU";
  }elsif($_[0] eq "USDJPY"){
    return "UJ";
  }elsif($_[0] eq "USDCHF"){
    return "UC";
  }elsif($_[0] eq "EURJPY"){
    return "EJ";
  }elsif($_[0] eq "GBPUSD"){
    return "GU";
  }elsif($_[0] eq "AUDUSD"){
    return "AU";
  }elsif($_[0] eq "XAGUSD"){
    return "SI";
  }elsif($_[0] eq "XAUUSD"){
    return "GO";
  }
}

sub read_file{
  open(DATA, $_[0]);
  my @lines = <DATA>;
  close(DATA);
  return @lines;
}

sub infiniteLoop{
	my $curr_mod = (stat($INPUT_FILE))[9];
	if($LAST_MOD != $curr_mod){
		start();
		$LAST_MOD = $curr_mod;
	}
	Tkx::after(3000, sub {infiniteLoop();});
}

init();
Tkx::MainLoop();

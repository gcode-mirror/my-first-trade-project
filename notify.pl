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

our $LOG_LABEL;
our $LOG_LABEL_TXT = 0;

our $PROFIT_SUM_LABEL;
our $PROFIT_SUM_TXT = 0;

our $FLIP_WINDOW = 0;

our $VISITED_LOG_NR = 0;
our $LAST_LOG_NR = 0;

our @WIDGETS;
our @DATA;

# ======================================================== STYLE ==================================================================
Tkx::ttk__style_configure('sep.TFrame', -background => "CornflowerBlue");

Tkx::ttk__style_configure('none.TLabel', -background => "#ccc", -foreground => "#555");
Tkx::ttk__style_configure('has.TLabel', -background => "red", -foreground => "white");

Tkx::ttk__style_configure('basic.TLabel', -background => "white", -foreground => "black" );
Tkx::ttk__style_configure('alert.TLabel', -background => "red", -foreground => "white");

Tkx::ttk__style_configure('warn.TLabel', -background => "Gold", -foreground => "black");


Tkx::ttk__style_configure('positive.TLabel', -background => "#CCFDCC", -foreground => "black");
Tkx::ttk__style_configure('negatíve.TLabel', -background => "#FFE2E6", -foreground => "black");

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
  
  $BASE_WINDOW->g_bind("<Alt-3>", sub {flipWindow();});
  
  my $frame = $BASE_WINDOW->new_ttk__frame( -borderwidth => 0, -width => 1, -padding =>"0 0 0 0");
  $frame -> g_grid(-row => 0, -column => 0, -sticky => "nwes");
  
    $LOG_LABEL = $frame->new_ttk__label(-textvariable => \$LOG_LABEL_TXT, -style =>'none.TLabel', -anchor=> 'center', -font => "verdana 5 bold", -padding =>"2 -2 2 -2");
    $LOG_LABEL->g_grid(-row => 0, -column => 0, -sticky => "nwes");
    $LOG_LABEL -> g_bind("<1>",sub {$VISITED_LOG_NR = $LOG_LABEL_TXT; $LOG_LABEL_TXT = 0; $LOG_LABEL->configure(-style =>'none.TLabel'); });

    @arr = split(/;/, $lines[$#lines]);
    $PROFIT_SUM_LABEL = $frame->new_ttk__label(-textvariable => \$PROFIT_SUM_TXT, -style =>'none.TLabel', -anchor=> 'center', -font => "verdana 5 bold", -padding =>"0 -2 0 -2");
    $PROFIT_SUM_LABEL -> g_grid(-row => 1, -column => 0, -sticky => "nwes");
    $PROFIT_SUM_LABEL -> g_grid_remove();
    
  $frame->g_grid_columnconfigure(0, -weight => 1);
  $frame->g_grid_rowconfigure(0, -weight => 1);
   
  $BASE_WINDOW->g_grid_columnconfigure(0, -weight => 1);
  $BASE_WINDOW->g_grid_rowconfigure(0, -weight => 1);
  
  for(my $i = 0, $len = $#lines; $i < $len; $i++) {
    @arr = split(/;/, $lines[$i]);
    
    $WIDGETS[$i][0] = $BASE_WINDOW->new_ttk__frame( -borderwidth => 0, -relief => "flat", -padding =>(($i == 0)?'0 2':'0 1').' 0 0', -style =>'sep.TFrame');
		$WIDGETS[$i][0]->g_grid(-row => $i+1, -column => 0, -sticky => "nwes");
    
      $WIDGETS[$i][1] = $arr[2];
      $WIDGETS[$i][2] = $WIDGETS[$i][0]->new_ttk__label(-textvariable => \$WIDGETS[$i][1], -font => "verdana 6 bold", -anchor=> 'center', -padding => '-1 1 -1 -1', -style => 'basic.TLabel');
      $WIDGETS[$i][2]->g_grid(-row => 0, -column => 0, -sticky => "nwes");
      # $WIDGETS[$i][2]->g_bind("<1>",[sub {changeState($_[0]);},$i]);
      
      $WIDGETS[$i][3] = $arr[3];
      $WIDGETS[$i][4] = $WIDGETS[$i][0]->new_ttk__label(-textvariable => \$WIDGETS[$i][3], -font => "verdana 5 bold", -anchor=> 'center', -padding => '-1 1 -1 -1', -style => 'basic.TLabel');
      $WIDGETS[$i][4]->g_grid(-row => 0, -column => 1, -sticky => "nwes");
      $WIDGETS[$i][4] -> g_grid_remove();
      
    $WIDGETS[$i][0]->g_grid_columnconfigure(0, -weight => 1);
    $WIDGETS[$i][0]->g_grid_columnconfigure(1, -weight => 1);
    $WIDGETS[$i][0]->g_grid_remove(); 
  }
  
  start();
	infiniteLoop();
}

sub start{
  my @lines = read_file($INPUT_FILE);
  my @arr;
  my $nr_of_notified = 0;
  my $bg;
  
  for(my $i = 0, $len = $#lines; $i < $len; $i++) {
    @arr = split(/;/, $lines[$i]);
    
    $WIDGETS[$i][1] = $arr[2];
    $WIDGETS[$i][3] = $arr[3];
    
    if( $arr[1] == 0 ){
      $WIDGETS[$i][2] -> configure(-style =>'basic.TLabel');
    }else{
      $WIDGETS[$i][2] -> configure(-style =>'warn.TLabel');
    }
  }
  
  @arr = split(/;/, $lines[$#lines]);
  if( $arr[0] > $VISITED_LOG_NR ){
    $LOG_LABEL->configure(-style =>'has.TLabel');
  }else{
    $LOG_LABEL->configure(-style =>'none.TLabel');
  }
  $LOG_LABEL_TXT = $arr[0] - $VISITED_LOG_NR;
  
  if( $arr[1] == 0 ){
    if( $PROFIT_SUM_TXT != 0 ){
      for($j = 0; $j <= $#WIDGETS; $j++){
        $WIDGETS[$j][4] -> g_grid_remove();
      }
      $PROFIT_SUM_LABEL -> g_grid_remove();
      $PROFIT_SUM_LABEL -> configure(-style =>'none.TLabel');
    }
  }else{
    if( $arr[1] > 0 ){
      if( $PROFIT_SUM_TXT < 1 ){
        $PROFIT_SUM_LABEL -> configure(-style =>'positive.TLabel');
        for($j = 0; $j <= $#WIDGETS; $j++){
          $WIDGETS[$j][4] -> g_grid();
        }
        $PROFIT_SUM_LABEL -> g_grid();
      }
    }else{
      if( $PROFIT_SUM_TXT > -1 ){
        $PROFIT_SUM_LABEL -> configure(-style =>'negatíve.TLabel');
        for($j = 0; $j <= $#WIDGETS; $j++){
          $WIDGETS[$j][4] -> g_grid();
        }
        $PROFIT_SUM_LABEL -> g_grid();
      }
    }
  }
  $PROFIT_SUM_TXT = $arr[1];
  
  if( $arr[0] > $LAST_LOG_NR ){
    Win32::Sound::Stop();
    Win32::Sound::Play($ALERT_SOUND,SND_ASYNC);
    $LAST_LOG_NR = $arr[0];
  }
}

sub flipWindow{
  if($FLIP_WINDOW == 0){
    for($i = 0; $i <= $#WIDGETS; $i++){
      $WIDGETS[$i][0]->g_grid(-row => 0, -column => $i+1);
      $WIDGETS[$i][4]->g_grid(-row => 1, -column => 0);
      
      $WIDGETS[$i][0] -> configure(-padding =>(($i == 0)?'2':'1').' 0 0 0');
      $WIDGETS[$i][2] -> configure(-padding => "0 -2 0 -1");
      $WIDGETS[$i][4] -> configure(-padding => "0 -2 0 -2");
      if( $PROFIT_SUM_TXT == 0 ){
        $WIDGETS[$i][4] -> g_grid_remove();
      }
    }
    $FLIP_WINDOW = 1;
  }else{
    for($i = 0; $i <= $#WIDGETS; $i++){
      $WIDGETS[$i][0]->g_grid(-row => $i+1, -column => 0);
      $WIDGETS[$i][4]->g_grid(-row => 0, -column => 1);
      
      $WIDGETS[$i][0] -> configure(-padding =>(($i == 0)?'0 2':'0 1').' 0 0');
      $WIDGETS[$i][2] -> configure(-padding => '-1 1 -1 -1');
      $WIDGETS[$i][4] -> configure(-padding => '-1 1 -1 -1');
      
      if( $PROFIT_SUM_TXT == 0 ){
        $WIDGETS[$i][4] -> g_grid_remove();
      }
    }
    $FLIP_WINDOW = 0;
  }
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

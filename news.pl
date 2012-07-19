#!/usr/bin/perl

use LWP::Simple;
use Time::Local;

our @IN;
our $ERR;
our $TIMEZONE = 5 * 3600; #5 hour

getstore("http://www.forexfactory.com/calendar.php#details=40989", "ppp.html");

exit;
sub process{
	# my $url = get 'http://www.forexfactory.com/calendar.php';
	# my @lines = split(/\n/, $url);
	my @lines = read_file("c:\\mt4\\experts\\files\\xxx.html");
	
	my @csv;
	my $date;
	my $tmp;
	my $nr = 0;
	my $i;
	
	for( $i = 0, $len = $#lines; $i < $len; $i++) {
		if( $lines[$i] =~ /^\s+(\S+ \d+)\s*$/ ){
			$date = $1;
			
		}elsif( $lines[$i] =~ /^\s+<span class="smallfont">([a-zA-Z0-9: ]+)<\/span>\s*$/ || $lines[$i] =~ /alt="Up Next".*>(.*)<\/span/ ){
			# month and day
			$IN[$nr][0] = $date;
			
			# hour and time
			$tmp = $1;
			if( $tmp =~ /\s*(\d+):(\d+)(am|pm)\s*/ ){
				if( $3 eq 'pm' ){
					$IN[$nr][1] = ($1+12).':'.$2;
				}else{
					$IN[$nr][1] = $1.':'.$2;
				}
			}elsif( $tmp =~ /\s*(All Day|Tentative)\s*/ ){
				$IN[$nr][1] = $1;
			}else{
				$ERR = 'Wrong hour or time '.$tmp.' ('.$lines[$i].')';
				return -1;
			}
			
		}elsif( $lines[$i] =~ /<span class="smallfont">([A-Z ]+)<\/span><\/td>\s*$/){
			# currency
			$IN[$nr][2] = $1;
			
		}elsif( $lines[$i] =~ /title="(Medium|High|Low|Non-Economic).*/){
			# priority
			$tmp = $1;
			if( $tmp eq 'High' ){
				$IN[$nr][3] = 3;
			}elsif( $tmp eq 'Medium' ){
				$IN[$nr][3] = 2;
			}elsif( $tmp eq 'Low' ){
				$IN[$nr][3] = 1;
			}else{
				$IN[$nr][3] = 0;
			}
			
		}elsif( $lines[$i] =~ /id="title_.*>\s*(.*)\s*</){
			# description
			$IN[$nr][4] = $1;
			$IN[$nr][4] =~ s/;/:/g;
			
		}elsif( $lines[$i] =~ /<div class="smallfont"><span class="\s*(.*)\s*">\s*(.*)\s*<\/span><\/div>\s*$/){
			# impact
			$IN[$nr][5] = $1;
			
			# Actual data and unit
			$tmp = $2;
			if( $tmp eq '' ){
				$IN[$nr][6] = '';
				$IN[$nr][7] = '-';
			}elsif( $tmp =~ /([\d\.\+\-]+)(.*)/ ){
				$IN[$nr][6] = $2;
				$IN[$nr][7] = $1;
			}else{
				$ERR = 'Unknown actual data '.$tmp.' ('.$IN[$nr][4].')';
				return -1;
			}
			
		}elsif( $lines[$i] =~ /calhigh.*<span class="smallfont">(.*)<\/span><\/td>\s*$/){
			# Forecast data
			$tmp = $1;
			if( $tmp eq '' ){
				$IN[$nr][8] = '-';
			}elsif( $tmp =~ /([\d\.\+\-]+)(.*)/ ){
				if( $IN[$nr][6] eq '' ){
					$IN[$nr][6] = $2;
				}elsif( $2 ne $IN[$nr][6] ){
					$ERR = 'Wrong Forecast unit '.$tmp.' ('.$IN[$nr][4].')';
					return -1;
				}
				$IN[$nr][8] = $1;
			}else{
				$ERR = 'Unknown forecast data '.$tmp.' ('.$IN[$nr][4].')';
				return -1;
			}
			
		}elsif( $lines[$i] =~ /calhigh.*<div class="smallfont">(.*)<\/div><\/span><\/td>\s*$/){
			# Previous data
			$tmp = $1;
			if( $tmp eq '' ){
				$IN[$nr][9] = '-';
			}elsif( $tmp =~ /([\d\.\+\-]+)(.*)/ ){
				if( $IN[$nr][6] eq '' ){
					$IN[$nr][6] = $2;
				}elsif( $2 ne $IN[$nr][6] ){
					$ERR = 'Wrong Previous unit: '.$tmp.' current unit:'.$IN[$nr][6].' ('.$IN[$nr][4].')';
					return -1;
				}
				$IN[$nr][9] = $1;
			}else{
				$ERR = 'Unknown Previous data '.$tmp.' ('.$IN[$nr][4].')';
				return -1;
			}
			$nr++;
		}
	}
	
	my $year = ((localtime)[5])+1900;
	my $mon;
	my $day;
	my $server_time;
	my $local_time;
	my $ts;
	my $prior;
	my $out = '';
	for( $i = 0, $len = $#IN; $i < $len; $i++ ){
	
		if( $IN[$i][0] =~ /\s*(\S+) (\d+)\s*/ ){
			$mon = getMonthId($1);
			$day = $2;
			
		}else{
			$ERR = 'Wrong month and day '.$IN[$i][0].' ('.$IN[$i][4].')';
			return -1;
		}
		
		if( $IN[$i][1] =~ /(\d+):(\d+)/ ){
			$ts = timelocal( 0, $2, $1, $day, $mon, $year ) + $TIMEZONE;
			$server_time = sprintf("%02d:%02d", (localtime($ts))[2], (localtime($ts))[1]);
			$tmp = $ts + 3600;
			$local_time = sprintf("%02d:%02d", (localtime($tmp))[2], (localtime($tmp))[1]);
		}else{
			$ts = timelocal( 0, 0, 0, $day, $mon, $year );
			$hour = '00';
			$min = '00';
		}
		

		#  timestamp     actual         forcast         prevous         unit       description     server_time      local_time        prio
		$out = $ts.';('.$IN[$i][7].'|'.$IN[$i][8].'|'.$IN[$i][9].')'.$IN[$i][6].' '.$IN[$i][4].';'.$server_time.';'.$local_time.';'.$IN[$i][3].';';
	}
}

our @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
sub getMonthId{
	for( my $i = 0; $i < $#months; $i++ ){
		if( $months[$i] eq $_[0] ){
			return $i;
		}
	}
	return -1;
}

sub read_file{
  open(DATA, $_[0]);
  my @lines = <DATA>;
  close(DATA);
  return @lines;
}

if( process() == -1 ){
	print $ERR;
}else{

}




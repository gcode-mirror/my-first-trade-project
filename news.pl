#!/usr/bin/perl

# BEGIN {
	# Win32::SetChildShowWindow(0) if defined &Win32::SetChildShowWindow
# };

use LWP::Simple;
use Time::Local;
use FindBin qw($Bin);
our $BASE_DIR = $Bin;
our $ERR;
our $TIMEZONE = 5 * 3600; #5 hour

# getstore("http://www.forexfactory.com/calendar.php?week=jul16.2012", "ppp.html");
# getstore("http://www.forexfactory.com/calendar.php?week=jul23.2012", "ppp2.html");

require $BASE_DIR.'\history.pl';

our @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

sub process{
	my $out = 'ok;';
	my $tmp;
	my $save_file = 0;
	my $year = ((localtime)[5])+1900;
	my ($month, $day, $date, $currency, $prio, $desc, $act, $forc, $prev, $unit, $ts, $avarage, $goodeffect, $max, $power, $desc2, $dif, $len, $unknown, $save_data);
	my @blocks;
	
	$tmp = (localtime(time))[6];
	# if( $tmp == 6 ){
		# $tmp = -2;
	# }elsif( $tmp == 0 ){
		# $tmp = -1;
	# }else{
		# $tmp--;
	# }
	$ts = time - ($tmp * 86400);
	$day = (localtime($ts))[3];
	$month = (localtime($ts))[4];
	my $filename = 'Calendar-'.sprintf ("%4d-%02d-%2d", $year, $month + 1, $day).'.csv';
	$month = lc($months[$month]);
	# print $filename;
	# exit;
	my $html = get 'http://www.forexfactory.com/calendar.php?week='.$month.$day.'.'.$year;
	
	# @blocks = read_file("c:\\mt4\\ppp.html");
	# my $html = '';
	# for(@blocks){
		# $html .= $_;
	# }
	
	$html = substr ($html, index( $html, '<tr class="calendar_row' ));
	$tmp = index( $html, '<tr class="calendar_row" data-eventid="">' );
	if( $tmp == -1 ){
		$tmp = index( $html, '</table>' );
	}
	$html = substr ($html, 0, $tmp);
	$html =~ s/\s*\n\s*//g;
	$html =~ s/\s{2,}/ /g;
		
	@blocks = split(/<\/tr><tr class="calendar_row" data-eventid="\d+">/, $html);
	
	# print $blocks[$#blocks - 1]."\n\n";
	# my @arr = split(/<\/td>/, $blocks[0]);
	# for(@arr){
		# print $_."\n\n";
	# }
	# exit;
	
	$month = $day = $date = $prio = $desc = $ts = '';
	my @currencies = qw(EUR AUD GBP JPY USD);
	my @lines;
	for(@blocks){
		@lines = split(/<\/td>/, $_);
		
		if( $lines[2] =~ />([A-Z]{3})$/ ){
			$currency =  $1;
			if( !grep $_ eq $currency, @currencies ){
				next;
			}
		}else{
			$out = 'Wrong currency '.$lines[2];
			last;
		}
		
		if( $lines[0] =~ />(\S{3}) (\d+)\s*<\/div>/ ){
			$day = $2;
			$date = $1.' '.$day.', '.$year;
			$month = getMonthId($1);
		}
		
		if( $lines[1] =~ />(\d+):(\d+)(am|pm)$/ ){
			$tmp = $1;
			if( $3 eq 'pm' ){
				$tmp += 12;
			}
			$ts = timelocal( 0, $2, $tmp, $day, $month, $year ) + $TIMEZONE;
		
		# }elsif( $lines[1] =~ />(All Day|Tentative)$/ ){
		}else{
			$ts = timelocal( 0, 0, 0, $day, $month, $year );
		}
		# else{
			# $out = 'Wrong time '.$lines[1];
			# last;
		# }
		
		if( $lines[3] =~ /title="(Medium|High|Low|Non-Economic).*/ ){
			$tmp = $1;
			if( $tmp eq 'High' ){
				$prio = 3;
			}elsif( $tmp eq 'Medium' ){
				$prio = 2;
			}elsif( $tmp eq 'Low' ){
				$prio = 1;
			}elsif( $tmp eq 'Non-Economic' ){
				$prio = 0;
			}
		}else{
			$out = 'Wrong priority '.$lines[3];
			last;
		}

		if( $lines[4] =~ /<div>\s*(.*)\s*<\/div>$/ ){
			$desc = $1;
			$desc =~ s/;/:/g;
			$desc =~ s/\\/\//g;
			$desc =~ s/'/\\'/g;
		}else{
			$out = 'Missing description '.$lines[4];
			last;
		}
		
		$lines[6] =~ s/<\/span>$//;
		if( $lines[6] =~ />([\d\.\+\-]*)([^<]*)$/ ){
			$unit = $2;
			$act = $1;
			if( $act eq '' ){
				$act = '-';
			}
		}else{
			$out = 'wrong actual data '.$lines[6];
			last;
		}
		
		$lines[7] =~ s/<\/span>$//;
		if( $lines[7] =~ />([\d\.\+\-]*)[^<]*$/ ){
			$forc = $1;
			if( $forc eq '' ){
				$forc = '-';
			}
		}else{
			$out = 'wrong actual data '.$lines[7];
			last;
		}
		
		$lines[8] =~ s/<\/span>$//;
		if( $lines[8] =~ />([\d\.\+\-]*)[^<]*$/ ){
			$prev = $1;
			if( $prev eq '' ){
				$prev = '-';
			}
		}else{
			$out = 'wrong actual data '.$lines[8];
			last;
		}
		
		$goodeffect = '-';
		if( $act ne '-' && $forc ne '-' && $act =~ /^-?[0-9]+\.[0-9]*$/ ){
			$avarage = 0;
			$dif = abs( $act - $forc );
			$max = $dif;
			$save_data = $unknown = 1;
			
			for my $k1 ( keys %$HISTORY_DATA ){
				if( $HISTORY_DATA->{ $k1 }->{ CURRENCY } eq $currency && $HISTORY_DATA->{ $k1 }->{ DESC } eq $desc ){
					$unknown = 0;
					$goodeffect = $HISTORY_DATA->{ $k1 }->{ GOODEFFECT };
					$len = scalar keys %{$HISTORY_DATA -> { $k1 } -> { HISTORY }};
					
					for my $k2 ( keys %{$HISTORY_DATA->{ $k1 }->{ HISTORY }} ){
						if( $HISTORY_DATA->{ $k1 }->{ HISTORY } -> { $k2 } -> { DATE } eq $date ){
							$save_data = 0;
						}
						$tmp = abs( $HISTORY_DATA->{ $k1 }->{ HISTORY } -> { $k2 } -> { ACT } - $HISTORY_DATA->{ $k1 }->{ HISTORY } -> { $k2 } -> { FORC } );
						$avarage += $tmp;
						if( $tmp > $max ){
							$max = $tmp;
						}
					}
					
					if( $save_data == 1 ){
						$HISTORY_DATA->{ $k1 }->{ HISTORY } -> { $len } -> { DATE => $date, ACT => $act, FORC => $forc, PREV => $prev };
						$save_file = 1;
						$avarage += $dif;
						$len++;
					}
					
					$avarage = $avarage / $len;
					
					if( $dif > $max * 0.7 ){
						$power = 3;
					}elsif( $dif > $avarage ){
						$power = 2;
					}else{
						$power = 1;
					}
					last;
				}
			}
			
			if( $unknown == 1 ){
				$max = $avarage = 0;
				$power = 0;
			}
			
		}else{
			$power = 1;
			$avarage = $max = $unknown = 0;
		}
		
		if( $avarage == 0 ){
			$desc2 = '-';
		}else{
			$desc2 = '('.sprintf("%.2g", $dif ).'|'.sprintf("%.2g", $avarage ).'|'.$max.')'.$unit;
		}
		
		$desc = '('.$act.'|'.$forc.'|'.$prev.')'.$unit.' '.$power.'x '.$desc;
		$out .= $currency.';'.$ts.';'.$desc.';'.$prio.';'.$goodeffect.';'.$power.';'.$desc2."\n";
	}
	
	if( $save_file == 1 ){
		# saveHistoryData();
	}
	
	# print $out;

	open(DAT,' > '.$BASE_DIR.'/experts/files/'.$filename) || die("Cannot Open File");
		print DAT $out;
	close(DAT);
}

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

sub saveHistoryData{
	my $out = '';
	my $idx = 0;
	$out .= 'our $X = 0;'."\n";
	$out .= 'our $HISTORY_DATA = {'."\n";
	for my $k1 ( sort keys %$HISTORY_DATA ){
		$out .= '  $X++ => { '."\n";
		
		for my $k2 ( sort keys %{$HISTORY_DATA->{ $k1 }} ){
				if( $k2 eq 'HISTORY' ){
					$out .= '    '.$k2.'=> {'."\n";
					
					for my $k3 ( sort keys %{$HISTORY_DATA->{ $k1 }->{ $k2 }} ){
						$out .= '      '.$k3.'=> {'."\n";
						
						for my $k4 ( keys %{$HISTORY_DATA->{ $k1 }->{ $k2 } ->{ $k3 }} ){
							$out .= '        '.$k4.'=> \''.$HISTORY_DATA->{ $k1 }{ $k2 }{ $k3}{ $k4 }."',\n";
						}
						$out .= '      '.'},'."\n";
						
					}
					$out .= '    '.'},'."\n";
					
				}else{
					$out .= '    '.$k2.'=> \''.$HISTORY_DATA->{ $k1 }{ $k2 }."',\n";
				}
		}
		$out .= "  },\n";
	}
	$out .= "};\n";
	$out .= '1;';
	
	open(DAT," > history.pl") || die("Cannot Open File");
		print DAT $out;
	close(DAT);
}

process();



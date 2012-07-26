
#!/usr/bin/perl
use FindBin qw($Bin);
use YAML::XS;
use Data::Dumper;
our $BASE_DIR = $Bin;

require 'history.pl';

sub uniqCheck{
	my @tmp;
	my $len = scalar keys %$HISTORY_DATA;
	my $curr;
	my $desc;
	my $i;
	my $j = 0;
	my $nr = 0;
	my $max_item;
	my $max_id;
	
	for( $i = 0; $i < $len; $i++ ){
		$curr = $HISTORY_DATA -> {$i} -> {CURRENCY};
		$desc = $HISTORY_DATA -> {$i} -> {DESC};
		$max_item = (scalar keys %{$HISTORY_DATA -> {$i} -> {HISTORY}});
		$max_id = $i;
		
		for( $j = $i + 1; $j < $len; $j++ ){
			if( $curr eq $HISTORY_DATA -> {$j} -> {CURRENCY} && $desc eq $HISTORY_DATA -> {$j} -> {DESC} ){
				if( (scalar keys %{$HISTORY_DATA -> {$j} -> {HISTORY}}) <= $max_item ){
					$tmp[$nr++] = $j;
				}else{
					$tmp[$nr++] = $max_id;
					$curr = $HISTORY_DATA -> {$j} -> {CURRENCY};
					$desc = $HISTORY_DATA -> {$j} -> {DESC};
					$max_item = (scalar keys %{$HISTORY_DATA -> {$j} -> {HISTORY}});
					$max_id = $j;
				}
			}
		}
	}
	
	for( $i = 0; $i < $#tmp; $i++ ){
		delete $HISTORY_DATA -> {$tmp[$i]};
	}
	
	for my $top ( sort keys %$HISTORY_DATA ){
		printf "%4s", (scalar keys %{$HISTORY_DATA -> {$top} -> {HISTORY}});
		print ' '.$HISTORY_DATA -> {$top} -> {CURRENCY}.' '.$HISTORY_DATA -> {$top} -> {DESC}."\n";
	}
	
	print "\n".$len.' > '.(scalar keys %$HISTORY_DATA)."\n";
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

uniqCheck();
saveHistoryData();
#!/usr/bin/perl

use LWP::Simple;



sub start{
	# my $url = get 'http://www.forexfactory.com/calendar.php';
	# my @lines = split(/\n/, $url);
	my @lines = read_file("c:\\mt4\\experts\\files\\xxx.html");
	
	my @csv;
	for( my $i = 0, $len = $#lines; $i < $len; $i++) {
	
	
		if( $lines[$i] =~ /^\s+<span class="smallfont">([a-zA-Z0-9: ]+)<\/span>\s*$/ || $lines[$i] =~ /alt="Up Next".*>(.*)<\/span/ ){
			print $1." ";
			
		}elsif( $lines[$i] =~ /<span class="smallfont">([A-Z ]+)<\/span><\/td>\s*$/){
			print $1." ";	
			
		}elsif( $lines[$i] =~ /title="(Medium|High|Low) Impact Expected"/){
			print $1." ";
			
		}elsif( $lines[$i] =~ /id="title_.*>(.*)</){
			print $1." ";
			
		}elsif( $lines[$i] =~ /<div class="smallfont"><span class="(.*)">(.*)<\/span><\/div>\s*$/){
			
			print $1." ".$2." ";
			
		}elsif( $lines[$i] =~ /calhigh.*<span class="smallfont">(.*)<\/span><\/td>\s*$/){
			
			print $1." ";
			
		}elsif( $lines[$i] =~ /calhigh.*<div class="smallfont">(.*)<\/div><\/span><\/td>\s*$/){
			
			print $1."\n";
		}
	
	}

}

sub read_file{
  open(DATA, $_[0]);
  my @lines = <DATA>;
  close(DATA);
  return @lines;
}

start();



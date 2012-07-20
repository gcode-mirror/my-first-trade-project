#!/usr/bin/perl -w
#use strict;
use strict;
use YAML::XS;
use Data::Dumper;
use FindBin qw($Bin);
our $BASE_DIR = $Bin;


use constant {
    SEC   => 0,
    MIN   => 1,
    HOUR  => 2,
    MDAY  => 3,
    MON   => 4,
    YEAR  => 5,
    WDAY  => 6,
    YDAY  => 7,
    ISDST => 8,
};

# =for comment
my $config = {
  0 =>{
    NAME => 'John Doe',
    ADDRESS => '123 Main St./',
    PHONE => {
      0 =>{
        DATE => 'dfgsdfg',
        FORC => 'dfgsdfg',
        PREV => 'dfgsdfg',
      }, 1 => {
        DATE => 'zzzz',
        FORC => 'jjjjj',
        PREV => 'pppp',
      }
    }
  },1 => {
    NAME => 'John Doe2',
    ADDRESS => '123 Main St.2',
    PHONE => {
      0 =>{
        DATE => 'dfgsdfg2',
        FORC => 'dfgsdfg2',
        PREV => 'dfgsdfg2',
      }, 1 => {
        DATE => 'zzzz2',
        FORC => 'jjjjj2',
        PREV => 'pppp2',
      },
    }
  },
# include $BASE_DIR.'\ppp2.pl';
};
# =cut
  
# my $config = YAML::XS::LoadFile('test.yml');


print "=================== print all ==============\n";
print Dump( $config ), "\n\n";

print "=================== get spec group ==============\n";
print Dump( $config -> {1} ), "\n\n";

print "=================== get spec attr ==============\n";
print  $config -> {1} -> {ADDRESS} , "\n\n";

print "=================== get by variable val ==============\n";
my $i = 1;
print  $config -> {1} -> {PHONE} -> {$i} -> {DATE}, "\n\n";

print "=================== add ==============\n";
$config -> {1} -> {PHONE} -> {2} = {
                                                            DATE => 'vvvvvv',
                                                            FORC => 'uuuóóü',
                                                            PREV => 'ééééééé',
                                                          };
                                                          
print  Dump($config -> {1} -> {PHONE} -> {2}), "\n\n";

print "=================== get size ==============\n";
print  scalar keys %$config , "\n\n";
my $p = $config -> {1} -> {PHONE};
print  scalar keys %$p, "\n\n";
print  scalar keys %{$config -> {1} -> {PHONE}}, "\n\n";

print "=================== for ==============\n";
open(DAT," >test.yml") || die("Cannot Open File");
for my $k1 ( keys %$config ) {
  print DAT '  ', $k1, ' => { ', "\n";
  
  for my $k2 ( keys %{$config->{ $k1 }} ) {
      if( $k2 eq 'PHONE' ){
        print DAT '    ', $k2, '=> {', "\n";
        
        for my $k3 ( keys %{$config->{ $k1 }->{ $k2 }} ) {
          print DAT '      ', $k3, '=> {', "\n";
          
          for my $k4 ( keys %{$config->{ $k1 }->{ $k2 } ->{ $k3 }} ) {
            print DAT '        ', $k4, '=> \'', $config->{ $k1 }{ $k2 }{ $k3}{ $k4 }, "',\n";
          }
          print DAT '      ', '},', "\n";
          
        }
        print DAT '    ', '},', "\n";
        
      }else{
        print DAT '    ', $k2, '=> \'', $config->{ $k1 }{ $k2 }, "',\n";
      }
  }
  print DAT "  },\n";
}
close(DAT);

print "=================== save ==============\n";
# open(DAT," >test.yml") || die("Cannot Open File");
  # print DAT Dump( $config ); 
# close(DAT);

print "=================== delete ==============\n";
print Dump( $config -> {1} -> {PHONE} ), "\n\n";
delete $config -> {1} -> {PHONE} -> {2};
print Dump( $config -> {1} -> {PHONE} ), "\n\n";





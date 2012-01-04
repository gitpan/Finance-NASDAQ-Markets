#!/usr/bin/perl  -w
package Finance::NASDAQ::Markets;
use warnings;
use strict;
use LWP::Simple qw($ua get);
$ua->timeout(15);
require Exporter;
use HTML::TableExtract;
use HTML::TableContentParser;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw/index sector/;

=head1 NAME


Finance::NASDAQ::Markets - Fetch real time markets

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS


#package main;
#use Data::Dumper;
#my @idx = Finance::NASDAQ::Markets::index();
#my @sec = Finance::NASDAQ::Markets::sector();
#print Dumper [@idx,@sec];

=cut



sub _trim
{
    my $string = shift;
    $string =  "" unless  $string;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    $string =~ s/\t//;
    $string =~ s/^\s//;
    return $string;
}

#http://quotes.nasdaq.com/aspx/marketindices.aspx
#http://quotes.nasdaq.com/aspx/sectorindices.aspx

sub sector {  
return getdata("http://quotes.nasdaq.com/aspx/sectorindices.aspx");
}
sub index {  
return getdata("http://quotes.nasdaq.com/aspx/marketindices.aspx");
}

sub getdata {  
    my ($url) = @_;
    my @ids = qw/_LastSale _NetChange _PctChange _Volume/;
    my $content;
    my @set=()  ;
    $content = get $url;
 
    warn "NASDAQ is down" and return unless defined $content;


    my $p = HTML::TableContentParser->new();
    my @check=();
    my $tables = $p->parse($content);
         for my $t (@$tables) {
           for my $r (@{$t->{rows}}) {
          #   print "Row: ";
             for my $c (@{$r->{cells}}) {
                if($c->{data}=~/redarrow/){
                   push @check,"-";
                }
                if($c->{data}=~/greenarrow/){
                   push @check,"+";
                }
             }
             #print "\n";
           }
         }

    
     my $te = HTML::TableExtract->new( headers => [("Symbol",  "Name", "Index Value","Change Net / %", "High", "Low")] );
        $te->parse($content);
    
        my $i=0;
        foreach my  $ts ($te->tables) {
           
           foreach my $row ($ts->rows) {
          #print Dumper $ts;



           map  {$_=~s/(InfoQuote|Charting)//g; $_=_trim($_)} @$row;
           
            if(defined($check[$i])) {
            
               if($check[$i] =~ /-/){
                push @$row,'down';
               }elsif($check[$i] =~/\+/){
                push @$row,'up';
               }
              
                
                $row->[3] =~s/[^\0-\x80][^\0-\x80]/ $check[$i]/g;
                
                
                #print Dumper split("",$row->[3]);
              
                push @set,[@$row];
                $i++;
               }
           }

        }


    
    return @set;

}


1;

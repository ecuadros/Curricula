#!/usr/bin/perl -w

use warnings;
use strict;
use Text::Balanced qw<extract_bracketed>;


#my @lines = <IN>;

while ( <DATA> ) 
{ 

    ## Remove '\n' from input string.
    chomp;

    print "*" x 20, "\n";
    printf qq|%s\n|, $_; 
    print "." x 20, "\n";

    ## Extract all characters just before first curly bracket.
    my @str_parts = extract_bracketed( $_, '{}', '[^{}]*' );

    if ( $str_parts[2] ) { 
        printf qq|%s\n|, $str_parts[2];
    }   

    my $str_without_prefix = "@str_parts[0,1]";
    ## Extract data of balanced curly brackets, remove leading and trailing
    ## spaces and print.
    while ( my $match = extract_bracketed( $str_without_prefix, '{}' ) ) { 
        $match =~ s/^\s+//;
        $match =~ s/\s+$//;
        printf qq|%s\n|, $match;

    }   

    print "\n";
}

__DATA__
abc {{xyz} abc} {xyz}
{abc} {{xyz{jkl}}} abc
\newcommand{\SPEconomiesofComputingTopicUse}{El uso de la ingeniería económica para hacer frente a las finanzas.\xspace}
{xyz}
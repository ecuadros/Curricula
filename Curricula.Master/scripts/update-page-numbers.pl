#!/usr/bin/perl -w
use Data::Dumper;
use Lib::Common;
use strict;

my $file = "";
if( defined($ENV{'CurriculaParam'}))	{ $Common::command = $ENV{'CurriculaParam'};	}
if(defined($ARGV[0])) { $Common::command = shift or Util::halt("There is no command to process (i.e. AREA-INST)");	}

sub main()
{
        Common::setup();
        my $lang = $Common::config{language_without_accents};
        Common::read_pagerefs();
        Common::process_courses();

        Common::update_page_numbers(Common::get_expanded_template("out-big-graph-curricula-dot-file", $lang));
        Common::update_page_numbers_for_all_courses_maps();	
}

main();

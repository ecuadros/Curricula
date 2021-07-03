#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Lib::Common;
# use Cwd;

$Common::command = shift or Util::halt("There is no command to process (i.e. AREA-INST)");

sub main()
{	
	Common::set_initial_configuration($Common::command);
	Common::parse_bok();
# 	print Dumper(\%{$bok{AL}{KU}}); exit;
	Common::gen_bok();
	Util::print_message("End process-bok ...\n");
}

main();
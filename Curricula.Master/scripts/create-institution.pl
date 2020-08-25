#!/usr/bin/perl -w

use strict;
use Lib::Common;
use Lib::GenSyllabi;
use Lib::GeneralInfo;
use Data::Dumper;
my $how_to_use_message  = "Wrong parameters ... Use like this:\n ";
   $how_to_use_message .= "./scripts/create-institution.pl new-country new-big-area-name new-area new-institution source-to-copy-from\n";
   $how_to_use_message .= "i.e.: ./scripts/create-institution.pl Brasil Computing CS SBC CS-UTEC\n";

my $total_args = $#ARGV + 1;
#if( $total_args != 5 )
#{	Util::print_error($how_to_use_message);	exit; }

my $newcountry 		= $ARGV[0];
my $newdiscipline 	= $ARGV[1];
my $newarea			= $ARGV[2];
my $newinstitution	= $ARGV[3];
$Common::command 	= $ARGV[4];

sub main()
{
	Common::setup();
	my $institution_info_file = Common::get_template("this-institution-info-file");
	my $NewInstDir = Common::GetInstDir($newcountry, $newdiscipline, $newarea, $newinstitution);
	my $command = "mkdir -p $NewInstDir";
	Util::print_message("Creating directory: $NewInstDir");
	system($command);
	$command = "cp $institution_info_file $NewInstDir/.";
	Util::print_message("Copying institution file \"$command\"");
	system($command);
	exit;
	#$command = "cp $institution_info_file $new_inst_dir"
	Util::print_message("create-institution.pl finished ok ...");
}

main();


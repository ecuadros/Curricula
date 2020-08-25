#!/usr/bin/perl -w

use strict;
use Data::Dumper; 
use Lib::Common;
use Lib::GenSyllabi;

if( defined($ENV{'CurriculaParam'}))	{ $Common::command = $ENV{'CurriculaParam'};	}
if(defined($ARGV[0])) { $Common::command = shift or Util::halt("There is no command to process (i.e. AREA-INST)");	}

# flush stdout with every print -- gives better feedback during
# long computations
$| = 1;

sub main()
{
# 	Util::begin_time();
	Common::setup(); 
	my $lang = $Common::config{language_without_accents};
	Common::read_faculty(); 
	Common::read_distribution();
	Common::read_aditional_info_for_silabos(); # Days, time for each class, etc.
	
	Common::detect_link_for_courses();
	#Common::generate_faculty_info();
	Common::update_svg_links($lang);

# 	my $maintxt		= Util::read_file(Common::get_template("curricula-main"));
# 	my $output_file = Common::get_template("unified-main-file");
#  	Util::write_file($output_file, $maintxt);
}

main();


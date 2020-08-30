#!/usr/bin/perl -w

use strict;
use Lib::Common;
use Lib::GenSyllabi;
use Lib::GeneralInfo;
use Data::Dumper;
use Text::Balanced qw(extract_multiple extract_bracketed);

if(defined($ARGV[0])) { $Common::command = shift or Util::halt("There is no command to process (i.e. AREA-INST)");	}

# ok, Here we replace \'a by á, etc 
sub replacecodes()
{
	Util::precondition("parse_courses");
	Common::replace_special_characters_in_syllabi();
}

sub generate_general_info()
{	
	my $lang = $Common::config{language_without_accents};
	Common::read_all_min_max();
	Util::precondition("gen_syllabi"); 
	
	GeneralInfo::generate_lu_index();
	foreach my $lang (@{$Common::config{SyllabusLangsList}})
	{
		GeneralInfo::generate_description("prefix", $lang);			# CS: Computer Science, ...
	}
	GeneralInfo::generate_course_tables($lang); 					# Tables by semester
	GeneralInfo::generate_laboratories(); 							# List of Laboratories
# 	GeneralInfo::generate_distribution_area_by_semester();			# Table area by semester
	GeneralInfo::generate_distribution_credits_by_area_by_semester();
	
	GeneralInfo::generate_pie("credits");
	GeneralInfo::generate_pie("hours");
	GeneralInfo::generate_pie_by_levels();

	foreach my $lang (@{$Common::config{SyllabusLangsList}})
	{
		Util::print_color("Generating Posters in $lang ...");
		foreach my $size ("small", "big")
		{	
			GeneralInfo::generate_curricula_in_dot($size, $lang);
			if( $size eq "small" )
			{
				my $InFile  = Common::get_template("in-$size-graph-curricula-file"); 					# "in-small-graph-curricula-file",	"in-big-graph-curricula-file"
				my $OutFile = Common::get_expanded_template("out-$size-graph-curricula-file", $lang);	# "out-small-graph-curricula-file", "out-big-graph-curricula-file"
				Common::copy_file_expanding_tags($InFile, $OutFile, $lang);
			}
			if( $size eq "big" )
			{
				GeneralInfo::generate_map_of_courses_by_outcome($size, $lang);
			}
		}
		#GeneralInfo::generate_curricula_in_dot("big", $lang); 
		GeneralInfo::generate_poster($lang);
		Util::print_color("Common::config{meta_tags}{IN_TEX_DIR}=$Common::config{meta_tags}{IN_TEX_DIR}");
		Util::print_color("Common::config{meta_tags}{OUTPUT_TEX_DIR}=$Common::config{meta_tags}{OUTPUT_TEX_DIR}");
		GeneralInfo::generate_all_outcomes_by_course($lang);
	}
	#foreach my $lang (@{$Common::config{SyllabusLangsList}})
	#{
	#	Util::print_color("Generating Posters in $lang ...");
	#	GeneralInfo::generate_curricula_in_dot("small", $lang);
	#	#error??? system("cp ".Common::get_template("in-small-graph-curricula-file")." ".Common::ExpandTags(Common::get_template("out-small-graph-curricula-file"), $lang);
	#	GeneralInfo::generate_curricula_in_dot("big", $lang);   
	#	GeneralInfo::generate_poster($lang);
	#	#GeneralInfo::generate_all_outcomes_by_course($lang);
	#}
	GeneralInfo::generate_all_topics_by_course($lang);
	#Util::print_message("Check point ... generate_general_info() ...");  exit;
	GeneralInfo::generate_list_of_outcomes();
	GeneralInfo::generate_list_of_courses_by_outcome($lang);
	GeneralInfo::generate_list_of_courses_by_specific_outcome($lang);
	GeneralInfo::generate_table_of_courses_by_specific_outcome($lang);
 
	GeneralInfo::generate_list_of_courses_by_area($lang);
	foreach my $lang (@{$Common::config{SyllabusLangsList}})
	{
		GeneralInfo::generate_compatibility_with_standards($lang);
		#	GeneralInfo::generate_courses_by_professor();
	# 	GeneralInfo::generate_faculty_info();
		GeneralInfo::generate_courses_by_professor($lang);
		GeneralInfo::generate_professor_by_course($lang);
	}
 	GeneralInfo::process_equivalences();
# 	generate_sql_for_new_courses();
# 	generate_tables_for_advance();
# 	generate_courses_for_advance();
	Common::write_files_to_be_changed();
}

sub copy_basic_files()
{
	##system("cp ".Common::get_template("out-current-institution-file")." ".Common::get_template("OutputTexDir"));
	#system("cp ".Common::get_template("InLogosDir")."/$Common::config{institution}* ".Common::get_template("OutputFigsDir"));
	#system("cp ".Common::get_template("in-small-graph-curricula-file")." ".Common::get_template("OutputTexDir"));
	##system("cp ".Common::get_template("in-pdf-icon-file")." ".Common::get_template("OutputHtmlFigsDir"));
	#exit;
}

sub main()
{	
	Util::begin_time();
	Common::setup(); 
	foreach my $lang (@{$Common::config{SyllabusLangsList}})
	{
		Util::print_message("Generating BOK in $lang ...");
	    Common::generate_bok($lang);
		#$Util::flag = 100;
	    Util::print_message("Reading BOK in $lang ...");
		Common::read_bok($lang);  
		#Common::parse_bok($lang);
	} 
	Common::gen_only_macros();
    GeneralInfo::detect_critical_path(); 
	
	GenSyllabi::process_syllabi();
	
	foreach my $lang (@{$Common::config{SyllabusLangsList}})
	{
	    Util::print_color("Generating books in $lang ...");
		GenSyllabi::gen_book_of_descriptions($lang);
	    #GenSyllabi::gen_list_of_units_by_course();
	    GenSyllabi::gen_book_of_bibliography($lang);
	    GenSyllabi::generate_team_file($lang);
	}
	generate_general_info();

    #copy_basic_files();
#   Util::generate_batch_to_gen_figs(Common::get_template("out-batch-to-gen-figs-file"));
# 	
# 	Common::generate_html_index_by_country();
 	Common::shutdown();
	Util::print_time_elapsed();
}

main();


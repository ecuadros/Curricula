package GenSyllabi;
use warnings;
use Data::Dumper;
use Carp::Assert;
use Scalar::Util qw(blessed dualvar isdual readonly refaddr reftype
                        tainted weaken isweak isvstring looks_like_number
                        set_prototype);
                        # and other useful utils appearing below
use Switch;
use Lib::Common;
use strict;
my @versioned_environments = ("outcomes", "specificoutcomes", "competences");

sub get_environment($$$)
{
	my ($codcour, $txt, $env) = (@_);
	if($txt =~ m/\\begin\{$env\}\s*\n((?:.|\n)*)\\end\{$env\}/g)
	{	return $1;	}
# 	Util::print_warning("$codcour does not have $env");
	return "";
}

sub process_syllabus_units($$$$)
{
	my ($codcour, $lang, $syllabus_in, $unit_struct)	= (@_);
	my ($unit_count, $total_hours) 			= (0, 0);
	my %accu_hours     				= ();

	# \begin{unit}{\AL}{}   {Guttag13,Thompson11,Zelle10}{2}{C1,C5}
	$unit_count       = 0;
	my $units_adjusted = "";
	foreach my $line (split("\n", $syllabus_in))
	{
		if($line =~ m/\\begin\{unit\}(.*)(\r|\n)*$/ )
		{
			my $params = $1;
			$unit_count++;
			if($params =~ m/\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}/ )
			{
				#Util::print_color("codcour=$codcour, $line good line !");
			}
			elsif($params =~ m/\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}/ )
			{
				my ($p1, $p2, $p3, $p4) 	= ($1, $2, $3, $4);
				my ($pm1, $pm2, $pm3, $pm4) = (Common::replace_special_chars($p1), Common::replace_special_chars($p2), Common::replace_special_chars($p3), Common::replace_special_chars($p4));
				Util::print_warning("codcour=$codcour\n\\begin\{unit\}$params wrong number of parameters?"),
				$syllabus_in =~ s/\\begin\{unit\}\{$pm1\}\{$pm2\}\{$pm3\}\{$pm4\}/\\begin\{unit\}\{$p1\}\{\}\{$p2\}\{$p3\}\{$p4\}/g;
				Util::print_color("Changed to:\n$line\n");
			}
			else
			{
				Util::print_error("codcour=$codcour, did you invented a new format for units? ($line)");
			}
			if($line =~ m/\\begin\{unit\}\{.*?\}\{.*?\}\{.*?\}\{(.*?)\}\{.*?\}\s*((?:.|\n)*?)\\end\{unit\}/)
			{
				$unit_count++;
				my $nhours 	= $1;
				$total_hours   += $nhours;
				if( not looks_like_number($nhours) )
				{	Util::print_warning("Codcour=$codcour, Unit $unit_count, number of hours is wrong ($nhours)");		}
				$accu_hours{$unit_count}  = $total_hours;
			}
			$units_adjusted .= $line;
		}
	}

	my $all_units_txt     = "";
	my $unit_captions = "";
	$unit_count       = 0;

	my $sep = "";
	while($syllabus_in =~ m/\\begin\{unit\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\s*((?:.|\n)*?)\\end\{unit\}/g)
	{
		$unit_count++;
		$Common::course_info{$codcour}{n_units}++;
		my ($unit_caption, $alternative_caption, $unit_bibitems, $unit_hours, $level_of_competence, $unit_body) = ($1, $2, $3, $4, $5, $6);
		$unit_bibitems =~ s/ //g;

		push(@{$Common::course_info{$codcour}{units}{unit_caption}}, $unit_caption);
		push(@{$Common::course_info{$codcour}{units}{alternative_caption}}, $alternative_caption);
		push(@{$Common::course_info{$codcour}{units}{bib_items}}   , $unit_bibitems);
		push(@{$Common::course_info{$codcour}{units}{hours}}       , $unit_hours);
		push(@{$Common::course_info{$codcour}{units}{level_of_competence}} , $level_of_competence);
		$Common::course_info{$codcour}{allbibitems} .= "$sep$unit_bibitems";

		$unit_captions   .= "\\item $unit_caption\n";
		my %map = ();
		$map{UNIT_TITLE}  	= $unit_caption;
		$map{UNIT_BIBITEMS}	= $unit_bibitems;

		$map{LEVEL_OF_COMPETENCE}	= $level_of_competence;
		if($unit_caption =~ m/^\\(.*)/)
		{
			$unit_caption = $1;
			#Util::print_message("TODO Course: $codcour: \\$unit_caption found ...");
			#print Dumper (\%$Common::config{topics_priority}); exit;

			#if( not defined($Common::config{topics_priority}{$unit_caption}) )
			#{	Util::print_color("process_syllabus_units: course: $codcour ignoring unit \\$unit_caption for map_hours_unit_by_course ...");	}
			#else
			#{
				if(not defined($Common::map_hours_unit_by_course{$lang}{$unit_caption}{$codcour}))
				{	$Common::map_hours_unit_by_course{$lang}{$unit_caption}{$codcour} = 0;		}
				$Common::map_hours_unit_by_course{$lang}{$unit_caption}{$codcour} += $unit_hours;
			#}

			if(not defined($Common::acc_hours_by_course{$lang}{$codcour}))
			{	$Common::acc_hours_by_course{$lang}{$codcour}  = 0;						}
			$Common::acc_hours_by_course{$lang}{$codcour} += $unit_hours;

			if(not defined($Common::acc_hours_by_course{$lang}{$unit_caption}))
			{	$Common::acc_hours_by_unit{$lang}{$unit_caption}  = 0;						}
			$Common::acc_hours_by_unit{$lang}{$unit_caption} += $unit_hours;

# 			if( $unit_caption eq "DSSetsRelationsandFunctions" )
# 			{	print Dumper (\%Common::map_hours_unit_by_course{$lang}{$unit_caption}); 		}
		}
		$sep = ",";
		my ($topics, $unitgoals) = ("", "");
		if($unit_body =~ m/(\\begin\{topics\}\s*((?:.|\n)*?)\\end\{topics\})/g)
		{	$topics = $1; }
		elsif($unit_body =~ m/(\\.*?AllTopics)/g)
		{	$topics = $1; }

		if($unit_body =~ m/(\\begin\{learningoutcomes\}\s*(?:.|\n)*?\\end\{learningoutcomes\})/g)
		{	$unitgoals = $1; }
		elsif($unit_body =~ m/(\\.*?AllObjectives)/g)
		{	$unitgoals = $1; }
		push(@{$Common::course_info{$codcour}{units}{topics}},   $topics);
		push(@{$Common::course_info{$codcour}{units}{unitgoals}}, $unitgoals);

		my $thisunit            = $unit_struct;
		$map{HOURS}		= "$unit_hours";
		$map{FULL_HOURS}	= "$unit_hours $Common::config{dictionary}{hours}";
		$map{UNIT_GOAL}		= $unitgoals;
		$map{UNIT_CONTENT}	= $topics;
		$map{PERCENTAGE} 	= 0;
		$map{PERCENTAGE} 	= int(100*$accu_hours{$unit_count}/$total_hours+0.5) if($total_hours  > 0 );

		$sep = "";
		my $bib_citations = "";
		foreach my $bibitem (split(",", $unit_bibitems))
		{	$bib_citations .= "$sep\\cite{$bibitem}";	$sep = ", ";		}
		$map{CITATIONS} = $bib_citations;
		$thisunit = Common::replace_tags_from_hash($thisunit, "--", "--", %map);
		$all_units_txt .= $thisunit;
	}
	Util::check_point("process_syllabus_units");
	return ($all_units_txt, $unit_captions, $syllabus_in );
}

sub get_common_file($$$)
{
	my ($fullname, $codcour, $lang)   = (@_);
	my $InLangCommonDir = Common::get_template("InLangCommonDir");
	#Util::print_message("InLangCommonDir=$InLangCommonDir ...");
	my $InLangDir 		= Common::replace_special_chars(Common::get_expanded_template("InLangDir", $lang));

	my $PostfixDir = "";
	my $CommonTexFile	= "";
	if($fullname =~ m/$InLangDir\/(.*)\/.*\.tex/)
	{	$PostfixDir 	= $1;
		#Util::print_message("PostfixDir=$PostfixDir");
		$CommonTexFile	= "$InLangCommonDir/$PostfixDir/$codcour.tex";
		return $CommonTexFile;
	}
	Util::print_message("InLangCommonDir=$InLangCommonDir ...");
	Util::print_message("InLangDir=$InLangDir ...");
	Util::print_message("PostfixDir=$PostfixDir ...");
	Util::print_error("Something wrong with: get_common_file($fullname, $codcour, $lang)");
}

my %macro_for_env = ("outcomes"           => "ShowOutcome", 
					"competences"         => "ShowCompetence",
					"specificoutcomes"	  => "ShowSpecificOutcome",
					);

sub parse_environments_in_header($$$$)
{
	my ($codcour, $lang, $syllabus_in, $fullname)   = (@_);
	#$syllabus_in =~ s/\\ExpandOutcome\{/\\ShowOutcome\{/g;
	#$syllabus_in =~ s/\\Competence\{/\\ShowCompetence\{/g;
	#$syllabus_in =~ s/\{unitgoals\}/\{learningoutcomes\}/g;
	my $version = $Common::config{OutcomesVersion};
	#Util::print_message("parse_environments_in_header($fullname ...) !");
	foreach my $env (@versioned_environments)
	{
		$Common::course_info{$codcour}{$lang}{$env}{$version}{txt} 	= $1;
		$Common::course_info{$codcour}{$lang}{$env}{$version}{count} = 0;
		$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized}	= "";
		#Util::print_message("Common::course_info{$codcour}{$lang}{$env}{$version}{txt}=\n$body");
		#print Dumper(\%{$Common::course_info{$codcour}{outcomes}});
		#my $copy_syllabus_in = $syllabus_in;
		if( $syllabus_in =~ m/\\begin\{$env\}\{$version\}\s*\n((?:.|\n)*?)\\end\{$env\}/g) # legacy version of this environment
		{
			#Util::print_message("\\begin{$env}{$version} detected !");
			$Common::course_info{$codcour}{$lang}{$env}{$version}{txt} = $1;
			foreach my $one_line ( split("\n", $Common::course_info{$codcour}{$lang}{$env}{$version}{txt}) )
			{
				my ($key, $tail)     = ("", "");
				my $reg_exp =  "\\\\".$macro_for_env{$env}."(.*)";
				if( $one_line =~ m/$reg_exp/g )
				{
					($tail) = ($1);
					my @params = $tail =~ m/\{(.*?)\}/g;
					switch($env)
					{	case ["outcomes", "competences"]
						{ 	#print $env;
							$Common::course_info{$codcour}{$lang}{$env}{$version}{$params[0]} = $params[1];
							$Common::config{course_by_outcome}{$params[0]}{$codcour} = "";
							#Util::print_message("Common::config{course_by_outcome}{$params[0]}{$codcour}=$Common::config{course_by_outcome}{$params[0]}{$codcour}");
							#exit;
						}	#\% ($codcour, $semester, $lang)
						case "specificoutcomes"  
						{	# Save the specific outcome
							my $specificoutcome = "$params[0]$params[1]";
							$Common::course_info{$codcour}{$lang}{$env}{$version}{$specificoutcome} = $params[2];
							$Common::course_info{$codcour}{$lang}{outcomes}{$version}{specificoutcomes}{$specificoutcome} = $params[2];
							$Common::config{course_by_specificoutcome}{$params[0]}{$params[1]}{$codcour} = "";
							#$config{specificoutcome}{$code}{$number}{label}    = $2;
							#$config{specificoutcome}{$code}{$number}{priority} 
						}
					}
					$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized}  	.= "\\item \\".$macro_for_env{$env};
					foreach my $param (@params)
					{	$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized} .= "{$param}";		}
					$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized}		.= "\n";
					$Common::course_info{$codcour}{$lang}{$env}{$version}{count}++;
					my $prefix	        = "";
					if(defined($Common::config{$env."_map"}) and defined($Common::config{$env."_map"}{$key}) ) # outcome: a), b), c) ... Competence
					{	$prefix = $Common::config{$env."_map"}{$key};	}
					if( $env eq "outcomes")
					{	$Common::config{course_by_outcome}{$key}{$codcour} = "";	}
				}
			}
		}
		else
		{
			$Common::error{$codcour}{$lang}{file} = $fullname;
			$Common::error{$codcour}{$lang}{$env} = "I did not find $env"."{$version}";
		}
	}
}

sub get_professors_info($$)
{
	my ($codcour, $lang) 	= (@_);
	my %map 		= ("PROFESSOR_NAMES" => "", "PROFESSOR_SHORT_CVS" => "", "PROFESSOR_JUST_GRADE_AND_FULLNAME" => "");
	my $sep    		= "";
	if(defined($Common::config{distribution}{$codcour}))
	{
		my $first = 1;
		#print Dumper(\%Common::professor_role_order); exit;
		foreach my $role  ( sort {$Common::professor_role_order{$a} <=> $Common::professor_role_order{$b}}
							keys %Common::professor_role_order)
		{
			#print Dumper(\%{$Common::config{distribution}{$codcour}{$role}});
			my $count 				= 0;
			my $PROFESSOR_SHORT_CVS = "";
			foreach my $email (sort {$Common::config{faculty}{$b}{fields}{degreelevel} <=> $Common::config{faculty}{$a}{fields}{degreelevel} ||
									 $Common::config{faculty}{$a}{fields}{dedication}  cmp $Common::config{faculty}{$b}{fields}{dedication} ||
									 $Common::config{faculty}{$a}{fields}{name}        cmp $Common::config{faculty}{$b}{fields}{name}}
								keys %{$Common::config{distribution}{$codcour}{$role}}
							  )
			{
					if( $Common::config{faculty}{$email}{fields}{degreelevel} >= $Common::config{degrees}{MasterPT} )
					{
						my $coordinator = "";
						#if( $role eq "C" )
						#{	$coordinator = "~(\\textbf{$Common::config{dictionaries}{$lang}{Coordinator}})";	$first = 0;		}
						$map{PROFESSOR_NAMES} 	.= "$Common::config{faculty}{$email}{fields}{name} ";
						$PROFESSOR_SHORT_CVS	.= "\\item $Common::config{faculty}{$email}{fields}{name} <$email>$coordinator\n";
						$PROFESSOR_SHORT_CVS 	.= "\\vspace{-0.2cm}\n";
						$PROFESSOR_SHORT_CVS 	.= "\\begin{itemize}[noitemsep]\n";
						$PROFESSOR_SHORT_CVS 	.= "$Common::config{faculty}{$email}{fields}{shortcv}{$lang}";
						$PROFESSOR_SHORT_CVS 	.= "\\end{itemize}\n\n";
						$count++;
						#$map{PROFESSOR_JUST_GRADE_AND_FULLNAME} .= "$sep$Common::config{faculty}{$email}{fields}{title} $Common::config{faculty}{$email}{fields}{name}";
					}
					$sep = ", ";
			}
			if( $count > 0 )
			{	$map{PROFESSOR_SHORT_CVS} .= "\\noindent \\textbf{$Common::config{dictionaries}{$lang}{professor_role_label}{$role}}\n";
				$map{PROFESSOR_SHORT_CVS} .= "\\begin{itemize}[noitemsep]\n";
				$map{PROFESSOR_SHORT_CVS} .= $PROFESSOR_SHORT_CVS;
				$map{PROFESSOR_SHORT_CVS} .= "\\end{itemize}\n";
				#print Dumper (\%{$Common::config{dictionaries}{$lang}{professor_role_label}});
				#exit;
			}
		}
		#exit; #role
	}
	else
	{
 		Util::print_soft_error("There is no professor assigned to $codcour (Sem #$Common::course_info{$codcour}{semester})");
	}
	return ($map{PROFESSOR_NAMES}, $map{PROFESSOR_SHORT_CVS});
}

sub get_prerrequisites_info($$)
{
	my ($codcour, $lang) = (@_);
	my %map 		= ();
	if($Common::course_info{$codcour}{n_prereq} == 0)
	{	$map{PREREQUISITES_JUST_CODES}	= $Common::config{dictionaries}{$lang}{None};
        $map{PREREQUISITES}             = $Common::config{dictionaries}{$lang}{None};
	}
	else
	{
        $map{PREREQUISITES_JUST_CODES}	= $Common::course_info{$codcour}{prerequisites_just_codes};
        my $output = "";
        if( scalar(@{$Common::course_info{$codcour}{$lang}{code_name_and_sem_prerequisites}}) == 1 )
        {   $output = $Common::course_info{$codcour}{$lang}{code_name_and_sem_prerequisites}[0];    }
        else
        {   foreach my $txt ( @{$Common::course_info{$codcour}{$lang}{code_name_and_sem_prerequisites}} )
            {   $output .= "\t\t \\item $txt\n";        }
            $output = "\\begin{itemize}\n$output\\end{itemize}";
        }
        $map{PREREQUISITES} 			= $output;
	}
	return ($map{PREREQUISITES_JUST_CODES}, $map{PREREQUISITES});
}

sub get_formatted_skills($$$$$)
{
	my ($codcour, $env, $version, $lang, $fullname) = (@_);
	my %map = ("FULL_SPECIFIC" => "", "SPECIFIC_ITEMS" => "");
	my $EnvforOutcomes = $Common::config{EnvforOutcomes};
	$map{FULL_SPECIFIC}	= "";
	if($Common::course_info{$codcour}{$lang}{$env}{$version}{count} == 0)
	{	Util::print_warning("Course $codcour ... no {$env}{$version} detected ... assuming an empty one!"); 
		$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized} = "\\item \\colorbox{red}{No$env}\n";
	}
	#Util::print_message("Common::course_info{$codcour}{$lang}{$env}{$version}{count}=$Common::course_info{$codcour}{$lang}{$env}{$version}{count}"); exit;
	if( defined($Common::course_info{$codcour}{$lang}{$env}{$version}) )
	{	$map{FULL_SPECIFIC}	= "\\begin{$EnvforOutcomes}\n$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized}\\end{$EnvforOutcomes}";	}
	else{	Util::print_warning("There is no $env ($version) defined for $codcour ($fullname)"); 	}
	$map{SPECIFIC_ITEMS}	= $Common::course_info{$codcour}{$lang}{$env}{$version}{itemized};
	return ($map{FULL_SPECIFIC}, $map{SPECIFIC_ITEMS});
}

sub init_course_units_vars($)
{
	my ($codcour) = (@_);
	$Common::course_info{$codcour}{allbibitems}         = "";
	$Common::course_info{$codcour}{n_units}				= 0;
	$Common::course_info{$codcour}{units}{unit_caption}	= [];
	$Common::course_info{$codcour}{units}{bib_items}	= [];
	$Common::course_info{$codcour}{units}{hours}		= [];
	$Common::course_info{$codcour}{units}{bloom_level}	= [];
	$Common::course_info{$codcour}{units}{topics}    	= [];
	$Common::course_info{$codcour}{units}{unitgoals}	= [];
}

# ok
sub read_syllabus_info($$$)
{
	my ($codcour, $semester, $lang)   = (@_);
	my $fullname 	= Common::get_syllabus_full_path($codcour, $semester, $lang);
	my $syllabus_in	= Util::read_file($fullname);
	init_course_units_vars($codcour);
	my $version = $Common::config{OutcomesVersion};
 	#if($codcour =~ m/CS2H/g)
	#{	Util::print_message("GenSyllabi::read_syllabus_info $codcour ...");  }

	my $CommonTexFile = get_common_file($fullname, $codcour, $lang);
	if( -e $CommonTexFile )
	{
		my $CommonTxt = Util::read_file($CommonTexFile);
		$syllabus_in =~ s/--COMMON-CONTENT--/$CommonTxt/g;
		#Util::print_color($syllabus_in);
		#exit;
	}
	#Util::print_message("CommonTexFile=$CommonTexFile ..."); exit;
	$syllabus_in = Common::replace_accents($syllabus_in);
	while($syllabus_in =~ m/\n\n\n/)
	{	$syllabus_in =~ s/\n\n\n/\n\n/g;	}
 	#my $codcour     = Common::get_alias($codcour);
	my $course_name = $Common::course_info{$codcour}{$lang}{course_name};
	#my $course_type = $Common::config{dictionary}{$Common::course_info{$codcour}{course_type}};
	#my $header      = "\n\\course{$codcour. $course_name}{$course_type}{$codcour}\n";
	#$header        .= "% Source file: $fullname\n";
	#my $newhead 	= "\\begin{syllabus}\n$header\n\\begin{justification}";
	#$syllabus_in 	=~ s/\\begin\{syllabus\}\s*((?:.|\n)*?)\\begin\{justification\}/$newhead/g;
# 	Common::read_outcomes_involved($codcour, $fulltxt);

	my %map = ();
	$map{SOURCE_FILE_NAME} = $fullname;
	$Common::course_info{$codcour}{unitcount}	= 0;
	my $syllabus_template = $Common::config{syllabus_template};
	my $unit_struct = "";
	if($syllabus_template =~ m/--BEGINUNIT--\s*\n((?:.|\n)*)--ENDUNIT--/)
	{	$unit_struct = $1;	}
		my $syllabus_adjusted = "";
	# Aqui
	($map{UNITS_SYLLABUS}, $map{SHORT_DESCRIPTION}, $syllabus_adjusted) = process_syllabus_units($codcour, $lang, $syllabus_in, $unit_struct);

	if( not $syllabus_adjusted eq $syllabus_in )
	{
		system("cp $fullname $fullname.bak");
		$syllabus_in = $syllabus_adjusted;
		Util::print_color("Syllabus adjusted (new units format)... see old file at: $fullname.bak");
		#Util::write_file($fullname, $syllabus_in);
	}
	else
	{	#Util::write_file($fullname, $syllabus_in);		
	}

	foreach my $env ("justification", "goals")
	{
	    $Common::course_info{$codcour}{$lang}{$env}{txt} 	= get_environment($codcour, $syllabus_in, $env);
	}

	# 1st: Get general information from this syllabus
	#Util::print_soft_error("Syllabus before ($fullname)");
	#Util::print_warning($syllabus_in);
	parse_environments_in_header($codcour, $lang, $syllabus_in, $fullname);
	#exit;
	#Aqui begin
	$map{COURSE_CODE} 	= $codcour;
	$map{COURSE_NAME} 	= $course_name;
	$map{COURSE_TYPE}	= $Common::config{dictionaries}{$lang}{$Common::course_info{$codcour}{course_type}};

	$semester 			= $Common::course_info{$codcour}{semester};
	$map{SEMESTER}    	= $semester;
	$map{SEMESTER}     .= "\$^{$Common::config{dictionary}{ordinal_postfix}{$semester}}\$ ";
	$map{SEMESTER}     .= "$Common::config{dictionary}{Semester}.";
	$map{CREDITS}		= $Common::course_info{$codcour}{cr};
	$map{JUSTIFICATION}	= $Common::course_info{$codcour}{$lang}{justification}{txt};

	$map{FULL_GOALS}	= "\\begin{itemize}\n$Common::course_info{$codcour}{$lang}{goals}{txt}\n\\end{itemize}";
	$map{GOALS_ITEMS}	= $Common::course_info{$codcour}{$lang}{goals}{txt};

	($map{FULL_OUTCOMES},          $map{OUTCOMES_ITEMS}) 		  = get_formatted_skills($codcour, "outcomes", $version, $lang, $fullname);
	($map{FULL_SPECIFIC_OUTCOMES}, $map{SPECIFIC_OUTCOMES_ITEMS}) = get_formatted_skills($codcour, "specificoutcomes", $version, $lang, $fullname);
	($map{FULL_COMPETENCES},       $map{COMPETENCES_ITEMS})		  = get_formatted_skills($codcour, "competences", $version, $lang, $fullname);
	
	$map{EVALUATION} 	= $Common::config{general_evaluation};
	#Util::print_message("map{EVALUATION} =\n$map{EVALUATION}");
	if( defined($Common::course_info{$codcour}{$lang}{specific_evaluation}) )
	{	$map{EVALUATION} = $Common::course_info{$codcour}{$lang}{specific_evaluation};	}

	($map{PROFESSOR_NAMES}, $map{PROFESSOR_SHORT_CVS}, $map{PROFESSOR_JUST_GRADE_AND_FULLNAME}) = get_professors_info($codcour, $lang);
	$Common::course_info{$codcour}{docentes_names}  	= $map{PROFESSOR_NAMES};
	$Common::course_info{$codcour}{docentes_titles}  	= $map{PROFESSOR_TITLES};
	$Common::course_info{$codcour}{docentes_shortcv} 	= $map{PROFESSOR_SHORT_CVS};

	my $horastxt = "";
	$horastxt 			.= "$Common::course_info{$codcour}{th} HT; " if($Common::course_info{$codcour}{th} > 0);
	$horastxt 			.= "$Common::course_info{$codcour}{ph} HP; " if($Common::course_info{$codcour}{ph} > 0);
	$horastxt 			.= "$Common::course_info{$codcour}{lh} HL; " if($Common::course_info{$codcour}{lh} > 0);
	$map{HOURS}			 = $horastxt;
	($map{THEORY_HOURS}, $map{PRACTICE_HOURS}, $map{LAB_HOURS})	= ("-", "-", "-");

	if($Common::course_info{$codcour}{th} > 0)
	{   $map{THEORY_HOURS} = "$Common::course_info{$codcour}{th} (<<Weekly>>)";	}

	if($Common::course_info{$codcour}{ph} > 0)
	{   $map{PRACTICE_HOURS} = "$Common::course_info{$codcour}{ph} (<<Weekly>>)";	}

	if($Common::course_info{$codcour}{lh} > 0)
	{   $map{LAB_HOURS} = "$Common::course_info{$codcour}{lh} (<<Weekly>>)";	}

	($map{PREREQUISITES_JUST_CODES}, $map{PREREQUISITES}) = get_prerrequisites_info($codcour, $lang);
	
	$map{LIST_OF_TOPICS} = $map{SHORT_DESCRIPTION};
	$map{SHORT_DESCRIPTION} = "\\begin{inparaenum}\n$map{SHORT_DESCRIPTION}\\end{inparaenum}";

	my ($bibfile_in, $bibfile_out) = ("", "");
	if($syllabus_in =~ m/\\bibfile\{(.*?)\}/g)
	{	$bibfile_in = $1;	$bibfile_in     =~ s/ //g;	}

	$map{BIBSTYLE}	= $Common::config{bibstyle};
	if( $bibfile_in =~ m/.*\/(.*)/)
	{	$bibfile_out 	= $1;
		$Common::course_info{$codcour}{short_bibfiles} = $1;
	}
	$map{IN_BIBFILE} 	= $bibfile_in;
	$map{BIBFILE} 		= $bibfile_out.".bib";
	$Common::course_info{$codcour}{bibfiles} = $bibfile_in;

	foreach (keys %{$Common::course_info{$codcour}{extra_tags}})
	{	$map{$_} = $Common::course_info{$codcour}{extra_tags}{$_};		}

	return %map;
}

sub read_syllabus_info_old($$$)
{
	my ($codcour, $semester, $lang)   = (@_);
	my $fullname 	= Common::get_syllabus_full_path($codcour, $semester, $lang);
	my $syllabus_in	= Util::read_file($fullname);
 	#Util::print_message("GenSyllabi::read_syllabus_info $codcour ..."); exit;
	my $CommonTexFile = get_common_file($fullname, $codcour, $lang);
	if( -e $CommonTexFile )
	{
		my $CommonTxt = Util::read_file($CommonTexFile);
		$syllabus_in =~ s/--COMMON-CONTENT--/$CommonTxt/g;
		#Util::print_color($syllabus_in);
		#exit;
	}
	#Util::print_message("CommonTexFile=$CommonTexFile ..."); exit;

	$syllabus_in =~ s/\\ExpandOutcome\{/\\ShowOutcome\{/g;
	$syllabus_in =~ s/\\Competence\{/\\ShowCompetence\{/g;
	$syllabus_in =~ s/\{unitgoals\}/\{learningoutcomes\}/g;

	$syllabus_in = Common::replace_accents($syllabus_in);
	while($syllabus_in =~ m/\n\n\n/)
	{	$syllabus_in =~ s/\n\n\n/\n\n/g;	}
# 	my $codcour_label       = get_alias($codcour);
	my $course_name = $Common::course_info{$codcour}{$lang}{course_name};
	my $course_type = $Common::config{dictionary}{$Common::course_info{$codcour}{course_type}};
	my $header      = "\n\\course{$codcour. $course_name}{$course_type}{$codcour}\n";
	$header        .= "% Source file: $fullname\n";
	my $newhead 	= "\\begin{syllabus}\n$header\n\\begin{justification}";
	$syllabus_in 	=~ s/\\begin\{syllabus\}\s*((?:.|\n)*?)\\begin\{justification\}/$newhead/g;
# 	Common::read_outcomes_involved($codcour, $fulltxt);

	my %map = ();
	$map{SOURCE_FILE_NAME} = $fullname;
	$Common::course_info{$codcour}{unitcount}	= 0;
	foreach my $env ("justification", "goals")
	{
	    $Common::course_info{$codcour}{$lang}{$env}{txt} 	= get_environment($codcour, $syllabus_in, $env);
	}

	# 1st: Get general information from this syllabus
	#Util::print_soft_error("Syllabus before ($fullname)");
	#Util::print_warning($syllabus_in);
	
	foreach my $env (@versioned_environments)
	{
		my $version = $Common::config{OutcomesVersionDefault};
		my $body = "";
		my $syllabus_in_copy = $syllabus_in;
		while( $syllabus_in_copy =~ m/\\begin\{$env\}(.*?)\n((?:.|\n)*?)\\end\{$env\}/g) # legacy version of this environment
		{	my $version_brute = $1;
			$body = $2;
 			#Util::print_message("Version detected $codcour ($env) \"$version_brute\"");
			$version = $version_brute;
			$version =~ s/ //g;
			if( $version =~ m/\{(.*?)\}/g ) # We have already an existing version
			{	$version = $1;
			}
			else  # We do not have a version yet ... add a default ($Common::config{OutcomesVersionDefault})
			{	$version = $Common::config{OutcomesVersionDefault};
				$syllabus_in_copy =~ s/\\begin\{$env\}\s*.*?\s*\n((?:.|\n)*?)\\end\{$env\}/\\begin\{$env\}\{$version\}\n$body\\end\{$env\}/g;
			}
			$Common::course_info{$codcour}{$lang}{$env}{$version}{txt} 	= $body;
			#Util::print_message("Common::course_info{$codcour}{$lang}{$env}{$version}{txt}=\n$body");
		}
		if( not defined($Common::course_info{$codcour}{$lang}{$env}{$version}{txt}) )
		{	$Common::course_info{$codcour}{$lang}{$env}{$version}{txt} = "";	}

		$syllabus_in = $syllabus_in_copy;
		$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized}	= "";
		#$Common::course_info{$codcour}{$lang}{$env}{$version}{array}	= [];
		$Common::course_info{$codcour}{$lang}{$env}{$version}{count}     	= 0;
	}
	my $version = $Common::config{OutcomesVersion};
	foreach my $env (@versioned_environments)
	{
		#print Dumper(\%{$Common::course_info{$codcour}{outcomes}});
		$Common::course_info{$codcour}{$lang}{$env}{$version}{count} = 0;
		foreach my $one_line ( split("\n", $Common::course_info{$codcour}{$lang}{$env}{$version}{txt}) )
		{
			my ($key, $tail)     = ("", "");
			my $reg_exp =  "\\\\".$macro_for_env{$env}."(.*)";
			if( $one_line =~ m/$reg_exp/g )
			{
				($tail) = ($1);
				my @params = $tail =~ m/\{(.*?)\}/g;
				switch($env)
				{	case ["outcomes", "competences"]
					{ 	#print $env;
					   	$Common::course_info{$codcour}{$lang}{$env}{$version}{$params[0]} = $params[1];
						$Common::config{course_by_outcome}{$params[0]}{$codcour} = "";
						Util::print_message("Common::config{course_by_outcome}{$params[0]}{$codcour}=$Common::config{course_by_outcome}{$params[0]}{$codcour}");
						exit;
					}	#\% ($codcour, $semester, $lang)
					case "specificoutcomes"  
					{	# Save the specific outcome
						my $specificoutcome = "$params[0]$params[1]";
						$Common::course_info{$codcour}{$lang}{$env}{$version}{$specificoutcome} = $params[2];
						$Common::course_info{$codcour}{$lang}{outcomes}{$version}{specificoutcomes}{$specificoutcome} = $params[2];
					}
				}
				$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized}  	.= "\\item \\".$macro_for_env{$env}."\n";
				foreach my $param (@params)
				{	$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized} .= "{$param}";		}
				$Common::course_info{$codcour}{$lang}{$env}{$version}{itemized}		.= "\n";
				$Common::course_info{$codcour}{$lang}{$env}{$version}{count}++;
				my $prefix	        = "";
				if(defined($Common::config{$env."_map"}) and defined($Common::config{$env."_map"}{$key}) ) # outcome: a), b), c) ... Competence
				{	$prefix = $Common::config{$env."_map"}{$key};	}
			}
		}
		if( $Common::course_info{$codcour}{$lang}{$env}{$version}{count} == 0 )
		{
			$Common::error{$codcour}{$lang}{file} = $fullname;
			$Common::error{$codcour}{$lang}{$env} = "I did not find $env"."{$version}";
		}
	}
	#exit;
	#Aqui begin
	$map{COURSE_CODE} 	= $codcour;
	$map{COURSE_NAME} 	= $course_name;
	$map{COURSE_TYPE}	= $Common::config{dictionaries}{$lang}{$Common::course_info{$codcour}{course_type}};

	$semester 			= $Common::course_info{$codcour}{semester};
	$map{SEMESTER}    	= $semester;
	$map{SEMESTER}     .= "\$^{$Common::config{dictionary}{ordinal_postfix}{$semester}}\$ ";
	$map{SEMESTER}     .= "$Common::config{dictionary}{Semester}.";
	$map{CREDITS}		= $Common::course_info{$codcour}{cr};
	$map{JUSTIFICATION}	= $Common::course_info{$codcour}{$lang}{justification}{txt};

	$map{FULL_GOALS}	= "\\begin{itemize}\n$Common::course_info{$codcour}{$lang}{goals}{txt}\n\\end{itemize}";
	$map{GOALS_ITEMS}	= $Common::course_info{$codcour}{$lang}{goals}{txt};

	# Outcomes
	my $EnvforOutcomes = $Common::config{EnvforOutcomes};
	$map{FULL_OUTCOMES}	= "";
	if( defined($Common::course_info{$codcour}{$lang}{outcomes}{$version})	)
	{	$map{FULL_OUTCOMES}	= "\\begin{$EnvforOutcomes}\n$Common::course_info{$codcour}{$lang}{outcomes}{$version}{itemized}\\end{$EnvforOutcomes}";	}
	else{	Util::print_warning("There is no outcomes ($version) defined for $codcour ($fullname)"); 	}
	$map{OUTCOMES_ITEMS}	= $Common::course_info{$codcour}{$lang}{outcomes}{$version}{itemized};

	# Specific outcomes
	$EnvforOutcomes = $Common::config{EnvforOutcomes};
	$map{FULL_SPECIFIC_OUTCOMES}	= "";
	if($Common::course_info{$codcour}{$lang}{specificoutcomes}{$version}{count} == 0)
	{	Util::print_warning("Course $codcour ... no {specificoutcomes}{$version} detected ... assuming an empty one!"); 
		$Common::course_info{$codcour}{$lang}{specificoutcomes}{$version}{itemized} = "\\item \\colorbox{red}{<<NoSpecificOutcomes>>}\n";
	}
	if( defined($Common::course_info{$codcour}{$lang}{specificoutcomes}{$version})	)
	{	$map{FULL_SPECIFIC_OUTCOMES}	= "\\begin{$EnvforOutcomes}\n$Common::course_info{$codcour}{$lang}{specificoutcomes}{$version}{itemized}\\end{$EnvforOutcomes}";	}
	else{	Util::print_warning("There is no specific outcomes ($version) defined for $codcour ($fullname)"); 	}
	$map{SPECIFIC_OUTCOMES_ITEMS}	= $Common::course_info{$codcour}{$lang}{specificoutcomes}{$version}{itemized};

	# Competences
	$map{FULL_COMPETENCES}	= "";
	if( defined($Common::course_info{$codcour}{$lang}{competences}{$version}) )
	{	$map{FULL_COMPETENCES}	= "\\begin{description}\n$Common::course_info{$codcour}{$lang}{competences}{$version}{itemized}\\end{description}";	}
	else{	Util::print_warning("There is no competences ($version) defined for $codcour ($fullname)"); 	}
	$map{COMPETENCES_ITEMS}	= $Common::course_info{$codcour}{$lang}{competences}{$version}{itemized};

	$map{EVALUATION} 	= $Common::config{general_evaluation};
	#Util::print_message("map{EVALUATION} =\n$map{EVALUATION}");
	if( defined($Common::course_info{$codcour}{$lang}{specific_evaluation}) )
	{	$map{EVALUATION} = $Common::course_info{$codcour}{$lang}{specific_evaluation};	}

	($map{PROFESSOR_NAMES}, $map{PROFESSOR_SHORT_CVS}, $map{PROFESSOR_JUST_GRADE_AND_FULLNAME}) = ("", "", "");
	my $sep    = "";
	if(defined($Common::antialias_info{$codcour}))
	{	$codcour = $Common::antialias_info{$codcour}	}
	if(defined($Common::config{distribution}{$codcour}))
	{
		my $first = 1;
		#print Dumper(\%Common::professor_role_order); exit;
		foreach my $role  ( sort {$Common::professor_role_order{$a} <=> $Common::professor_role_order{$b}}
							keys %Common::professor_role_order)
		{
			#print Dumper(\%{$Common::config{distribution}{$codcour}{$role}});
			my $count 				= 0;
			my $PROFESSOR_SHORT_CVS = "";
			foreach my $email (sort {$Common::config{faculty}{$b}{fields}{degreelevel} <=> $Common::config{faculty}{$a}{fields}{degreelevel} ||
									 $Common::config{faculty}{$a}{fields}{dedication}  cmp $Common::config{faculty}{$b}{fields}{dedication} ||
									 $Common::config{faculty}{$a}{fields}{name}        cmp $Common::config{faculty}{$b}{fields}{name}}
								keys %{$Common::config{distribution}{$codcour}{$role}}
							  )
			{
					if( $Common::config{faculty}{$email}{fields}{degreelevel} >= $Common::config{degrees}{MasterPT} )
					{
						my $coordinator = "";
						#if( $role eq "C" )
						#{	$coordinator = "~(\\textbf{$Common::config{dictionaries}{$lang}{Coordinator}})";	$first = 0;		}
						$map{PROFESSOR_NAMES} 	.= "$Common::config{faculty}{$email}{fields}{name} ";
						$PROFESSOR_SHORT_CVS	.= "\\item $Common::config{faculty}{$email}{fields}{name} <$email>$coordinator\n";
						$PROFESSOR_SHORT_CVS 	.= "\\vspace{-0.2cm}\n";
						$PROFESSOR_SHORT_CVS 	.= "\\begin{itemize}[noitemsep]\n";
						$PROFESSOR_SHORT_CVS 	.= "$Common::config{faculty}{$email}{fields}{shortcv}{$lang}";
						$PROFESSOR_SHORT_CVS 	.= "\\end{itemize}\n\n";
						$count++;
						#$map{PROFESSOR_JUST_GRADE_AND_FULLNAME} .= "$sep$Common::config{faculty}{$email}{fields}{title} $Common::config{faculty}{$email}{fields}{name}";
					}
					$sep = ", ";
			}
			if( $count > 0 )
			{	$map{PROFESSOR_SHORT_CVS} .= "\\noindent \\textbf{$Common::config{dictionaries}{$lang}{professor_role_label}{$role}}\n";
				$map{PROFESSOR_SHORT_CVS} .= "\\begin{itemize}[noitemsep]\n";
				$map{PROFESSOR_SHORT_CVS} .= $PROFESSOR_SHORT_CVS;
				$map{PROFESSOR_SHORT_CVS} .= "\\end{itemize}\n";
				#print Dumper (\%{$Common::config{dictionaries}{$lang}{professor_role_label}});
				#exit;
			}
		}
		#exit; #role
	}
	else
	{
 		Util::print_soft_error("There is no professor assigned to $codcour (Sem #$Common::course_info{$codcour}{semester})");
	}
	#exit;
	$Common::course_info{$codcour}{docentes_names}  	= $map{PROFESSOR_NAMES};
	$Common::course_info{$codcour}{docentes_titles}  	= $map{PROFESSOR_TITLES};
	$Common::course_info{$codcour}{docentes_shortcv} 	= $map{PROFESSOR_SHORT_CVS};

	my $horastxt = "";
	$horastxt 			.= "$Common::course_info{$codcour}{th} HT; " if($Common::course_info{$codcour}{th} > 0);
	$horastxt 			.= "$Common::course_info{$codcour}{ph} HP; " if($Common::course_info{$codcour}{ph} > 0);
	$horastxt 			.= "$Common::course_info{$codcour}{lh} HL; " if($Common::course_info{$codcour}{lh} > 0);
	$map{HOURS}			 = $horastxt;
	($map{THEORY_HOURS}, $map{PRACTICE_HOURS}, $map{LAB_HOURS})	= ("-", "-", "-");

	if($Common::course_info{$codcour}{th} > 0)
	{   $map{THEORY_HOURS} = "$Common::course_info{$codcour}{th} (<<Weekly>>)";	}

	if($Common::course_info{$codcour}{ph} > 0)
	{   $map{PRACTICE_HOURS} = "$Common::course_info{$codcour}{ph} (<<Weekly>>)";	}

	if($Common::course_info{$codcour}{lh} > 0)
	{   $map{LAB_HOURS} = "$Common::course_info{$codcour}{lh} (<<Weekly>>)";	}

	if($Common::course_info{$codcour}{n_prereq} == 0)
	{	$map{PREREQUISITES_JUST_CODES}	= $Common::config{dictionaries}{$lang}{None};
        $map{PREREQUISITES}             = $Common::config{dictionaries}{$lang}{None};
	}
	else
	{
        $map{PREREQUISITES_JUST_CODES}	= $Common::course_info{$codcour}{prerequisites_just_codes};
        my $output = "";
        if( scalar(@{$Common::course_info{$codcour}{$lang}{code_name_and_sem_prerequisites}}) == 1 )
        {   $output = $Common::course_info{$codcour}{$lang}{code_name_and_sem_prerequisites}[0];    }
        else
        {
            foreach my $txt ( @{$Common::course_info{$codcour}{$lang}{code_name_and_sem_prerequisites}} )
            {   $output .= "\t\t \\item $txt\n";        }
            $output = "\\begin{itemize}\n$output\\end{itemize}";
        }
        $map{PREREQUISITES} 			= $output;
	}

	my $syllabus_template = $Common::config{syllabus_template};
	my $unit_struct = "";
	if($syllabus_template =~ m/--BEGINUNIT--\s*\n((?:.|\n)*)--ENDUNIT--/)
	{	$unit_struct = $1;	}
	my $syllabus_adjusted = "";
	($map{UNITS_SYLLABUS}, $map{SHORT_DESCRIPTION}, $syllabus_adjusted) = process_syllabus_units($codcour, $lang, $syllabus_in, $unit_struct);
	$map{LIST_OF_TOPICS} = $map{SHORT_DESCRIPTION};
	$map{SHORT_DESCRIPTION} = "\\begin{inparaenum}\n$map{SHORT_DESCRIPTION}\\end{inparaenum}";

	my ($bibfile_in, $bibfile_out) = ("", "");
	if($syllabus_in =~ m/\\bibfile\{(.*?)\}/g)
	{	$bibfile_in = $1;	$bibfile_in     =~ s/ //g;	}

	$map{BIBSTYLE}	= $Common::config{bibstyle};
	if( $bibfile_in =~ m/.*\/(.*)/)
	{	$bibfile_out 	= $1;
		$Common::course_info{$codcour}{short_bibfiles} = $1;
	}
	$map{IN_BIBFILE} 	= $bibfile_in;
	$map{BIBFILE} 		= $bibfile_out.".bib";
	$Common::course_info{$codcour}{bibfiles} = $bibfile_in;

	foreach (keys %{$Common::course_info{$codcour}{extra_tags}})
	{	$map{$_} = $Common::course_info{$codcour}{extra_tags}{$_};		}

	if( not $syllabus_adjusted eq $syllabus_in )
	{
		system("cp $fullname $fullname.bak");
		$syllabus_in = $syllabus_adjusted;
		Util::print_color("Syllabus adjusted ... see old file at: $fullname.bak");
		Util::write_file($fullname, $syllabus_in);
	}
	else
	{	Util::write_file($fullname, $syllabus_in);	}
	
	return %map;
}

sub genenerate_tex_syllabus_file($$$$$%)
{
	my ($codcour, $file_template, $units_field, $output_file, $lang, %map)   = (@_);
# 	my $unit_struct = "";
# 	if($file_template =~ m/--BEGINUNIT--\s*\n((?:.|\n)*)--ENDUNIT--/)
# 	{	$unit_struct = $1;	}
	$file_template =~ s/--BEGINUNIT--\s*\n((?:.|\n)*)--ENDUNIT--/$map{$units_field}/g;
	$file_template =~ s/\\newcommand\{\\INST\}\{\}/\\newcommand\{\\INST\}\{$Common::institution\}/g;
	$file_template =~ s/\\newcommand\{\\AREA\}\{\}/\\newcommand\{\\AREA\}\{$Common::area\}/g;
	Util::print_message("genenerate_tex_syllabus_file $codcour: $output_file ...");

	if($file_template =~ m/--OUTCOMES-FOR-OTHERS--/g)
	{
		my $nkeys = keys %{$Common::course_info{$codcour}{extra_tags}};
		if($nkeys > 0 )
		{	Util::print_message("$output_file extra tags detected ok!");
			#print Dumper (\%{$Common::course_info{$codcour}{extra_tags}});	
			$file_template =~ s/<<Competences>>/<<CompetencesForCS>>/g;
			my $extra_txt = "\\item \\textbf{<<CompetencesForEngineering>>} \n";
			#Util::print_message("OutcomesForOtherContent$lang=".$Common::course_info{$codcour}{extra_tags}{"OutcomesForOtherContent$lang"});
			my $EnvforOutcomes = $Common::config{EnvforOutcomes};
			$extra_txt .= "\\begin{$EnvforOutcomes}\n$Common::course_info{$codcour}{$lang}{extra_tags}{OutcomesForOtherContent}\\end{$EnvforOutcomes}\n";
			$file_template =~ s/--OUTCOMES-FOR-OTHERS--/$extra_txt/g;
			#$extra_txt .= 
			#exit;
		}
		else{	$file_template =~ s/--OUTCOMES-FOR-OTHERS--//g;}
	}
	$file_template = Common::ExpandTags($file_template, $lang);
	for(my $i = 0 ; $i < 2; $i++ )
	{
	    $file_template = Common::replace_tags_from_hash($file_template, "--", "--", %map);
	    $file_template = Common::translate($file_template, $lang);
	}
    #file_template =~ s/--.*?--//g;
	if(-e $output_file)
    {	system("rm $output_file");	}
	Util::write_file($output_file, $file_template);
	#Util::print_message("Generating $output_file ok!");
	#exit;
}

sub read_sumilla_template()
{
	return;
	my $syllabus_file = Common::get_template("in-syllabus-template-file");
	$Common::config{sumilla_template} = "";
	if(-e $syllabus_file)
	{	Util::print_message("Reading ... \"$syllabus_file\"");
	    $Common::config{sumilla_template} = Util::read_file($syllabus_file);
	}
	else
	{	Util::print_warning("It seems that you forgot the syllabus program template file ... \"$syllabus_file\"");}

	$syllabus_file = Common::get_template("in-syllabus-program-template-file");
	if(-e $syllabus_file)
	{	Util::print_message("Reading ... \"$syllabus_file\"");
		$Common::config{sumilla_template} = Util::read_file($syllabus_file);
	}
	else
	{	Util::print_warning("It seems that you forgot the syllabus program template for this cycle ... \"$syllabus_file\"");}

	if($Common::config{sumilla_template} eq "")
	{		Util::print_error("It seems that you forgot the template sumilla file ... \"$syllabus_file\"");   }
}

sub read_syllabus_template()
{
	my $syllabus_file = Common::get_template("in-syllabus-template-file");
	$Common::config{syllabus_template} = "";
	if(-e $syllabus_file)
	{	Util::print_message("Reading ... \"$syllabus_file\"");
	    $Common::config{syllabus_template} = Util::read_file($syllabus_file);
	}
	else
	{	Util::print_warning("It seems that you forgot the syllabus program template file ... \"$syllabus_file\"");}

	$syllabus_file = Common::get_template("in-syllabus-program-template-file");
	if(-e $syllabus_file)
	{	Util::print_message("Reading ... \"$syllabus_file\"");
		$Common::config{syllabus_template} = Util::read_file($syllabus_file);
	}
	else
	{	Util::print_warning("It seems that you forgot the syllabus program template for this cycle ... \"$syllabus_file\"");}

	if($Common::config{syllabus_template} eq "")
	{		Util::print_error("It seems that you forgot the template sumilla file ... \"$syllabus_file\"");   }

	if( $Common::config{syllabus_template} =~ m/\\begin\{evaluation\}\s*\n((?:.|\n)*?)\n\\end\{evaluation\}/g )
	{
	      $Common::config{general_evaluation} = $1;
	      $Common::config{syllabus_template}  =~ s/\\begin\{evaluation\}\s*\n(?:.|\n)*?\n\\end\{evaluation\}/--EVALUATION--/;
	      Util::print_message("File General Evaluation detected ok!");
	}
	else
	{
	      Util::print_error("It seems you did not write General Evaluation Criteria on your Syllabus template (See file: $syllabus_file) ...");
	}
}

# ok, Here we generate syllabi, prerequisitite files
sub process_syllabi()
{
	Common::read_faculty();
	Common::read_distribution();
	Common::sort_faculty_list();
	Common::read_aditional_info_for_silabos(); # Days, time for each class, etc.

	# It generates all the sillabi
	read_sumilla_template();   # 1st Read template for sumilla
	read_syllabus_template();  # 2nd Read the syllabus template
	gen_course_general_info($Common::config{language_without_accents}); # 3th Generate files containing Prerequisites, etc
	generate_dot_maps_for_all_courses($Common::config{language_without_accents});   # 4th Generate dot files

	# 4th: Read evaluation info for this institution
	Common::read_specific_evaluacion_info(); # It loads the field: $Common::course_info{$codcour}{specific_evaluation} for each course with specific evaluation  	
	generate_tex_syllabi_files();
	generate_syllabi_include();
	
 	gen_batch_to_compile_syllabi();
	foreach my $lang (@{$Common::config{SyllabusLangsList}})
	{
	    gen_book("Syllabi", "../syllabi/", "", $lang);
	    if( $Common::config{flags}{DeliveryControl} && $Common::config{flags}{DeliveryControl} == 1 )
	    {	gen_book("Syllabi", "../pdf/", "-delivery-control", $lang);
	    }
	}
	Util::check_point("gen_syllabi");
}

# ok
sub generate_tex_syllabi_files()
{
	Util::precondition("parse_courses");

	# Generate all the syllabi
	my $count_courses 	= 0;
	my $OutputTexDir = Common::get_template("OutputTexDir");
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax}; $semester++)
	{
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{
			my $codcour_label = Common::get_label($codcour);
			foreach my $lang (@{$Common::config{SyllabusLangsList}})
			{
				my %map = read_syllabus_info($codcour, $semester, $lang);
				$map{AREA}			= $Common::config{area};

				my $output_file = "$OutputTexDir/$codcour_label-$Common::config{dictionaries}{$lang}{lang_prefix}.tex";
				#Util::print_message("Generating Syllabus: $output_file");
				genenerate_tex_syllabus_file($codcour_label, $Common::config{syllabus_template}, "UNITS_SYLLABUS", $output_file, $lang, %map);
				
				# Copy bib files
				my $syllabus_bib = Common::get_template("InSyllabiContainerDir")."/$map{IN_BIBFILE}.bib";
				#Util::print_message("cp $syllabus_bib $OutputTexDir");
				eval { system("cp $syllabus_bib $OutputTexDir"); }

				#eval { system("cp $syllabus_bib $OutputTexDir"); }
				#warn $@ if $@;
			}
# 			genenerate_tex_syllabus_file($codcour, $Common::config{sumilla_template} , "UNITS_SUMILLA" , "$OutputTexDir/$codcour-sumilla.tex", %map);
		}
	}
	#system("chgrp curricula $OutputTexDir/*");
	my $firstpage_file = Common::get_template("in-syllabus-first-page-file");
	my $command = "cp $firstpage_file $OutputTexDir/.";
	Util::print_message($command);
	system($command);
	Util::check_point("generate_tex_syllabi_files");
}

# ok
sub gen_batch_to_compile_syllabi()
{
	Util::precondition("set_global_variables");
# 	Util::print_message("gen_batch_to_compile_syllabi starting ...");
	my $out_gen_syllabi = Common::get_template("out-gen-syllabi.sh-file");

	my $output = "";
	#$output .= "rm *.ps *.pdf *.log *.dvi *.aux *.bbl *.blg *.toc\n\n";
	$output .= "#!/bin/csh\n";
	$output .= "set course=\$1\n";
	$output .= "if(\$course == \"\") then\n";
	$output .= "set course=\"all\"\n";
	$output .= "endif\n";
# 	$output .= "echo \"codigo=\$course\";\n";

	$output .= "\n";
	my $html_out_dir 		 = Common::get_template("OutputHtmlDir");
	my $html_out_dir_syllabi = $html_out_dir."/syllabi";
	$output .= "if(\$course == \"all\") then\n";
	$output .= "\trm -rf $html_out_dir_syllabi\n";

	foreach my $TempDir ("OutputSyllabiDir", "OutputFullSyllabiDir")
	{
		my $tex_out_dir_syllabi	 = Common::get_template($TempDir);
		#$output .= "if(\$course == \"all\") then\n";
		$output .= "\trm -rf $tex_out_dir_syllabi\n";
	}
	$output .= "endif\n\n";

	$output .= "mkdir -p $html_out_dir_syllabi\n";
	foreach my $TempDir ("OutputSyllabiDir", "OutputFullSyllabiDir")
	{
		my $tex_out_dir_syllabi	 = Common::get_template($TempDir);
		#$output .= "if(\$course == \"all\") then\n";
		$output .= "mkdir -p $tex_out_dir_syllabi\n";
	}
	$output .= "\n";

	my ($gen_syllabi, $cp_bib) = ("", "");
	my $scripts_dir 		= Common::get_template("InScriptsDir");
	my $output_tex_dir 		= Common::get_template("OutputTexDir");
	my $OutputInstDir 		= Common::get_template("OutputInstDir");
	my $OutputSyllabiDir	= Common::get_template("OutputSyllabiDir");
	my $OutputFullSyllabiDir= Common::get_template("OutputFullSyllabiDir");

	my $syllabus_container_dir 	= Common::get_template("InSyllabiContainerDir");
	my $count_courses 		= 0;
	my ($parallel_sep)   = ("");
        $parallel_sep = "&" if($Common::config{parallel} == 1);

	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax}; $semester++)
	{
		$output .= "#Semester #$semester\n";
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{
			$output .= "if(\$course == \"$codcour\" || \$course == \"$codcour\" || \$course == \"all\") then\n";
# 			Util::print_message("codcour = $codcour, bibfiles=$Common::course_info{$codcour}{bibfiles}");
			foreach (split(",", $Common::course_info{$codcour}{bibfiles}))
			{
				$output .= "cp $syllabus_container_dir/$_.bib $output_tex_dir\n";
 				#Util::print_message("$syllabus_container_dir/$_");
			}
			foreach my $lang (@{$Common::config{SyllabusLangsList}})
			{
				my $lang_prefix	= $Common::config{dictionaries}{$lang}{lang_prefix};
				$output .= "$scripts_dir/gen-syllabus.sh $codcour-$lang_prefix $OutputInstDir$parallel_sep\n";
				if(defined($Common::config{distribution}{$codcour}))
				{
					                                    #2020-1-QI0027-química general.doc
					my $fullname = "$OutputFullSyllabiDir/$Common::config{Semester} $codcour-$lang_prefix - $Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name}.pdf";
					#my $fullname = "$OutputFullSyllabiDir/$codcour-$lang_prefix - $Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name} ($Common::config{Semester}).pdf";
					$output .= "cp \"$OutputSyllabiDir/$codcour-$lang_prefix.pdf\" \"$fullname\"\n";
				}
			}
			$output .= "endif\n\n";
			$count_courses++;
		}
	}
	#$output .= "\n$cp_bib\n$gen_syllabi";
	Util::write_file($out_gen_syllabi, $output);
	system("chmod 774 $out_gen_syllabi");
	Util::print_message("gen_batch_to_compile_syllabi $Common::institution ($count_courses courses) OK!");
}

sub get_hidden_chapter_info($$)
{
	my ($semester, $lang) = (@_);
	my $output_tex .= "\% $semester$Common::config{dictionaries}{$lang}{ordinal_postfix}{$semester} $Common::config{dictionaries}{$lang}{Semester}\n";
	$output_tex .= "\\addtocounter{chapter}{1}\n";
	$output_tex .= "\\addcontentsline{toc}{chapter}{$Common::config{dictionaries}{$lang}{semester_ordinal}{$semester} $Common::config{dictionaries}{$lang}{Semester}}\n";
	$output_tex .= "\\setcounter{section}{0}\n";
	return $output_tex;
}

sub generate_fancy_header_file($)
{
	my ($lang) = (@_);
	my $lang_prefix = $Common::config{dictionaries}{$lang}{lang_prefix};
	my $in_fancy_hdr_file = Common::get_template("in-config-hdr-foot-sty-file");
	my $fancy_hdr_content = Util::read_file($in_fancy_hdr_file);
	$fancy_hdr_content =~ s/<SchoolFullName>/\\SchoolFullName$lang_prefix/g;
	$fancy_hdr_content =~ s/<<Curricula>>/$Common::config{dictionaries}{$lang}{Curricula}/g;
	
	my $out_fancy_hdr_file = Common::get_template("out-config-hdr-foot-sty-file");
	$out_fancy_hdr_file =~ s/<LANG>/$Common::config{dictionaries}{$lang}{lang_prefix}/g;
	Util::print_message("Generating $out_fancy_hdr_file ...");
	Util::write_file($out_fancy_hdr_file, $fancy_hdr_content);
}

sub write_book_files($$$)
{
	my ($InBook, $lang, $output_tex) = (@_);
	my $InBookFile     = Common::get_template("in-Book-of-$InBook-main-file");
	system("cp $InBookFile ".Common::get_template("OutputTexDir"));

	my $InBookContent = Util::read_file($InBookFile);
	$InBookContent = Common::ExpandTags($InBookContent, $lang);

	my $OutBookFile = Common::get_template("out-Book-of-$InBook-main-file");
	$OutBookFile = Common::ExpandTags($OutBookFile, $lang);

	Util::print_message("\nGenerating $OutBookFile ok! (write_book_files)");
	$InBookContent = Common::translate($InBookContent, $lang);
	Util::write_file($OutBookFile, $InBookContent);

	my $InBookFaceFile = Common::get_template("in-Book-of-$InBook-face-file");
	my $InBookFaceTxt = Util::read_file($InBookFaceFile);
	$InBookFaceTxt = Common::ExpandTags($InBookFaceTxt, $lang);
	if( system("cp $InBookFaceFile ".Common::get_template("OutputTexDir")) >> 8 == 0 )
	{	Util::print_message("Copied $InBookFaceFile to".Common::get_template("OutputTexDir")."... ok!");	}

	my $OutputIncludeListFile = Common::get_template("out-$InBook-includelist-file");
	$OutputIncludeListFile = Common::ExpandTags($OutputIncludeListFile, $lang);

	Util::print_message("Generating $OutputIncludeListFile ok! (write_book_files)");
	Util::write_file($OutputIncludeListFile, $output_tex);
	generate_fancy_header_file($lang);
}

# ok
# GenSyllabi::gen_book("Syllabi", "syllabi/", "");
# GenSyllabi::gen_book("Syllabi", "../pdf/", "-delivery-control", $lang);
sub gen_book($$$$)
{
	my ($InBook, $prefix, $postfix, $lang) = (@_);
	Util::precondition("set_global_variables");

	my $output_tex = "% Generated by gen_book($InBook, $prefix, $postfix, $lang)\n";
	#$output_tex .="rm *.ps *.pdf *.log *.dvi *.aux *.bbl *.blg *.toc\n\n";
	my $count = 0;
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
	{
		$output_tex .= get_hidden_chapter_info($semester, $lang);
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{
		    my $codcour_label = Common::get_label($codcour);
		    #-$Common::config{dictionaries}{$lang}{lang_prefix}.tex";
		    $output_tex .= "\\includepdf[pages=-,addtotoc={1,section,1,{$codcour. $Common::course_info{$codcour}{$lang}{course_name}},$codcour-$Common::config{dictionaries}{$lang}{lang_prefix}}]";
		    $output_tex .= "{$prefix$codcour-$Common::config{dictionaries}{$lang}{lang_prefix}$postfix}\n";
		    $count++;
		}
		$output_tex .= "\n";
	}
	write_book_files("Syllabi", $lang, $output_tex);
# 	Util::print_message("gen_book ($count courses) in $OutputFile OK!");
}

sub gen_book_of_bibliography($)
{
      my ($lang) = (@_);
      Util::precondition("set_global_variables");
      my $count = 0;
      my $output_tex = "";

      for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
      {
	      $output_tex .= get_hidden_chapter_info($semester, $lang);
	      foreach my $codcour (@{$Common::courses_by_semester{$semester}})
	      {
		      # print "codcour=$codcour ...\n";
		      my $bibfiles = $Common::course_info{$codcour}{short_bibfiles};
		      #print "codcour = $codcour    ";
		      my $sec_title = "$codcour. $Common::course_info{$codcour}{$lang}{course_name} ";
# 			$sec_title .= "($semester$Common::rom_postfix{$semester} sem)";
		      $output_tex .= "\\section{$sec_title}\\label{sec:$codcour}\n";
		      $output_tex .= "\\begin{btUnit}%\n";
		      $output_tex .= "\\nocite{$Common::course_info{$codcour}{allbibitems}}\n";
		      $output_tex .= "\\begin{btSect}[apalike]{$bibfiles}%\n";
		      $output_tex .= "\\btPrintCited\n";
		      $output_tex .= "\\end{btSect}%\n";
		      $output_tex .= "\\end{btUnit}%\n\n";
		      #$output_tex .= "$Common::course_info{$codcour}{justification}\n\n";
		      $count++;
	      }
	      $output_tex .= "\n";
      }
      write_book_files("Bibliography", $lang, $output_tex);
      Util::print_message("gen_book_of_bibliography ($count courses) OK!");
}

# ok
sub gen_book_of_descriptions($)
{
      my ($lang) = (@_);
      Util::precondition("set_global_variables");
      my $output_tex = "";
      my $count = 0;
      for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
      {
	      $output_tex .= get_hidden_chapter_info($semester, $lang);
	      foreach my $codcour (@{$Common::courses_by_semester{$semester}})
	      {
		      #Util::print_message("codcour = $codcour    ");
		      #my $codcour_label = Common::get_label($codcour);
		      my $sec_title = "$codcour. $Common::course_info{$codcour}{$lang}{course_name}";
  # 			$sec_title 	.= "($semester$Common::config{dictionary}{ordinal_postfix}{$semester} ";
  # 			$sec_title 	.= "$Common::config{dictionary}{Semester})";
		      $output_tex .= "\\section{$sec_title}\\label{sec:$codcour}\n";
		      $output_tex .= "$Common::course_info{$codcour}{$lang}{justification}{txt}\n\n";
		      $count++;
	      }
	      $output_tex .= "\n";
      }
      write_book_files("Descriptions", $lang, $output_tex);
      Util::print_message("gen_book_of_descriptions ($count courses) OK!");
}

sub generate_team_file($)
{	
	my ($lang) = (@_);
	my $TeamContentBase 	= Util::read_file(Common::get_template("InProgramDir")."/team.tex");
	my $OutputTeamFileBase	= Common::get_template("out-team-file");
	
	my $TeamContent = Common::translate($TeamContentBase, $lang);
	$TeamContent =~ s/<LANG>/$Common::config{dictionaries}{$lang}{lang_prefix}/g;
	my $OutputTeamFile = $OutputTeamFileBase;
	$OutputTeamFile =~ s/<LANG>/$Common::config{dictionaries}{$lang}{lang_prefix}/g;
	Util::print_message("Generating $OutputTeamFile ok ...");
	Util::write_file($OutputTeamFile, $TeamContent);
}

# # ok
# sub gen_list_of_units_by_course()
# {
# 	Util::precondition("set_global_variables");
# 	my $file_name = Common::get_template("out-list-of-unit-by-course-file");
# 	my $output_tex = "";
# 	my $count = 0;
# 	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
# 	{
# 		$output_tex .= get_hidden_chapter_info($semester);
# 		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
# 		{
# 			#my $codcour_label 	= Common::get_label($codcour);
# 			my $i = 0;
# 			my $sec_title = "$codcour. $Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name}";
#  			#$sec_title 	.= "($semester$Common::config{dictionary}{ordinal_postfix}{$semester} ";
#  			#$sec_title 	.= "$Common::config{dictionary}{Semester})";
# 			$output_tex .= "\\section{$sec_title}\\label{sec:$codcour}\n";
# 			#for($i = 0 ; $i < $Common::course_info{$codcour}{outcomes}{count}; $i++)
# 			$output_tex .= "\\subsection{Resultados}\n";
# 			$output_tex .= "\\begin{itemize}\n";
# 			my $outcomes_txt = "";
# 			foreach my $outcome_key (@{$Common::course_info{$codcour}{outcomes}{$version}{array}}) # Sequential to list later
# 			{
# 				my $bloom 	= $Common::course_info{$codcour}{outcomes}{$version}{$outcome_key};
# 				$outcomes_txt  .= "\\item \\ref{out:Outcome$outcome_key}) \\Outcome$outcome_key"."Short [$bloom, ~~~~~]\n";
# 			}
# 			if( $Common::course_info{$codcour}{outcomes}{count} == 0 )
# 			{	$output_tex .= "\t\\item $Common::config{dictionary}{None}\n";	}
# 			$output_tex .= $outcomes_txt;
# 			$output_tex .= "\\end{itemize}\n\n";
#
# 			$output_tex .= "\\subsection{Unidades}\n";
# 			$output_tex .= "\\begin{itemize}\n";
# 			my $units_txt = "";
# 			for($i = 0 ; $i < $Common::course_info{$codcour}{n_units}; $i++)
# 			{
# 			      $units_txt .= "\t\\item $Common::course_info{$codcour}{units}{unit_caption}[$i], ";
# 			      $units_txt .= "$Common::course_info{$codcour}{units}{hours}[$i] $Common::config{dictionary}{hrs}, ";
# 			      $units_txt .= "[$Common::course_info{$codcour}{units}{bloom_level}[$i], ~~~~~]\n";
# 			}
# 			#if( $Common::course_info{$codcour}{n_units} == 0 )
# 			if( $i == 0 )
# 			{	$units_txt = "\t\\item $Common::config{dictionary}{None}\n";	}
# 			$output_tex .= $units_txt;
# 			$output_tex .= "\\end{itemize}\n\n";
# 			$count++;
# 		}
# 		$output_tex .= "\n";
# 	}
# 	Util::write_file($file_name, $output_tex);
# 	system("cp ".Common::get_template("in-Book-of-units-by-course-main-file")." ".Common::get_template("OutputTexDir"));
# 	system("cp ".Common::get_template("in-Book-of-units-by-course-face-file")." ".Common::get_template("OutputTexDir"));
# 	Util::print_message("gen_list_of_units_by_course $file_name ($count courses) OK!");
# }

sub generate_formatted_syllabus($$$$)
{
	my ($codcour, $source, $target, $lang) = (@_);
	my $active_version = $Common::config{OutcomesVersion};
	my $source_txt = Util::read_file($source);

	my $course_name = $Common::course_info{$codcour}{$lang}{course_name};
	my $course_type = $Common::config{dictionary}{$Common::course_info{$codcour}{course_type}};
	my $header      = "\n\\course{$codcour. $course_name}{$course_type}{$codcour}\n";
	$header        .= "% Source file: $source\n";
	my $newhead 	= "\\begin{syllabus}\n$header\n\\begin{justification}";
	$source_txt 	=~ s/\\begin\{syllabus\}\s*((?:.|\n)*?)\\begin\{justification\}/$newhead/g;

	foreach my $env (@versioned_environments)
	{
		my $syllabus_in_copy = $source_txt;
		while( $syllabus_in_copy =~ m/\\begin\{$env\}\{(.*?)\}\s*\n((?:.|\n)*?)\\end\{$env\}/g)
		{	my $version = $1;
			my $body = $2;
			if( $version eq $active_version ) # This is a necessary environment
			{	$syllabus_in_copy =~ s/\\begin\{$env\}\{$version\}\s*\n((?:.|\n)*?)\\end\{$env\}/\\begin\{$env\}\n$1\\end\{$env\}/g;	}
			else
			{	$syllabus_in_copy =~ s/\\begin\{$env\}\{$version\}\s*\n((?:.|\n)*?)\\end\{$env\}\s*\n//g;	}

		}
		$source_txt = $syllabus_in_copy;
	}
	while ($source_txt =~ m/\n\n\n/ )
	{		$source_txt =~ s/\n\n\n/\n\n/;		}

	Util::print_message("$source -> $target (OK)");
	Util::write_file($target, $source_txt);
	#if($codcour eq "IN0054")
	#{	Util::print_message("generate_formatted_syllabus($codcour, $source, $target, $lang)");
	#	exit;	
	#}
}

sub generate_syllabi_include()
{
	my $output_file = Common::get_template("out-list-of-syllabi-include-file");
	my $output_tex  = "";

	$output_tex  .= "%This file is generated automatically ... do not touch !!! (GenSyllabi.pm: generate_syllabi_include()) \n";
	$output_tex  .= "\\newcounter{conti}\n";

	my $OutputTexDir = Common::get_template("OutputTexDir");
	my $ncourses    = 0;
	my $newpage = "";
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
	{
		$output_tex .= "\n";
		$output_tex .= "\\addcontentsline{toc}{section}{$Common::config{dictionary}{semester_ordinal}{$semester} ";
		$output_tex .= "$Common::config{dictionary}{Semester}}\n";
		foreach my $codcour ( @{$Common::courses_by_semester{$semester}} )
		{
			#my $codcour_label = Common::get_label($codcour);
			my $lang 		= Common::get_template("language_without_accents");
			my $lang_prefix	= $Common::config{dictionaries}{$lang}{lang_prefix};
			my $course_fullpath = Common::get_syllabus_full_path($codcour, $semester, $lang);
			generate_formatted_syllabus($codcour, $course_fullpath, "$OutputTexDir/$codcour-orig-$lang_prefix.tex", $lang);
			#if($codcour =~ m/CS2H/g)
			#	{	Util::print_message("GenSyllabi::generate_formatted_syllabus $codcour ...");  exit; }

			$course_fullpath =~ s/(.*)\.tex/$1/g;
			$output_tex .= "$newpage\\input{$OutputTexDir/$codcour-orig-$lang_prefix}";
			$output_tex .= "% $codcour $Common::course_info{$codcour}{$lang}{course_name}\n";
			#if($codcour =~ m/CS2H/g)
			#	{	Util::print_message("GenSyllabi::read_syllabus_info $codcour ...");  exit; }

			$ncourses++;
			$newpage = "\\newpage";
		}
		$output_tex .= "\n";
	}
	Util::write_file($output_file, $output_tex);
	Util::print_message("generate_syllabi_include() OK!");
}

sub gen_course_general_info($)
{
    my ($lang) = (@_);
	my $OutputPrereqDir = Common::get_template("OutputPrereqDir");
	my $OutputFigsDir = Common::get_template("OutputFigsDir");

	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
	{
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{
			my $normal_header   = "\\begin{itemize}\n";
			my $codcour_label = Common::get_label($codcour);
			# Semester: 5th Sem.
			$normal_header .= "\\item \\textbf{$Common::config{dictionary}{Semester}}: ";
			$normal_header .= "$semester\$^{$Common::config{dictionary}{ordinal_postfix}{$semester}}\$ ";
			$normal_header .= "$Common::config{dictionary}{Sem}. ";

			# Credits
			$normal_header .= "\\textbf{$Common::config{dictionary}{Credits}}: $Common::course_info{$codcour}{cr}\n";

			# Hours of this course
			$normal_header .= "\\item \\textbf{$Common::config{dictionary}{HoursOfThisCourse}}: ";
			if($Common::course_info{$codcour}{th} > 0)
			{	$normal_header .= "\\textbf{$Common::config{dictionary}{Theory}}: $Common::course_info{$codcour}{th} $Common::config{dictionary}{hours}; ";	}
			if($Common::course_info{$codcour}{ph} > 0)
			{	$normal_header .= "\\textbf{$Common::config{dictionary}{Practice}}: $Common::course_info{$codcour}{ph} $Common::config{dictionary}{hours}; ";	}
			if($Common::course_info{$codcour}{lh} > 0)
			{	$normal_header .= "\\textbf{$Common::config{dictionary}{Laboratory}}: $Common::course_info{$codcour}{lh} $Common::config{dictionary}{hours}; ";	}
			$normal_header .= "\n";

			my $syllabus_link = "";
			$syllabus_link .= "\t\\begin{htmlonly}\n";
			$syllabus_link .= "\t\\item \\textbf{$Common::config{dictionary}{Syllabus}}:\n";
			$syllabus_link .= "\t\t\\begin{rawhtml}";
			$syllabus_link .= Common::get_syllabi_language_links("\t\t", $codcour_label)."-";
			$syllabus_link .=  "\t\t\\end{rawhtml}\n";
			$syllabus_link .=  "\t\\end{htmlonly}\n";
			$normal_header .= $syllabus_link;

			my $prereq_txt = "\\item \\textbf{$Common::config{dictionary}{Prerequisites}}: ";
			if($Common::course_info{$codcour}{n_prereq} == 0)
			{	$prereq_txt .= "$Common::config{dictionary}{None}\n";	}
			else
			{
				$prereq_txt .= "\n\t\\begin{itemize}\n";
				foreach my $course (@{$Common::course_info{$codcour}{$lang}{full_prerequisites}})
				{
					$prereq_txt .= "\t\t\\item $course\n";
				}
				$prereq_txt .= "\t\\end{itemize}\n";
			}
			$normal_header .= $prereq_txt;
			$normal_header    .= "\\end{itemize}\n";

			my $output_file = "$OutputPrereqDir/$codcour_label";
			Util::write_file("$output_file.tex", $normal_header);
# 			Util::print_message("$codcour, $output_file.tex ok!");

			my $output_tex  = "";
			$output_tex    .= "\\input{$output_file}\n\n";
			my $map_for_course = <<'MAP';
\begin{htmlonly}
	\begin{rawhtml}
		<div class="center">
            <iframe scrolling="no" frameborder="0" src="./figs/<codcour>.svg" width="<WIDTH>" height="<HEIGHT>">
                  <p><b>This browser is not able to show SVG: try Firefox, Chrome, Safari, or Opera instead.</b></p>
            </iframe>
        </div>
	\end{rawhtml}
\end{htmlonly}
MAP
			#$map_for_course =~ s/<OutputFigsDir>/$OutputFigsDir/g;
			$map_for_course =~ s/<codcour>/$codcour_label/g;
			$output_tex    .= $map_for_course;
			#$output_tex    .= "\\begin{figure}\n";
			#$output_tex    .= "\\centering\n";
			#$output_tex    .= "\\includegraphics[scale=0.66]{\\OutputFigsDir/$codcour_label}\n";
			#$output_tex    .= "\\caption{Cursos relacionados con xyz \\htmlref{$codcour_label}{sec:$codcour_label}}\n";
			#$output_tex    .= "\\label{fig:prereq:$codcour_label}\n";
			#$output_tex    .= "\\end{figure}\n";

			Util::write_file("$output_file-html.tex", $output_tex);
 			Util::print_message("$output_file-html.tex ok!");
			#exit;
		}
	 }
	 #Util::print_error("TODO: XYZ Aqui falta poner varios silabos en idiomas !");
}

sub get_course_dot_map($$$)
{
	my ($codcour, $lang, $course_tpl) = (@_);
	my $min_sem_to_show = $Common::course_info{$codcour}{semester};
	my $max_sem_to_show = $Common::course_info{$codcour}{semester};

	my %local_list_of_courses_by_semester = ();
	push(@{$local_list_of_courses_by_semester{$Common::course_info{$codcour}{semester}}}, $codcour);
	my $prev_courses_dot = "";
	# Map PREVIOUS courses
	foreach my $codprev (@{$Common::course_info{$codcour}{prerequisites_for_this_course}})
	{	$prev_courses_dot .= Common::generate_course_info_in_dot_with_sem($codprev, $course_tpl, $lang)."\n";
		my ($output_txt, $regular_course) = Common::generate_connection_between_two_courses($codprev, $codcour, $lang);
		$prev_courses_dot .= $output_txt;
		if($regular_course == 1 )
		{	if(	$Common::course_info{$codprev}{semester} < $min_sem_to_show )
			{	$min_sem_to_show = $Common::course_info{$codprev}{semester} ;	}
			push(@{$local_list_of_courses_by_semester{$Common::course_info{$codprev}{semester}}}, $codprev);
		}
	}
	my $this_course_dot = $course_tpl;
	my %map = ("FONTCOLOR"	  => "black",
				"FILLCOLOR"	  => "yellow",
				"BORDERCOLOR" => "black");
	$this_course_dot = Common::replace_tags_from_hash($this_course_dot, "<", ">", %map);
	$this_course_dot = Common::generate_course_info_in_dot_with_sem($codcour, $this_course_dot, $lang)."\n";
	$this_course_dot =~ s/\s*URL="URL.*?",\s*/ /g;

	# Map courses AFTER this course
	my $post_courses_dot = "";
	foreach my $codpost (@{$Common::course_info{$codcour}{courses_after_this_course}})
	{
		$post_courses_dot .= Common::generate_course_info_in_dot_with_sem($codpost, $course_tpl, $lang)."\n";
		my ($output_txt, $regular_course) = Common::generate_connection_between_two_courses($codcour, $codpost, $lang);
		$post_courses_dot .= $output_txt;
		if($regular_course == 1 )
		{	if(	$Common::course_info{$codpost}{semester} > $max_sem_to_show )
			{	$max_sem_to_show = $Common::course_info{$codpost}{semester} ;	}
			push(@{$local_list_of_courses_by_semester{$Common::course_info{$codpost}{semester}}}, $codpost);
		}
	}
	my $sem_col 		= "";
	my $sem_definitions = "";
	my $same_rank 		= "";
	my $sep 			= "";
	for( my $sem_count = $min_sem_to_show; $sem_count <= $max_sem_to_show; $sem_count++)
	{
		my $sem_label = Common::sem_label($sem_count, $lang);
		my $this_sem = "\t{ rank = same; $sem_label; ";
		foreach my $one_cour (@{$local_list_of_courses_by_semester{$sem_count}})
		{	$this_sem .= "\"".Common::get_label($one_cour)."\"; ";		}
		$same_rank .= "$this_sem }\n";
		$sem_col .= "$sep$sem_label";
# 				,fillcolor=black,style=filled,fontcolor=white
		$sem_definitions .= "\t$sem_label [shape=box];\n";
		$sep = "->";
	}
	my $output_tex  = "";
	$output_tex .= "digraph $codcour\n";
	$output_tex .= "{\n";
	$output_tex .= "\tbgcolor=white;\n";
	$output_tex .= "\tcompound=true;\n";
	$output_tex .= "\t$sem_col;\n";
	$output_tex .= "\n";
	$output_tex .= $sem_definitions;
	if(not $prev_courses_dot eq "")
	{	$output_tex .= "$prev_courses_dot\n";	}

	$output_tex .= "$this_course_dot\n";

	if(not $post_courses_dot eq "")
	{	$output_tex .= "$post_courses_dot\n";	}
	$output_tex .= "$same_rank\n";

	$output_tex .= "}\n";
	return $output_tex;
}


sub generate_course_dot_map($$$$)
{
	my ($codcour, $lang, $course_tpl, $output_file) = (@_);
	my $output_tex 	= get_course_dot_map($codcour, $lang, $course_tpl);
	Util::write_file($output_file, $output_tex);
	Util::print_message("Generating $output_file ok! ..."); 
}

sub generate_dot_maps_for_all_courses($)
{
    my ($lang) = (@_);
	Util::check_point("detect_critical_path");
	my $size = "big";
	my $template_file	= Common::read_dot_template($size, $lang);
	my $course_tpl 		= Util::read_file($template_file);
	Util::print_message("Reading $template_file ... (generate_dot_maps_for_all_courses)");
	my $OutputDotDir  				= Common::get_template("OutputDotDir");
	my $OutputFigsDir 				= Common::get_template("OutputFigsDir");
	my $batch_txt 					= "#!/bin/csh\n\n";
	
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
	{	$batch_txt .= "# Semester #$semester\n";
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{	my $output_file = "$OutputDotDir/$codcour.dot";
			generate_course_dot_map($codcour, $lang, $course_tpl, $output_file);
			$batch_txt	.= "echo \"Generating $OutputFigsDir/$codcour.svg ...\"\n";
			$batch_txt	.= "dot -Tps  $output_file -o $OutputFigsDir/$codcour.ps; \n";
      		$batch_txt	.= "dot -Tsvg $output_file -o $OutputFigsDir/$codcour.svg; \n\n";
		}
	 }
	 my $batch_map_for_course_file = Common::get_template("out-gen-map-for-course");
	 Util::write_file($batch_map_for_course_file, $batch_txt);
	 system("chmod 774 $batch_map_for_course_file");
	 Util::print_message("generate_dot_maps_for_all_courses ok!");
}

1;

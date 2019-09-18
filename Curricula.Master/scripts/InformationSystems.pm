#!/usr/bin/perl -w
use strict;
use Lib::Common;

package Common;
use Carp::Assert;
use Data::Dumper;
use Clone 'clone';
use Lib::Util;
use Cwd;
use strict;

if( defined($ENV{'CurriculaParam'}))    { $Common::command = $ENV{'CurriculaParam'};    }
if(defined($ARGV[0])) { $Common::command = shift or Util::halt("There is no command to process (i.e. AREA-INST)");      }

my %LU_info = ();
my %ISBOKAreas = ("IT"  => "Tecnologia de Información",
                "OMC" => "Organización y Gestión",
                "TDS" => "Teorí­a y Desarrollo de Sistemas de Información"
	       );
my $replacements    = "";

sub format_body($@)
{
	my ($env, @list) = (@_);
 	#print "Env = $env\n";
	my $out_txt = "";
	$out_txt .= "\\begin{$env}\n";
	my $count = 0;
	foreach my $item (@list)
	{
		if($item =~ m/-(.*)/)
		{
			$out_txt .= "\\item $1\n";
			$count++;
		}
		else
		{	Util::print_message("Line out of format \"$item\"\n");
		}
	}
	$out_txt .= "\\end{$env}\n";
	if($count > 0)
	{	return ($out_txt, $count);	}
	return ("", 0);
}

sub generate_IS_LU($$)
{
	my ($in_file, $out_file) = (@_);	
	my $fulltxt = Util::read_file($in_file);
	$fulltxt =~ s/\n\n/\n/g;
	Util::print_message("Reading $in_file ...\n");
	
	my $out_txt = "";
	$out_txt = "% File generated by ./scripts/gen-IS-bok.pl $Common::config{area}-$Common::config{institution} ... do not modify manually !!!\n";
	my $count = 0;
	while($fulltxt =~ m/\\begin\{LU(.*?)\}(.*?)\{(.*?)\}\{(.*?)\}\{(.*?)\}\s*((?:.|\n)*?)\\end\{LU\}/g)
	{
		my $unit_number  = $1;
		my $subsection   = $2;
		my $unit_title   = $3;
		my $unit_bib     = $4;
		my $unit_others  = $5;
		my $body 	 = $6;
		#Util::print_message("LU$unit_number ... subsection =\"$subsection\"");
		my ($goal_body, $obj_body) = ("", "");
		my (@goal_v   , @obj_v) = ((), ());
		my $prefix = "";
		if($subsection =~ m/\[(.*?)\]/)
		{	$prefix = "sub";	
			#print "sub $1\n";
		}
		$unit_title = $Common::config{dictionary}{UnitNotDefined} if($unit_title eq "");
		$out_txt .= "\\$prefix"."subsection{LU$unit_number. $unit_title}";
		#$out_txt .= "\\$prefix"."subsection*{\\thesubsection~$unit_title (Unidad de Aprendizaje \\\#$unit_number)}";
		$out_txt .= "\\label{sec:LU$unit_number}\n";
		#$out_txt .= "\\addtocounter{subsection}{1}\n";
		
		# Processing goals ...
		if($body =~ m/\\begin\{goal\}\s*((?:.|\n)*?)\\end\{goal\}/)
		{	#print "$1\n"; 
			@goal_v    = split(/\n/, $1); 	
		}
		else{		Util::print_message("UN = $unit_number there is something wrong in {goal} environment ...\n");	}
		
		my ($goals_tex, $ngoals) = format_body("LUGoal", @goal_v);

		#print "$goals_tex\n"; #exit;
		$LU_info{$unit_number}{LUGoal} = $goals_tex;
		
		# Processing objectives ...
		if($body =~ m/\\begin\{objectives\}\s*((?:.|\n)*?)\\end\{objectives\}/)
		{	#print "$1\n"; #exit;
			@obj_v    = split(/\n/, $1);		
		}
		else{		Util::print_message("UN = $unit_number there is something wrong in {objectives} environment\n");	}
		my ($obj_tex, $nobj) = format_body("LUObjective", @obj_v);
		#print "$obj_tex\n"; exit;
		$LU_info{$unit_number}{LUObjective} = $obj_tex;
		
		if( ($ngoals+$nobj) > 0)
		{
		      $out_txt .= "\\begin{LearningUnit}\n";
		      $out_txt .= "$goals_tex\n";
		      $out_txt .= "$obj_tex";	
		      $out_txt .= "\\end{LearningUnit}\n\n";
		}
		$count++;
	}
	Util::write_file($out_file, $out_txt);
	Util::print_message("generate_IS_LU ($count LU processed) OK!");
	Util::check_point("generate_IS_LU");
}

sub generate_IS_LU_macros($$)
{
	my ($in_file, $out_file) = (@_);
	Util::precondition("generate_IS_LU");
	my $fulltxt = Util::read_file($in_file);
	$fulltxt =~ s/\n\n/\n/g;
	my $out_txt = "";
	
	while($fulltxt =~ m/\\begin\{LU(.*?)\}(.*?)\{(.*?)\}\{(.*?)\}\{(.*?)\}\s*((?:.|\n)*?)\\end\{LU\}/g)
	{
		my ($unit_number, $subunit_number)  = ($1,$2);
		#Util::print_message("LU$unit_number       \r");
		my $unit_name    = $3;
		my $unit_bib     = $4;
		my $unit_hours   = $5;

		my $newunit = Common::change_number_by_text($unit_number);
		my $prefix = "LU$newunit";
		$prefix =~ s/\./x/g;
		$out_txt .= "\\newcommand{\\$prefix"."Def}{LU$unit_number $unit_name}\n";
		Util::print_message("$prefix"."Def");
		$replacements .=  "LU".$newunit."Name=>LU".$newunit."Def\n";

# 		print "LU$newunit"."Name\n";;
		$unit_bib =~ s/ //g;
		$unit_bib = "I do not find bib-item in $in_file" if($unit_bib eq "");
		$out_txt .= "\\newcommand{\\$prefix"."Bib}{$unit_bib}\n";
		$out_txt .= "\\newcommand{\\$prefix"."Hours}{$unit_hours}\n\n";
		$out_txt .= "\\newcommand{\\$prefix"."Goal}{%\n";
		$out_txt .= "$LU_info{$unit_number}{LUGoal}";
		$out_txt .= "$LU_info{$unit_number}{LUObjective}}\n\n";
	}
	Util::write_file($out_file, $out_txt);
	Util::check_point("generate_IS_LU_macros");
	Util::print_message("generate_IS_LU_macros OK!");
}

sub process_topics($)
{
	my ($txt) = (@_);
	my $out_txt 	  = "";
	my @lines = split "\n", $txt;
	my $count = 0;
	foreach my $line (@lines)
	{
		if($line =~ m/^-(.*)/)
		{
			$lines[$count] = "\\item $1";
		}
		$count++;
	}
	
	return join("\n", @lines);
}

sub gen_IS_BOK($$)
{
	my ($in_file, $out_file) = (@_);
	open(IN, "<$in_file") or die "gen_IS_BOK: $in_file does not open  \n";
	my $fulltxt = join("", <IN>);
	close IN;
 	$fulltxt =~ s/\n\n/\n/g;
	
	#$fulltxt = Common::replace_accents($fulltxt);
	#@contents = split("\n", $fulltxt);
	my $out_txt  = "";
	while($fulltxt =~ m/\\begin\{BKL2\}\{(.*?)\}\{(.*?)\}\s*((?:.|\n)*?)\\end\{BKL2\}/g)
	{
		my $topic_code = $1;
		my $topic_name = $2;
		my $topic_body = $3;
		
		#Util::print_message("topic_code = $topic_code, topic_name = $topic_name");
		$topic_body = process_topics($topic_body);

		my $topic_env = "boktopico";
		$topic_body =~ s/\(begin_topics\)/\\begin{$topic_env}/g;
		$topic_body =~ s/\(end_topics\)/\\end{$topic_env}/g;
		
		$topic_env = "boksubtopico";
		$topic_body =~ s/\(begin_subtopics\)/\\begin{$topic_env}/g;
		$topic_body =~ s/\(end_subtopics\)/\\end{$topic_env}/g;

		while($topic_body =~ m/\\begin\{$topic_env\}\s*((?:.|\n)*?)\\end\{$topic_env\}/g)
		{
			my $subtopic_body = $1;
			my $count = 0;
			while($subtopic_body =~ m/\\item /g)
			{
				$count++;
			}
			if($count == 0)
			{
				$topic_body =~ s/\\begin\{$topic_env\}\s*$subtopic_body\\end\{$topic_env\}//g;
			}
		}
		
		$topic_body =~ s/\(inicio_objetivo\)//g;
		$topic_body =~ s/\(fin_objetivo\)//g;

		$out_txt .= "\\subsection{$topic_code. $topic_name}\\label{sec:BOK-$topic_code}\n";
		$out_txt .= $topic_body;
	}
	Util::write_file($out_file, $out_txt);
	Util::print_message("gen_IS_BOK OK!");
}

# pending
sub generate_IS_BOK_macros($$)
{
	my ($in_file, $out_file) = (@_);
	my $fulltxt = Util::read_file($in_file);
	$fulltxt =~ s/\n\n/\n/g;

	my @contents = split(/\n/, $fulltxt);
	my $out_txt  = "";
	my $level    = 0;
	my @prefix   = (0, 0, 0, 0, 0);
	my ($BLK1, $BLK2, $BLK3, $BLK4) = (1, 2, 3, 4);
	my $curr_area = "";
	my $current_BOKArea = "";
	my $current_topic   = "";
	foreach my $linea (@contents)
	{
		if($linea =~ m/\\begin\{BKL2\}\{(.*?)(\d+)\}\{(.*?)\}/g)
		{
			my $topic_area = $1;
			my $topic_code = $2;
			my $topic_name = $3;
			$prefix[$BLK2] = $topic_code;
			$prefix[$BLK3] = 0;
			# It is a new area
			if(not $topic_area eq $curr_area)
			{
				$curr_area = $topic_area;
				$prefix[$BLK1]++;
			}
			if(not $current_BOKArea eq $topic_area)
			{
				$current_BOKArea = $topic_area;
				#Util::print_message("topic_area=$topic_area");
				if( defined($ISBOKAreas{$topic_area}) )
				{	$out_txt .= "\\newcommand{\\$topic_area"."BOKArea}{$BOKAreas{$topic_area}}\n";	}
				else
				{	Util::halt("It seems you did not defined prefix \"$topic_area\" ... see file $in_file");	}
				$out_txt .= "\\newcommand{\\$topic_area"."Description}{}\n\n";
			}
			$level = 2;
			$current_topic  = Common::change_number_by_text("$topic_area$topic_code");
			$out_txt .= "\n\\newcommand{\\$current_topic"."Def}{$topic_name}\n";
			#$out_txt .= "\%$topic_area$topic_code\n";
		}
		elsif($linea =~ m/\(begin_topics\)/){	$level++;	}
		elsif($linea =~ m/\(end_topics\)/){	$level--;	}
		elsif($linea =~ m/\(begin_subtopics\)/)
		{	
			$prefix[$BLK4] = 0;
			$level++;
		}
		elsif($linea =~ m/\(end_subtopics\)/){	$level--;	}
		elsif($linea =~ m/^-(.*)/)
		{
			my $item = $1;
			$prefix[$level]++;
			my $label = "$prefix[$BLK1].$prefix[$BLK2]";
			if($level >= 3)
			{	$label .= ".$prefix[$BLK3]";
				if($level >= 4) {	$label .= ".$prefix[$BLK4]";	}
			}
			my $labelproc = Common::change_number_by_text($label); 
			$labelproc =~ s/\./x/g;
			$out_txt .= "\%level = $level, prefix[level] = $label\n";
			
			my $new_command    = "$current_topic"."Topic$labelproc";
			my $this_replacement = "$labelproc=>$new_command\n";
			$out_txt .= "\% rep: $this_replacement\n";
			$out_txt .= "\\newcommand{\\$new_command}{$item}\n";

			$replacements  .= $this_replacement;
		}
# 		$topic_body =~ s/\(inicio_objetivo\)//g;
# 		$topic_body =~ s/\(fin_objetivo\)//g;
	}
	$replacements  .= "\n";
	Util::write_file($out_file, $out_txt);

	#Util::print_message("generate IS_BOK_macros($in_file, $out_file) OK!");
	Util::print_message("generate IS_BOK_macros OK!");
}

sub generate_IS_BOK($)
{
	my ($lang) = (@_);
	Util::begin_time();
	Common::set_initial_configuration($Common::command);
	my $OutputTexDir = Common::get_template("OutputTexDir");

	my $LU_unprocessed_file = Common::get_expanded_template("InTexDir", $lang)."/learning-units.tex";
	my $bok_in_file 		= Common::get_expanded_template("InTexDir", $lang)."/IS-bok-in.tex";
	
	generate_IS_LU       ($LU_unprocessed_file, Common::get_expanded_template("InTexDir", $lang)."/LU.tex"));;
	gen_IS_BOK      ($bok_in_file, "$OutputTexDir/IS-bok.tex");
	generate IS_BOK_macros($bok_in_file, Common::get_template("InStyDir")."/bok-macros.sty");
	generate_IS_LU_macros ($LU_unprocessed_file, Common::get_template("InStyDir")."/LU-macros.sty");

	my $replacements_file = Common::get_template("in-replacements-file");
	Util::print_message("Generating: $replacements_file ... OK!");
    Util::write_file($replacements_file, $replacements);
}

#my $lang = $Common::config{language_without_accents}
#generate_IS_BOK($lang);
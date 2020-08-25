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

# ok

sub replace_outcomes_sequence($)
{
    my ($maintxt) = (@_);
#     if( $maintxt =~ m/\\begin\{enumerate\}\[a\)\]\s*\n((.|\t|\s|\n)*?)\\end\{enumerate\}/g )
#     {
# 	my ($outcomeslist) = ($1);
# 	$maintxt =~ s/\\begin\{enumerate\}\[a\)\]\s*\n((.|\t|\s|\n)*?)\\end\{enumerate\}/--outcomes-list--/g;
# 	my $output = "";
# 	foreach my $outcome_in (split("\n", $outcomeslist))
# 	{
# 	      if( $outcome_in =~ m/\\item (.*)\\label\{out:Outcome(.*?)\}/g )
# 	      {
# 	          my ($txt, $letter) = ($1, $2);
# 		  $output .= "\\item \\textbf{ $letter} $txt\\label\{out:Outcome$letter\}\n";
# 	      }
# 	}
# # 	print Dumper($output); exit;
# 	$outcomeslist = Common::replace_special_chars($outcomeslist);
# 	$maintxt =~ s/--outcomes-list--/\\begin\{enumerate\}\n$output/\\end\{enumerate\}\n/g;
#     }
# #     \\begin\{enumerate\}\[a\)\]\s*\n$outcomeslist\\end\{enumerate\} )
    return $maintxt;
}

sub replace_syllabus($)
{
	my ($text) = (@_);
	my $syllabus_count = 0;
	$text =~ s/\\begin\{syllabus\}/\%/g;
	#Replace Sumillas
	while($text =~ m/\\course\{(.*?)\}\{(.*?)\}\{(.*?)\}/g)
	{
		my ($course_name, $course_type, $codcour) = ($1, $2, $3);
 		my ($course_name_wsc, $course_type_wsc, $codcour_wsc) = (Common::replace_special_chars($course_name), Common::replace_special_chars($course_type), Common::replace_special_chars($codcour));
		my $syllabus_head  = ""; 

		$syllabus_head .= "\n\\section{$course_name ($course_type)}\\label{sec:$codcour}\n";
		$syllabus_head .= "\\input{".Common::get_template("OutputPrereqDir")."/$codcour-html}\n";

		$text =~ s/\\course\{$course_name_wsc\}\{$course_type_wsc\}\{$codcour_wsc\}/$syllabus_head/g;
# 		print ".";
		$syllabus_count++;
	}
	$text =~ s/\\end\{syllabus\}//g;
	return ($text, $syllabus_count);
}

sub replace_outcomes_environments($$$)
{
	my ($text, $specific, $label_tex) = (@_);
	my $env = $specific."outcomes";
	my $outcomes_count = 0;
	$text =~ s/\\begin\{$env\}\s*\n((.|\t|\s|\n)*?)\\end\{$env\}/$label_tex\n\\begin\{description\}\n$1\\end\{description\}\n/g;
	$text =~ s/\\begin\{$env\}(\{.*\})+\s*\n((.|\t|\s|\n)*?)\\end\{$env\}/$label_tex\n\\begin\{description\}\n$2\\end\{description\}\n/g;
	return ($text, $outcomes_count);
}

sub replace_competences_environments($$)
{
	my ($text, $label_tex) = (@_);
	my $outcomes_count = 0;
	$text =~ s/\\begin\{competences\}\s*\n((.|\t|\s|\n)*?)\\end\{competences\}/$label_tex\n\\begin\{description\}\n$1\\end\{description\}\n\n\\subsection\{$Common::config{dictionary}{Units}\}/g;
	return ($text, $outcomes_count);
}

# ok
sub replace_unit_environments($$$$)
{
	my ($text,$env_name,$label_text, $label_type) = (@_);
	my $count  = 0;

	my ($macro, $alt_name, $bib_items, $nhours, $skills) = ("", "", "", "", "");
	while( $text =~ m/\\begin\{$env_name\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}/g )
	{	($macro, $alt_name, $bib_items, $nhours, $skills) = ($1, $2, $3, $4, $5);
		my ($macro2, $alt_name2) = (Common::replace_special_chars($macro), Common::replace_special_chars($alt_name));
		my $unit_name = $macro;
		if( $macro eq "" )
		{	$unit_name = $alt_name;		}
		my $unit_header = "\\begin{$env_name}{$macro}{$alt_name}{$bib_items}{$nhours}{$skills}";
		#if( $macro eq "")
		#{	Util::print_message("replacing unit: $unit_header");	}
		$text =~ s/\\begin\{$env_name\}\{$macro2\}\{$alt_name2\}\{$bib_items\}\{$nhours\}\{$skills\}/\\subsubsection{$unit_name ($nhours $Common::config{dictionary}{hours}) \[$Common::config{dictionary}{Skills} $skills\]}\n\\textbf{$Common::config{dictionary}{BibliographySection}}: \\cite{$bib_items}/g;
# 		$text =~ s/\\begin{$env_name}{$macro}{$alt_name}{$bib_items}{$nhours}{$skills}/\\subsubsection{$unit_name ($nhours $Common::config{dictionary}{hours}) \[$Common::config{dictionary}{Skills} $skills\]}\n\\textbf{$Common::config{dictionary}{BibliographySection}}: \\cite{$bib_items}/g;
	}
	$text =~ s/\\end\{$env_name\}//g;
	return ($text, $count);
}

# ok
sub replace_bib_environments($$$$)
{
	my ($text, $env_name, $label_text, $label_type) = (@_);
	my $count  = 0;
	#Replace Bib files
	while($text =~ m/\\bibfile\{(.*?)\}/g)
	{
		my $bib_file = $1;
		#print "bib_file=\"$bib_file\" ";
		push(@{$Common::config{bib_files}}, $bib_file);
		my $text_out  = "";
		$text =~ s/\\bibfile\{$bib_file\}/$text_out/g;
		$count++;
	}
	$text =~ s/\\begin\{$env_name\}\s*\n//g;
	$text =~ s/\\end\{$env_name\}\s*\n//g;
	return ($text, $count);
}

# ok
sub replace_environments($)
{
	my ($text) = (@_);
	my ($environments_count, $syllabus_count, $justification_count, $goals_count) = (0, 0, 0, 0);
	my ($units_count, $bib_count, $topicos_count, $objetivos_count, $outcomes_count, $specific_outcomes_count)        = (0, 0, 0, 0, 0, 0);

	($text, $syllabus_count) = replace_syllabus($text);
	Util::print_message("$Common::institution: Syllabi processed: $syllabus_count ...");
	
	($text, $justification_count) = Common::replace_bold_environments($text, "justification", $Common::config{dictionary}{Justification}, $Common::config{subsection_label});
	Util::print_message("$Common::institution: Justification: $justification_count");
	
	($text, $goals_count) = Common::replace_enumerate_environments($text, "goals", $Common::config{dictionary}{GeneralGoals}, $Common::config{subsection_label});
	Util::print_message("$Common::institution: Goals: $goals_count");
	
	#$text =~ s/\\ExpandOutcome{(.*?)}{(.*?)}/\\item[\\ref{out:Outcome$1}) $Common::config{dictionary}{BloomLevel} $2] \\Outcome$1/g;
	#$text =~ s/\\PrintOutcome{(.*?)}/\\ref{out:Outcome$1})~\\Outcome$1/g;

	#$text =~ s/\\ExpandOutcome{(.*?)}{(.*?)}/\\item[\\ref{out:Outcome$1}) $Common::config{dictionary}{BloomLevel} $2] \\Outcome$1/g;
	#$text =~ s/\\PrintOutcome{(.*?)}/\\ref{out:Outcome$1})~\\Outcome$1/g;
	
	($text, $outcomes_count) = replace_outcomes_environments($text, "", "\\$Common::config{subsection_label}"."{$Common::config{dictionary}{ContributionToOutcomes}}" );
	Util::print_message("$Common::institution: Outcomes: $outcomes_count");
	
	($text, $specific_outcomes_count) = replace_outcomes_environments($text, "specific", "\\$Common::config{subsection_label}"."{$Common::config{dictionary}{ContributionToOutcomes}}" );
	Util::print_message("$Common::institution: Specific Outcomes: $specific_outcomes_count");
	
	($text, $outcomes_count) = replace_competences_environments($text, "\\$Common::config{subsection_label}"."{$Common::config{dictionary}{ContributionToSkills}}" );
	Util::print_message("$Common::institution: Outcomes: $outcomes_count");

	($text, $objetivos_count) = Common::replace_enumerate_environments($text, "learningoutcomes", $Common::config{dictionary}{LearningOutcomes}, $Common::config{bold_label});
	Util::print_message("$Common::institution: Goals: $objetivos_count");

	($text, $topicos_count) = Common::replace_enumerate_environments($text,"topics", $Common::config{dictionary}{Topics}, $Common::config{bold_label});
	Util::print_message("$Common::institution: Topics: $topicos_count");

	($text, $units_count) = replace_unit_environments($text, "unit", "", $Common::config{subsection_label});
	Util::print_message("$Common::institution: Units: $units_count");

	($text, $bib_count) = replace_bib_environments($text, "coursebibliography", $Common::config{dictionary}{BibliographySection}, $Common::config{subsection_label});
	Util::print_message("$Common::institution: Bib files: $bib_count");

	my $count = $environments_count + $syllabus_count + $justification_count + $goals_count;
	$count += $units_count + $bib_count + $topicos_count + $objetivos_count;
	return ($text, $count);
}

sub replace_special_cases($)
{
    my ($maintxt) = (@_);
#     $maintxt =~ s/  / /g;
#     $maintxt =~ s/\s*\}/\}/g;
#     $maintxt =~ s/\{\s*/\{/g;
    $maintxt =~ s/\\begin\{btSect\}((.|\\|\n)*)\\end\{btSect\}//g;
    $maintxt =~ s/\\begin\{btUnit\}//g;
    $maintxt =~ s/\\end\{btUnit\}//g;
    $maintxt =~ s/\\usepackage\{bibtopic\}//g;
    $maintxt =~ s/\\usepackage\{.*?syllabus\}//g;
	$maintxt =~ s/\\usepackage\{.*?config-hdr-foot.*?\}//g; # s matches the .
    $maintxt =~ s/\\Revisado\{.*?\}//g;
    $maintxt =~ s/\\.*?\{landscape\}//g;
    $maintxt =~ s/\\pagebreak//g;
    $maintxt =~ s/\\newpage//g;
    $maintxt =~ s/\s*$Common::config{dictionary}{Pag}.?~\\pageref\{sec:.*?\}//g;
    $maintxt =~ s/[,-]\)/\)/g;
    $maintxt =~ s/\(\)//g;
    $maintxt =~ s/\$\^\{(.*?)\}\$~$Common::config{dictionary}{Sem}/$1~$Common::config{dictionary}{Sem}/g;
    #$maintxt =~ s/\\newcommand{\\comment}/\%\\newcommand{\\comment}/g;
    $maintxt =~ s/\\newcommand\{$Common::institution\}\{.*?\}//g;
    my $country_without_accents = Common::get_template("country_without_accents");
    $maintxt =~ s/\\newcommand\{$country_without_accents\}\{.*?\}//g;
    my $country = Common::get_template("country");
    $maintxt =~ s/\\newcommand\{$country\}\{.*?\}//g;
    my $language_without_accents = Common::get_template("language_without_accents");
    $maintxt =~ s/\\newcommand\{$language_without_accents}\{.*?\}//g;
    my $language = Common::get_template("language");
    $maintxt =~ s/\\newcommand\{$language\}\{.*?\}//g;

    $maintxt =~ s/\{inparaenum\}/\{enumerate\}/g;
    $maintxt =~ s/\{subtopics\}/\{enumerate\}/g;
    $maintxt =~ s/\{subtopicos\}/\{enumerate\}/g;
    $maintxt =~ s/\{evaluation\}/\{itemize\}/g;
    $maintxt =~ s/\$(.*?)\^\{(.*?)\}\$/$1$2/g;

    my $column2 = Common::replace_special_chars($Common::config{column2});
    $maintxt =~ s/$column2//g;
    my $row2 = Common::replace_special_chars($Common::config{row2});
    $maintxt =~ s/$row2//g;

    $maintxt =~ s/(\\begin\{tabularx\})\{.*?\}/$1/g;
    $maintxt =~ s/\\begin\{tabularx\}/\\begin\{tabular\}/g;
    $maintxt =~ s/\\end\{tabularx\}/\\end\{tabular\}/g;
    $maintxt =~ s/\[h!\]//g;

    $maintxt =~ s/\\begin\{LearningUnit\}//g;
    $maintxt =~ s/\\end\{LearningUnit\}//g;
    $maintxt =~ s/\\begin\{LUGoal\}/\\begin\{enumerate\}\[ \\textbf\{I:\}\]/g;
    $maintxt =~ s/\\end\{LUGoal\}/\\end\{enumerate\}/g;
    $maintxt =~ s/\\begin\{LUObjective\}/\\begin\{enumerate\}\[ \\textbf\{I:\}\]/g;
    $maintxt =~ s/\\end\{LUObjective\}/\\end\{enumerate\}/g;

    my %columns_header = ();
    while($maintxt =~ m/\\begin\{tabular\}\{/g)
    {     my ($cpar, $header) = (1, "");
          while($cpar > 0 and $maintxt =~ m/(.)/g)
          {
              my $c = $1;
              $cpar++ if($c eq "{");
              $cpar-- if($c eq "}");
              $header .= $c if($cpar > 0);
          }
          $columns_header{$header} = "";
    }
    foreach my $old_columns_header (keys %columns_header)
    {
          my $new_columns_header = $old_columns_header;
          $new_columns_header    =~ s/\|//g;
          $new_columns_header    =~ s/X/l/g;
          #Util::print_message(".");
          $new_columns_header    = Common::InsertSeparator($new_columns_header);
          #Util::print_message(":");
          $old_columns_header    = Common::replace_special_chars($old_columns_header);
          #Util::print_message("*");
          #Util::print_message("$old_columns_header->$new_columns_header");
          $maintxt =~ s/\\begin\{tabular\}\{$old_columns_header\}/\\begin\{tabular\}\{$new_columns_header\}/g;
    }
#      $maintxt =~ s/\\rotatebox.*?\{.*?\}\{\(\\colorbox\{.*?\}\{\\htmlref\{.*?\}\{.*?\}\}\)\}/$1/g; xyz;
		   #\rotatebox[origin=lb,units=360]{90}{\colorbox{cornflowerblue}{\htmlref{CS1D01}{sec:CS1D01}}}
     $maintxt =~ s/\\rotatebox.*?\{.*?\}\{(.*?\{.*?\}\{\\htmlref\{.*?\}\{.*?\}\})\}/$1/g;
    #print "siglas = $macros{siglas} x2\n";

     #\\ref{out:Outcomeb}) & \PrintOutcomeWOLetter{b}
#     if(defined($Common::config{outcomes_map}{a}))
#     {   
	    #$maintxt =~ s/\\PrintOutcomeLetter{(.*?)}\s*?&\s*\\PrintOutcomeWOLetter{(.*?)}/\\multicolumn{2}{l}{\\textbf{$Common::config{outcomes_map}{$1}\)}~\\Outcome$1Short}/g;
	    $maintxt =~ s/\\PrintOutcomeWOLetter\{(.*?)\}/\\Outcome$1Short/g;
#     }
    my $Skill = Common::replace_special_chars("$Common::config{dictionary}{Skill}/$Common::config{dictionary}{COURSENAME}");
    #Util::print_message("Skill = $Skill");
     $maintxt =~ s/&\s*?\\textbf\{$Skill\}/\\multicolumn\{2\}\{l\}\{\\textbf\{$Common::config{dictionary}{Skill}\}\}/g;
    while( $maintxt =~ m/\\includegraphics\[(.*?)\]\{(.*?)\}/g)
    {
	my ($fig_params, $file) = ($1, $2);
	my $file_processed	= Common::replace_special_chars($file);
	if(not $file =~ m/logo/)
	{	$maintxt =~ s/\\includegraphics\[(.*?)\]\{$file_processed\}/\\includegraphics\{$file\}/g;	}
    }
    $maintxt =~ s/small-graph-curricula\.ps\}/big-graph-curricula\}/;
    return $maintxt;
}

sub main()
{
	Util::begin_time();
	Common::setup();
	Common::read_files_to_be_changed();

	my $lang = $Common::config{language_without_accents};
	my $outcomes_macros_file = Common::get_expanded_template("in-outcomes-macros-file", $lang);
	$outcomes_macros_file =~ s/<LANG>/$lang/g;
	Common::read_special_macros($outcomes_macros_file, "Outcome"); 
	Common::read_special_macros($outcomes_macros_file, "Competence"); 
	Common::read_special_macros($outcomes_macros_file, "CompetenceLevel"); 
	
	Common::read_bok($lang);
	#foreach my $key (sort {$a cmp $b} keys %{$Common::config{macros}})
	#{	
	#	if($key =~ m/SDFFundamentalDataStructuresTopic.*/g )
	#	{
	#		#print Dumper( \%{$Common::config{macros}{SDFFundamentalDataStructuresTopicAbstract}} );
	#		#print Dumper( \%{$Common::config{macros}{SDFFundamentalDataStructuresTopicReferences}} );
	#		Util::print_message("$key=$Common::config{macros}{$key}");
	#	}
	#}
	
	GenSyllabi::process_syllabi();
	Common::sort_macros();
	#Util::print_message("test"); exit;
	my $output_file     = Common::get_template("unified-main-file");
	my $main_file       = Common::get_template("curricula-main");
	my $maintxt		    = Util::read_file($main_file);
	$maintxt		    = Common::clean_file($maintxt);
	my $changes 		= 1;
	my $macros_changed	= 0;
	my $environments_count	= 0;
	my $laps		= 0;
	
	while(($changes+$macros_changed+$environments_count) > 0)
	#for(my $laps = 0; $laps < 5 ; $laps++)
	{
		Util::print_message("Laps = ".++$laps) 	   if( $Common::config{verbose} == 1 );
		($maintxt, $macros_changed) = Common::expand_macros   ($main_file, $maintxt);
		($maintxt, $changes)        = Common::expand_sub_files($maintxt);
		($maintxt, $environments_count) = replace_environments($maintxt);
		Util::print_message(" ($changes+$macros_changed+$environments_count) ...") if( $Common::config{verbose} == 1 );
		$maintxt =~ s/\\xref\{(.*?)\}/\\htmlref\{\\$1\}\{sec:BOK:$1\}/g;
		$maintxt =~ s/\\xrefTextAndPage\{(.*?)\}/\\htmlref\{\\$1\}\{sec:BOK:$1\}/g;
#		$maintxt =~ s/\\xref\{(.*?)\}/\\ref\{sec:BOK:$1\} \\htmlref\{\csname #1\endcsname\}\{sec:BOK:#1\}
		Util::print_message("$Common::institution: Environments = $environments_count");
# 		Util::write_file($output_file, $maintxt);
	}

	while( $maintxt =~ m/\\Competence\{(.*?)\}/g )
	{   my ($competence) = ($1);
	    if( not defined($Common::config{Competence}{$1}) )
	    {	Util::print_error("\\Competence{$competence} not defined  ... ($Common::config{Competence}{$competence})");		
		}
	    my $competence_wsc = Common::replace_special_chars($competence);
# 	   	Util::print_message("Replacing \\Competence{$competence} ... ($Common::config{Competence}{$competence})");
	    $maintxt =~ s/\\Competence\{$competence_wsc\}/$competence\) $Common::config{Competence}{$competence}\\label\{outcome:$competence\}/g;
    }
	$maintxt =~ s/\\Competence\{(.*?)\}/$Common::config{Competence}{$1}\\label\{outcome:$1\}/g;
	$maintxt =~ s/\\ShowOutcome\{(.*?)\}\{(.*?)\}/[$1)] $Common::config{Outcome}{$1} ($Common::config{CompetenceLevel}{$2})/g;
	$maintxt =~ s/\\ShowCompetence\{(.*?)\}\{(.*?)\}/[$1)] $Common::config{Competence}{$1} \$\\Rightarrow\$ \\textbf\{Outcome: $2\}/g;
	$maintxt =~ s/\\ShowOutcomeText\{(.*?)\}/$Common::config{Outcome}{$1}/g;

	while( $maintxt =~ m/\\ShowShortOutcome\{(.*?)\}/g )
	{	my $outcome = $1; my $OutcomeShort = $outcome."Short";
# 		Util::print_message("Using short outcome: $OutcomeShort");
		if( $Common::config{Outcome}{$OutcomeShort} )
		{	$maintxt =~ s/\\ShowShortOutcome\{$outcome\}/$Common::config{Outcome}{$OutcomeShort}/g;	}
		else{	Util::print_message("Not defined: Common::config{Outcome}{$OutcomeShort} ... See $outcomes_macros_file !");	}
	}
	$maintxt =~ s/\\xspace/ /g;
	($maintxt, $macros_changed) = Common::expand_macros($main_file, $maintxt);
	foreach my $learningoutcome ("Familiarity", "Usage", "Assessment")
	{	
		#Util::print_message("Common::config{macros}{$learningoutcome}=$Common::config{dictionary}{$learningoutcome}");
		#Using$Common::config{macros}{$learningoutcome}
# 		$maintxt =~ s/\[\\$learningoutcome\s*?\]/\[\\textbf\{$Common::config{macros}{$learningoutcome}}\]/g;
		$maintxt =~ s/\\$learningoutcome/\\textbf\{$Common::config{dictionary}{$learningoutcome}\}/g;
#   		$maintxt =~ s/\(\\$learningoutcome\s*?\)/\(\\textbf\{$Common::config{macros}{$learningoutcome}}\)/g;
		#$maintxt =~ s/\($Common::config{macros}{$learningoutcome}\s*?\)/\(\\textbf\{$Common::config{macros}{$learningoutcome}}\)/g;	
	}
	
	my $books_html	= Common::generate_books_links();
	$maintxt =~ s/<BOOKS>/$books_html/g;
	my $pdf_name = "$Common::config{area}-$Common::config{institution} $Common::config{Plan}";
	my $OutputPdfInstDir = Common::get_template("OutputPdfInstDir");
	my $size 		= Common::get_size("$OutputPdfInstDir/$pdf_name.pdf");
	my $PdfnPages	= Common::getPDFnPages("$OutputPdfInstDir/$pdf_name.pdf");
	my $pdflink		= Common::get_link_with_language_icon("$pdf_name.pdf ($PdfnPages Pages, $size)", "$pdf_name.pdf", $lang);
	$maintxt =~ s/<PDF-LINK>/$pdflink/g;

	#print Dumper(\%{$Common::config{meta_tags}}); exit;
	$maintxt = Common::replace_meta_tags($maintxt, $lang);
	$maintxt = replace_special_cases($maintxt);
#   $maintxt = replace_outcomes_sequence($maintxt);
        
	my $all_bib_items = Common::get_list_of_bib_files();
    #$maintxt =~ s/\\xspace}/}/g;
	$maintxt =~ s/\\end\{document\}/\\bibliography\{$all_bib_items\}\n\\end\{document\}/g;
	while ($maintxt =~ m/\n\n\n/){	$maintxt =~ s/\n\n\n/\n\n/g;	}
	$maintxt = Common::replace_latex_babel_to_latex_standard($maintxt);
	
	$maintxt =~ s/\\cellcolor\{.*?\}//g;
	$maintxt =~ s/\{enumerate\}\s*\\\\\s*\\/\{enumerate\} \\/g;
	Util::write_file($output_file, $maintxt);
	Util::print_message("File $output_file generated OK!");
	Util::print_message("Finishing gen-html-main.pl ... ");
}

main();


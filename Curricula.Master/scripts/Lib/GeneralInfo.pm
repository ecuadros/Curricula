package GeneralInfo;
use Math::Trig;
use Carp::Assert;
use Lib::Common;
use Data::Dumper;
use Cwd;
use List::Util qw(max);
use strict;

# ok
sub generate_course_tables($)
{
	my ($lang) = (@_);
	my $output_file = Common::get_expanded_template("out-tables-foreach-semester-file", $lang);
    my ($begin_tag, $end_tag) = ("<<", ">>");
	my $output_txt = "";
	my $total_credits = 0;
	my $this_line   = $Common::config{dictionary}{course_fields};
 	#Util::print_message("course_field=$this_line"); exit;
	my $cred_column = Common::find_credit_column($Common::config{dictionary}{course_fields});
	my $n_columns   = Common::count_number_of_tags($this_line);
#  	print "COURSENAME=$Common::config{COURSENAME}\n"; exit;

	#Util::print_message("cred_column = $cred_column"); exit;
	my %electives = ();
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
	{
		# Write the header for this table
		my $this_sem_text = "";
		$this_sem_text .= "\\begin{center}\n";
		$this_sem_text .= "\\begin{tabularx}{23cm}{$Common::config{dictionary}{fields_header}}\\hline\n";
		my $caption .= "$Common::config{dictionary}{semester_ordinal}{$semester} ";
		   $caption .= "$Common::config{dictionary}{Semester}";
		$this_sem_text .= "\\multicolumn{$n_columns}{|l|}{\\textbf{$caption}} \\\\ \\hline \n";

# 		$this_sem_text .= "Code & Course & Area & HT & HP & HL & Cr & T & Prerequisites             \\\\ \\hline\n";
 		my $course_headers = $Common::config{course_fields};
		#Util::print_color("GeneralInfo:course_fields=$course_headers");
		#exit;
		if(defined($course_headers) and defined($course_headers))
		{
			$course_headers =~ s/$begin_tag/\\textbf\{$begin_tag/g;
			$course_headers =~ s/$end_tag/$end_tag\}/g;
			$this_sem_text .= Common::replace_tags_from_hash($course_headers, $begin_tag, $end_tag, %{$Common::config{dictionary}});
			$this_sem_text .= "\n";
		}

		# 2nd Write the info for this course
		my $ncourses = 0;
# 		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
# 		{    Util::print_message("Common::course_info{$codcour}{course_type} = $Common::course_info{$codcour}{course_type}");
# 		}

        foreach my $codcour ( @{$Common::courses_by_semester{$semester}} )
		{
            #print "{$semester}{$Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name}}{$Common::course_info{$codcour}{cr}}{$codcour}% $Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name}, $Common::course_info{$codcour}{cr}\n";
			my %this_course_info 	= ();
			#my $codcour_label 	= Common::get_label($codcour);
			$this_line		= $Common::config{dictionary}{course_fields};
			my $prefix		= $Common::course_info{$codcour}{prefix};
			my $pdflink 	= "";
			# my $pdflink 	= Common::get_pdf_link($codcour);
			if(not defined($Common::course_info{$codcour}{bgcolor}))
			{
				Util::print_message("Color is not configured for ".Util::red($codcour)." ...");
				Util::print_message("Verify files: ".Util::red(Common::get_template("colors")));
				my $whichdoesnotexists = "";
				my $InstitutionColorsFile = Common::get_template("institution-color");
				if( -e $InstitutionColorsFile )
				{	Util::print_message("and ".Util::green($InstitutionColorsFile)." ...");	}
				else
				{	Util::print_message("OR ".Util::red("create: $InstitutionColorsFile ..."));	}
				assert(0);
				exit;
			}
 			#Util::print_message("codcour = $codcour, $Common::course_info{$codcour}{bgcolor}");
			$this_course_info{COURSECODE}  = "\\htmlref{\\colorbox{$Common::course_info{$codcour}{bgcolor}}{$codcour}}{sec:$codcour}";
			$this_course_info{COURSENAME} .= Common::GetCourseNameWithLink($codcour, $lang, 1, $pdflink);

#			$this_course_info{COURSENAME} = "\\htmlref{$Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name}}{sec:$codcour}";
# 			Util::print_message("codcour=$codcour");
# 			print Dumper ( \%{$Common::course_info{$codcour}} );
#			if(not $Common::course_info{$codcour}{recommended} eq "")
#			{
#				my ($rec_courses, $sep) = ("", "");
#				foreach my $rec (split(",", $Common::course_info{$codcour}{recommended}))
#				{
## 					print "$rec(A)\n";
#					$rec = Common::get_label($rec);
#					my $semester_rec = $Common::course_info{$rec}{semester};
#					$rec_courses .= "$sep\\htmlref{$rec $Common::course_info{$rec}{$Common::config{language_without_accents}}{course_name}}{sec:$codcour}";
#					$rec_courses .= "($semester_rec";
#					$rec_courses .= "\$^{$Common::config{dictionary}{ordinal_postfix}{$semester_rec}}\$)";
#					$sep = ", ";
## 					print "$rec(C)\n";
#				}
#				$this_course_info{COURSENAME} .= "\\footnote{$Common::config{dictionary}{AdviceRecCourses}: $rec_courses.}";
#			}
#			$this_course_info{COURSENAME} .= " ($Common::config{dictionary}{Pag}~\\pageref{sec:$codcour})~$pdflink";
			$this_course_info{COURSEAREA} .= "$Common::course_info{$codcour}{area}";
			$this_course_info{DPTO}       .= "$Common::course_info{$codcour}{department}";

			if($Common::course_info{$codcour}{th} > 0)
			{	$this_course_info{THEORY} = "$Common::course_info{$codcour}{th}";	}
			else{	$this_course_info{THEORY}      = "~";	}

			if($Common::course_info{$codcour}{ph} > 0)
			{	$this_course_info{PRACTICE} = "$Common::course_info{$codcour}{ph}";	}
			else{	$this_course_info{PRACTICE} = "~";	}

			if($Common::course_info{$codcour}{lh} > 0)
			{	$this_course_info{LABORATORY} = "$Common::course_info{$codcour}{lh}";	}
			else{	$this_course_info{LABORATORY} = "~";	}
			$this_course_info{CR} = "$Common::course_info{$codcour}{cr}";

			if($Common::course_info{$codcour}{course_type} eq "Mandatory")
			{	$this_course_info{TYPE} = $Common::config{dictionary}{MandatoryShort};		}
			else{	$this_course_info{TYPE} = $Common::config{dictionary}{ElectiveShort};		}

			my $area		= $Common::course_info{$codcour}{area};
			$Common::counts{map_cred_area}{$semester}{$area} = 0 if(not defined($Common::counts{map_cred_area}{$semester}{$area}));
			if($Common::course_info{$codcour}{course_type} eq "Mandatory")
			{
				$Common::counts{map_cred_area}{$semester}{$area}  += $Common::course_info{$codcour}{cr};
			}
			else # Electives
			{
                my $group = $Common::course_info{$codcour}{group};
                assert(not $group eq "");
				$Common::counts{electives}{$semester}{$group}{cr}	= $Common::course_info{$codcour}{cr};
                $Common::counts{electives}{$semester}{$group}{area}	= $Common::course_info{$codcour}{area};
			}
			$this_course_info{PREREQ} = "~";
			if( not $Common::course_info{$codcour}{code_and_sem_prerequisites} eq "" )
			{	$this_course_info{PREREQ} = $Common::course_info{$codcour}{code_and_sem_prerequisites};
			}

			$this_line 	= Common::replace_tags_from_hash($this_line, $begin_tag, $end_tag, %this_course_info);
			$this_line 	=~ s/$begin_tag(.*?)$end_tag/~/g;

			$this_sem_text .= $this_line;
			$this_sem_text .= "\n";
			$ncourses++;
		}

		# 3rd. Write the last line containing credits
		$this_line    = $Common::config{course_fields};
		my $cred_left = $Common::config{dictionary}{credits_per_semester} - $Common::config{credits_this_semester}{$semester};
		if($cred_left > 0 && $Common::institution eq "SPC")
		{
			my $line = $Common::config{dictionary}{FreeCreditsAdvice};
			$line =~ s/<NFREECREDITS>/$cred_left/g;
			$line =~ s/<CREDITS>/$Common::config{dictionary}{CREDITS}/g;

			$this_sem_text .=  "\\multicolumn{$n_columns}{|l|}{$line} \\\\ \\hline\n";
		}

		if($cred_column == 1)
		{	$this_sem_text .= " $Common::config{credits_this_semester}{$semester} & ";
			$this_sem_text .= "\\multicolumn{".($n_columns-$cred_column)."}{|l}{}";
		}
		elsif($cred_column > 1 and $cred_column < $n_columns)
		{
			$this_sem_text .= "\\multicolumn{".($cred_column-1)."}{l|}{} & ";
			$this_sem_text .= " $Common::config{credits_this_semester}{$semester} & ";
			$this_sem_text .= "\\multicolumn{".($n_columns-$cred_column)."}{|l}{}";
		}
		elsif($cred_column == $n_columns)
		{	$this_sem_text .= "\\multicolumn{".($cred_column-1)."}{l|}{} & ";
			$this_sem_text .= " $Common::config{credits_this_semester}{$semester}";
			
		}
		$this_sem_text .= " \\\\ \\cline{$cred_column-$cred_column}\n";

		$this_sem_text .= "\\end{tabularx}\n";
		#$this_sem_text .= "\\end{table}\n";
		$this_sem_text .= "\\end{center}\n\n";
		if( $ncourses > 0 )
		{
			$output_txt .= $this_sem_text;
			$total_credits += $Common::config{credits_this_semester}{$semester};
		}
	}

# 	print Dumper \%{$Common::counts{electives}};
# 	print Dumper \%{$Common::counts{map_cred_area}{9}};
	foreach my $semester (keys %{$Common::counts{electives}})
	{
		foreach my $group (keys %{$Common::counts{electives}{$semester}})
		{
			#Util::print_message("Semester $semester, Group $group");
			#print Dumper \%{$Common::counts{electives}{$semester}{$group}}
			my $area = $Common::counts{electives}{$semester}{$group}{area};
			$Common::counts{map_cred_area}{$semester}{$area} += $Common::counts{electives}{$semester}{$group}{cr};
		}
 	}
	$output_txt .= "\\noindent\\textbf{$Common::config{dictionary}{TotalNumberOfCreditsMsg}: } \\input{\\OutputTexDir/ncredits}.\n";
	Util::write_file($output_file, $output_txt);
        $Common::config{ncredits} = $total_credits;
        my $ncredits_file = Common::get_template("out-ncredits-file");
	Util::write_file(Common::get_template("out-ncredits-file"), "$Common::config{ncredits}\\xspace");
	Util::print_message("generate_course_tables ($lang) ($output_file) OK!");

# 	print Dumper \%{$Common::counts{map_cred_area}{2}};
# 	print Dumper \%{$Common::counts{map_cred_area}{9}};
}

sub generate_laboratories()
{
	my $output_txt = "";
	#Util::print_message("$Common::config{n_semesters}");
	my $cols4labs = $Common::config{COL4LABS};
	for(my $semester=1; $semester <= $Common::config{n_semesters} ; $semester++)
	{
		foreach my $codcour ( @{$Common::courses_by_semester{$semester}} )
		{
			if($Common::course_info{$codcour}{$cols4labs} > 0)
			{
				if($Common::course_info{$codcour}{labtype} eq "")
				{	Util::print_message("Course $codcour (Sem #$semester) has not LabType ... did you forget?");
					assert(not $Common::course_info{$codcour}{labtype} eq "");
				}
				#Util::print_message("Course $codcour (Sem #$semester) LabType: $Common::course_info{$codcour}{labtype}");
				my $this_course = "\\section*{$codcour. $Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name} ($Common::config{dictionary}{$Common::course_info{$codcour}{course_type}}) ";
				$this_course .= "$Common::course_info{$codcour}{semester}$Common::config{dictionary}{ordinal_postfix}{$semester} $Common::config{dictionary}{Sem}, Lab: $Common::course_info{$codcour}{lh} $Common::config{dictionary}{hrs}}\n";
				$this_course .= "\\Lab$Common::course_info{$codcour}{labtype}\n\n";
				$output_txt .= $this_course;
			}
		}
	}
	Util::write_file(Common::get_template("out-laboratories-by-course-file"), $output_txt);
	Util::check_point("generate_laboratories");
	Util::print_message("generate_laboratories OK!");
}

# Generates the table of credits by area
sub generate_distribution_credits_by_area_by_semester()
{
	my $output_file = Common::get_template("out-distribution-of-credits-by-area-by-semester-file");
	my $output_txt 	= "";

	my $table_begin = "\\begin{table}[H]\n";
	   $table_begin.= "\\centering\n";
	my $nareas = 0;
	my $width       = 6 + 1.3 * keys %{$Common::config{area_priority}};
	   $table_begin.= "\\begin{tabularx}{$width"."cm}{";
	my $table_end1  = "\\end{tabularx}\n";
	my $table_end2  = "\\end{table}\n\n";

	my ($header, $areas_header, $area_sum, $percent)       = ("|X|", "  ", " \\textbf{$Common::config{dictionary}{Total}} ", "");
	my $area;
	foreach $area (sort {$Common::config{area_priority}{$a} <=> $Common::config{area_priority}{$b}} keys %{$Common::config{area_priority}})
	{
		$header         .= "c|";
		my $color		  = $Common::config{colors}{$area}{bgcolor};
		$areas_header   .= "& \\colorbox{$color}{\\textbf{$area}}";
		$Common::counts{credits}{prefix}{$area} = 0;
		$area_sum .= " & $area";
		$percent  .= " & $area";
	}
	$table_begin  .= $header."c|} \\hline\n";
	$areas_header .= " &  \\\\ \\hline\n";
	$area_sum     .= " & $Common::config{ncredits} \\\\ \\hline\n";;
	$percent      .= " &  \\\\ \\hline\n";;

	my $table_body= "";
	for(my $semester=1; $semester <= $Common::config{n_semesters} ; $semester++)
	{
		$table_body .= "\\textbf{$Common::config{dictionary}{semester_ordinal}{$semester} $Common::config{dictionary}{Semester}}";
		my $sum_sem  = 0;
		foreach $area (sort {$Common::config{area_priority}{$a} <=> $Common::config{area_priority}{$b}} keys %{$Common::config{area_priority}})
		{
			#print "$area\n";
			$table_body .= "& ";
			if(defined($Common::counts{map_cred_area}{$semester}{$area}))
			{
				#Util::print_message("Sem = $semester, a=$area => $Common::counts{map_cred_area}{$semester}{$area}");
				$table_body      .= "$Common::counts{map_cred_area}{$semester}{$area} ";
				$sum_sem         += $Common::counts{map_cred_area}{$semester}{$area};
				$Common::counts{credits}{prefix}{$area} += $Common::counts{map_cred_area}{$semester}{$area};
			}
		}
		$table_body .= " & $sum_sem \\\\ \\hline\n";
		#$Common::counts{map_cred_area}{$semester}{$area}
	}

	foreach $area (sort {$Common::config{area_priority}{$a} <=> $Common::config{area_priority}{$b}} keys %{$Common::config{area_priority}})
	{	$area_sum =~ s/$area/$Common::counts{credits}{prefix}{$area}/g;
		my $area_percent = int(1000*$Common::counts{credits}{prefix}{$area}/$Common::config{ncredits})/10.0;
		$percent =~ s/$area/$area_percent\\%/g;
	}
	$output_txt .= $table_begin;
	$output_txt .= $areas_header;
	$output_txt .= $table_body;
	$output_txt .= $area_sum;
	$output_txt .= $percent;
	$output_txt .= $table_end1;
	$output_txt .= "\\caption{$Common::config{dictionary}{DistributionCreditsByArea}}\n";
	$output_txt .= "\\label{tab:DistributionCreditsByArea}\n";
	$output_txt .= $table_end2;
	Util::write_file($output_file, $output_txt);
	Util::print_message("generate_distribution_area_by_semester ($output_file) ... OK!");
}

sub generate_bok_index_old()
{
	my $bok_macros_file 	= Common::get_template("in-bok-macros-file");
	Util::print_message("Reading BOK file: $bok_macros_file ...");
	my $bok_txt 		= Util::read_file($bok_macros_file);
	my ($body, $this_area_txt) = ("", "");
	my $end  		= "15678";
	my %map = ();
	($map{CMD}, $map{HOURS}, $map{TOPICS}, $map{OBJECTIVES}, $map{NOBJECTIVES}, $map{THIS_UNIT_HOURS_LABEL})	= ("", 0, "", "", 0, "");
	($map{BOK_AREA_HOURS}, $map{BOK_AREA_HOURS_LABEL}) = (0, " ($Common::config{dictionary}{nocorehours})");
	my ($cur_area, $cur_prefix) = ("", "");
	my ($current_area) = ("");
	my ($bok_index, $bok_body)	= ("", "");
	my $unit_tpl = "\\subsection{<CMD><THIS_UNIT_HOURS_LABEL>}<LABEL>\n";
 	$unit_tpl .= "\\textbf{$Common::config{dictionary}{Topics}}\n";
	$unit_tpl .= "\\begin{multicols}{2}\n";
	$unit_tpl .= "\\begin{itemize}\n";
	$unit_tpl .= "<TOPICS>";
	$unit_tpl .= "\\end{itemize}\n";
	$unit_tpl .= "\\end{multicols}\n\n";

	my $learning_outcomes  = "\\textbf{$Common::config{dictionary}{LearningOutcomes}}\n";
	$learning_outcomes 	  .= "\\begin{itemize}\n";
	$learning_outcomes    .= "<OBJECTIVES>";
	$learning_outcomes    .= "\\end{itemize}\n\n";

        my $macros_order = "";
	while($bok_txt =~ m/\\newcommand\{\\(.*)\}\{/g)
	{
	    my ($cmd_full, $cmd)  = ("$1$end", $1);
	    my $cPar = 1;
	    $body = "";
	    while($cPar > 0)
	    {
		    $bok_txt =~ m/((.|\s))/g;
		    $cPar++ if($1 eq "{");
		    $cPar-- if($1 eq "}");
		    $body      .= $1 if($cPar > 0);
	    }
	    if($cmd_full =~ m/(.*?)BOKArea$end/)
	    {
			$current_area = $1;
	    }
	    elsif($cmd_full =~ m/($current_area)(.*)Def$end/)
	    {
		my ($this_area, $this_prefix) 	= ($1, $2);
            $macros_order .= "$this_area$this_prefix"."Def\n";
		my $prev_unit = "";
		if(not $map{CMD} eq "")
		{
		      $map{THIS_UNIT_HOURS_LABEL} = "";
		      $map{THIS_UNIT_HOURS_LABEL} = " ($map{HOURS} $Common::config{dictionary}{hour})"  if($map{HOURS} == 1);
		      $map{THIS_UNIT_HOURS_LABEL} = " ($map{HOURS} $Common::config{dictionary}{hours})" if($map{HOURS} > 1);
		      #print "CMD = $map{CMD}, HOURS_LABEL=\"$map{THIS_UNIT_HOURS_LABEL}\"\n";

		      $map{BOK_AREA_HOURS}       += $map{HOURS};
		      $map{BOK_AREA_HOURS_LABEL}  = " ($Common::config{dictionary}{nocorehours}))" if($map{BOK_AREA_HOURS} == 0);
		      $map{BOK_AREA_HOURS_LABEL}  = " ($map{BOK_AREA_HOURS} $Common::config{dictionary}{corehours})" if($map{BOK_AREA_HOURS} > 0);

		      $prev_unit 	 = Common::replace_tags_from_hash($unit_tpl, "<", ">", %map);
		      if($map{NOBJECTIVES} > 0)
		      {		$prev_unit 	 .= Common::replace_tags_from_hash($learning_outcomes, "<", ">", %map);
		      }
		      $map{BOK_AREA_INDEX}    .= "\\htmlref{$map{CMD_TEXT}$map{THIS_UNIT_HOURS_LABEL}}{$map{CMD_LABEL}}";
		      #	$map{BOK_AREA_INDEX}    .= " ($Common::config{dictionary}{Pag}~\\pageref{$map{CMD_LABEL}})";
		      $map{BOK_AREA_INDEX}    .= "\\\\\n";

		      $this_area_txt    .= $prev_unit;
		}
		($map{CMD}, $map{HOURS}, $map{TOPICS}, $map{OBJECTIVES}, $map{NOBJECTIVES}) = ("\\$cmd", 0, "", "", 0);
		my $label = "sec:BOK-$this_area$this_prefix";
		($map{CMD_TEXT}, $map{CMD_LABEL}, $Common::config{ref}{$cmd})	= ($body, $label, $label);
		$map{LABEL} 	 = "\\label{$label}";

		if(not $cur_area eq $this_area and not $cur_area eq "") # a new area is just starting
		{
		      my $label 	 = "sec:BOK-$cur_area";
		      my $BOKArea 	 = $cur_area."BOKArea";
		      #Util::print_message("check_point $Common::config{macros}{$BOKArea}");
		      $bok_index	.= "\\noindent {\\bf\n\\htmlref{$cur_area. $Common::config{macros}{$BOKArea}$map{BOK_AREA_HOURS_LABEL}}{$label}}";
		      $bok_index	.= " ($Common::config{dictionary}{Pag}~\\pageref{$label})";
		      $bok_index	.= "\\\\\n";
		      $bok_body  	.= "\\section{$cur_area. $Common::config{macros}{$BOKArea}$map{BOK_AREA_HOURS_LABEL}}\\label{$label}\n";
		      $bok_body		.= "\\noindent{\\bf\n$map{BOK_AREA_INDEX}}\n\n";
		      $bok_body  	.= "\\$cur_area"."Description\n\n";
		      $bok_body  	.= $this_area_txt;
		      ($this_area_txt, $map{BOK_AREA_HOURS}, $map{BOK_AREA_HOURS_LABEL}) = ("", 0, " ($Common::config{dictionary}{nocorehours})");

# 		      $bok_index	.= "\\begin{description}\n";
		      $bok_index	.= $map{BOK_AREA_INDEX};
# 		      $bok_index	.= "\\end{description}\n";
		      $bok_index	.= "\n";
		      $map{BOK_AREA_INDEX} = ("");
		}

		($map{THIS_UNIT_HOURS_LABEL})	= ("");
		($cur_area, $cur_prefix)	= ($this_area, $this_prefix);
	    }
	    elsif($cmd_full =~ m/($current_area)(.*)Hours$end/)
	    {
		Util::halt("Processing $cur_area$cur_prefix I found $1$2") if(not $cur_area eq $1 or not $cur_prefix eq $2);
		if($body eq ""){	Util::print_message("Processing $cur_area$cur_prefix Hours={} ignoring");	}
		else
		{
		      $map{HOURS} 		  = $body;
		}
	    }
	    elsif($cmd_full =~ m/($current_area)(.*)Topic(.*)$end/)
	    {
		if(not $cur_area eq $1 or not $cur_prefix eq $2)
                {       Util::print_message("Processing $cur_area$cur_prefix I found $1$2Topic$3 (ignoring for the index)");   }
		else{   $map{TOPICS}	.= "\t\\item \\$cur_area$cur_prefix"."Topic$3\n";      }
	    }
	    elsif($cmd_full =~ m/($current_area)(.*)AllTopics$end/)
	    {	next;	}
	    elsif($cmd_full =~ m/($current_area)(.*)Obj(.*)$end/)
	    {
		if(not $cur_area eq $1 or not $cur_prefix eq $2)
                {       Util::print_message("Processing $cur_area$cur_prefix I found $1$2Obj$3 (ignoring for the index)");     }
		else
		{   $map{OBJECTIVES}	.= "\t\\item \\$cur_area$cur_prefix"."Obj$3\n";
		    $map{NOBJECTIVES}++
		}
	    }
	    elsif($cmd_full =~ m/($current_area)(.*)AllObjectives$end/)
	    {	next;	}
	}
	# Flush the last unit
	$this_area_txt  .= Common::replace_tags_from_hash($unit_tpl, "<", ">", %map);
	if($map{NOBJECTIVES} > 0)
	{	$this_area_txt  .= Common::replace_tags_from_hash($learning_outcomes, "<", ">", %map);
	}
# Begin
        $map{THIS_UNIT_HOURS_LABEL} = "";
        $map{THIS_UNIT_HOURS_LABEL} = " ($map{HOURS} $Common::config{dictionary}{hour})"  if($map{HOURS} == 1);
        $map{THIS_UNIT_HOURS_LABEL} = " ($map{HOURS} $Common::config{dictionary}{hours})" if($map{HOURS} > 1);
        #print "CMD = $map{CMD}, HOURS_LABEL=\"$map{THIS_UNIT_HOURS_LABEL}\"\n";

        $map{BOK_AREA_HOURS}       += $map{HOURS};
        $map{BOK_AREA_HOURS_LABEL}  = " ($Common::config{dictionary}{nocorehours}))" if($map{BOK_AREA_HOURS} == 0);
        $map{BOK_AREA_HOURS_LABEL}  = " ($map{BOK_AREA_HOURS} $Common::config{dictionary}{corehours})" if($map{BOK_AREA_HOURS} > 0);

        my $prev_unit         = Common::replace_tags_from_hash($unit_tpl, "<", ">", %map);

        $map{BOK_AREA_INDEX}    .= "\\htmlref{$map{CMD_TEXT}$map{THIS_UNIT_HOURS_LABEL}}{$map{CMD_LABEL}}";
        # $map{BOK_AREA_INDEX}    .= " ($Common::config{dictionary}{Pag}~\\pageref{$map{CMD_LABEL}})";
        $map{BOK_AREA_INDEX}    .= "\\\\\n";
# End
	my $BOKArea 	 = $cur_area."BOKArea";
	$bok_body  	.= "\\subsection{$cur_area. $Common::config{macros}{$BOKArea}$map{BOK_AREA_HOURS_LABEL}}\\label{sec:BOK-$cur_area}\n";
	$bok_body	.= "\\noindent\\textbf{$map{BOK_AREA_INDEX}}\n\n";
	$bok_body  	.= "\\$cur_area"."Description\n\n";
	$bok_body  	.= $this_area_txt;

	my $label        = "sec:BOK-$cur_area";
	$bok_index      .= "\\noindent {\\bf\n\\htmlref{$cur_area. $Common::config{macros}{$BOKArea}$map{BOK_AREA_HOURS_LABEL}}{$label}}";
	$bok_index      .= " ($Common::config{dictionary}{Pag}~\\pageref{$label})";
	$bok_index      .= "\\\\\n";
	$bok_index      .= $map{BOK_AREA_INDEX};

	$bok_index	= "\\begin{multicols}{2}\n\\scriptsize\n$bok_index\\end{multicols}\n";
	Util::write_file(Common::get_template("out-bok-index-file"), $bok_index);
	Util::write_file(Common::get_template("out-bok-body-file"), $bok_body);

	#Util::write_file(Common::get_template("in-macros-order-file"), $macros_order);
	Util::check_point("generate_bok_index");
}

sub generate_lu_index()
{
	my $LU_file = Common::get_template("in-LU-file");
	if(not -e $LU_file)
	{	return;		}
	my $lu_txt  = Util::read_file($LU_file);
	while($lu_txt =~ m/\\subsection\{(LU\d*?)\..*?\}\\label\{(.*?)\}/g )
	{
	      my ($LU, $label) = ($1, $2);
	      $LU = Common::change_number_by_text($LU)."Def";
	      $Common::config{ref}{$LU} = $label;
	      Util::print_message("$LU, $label");
	}
}

# Generate the list of involved areas (HU, CS, ID, etc) and theirs descriptions
sub generate_description($$)
{
	my ($type, $lang) = (@_);
	my ($in_file, $out_file) = (Common::get_expanded_template("in-description-foreach-$type-file" , $lang), 
								Common::get_expanded_template("out-description-foreach-$type-file", $lang));
	my ($keyforhash) = $type."_priority";
	my $key_for_used_keys = "used_$type";
	if( not -e $in_file )
	{	Util::print_message("I can not find file \"$in_file\" did you create it?");	 }

	Util::print_message("Reading $in_file ...");
	my $txt = Util::read_file($in_file);
	my %description  = ();
	foreach (split("\n", $txt))
	{
		if(m/\\item\[(..)\](.*)/)
		{
			$description{$1} = $2;
		}
	}
	
	foreach my $key (keys %{$Common::config{$key_for_used_keys}})
	{
		if( not defined($Common::config{$keyforhash}{$key}) )
		{
			Common::print_keyLog("PrefixPriority");
			Util::print_message("I don't know ".Util::red("Common::config{$keyforhash}{$key}")." at ".Util::red("$in_file"));
			Util::print_error("generate_description($type, $lang)");
		}
	}
	#print Dumper(\%description); exit;
	my ($output, $list_of_areas) = ("", "");
	$output .= "\\begin{enumerate}\n";
# 	foreach my $area (sort {$Common::config{prefix_priority}{$a} cmp $Common::config{prefix_priority}{$b}} keys %{$Common::config{used_areas}})
 	foreach my $key (sort {$Common::config{$keyforhash}{$a}      cmp $Common::config{$keyforhash}{$b}}     
	                keys %{$Common::config{$key_for_used_keys}})
 	{
		if(defined($description{$key}))
		{
			$output .= "\\item \\textbf{$key} $description{$key}\n";
			$list_of_areas	.= "$key ";
		}
		else
		{	Util::print_soft_error("No area description for $key ... See $in_file ...");	}
 	}
	$output .= "\\end{enumerate}\n";
	Util::write_file($out_file, $output);
	Util::print_message("generation_foreach_area ($out_file): $list_of_areas... OK!");
}

my %critical_path = ();
sub initialize_critical_path()
{
		for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
		{
				foreach my $codcour (@{$Common::courses_by_semester{$semester}})
				{
						$Common::course_info{$codcour}{critical_path}{visited}  = 1;
						$Common::course_info{$codcour}{critical_path}{distance} = 0;
						#@{$Common::course_info{$codcour}{critical_path}{path}} = [];
				}
		}
}

sub process_critical_path_for_one_course($)
{
	my ($codcour) = (@_);
	my ($distance) = (0);
	my %paths = ();
	#Util::print_message("Processing $codcour");
	foreach my $codpost (@{$Common::course_info{$codcour}{courses_after_this_course}})
	{
		#Util::print_message("\t$codpost");
		my ($distance_child, @path_child) = process_critical_path_for_one_course($codpost);
		$distance_child++;
		#unshift(@path_child, $codcour);
		my $new_path_pos = 0;
		if( defined($paths{$distance_child}) )
		{		$new_path_pos = scalar( @{$paths{$distance_child}} );	}
		my $i=0;
		foreach (@path_child)
		{
				$paths{$distance_child}[$new_path_pos+$i][0] = $codcour;
				foreach my $one_codcour (@{$path_child[$i]})
				{		push(@{$paths{$distance_child}[$new_path_pos+$i]}, $one_codcour);			}
				$i++;
		}
		if ($distance_child > $distance)
		{		$distance	= $distance_child;		}
	}
	if($distance == 0)
	{
			$paths{++$distance}[0][0] = $codcour;
			return ($distance, @{$paths{$distance}})
	}
	#Util::print_message("Returning from $codcour, max distance=$distance");
	#print Dumper(\%paths);
	return ($distance, @{$paths{$distance}});
}

sub load_critical_path(@)
{
	my (@critical_paths) = (@_);
	#print Dumper(\@critical_paths);
	foreach my $_one_path (@critical_paths)
	{
			my @one_path = @{$_one_path};
			#print Dumper(\@one_path);
			my $ncourses = scalar(@one_path);
			for(my $i = 0; $i < $ncourses-1 ; $i++ )
			{		#Util::print_message($one_path[$i]."->".$one_path[$i+1]." *");
					my ($source, $target) = ($one_path[$i], $one_path[$i+1]);
					$Common::course_info{$source}{critical_path}{$target}++;
			}
	}
}

sub detect_critical_path()
{
	initialize_critical_path();
	my $max_distance = 0;
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
	{
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{
			my ($distance_for_this_course, @path) = process_critical_path_for_one_course($codcour);
			if( $distance_for_this_course >= $max_distance )
			{	
				$max_distance = $distance_for_this_course;
				push(@{$critical_path{$distance_for_this_course}}, @path);
			}
		}
	}
	load_critical_path(@{$critical_path{$max_distance}});
	Util::check_point("detect_critical_path");
	Util::print_color("detect_critical_path Ok!");
}

sub do_nothing($$$$)
{
	my ($codcour, $lang, $course_tpl, $outcome) = (@_);
	return $course_tpl;
}

#$highlight, $underemphasize
sub highlight_outcome($$$$)
{
	my ($codcour, $lang, $course_tpl, $outcome) = (@_);
	my $version = $Common::config{OutcomesVersion};
	my %map = ();
	if( defined($Common::course_info{$codcour}{$lang}{outcomes}{$version}{$outcome}) )
	{
		$map{"FONTCOLOR"}   = "black";
		$map{"FILLCOLOR"}   = "yellow";
		$map{"BORDERCOLOR"} = "black";
	}
	else
	{
		$map{"FONTCOLOR"}   = "black";
		$map{"FILLCOLOR"}   = "white";
		$map{"BORDERCOLOR"} = "black";
	}
	$course_tpl = Common::replace_tags_from_hash($course_tpl, "<", ">", %map);
	return $course_tpl;
}

# dot
sub generate_curricula_in_dot_internal($$$$$)
{
	my ($output_dot_file, $course_tpl, $lang, $filter, $pre_processing_course) = (@_);
	Util::check_point("detect_critical_path");
	my $output_txt = "";
	$output_txt .= "digraph curricula\n{\n";
	$output_txt .= "\tbgcolor=white;\n";
	$output_txt .= "\tnewrank=true;\n";
	$output_txt .= "\t";

	my $sep = "";
	# First:	Generate semesters connected on the left
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
	{
			#print "$semester ...  ";
			$output_txt .= "$sep";
			$output_txt .= Common::sem_label($semester, $lang);
			$sep = "->";
	}
	$output_txt .= ";\n";
	my $rank_text = "";

	#Second: generate the label for this graph
	$output_txt .= "\t\"$Common::config{area}-$Common::config{institution}\" [fillcolor=black, style=filled, fontcolor=white, fontsize=30,peripheries=2];\n";

	# Second: generate information for each semester
    my $cluster_count = 0;
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
	{
		my $ncourses = 0;
		my $sem_text = "";
		my $sem_rank = "";
		my $sem_label = Common::sem_label($semester, $lang);

		$sem_text .= "\t$sem_label";
		$sem_text .= " [shape=box];\n";

    	my %clusters_info = ();
		my $codcour = "";
		foreach $codcour ( @{$Common::courses_by_semester{$semester}} )
		{
		    my $group = $Common::course_info{$codcour}{group};
			my $track = $Common::config{empty_track};
			if( not $Common::course_info{$codcour}{track} eq "" )
			{	$track = $Common::course_info{$codcour}{track};		}
			my $this_course_tpl = $pre_processing_course->($codcour, $lang, $course_tpl, $filter);
		    my $this_course_dot = Common::generate_course_info_in_dot($codcour, $this_course_tpl, $lang)."\n";
		    if($Common::config{graph_version} == 1 || $group eq "")
			{       $sem_text .= $this_course_dot;   }
		    elsif($Common::config{graph_version} >= 2) # related links for elective courses
		    {       if(not defined($clusters_info{$track}{$group}))
		           	{       $clusters_info{$track}{$group}{dot} = "";
					}
		            $clusters_info{$track}{$group}{dot} .= $this_course_dot;
					push( @{$clusters_info{$track}{$group}{courses}}, $codcour);
		    }
			#my $codcour_label = Common::get_label($codcour);
			$sem_rank .= " \"$codcour\";";
			$ncourses++;
		}

		if($Common::config{graph_version} >= 2)
		{
			foreach my $track (keys %clusters_info)
			{
				#print Dumper(\%clusters_info);
				my $tab = "";
				if( not $track eq $Common::config{empty_track} )
				{	$sem_text .= "subgraph cluster$track\n{";
					$sem_text .= "\tlabel = \"Track $track\";\n";
					$sem_text .= "\tgraph[color=black,style=dotted,penwidth=2];\n";
					# $sem_text .= "Tag setted !\n";
					$tab = "\t";
				}
				foreach my $group ( keys %{$clusters_info{$track}} )
				{
					$sem_text .= $tab."subgraph cluster$group$cluster_count\n";
					$sem_text .= $tab."{\tlabel = \"$Common::config{dictionary}{Electives}\";\n";
					$sem_text .= "$tab\tgraph[color=black,style=dotted,penwidth=2];\n";

					foreach $codcour (@{$clusters_info{$track}{$group}{courses}})
					{
						my $this_course_tpl = $pre_processing_course->($codcour, $lang, $course_tpl, $filter);
						my $this_course_dot = Common::generate_course_info_in_dot($codcour, $this_course_tpl, $lang);
						$sem_text .= "$tab\t$this_course_dot\n";
						$sem_rank .= " \"$codcour\";";
						$ncourses++;
					}
					$sem_text .= $tab."}\n";
					$cluster_count++;
				}
				if( not $track eq $Common::config{empty_track} )
				{	$sem_text .= "}\n";	}
			}
		}
		$output_txt .= "\n#\t$semester $Common::config{dictionary}{Semester}\n";
		$output_txt .= "$sem_text";
		$rank_text .= "\n\t{ rank = same; $sem_label; $sem_rank }";
	}
	$output_txt .= "$rank_text\n\n";

	# Third: Generate connections among courses
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
	{
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{	if( not defined($Common::config{prefix_priority}{$Common::course_info{$codcour}{prefix}}) )
			{	Util::print_soft_error("Course $codcour ($Common::course_info{$codcour}{semester} Sem) has a prefix ($Common::course_info{$codcour}{prefix}) which hasn't prefix_priority defined ...\n See ./Curricula.in/lang/<LANG>/<AREA>.config/<AREA>-All.config ");
			}
		}
		foreach my $codcour ( @{$Common::courses_by_semester{$semester}} )
		{
			my $req = "";
			foreach $req (split(",", $Common::course_info{$codcour}{prerequisites_just_codes}))
			{
				if( $req =~ m/$Common::institution=(.*)/ )
				{
					$output_txt .= "\"$1\"->$codcour;\t\t";
					$output_txt .= "\"$1\" [$Common::config{ExtraDotItemStyle}];\n";
				}
				else
				{
					my ($source, $target) = (Common::get_label($req), $codcour);
					if($source eq "")
					{
						Util::print_message("Something wrong here ! codcour=$codcour (Sem: $Common::course_info{$codcour}{semester}), req=$req");
						Util::print_message("$Common::course_info{$codcour}{prerequisites_just_codes}");
						exit;
					}
					my ($output_connection, $regular_course) = Common::generate_connection_between_two_courses($source, $target, $lang);
					$output_txt .= $output_connection;
					# Util::print_message("generate_connection_between_two_courses($source, $target) : $output_connection");
					# exit;
				}
			}
			# Generate invisible links just to align courses
			foreach $req (sort {$a cmp $b}	keys %{$Common::course_info{$codcour}{prereq_invis}})
			{	$output_txt .= Common::generate_invisible_connection_between_two_courses($req, $codcour);
			}
			if( $Common::config{recommended_prereq_flag} == 1 )
			{	foreach my $rec (split(",", $Common::course_info{$codcour}{recommended}))
				{
					$output_txt .= Common::get_label($rec);
					$output_txt .= "->";
					$output_txt .= Common::get_label($codcour);
					$output_txt .= " [$Common::config{CoRequisiteStyle}];\n";
				}
			}
			if($Common::config{corequisites_flag} == 1)
			{
				foreach my $coreq (split(",", $Common::course_info{$codcour}{corequisites}))
				{
					#print "codigo = $codcour (sem=$Common::course_info{$codcour}{semester}), coreq = $coreq\n";
					$output_txt .= Common::get_label($coreq);
					$output_txt .= "->";
					$output_txt .= Common::get_label($codcour);
					$output_txt .= "[$Common::config{RecommendedRequisiteStyle}];\n";
				}
			}
		}
	}
	$output_txt .= "}\n";
	
	Util::write_file($output_dot_file, $output_txt);
	#Util::print_message($course_tpl);
	Util::print_message("generate_curricula_in_dot_internal($output_dot_file, <<course_tpl>>, $lang) OK!");
}

sub generate_curricula_in_dot($$)
{
	my ($size, $lang) = (@_);
	Util::check_point("detect_critical_path");
	my $output_dot_file = Common::ExpandTags(Common::get_template("out-$size-graph-curricula-dot-file"), $lang);
	my $course_tpl 	= Util::read_file(Common::read_dot_template($size, $lang));
	generate_curricula_in_dot_internal($output_dot_file, $course_tpl, $lang, "*", \&do_nothing);

	#my $OutputFigsDir	= Common::get_template("OutputFigsDir");
	#$Common::config{"dots_to_be_generated"}	.= "echo \"Generating $OutputFigsDir/$filename.svg ...\";\n";
	##$Common::config{"dots_to_be_generated"}	.= "dot -Tps  $output_dot_file -o $OutputFigsDir/$filename.ps; \n";
	#$Common::config{"dots_to_be_generated"}	.= "dot -Tsvg $output_dot_file -o $OutputFigsDir/$filename.svg; \n\n";
}

sub get_outcome_map_name($$$)
{
	my ($outcome, $size, $lang) = (@_);
	my $lang_prefix = $Common::config{dictionaries}{$lang}{lang_prefix};
	return "outcome-$outcome-$size-map-$lang_prefix";
}

sub generate_map_of_courses_by_outcome($$)
{
	my ($size, $lang) = (@_);
	Util::check_point("detect_critical_path");
	my $version	= $Common::config{OutcomesVersion};
	my $OutputDotDir 	= Common::get_template("OutputDotDir");
	my $OutputFigsDir	= Common::get_template("OutputFigsDir");
	my $course_tpl 		= Util::read_file(Common::read_dot_template($size, $lang));
	foreach my $outcome (split(",", $Common::config{outcomes_list}{$version}))
	{	
		my $courses_counter = keys %{ $Common::config{course_by_outcome}{$outcome} };
		if($courses_counter > 0)
		{
			my $filename 		= get_outcome_map_name($outcome, $size, $lang);
			my $output_dot_file = "$OutputDotDir/$filename.dot";
			generate_curricula_in_dot_internal($output_dot_file, $course_tpl, $lang, $outcome, \&highlight_outcome);
			$Common::config{"dots_to_be_generated"}	.= "echo \"Generating $OutputFigsDir/$filename.svg ...\";\n";
			#$Common::config{"dots_to_be_generated"}	.= "dot -Tps  $output_dot_file -o $OutputFigsDir/$filename.ps; \n";
			$Common::config{"dots_to_be_generated"}	.= "dot -Tsvg $output_dot_file -o $OutputFigsDir/$filename.svg; \n\n";
		}
	}
}

# ok
sub generate_poster($)
{
    my ($lang) = (@_);
	my $poster_txt = Util::read_file(Common::get_template("in-poster-file"));

    my $total_left_width = 90; #cm
    $poster_txt =~ s/<LOGO_WIDTH>/$Common::config{logowidth}$Common::config{logowidth_units}/g;

 	$Common::config{title_width} = Util::round(($total_left_width-$Common::config{logowidth}) - 1);
 	$poster_txt =~ s/<TITLE_WIDTH>/$Common::config{title_width}$Common::config{logowidth_units}/g;

 	$Common::config{def_width} 	= $Common::config{title_width}/2;
	$Common::config{COL2} 		= 0.4*$Common::config{title_width};
	$Common::config{COL3} 		= $Common::config{title_width}-$Common::config{COL2};
	$poster_txt =~ s/<COL2>/$Common::config{COL2}$Common::config{logowidth_units}/g;
 	$poster_txt =~ s/<COL3>/$Common::config{COL3}$Common::config{logowidth_units}/g;
	$poster_txt =~ s/<POSTER_RIGHT_BG>/$Common::config{POSTER_RIGHT_BG}/g;

	$poster_txt = Common::replace_meta_tags($poster_txt, $lang);
	#Util::print_message("Common::config{title_width}=$Common::config{title_width}");
	#Util::print_message("Common::config{def_width}=$Common::config{def_width}");
	#Util::print_message("Common::config{logowidth}=$Common::config{logowidth}");

# 	$Common::config{title_width} = Util::round(($total_left_width-$Common::config{logowidth})/3 + 1);
# 	$poster_txt =~ s/<TITLE_WIDTH>/$Common::config{title_width}$Common::config{logowidth_units}/g;
#
# 	$Common::config{def_width} = Util::round($total_left_width - $Common::config{logowidth} - $Common::config{title_width});
# 	$poster_txt =~ s/<DEF_WIDTH>/$Common::config{def_width}$Common::config{logowidth_units}/g;
	# Here we have to process more poster's content here
        # ..........
        # ..........
        # ..........
    $poster_txt = Common::translate($poster_txt, $lang);
	$poster_txt = Common::ExpandTags($poster_txt, $lang);
	my $OutPosterFile = Common::ExpandTags(Common::get_template("out-poster-file"), $lang);
	Util::write_file($OutPosterFile, $poster_txt);

	system("cp ".Common::get_template("in-a0poster-sty-file")." ".Common::get_template("OutputTexDir")); ;
	system("cp ".Common::get_template("in-poster-macros-sty-file")." ".Common::get_template("OutputTexDir")); ;

    my $cwd = getcwd();
    #chdir(Common::get_template("OutputFigsDir"));
    #system("rm Bloom.eps");
    #system("ln -s $cwd/".Common::get_template("InFigsDir")."/Bloom.eps");
	#system("rm Bloom-sequence.eps");
    #system("ln -s $cwd/".Common::get_template("InFigsDir")."/Bloom-sequence.eps");
    #chdir($cwd);
	Util::print_message("generate_poster($lang) OK! $OutPosterFile");
}

# ok
sub generate_pie($)
{
	my ($type)      = (@_);
	my $output_file = Common::get_template("out-pie-$type-file");
	my $output_txt  = "";

	$output_txt .= "\\begin{center}\n";
	$output_txt .= "\\psset{framesep=1pt,unit=1cm}\n";
	$output_txt .= "\\begin{pspicture}(-2.5,-2.5)(4,2.6)\n";
	$output_txt .= "\\psframe*[linecolor=white](-2.6,-2.6)(4,2.6)\n";
	$output_txt .= "\\SpecialCoor\n";
	my $count = $Common::counts{$type}{count};
	my $max   = $Common::config{ncredits};
	$output_txt .= "\\degrees[$max]\n";
	my $first   = 0;
	my $percent;
	my $credits = 0;

	#print Dumper(\%{$Common::counts{credits}{prefix}}); exit;
	#$counts{credits}{area_pie}{$area_pie}
	foreach my $prefix (sort {$Common::config{prefix_priority}{$a} cmp $Common::config{prefix_priority}{$b}} keys %{$Common::config{used_area_pie}})
	{
		#Util::print_message("type=$type, area=$prefix, $Common::counts{credits}{area_pie}{$prefix}");
		my $last  = $first + $Common::counts{credits}{area_pie}{$prefix}; #$counts{credits}{area_pie}
		$credits += $Common::counts{credits}{area_pie}{$prefix};
		my $mid = ($first + $last)/2;
		my $percent = Util::calc_percent($Common::counts{credits}{area_pie}{$prefix}, $max);
		#print "area=$prefix, first=$first, last=$last\n";
		if(defined($Common::config{colors}{$prefix}))
		{
			#$output_txt .= "\\pswedge[shadow=true,fillstyle=solid,fillcolor=$Common::config{colors}{$prefix}{bgcolor}]{2}{$first}{$last}\n";
			$output_txt .= "\\pswedge[fillstyle=solid,fillcolor=$Common::config{colors}{$prefix}{bgcolor}]{2}{$first}{$last}\n";
# 			$output_txt .= "\\rput(1.2; $mid ){\\psframebox*{\\Large \\colorbox{$Common::colors{$prefix}{bgcolor}}{$percent \\\%}}}\n";
			$output_txt .= "\\rput(1.2; $mid ){$percent \\\%}\n";
			$output_txt .= "\\uput{2.2}[ $mid ](0;0){$prefix ($Common::counts{credits}{area_pie}{$prefix})}\n\n";
			$first = $last;
		}
	}
	if($Common::version eq "draft")
	{
		my $free = $max-$count;
		my $last = $first + $free;
		my $mid = ($first + $last)/2;
		my $percent = Util::calc_percent($free, $max);
		$output_txt .= "\\pswedge[shadow=true,fillstyle=solid,fillcolor=blue]{2}{$first}{$max}\n";
		$output_txt .= "\\rput(1.2; $mid ){\\psframebox*{\\Large $percent \\\%}}\n";
		$output_txt .= "\\uput{2.2}[ $mid ](0;0){\\Large -- ($free)}\n\n";
	}
	$output_txt .= "\\end{pspicture}\n";
	$output_txt .= "\\end{center}\n";
	#$area_count{$Common::course_info{$codcour}{area}} += $Common::course_info{$codcour}{cr};
	#$credit_count += $Common::course_info{$codcour}{cr};
	Util::write_file_to_gen_fig($output_file, $output_txt);
# 	my $fig_file = Common::get_template("OutputFigsDir")."/pie-$type*";
# 	Util::print_message("Removing file: $fig_file ...");
# 	system("rm $fig_file");
# 	exit;
# 	Util::write_file("File $output_file Generated!", $output_txt);
}

sub get_bigtables_by_course_caption($$$$)
{
	my ($init_sem, $final_sem, $part_count, $prefix) = (@_);
	my $caption	 = "\\caption{$Common::config{dictionary}{$prefix}}\n";
	# Tópicos por curso del <BEGIN_SEM> al <END_SEM> <SEMESTER> (<NTABLE>/<NPARTS>)
	$caption	=~ s/<BEGIN_SEM>/\$$init_sem^{$Common::config{dictionary}{ordinal_postfix}{$init_sem}}\$/g;
	$caption	=~ s/<END_SEM>/\$$final_sem^{$Common::config{dictionary}{ordinal_postfix}{$final_sem}}\$/g;
	$caption	=~ s/<SEMESTER>/$Common::config{dictionary}{Semester}/g;
	$caption	=~ s/<NTABLE>/$part_count/g;
	return $caption;
}

sub generate_table_topics_by_course($$$$$$$)
{
	my ($lang, $init_sem, $sem_per_page, $rows_per_page, $outfile, $angle, $size) = (@_);

	#Util::precondition("gen_bok");
	Util::precondition("generate_tex_syllabi_files");
	my ($sep, $hline) = ($Common::config{sep}, $Common::config{hline});
	my $col_header     = $sep."cX$sep";
	my $sem_header     = " & ";
	my $row_text       = "<color> --mandatory-- & --unit-- ";
	#my $row_text       = "<color>--unit-- ";
	my $ku_and_course_title = "\\textbf{$Common::config{dictionary}{KUsTitle}}";

	my $first_row_text = "";
	$first_row_text  = "$Common::config{row2} " if($Common::config{graph_version}>= 2);
	$first_row_text .= "~ & $ku_and_course_title ";

	my $sum_row_text   = "~ & $Common::config{dictionary}{Total} ";
	#my $sum_row_text   = "$Common::config{dictionary}{Total} ";
	my %sem_per_course = ();

	$Common::data{hours_by_course} = ();
	my $semester;
	my $flag = 1; my $extra_header = "";
	for($semester=$init_sem; $semester < $init_sem+$sem_per_page && $semester <= $Common::config{n_semesters}; $semester++)
	{
		$sem_per_course{$semester} = 0;
		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{
			#my $codcour_label = Common::get_label($codcour);
			my $codcour_label = $codcour;
			$extra_header = "";
 			$extra_header = "$Common::config{column2}" if($flag == 1 && $Common::config{graph_version}>= 2);
			$flag = 1 - $flag;
			$col_header     	.= "$sep$extra_header"."c";
			my $color 		 = $Common::course_info{$codcour}{bgcolor};
			my $label 		 = Common::format_course_label($codcour_label, $color);
			if( $angle > 0 ) {$first_row_text .= "& \\rotatebox[origin=lb,units=360]{$angle}{$label} ";}
			else {		  $first_row_text .= "& $label ";	}
			$row_text       .= "& --$codcour_label-- ";
			$sum_row_text   .= "& --$codcour_label-- ";
			$Common::data{hours_by_course}{$codcour_label} = 0;
			$sem_per_course{$semester}++;
		}
		$col_header     .= "$sep";
		#my $header_label = "$semester\$^$Common::config{ordinal_postfix}{$semester}\$";
		$extra_header = "";
		$extra_header = "$Common::config{column2}" if($semester % 2 == 1 && $Common::config{graph_version}>= 2);
		my $header_label = "$Common::config{dictionary}{semester_ordinal}{$semester} $Common::config{dictionary}{Sem}";
		$sem_header .= "& \\multicolumn{$sem_per_course{$semester}}{$sep$extra_header"."c$sep}{$header_label} ";
	}
	my $final_sem = $semester-1;
	$col_header    .= $sep."c$sep} $hline\n";
	$sem_header    .= "& . \\\\ $hline\n";
	if( $angle > 0 ) {$first_row_text .= "& \\rotatebox[origin=lb,units=360]{$angle}{$Common::config{dictionary}{Total}}";}
	else 	{		  $first_row_text .= "& $Common::config{dictionary}{Total}";	}
	$first_row_text.= " \\\\ $hline\n";
	$row_text      .= "& <Sum> \\\\ $hline\n";
	$sum_row_text  .= "&        \\\\ $hline\n";

	my $current_row = "";
	my $table_text  = "";
	my $table_begin = "";
	#$table_begin   .= "\\begin{landscape}";
	if($size eq "book")
	{	$table_begin   .= "\\begin{center}\n";
		$table_begin   .= "\\begin{table}[H]\n";
	}
	my $tabsize 		= "";
	$tabsize 		= "24cm" if($size eq "book");
	$tabsize 		= "\\textwidth" if($size eq "poster");
	$table_begin   .= "\\begin{tabularx}{$tabsize}{";
	my $table_end1  = "\\end{tabularx}\n";
	my $table_end2  = "";
	if($size eq "book")
	{	$table_end2    .= "\\end{table}\n";
		$table_end2    .= "\\end{center}\n\n";
	}
	#$table_end     .= "\\end{landscape}\n\n";
	my $row_counter = 0;
	my $output_text = "";
	my $table_body  = "";
	#foreach my $main_areax (sort keys %Common::map_hours_unit_by_course)
	#{	print "\"$main_areax\"->$Common::areas_priority{$main_areax}\n";
	#}
	#print "Antes do foreach ...\n";
	my $part_count = 1;
	#print "main_area = $main_area \n";
 	#print "priority = $Common::config{topics_priority}{DSTRESDef}\n";
 	#print "nhoras = $Common::map_hours_unit_by_course{DSTRESDef}{CS105}\n";

	my $first_backgroud_flag = $Common::config{first_backgroud_flag};
	my $background = $first_backgroud_flag;
    
    #print Dumper (\%Common::map_hours_unit_by_course); Util::print_message("TODO"); exit;
	my %list_of_valid_ku = ();
	foreach my $ku ( keys %{$Common::map_hours_unit_by_course{$lang}})
	{	
		if( not defined($Common::config{topics_priority}{$ku}) )
		{	Util::print_color("generate_table_topics_by_course: ignoring $ku ...");		}
		else
		{	$list_of_valid_ku{$ku} = "";	}
	}
	#Util::print_message("TODO aqui");
	#print Dumper(\%{$Common::config{topics_priority}}); exit;

	foreach my $ku (sort {$Common::config{topics_priority}{$a} <=> $Common::config{topics_priority}{$b}} 
					keys %list_of_valid_ku)
	{
		my $ka = $Common::ku_info{$lang}{$ku}{ka};
		#Util::print_message("ABC ka=$ka");
  		#print "ka=$ka, unit_name= $ku, priority= $Common::config{topics_priority}{$ku}\n";
		if( not defined($Common::config{topics_priority}{$ku}) )
		{	print " falta $ku ";	}
		#print "\n";
		$current_row 	= $row_text;
		my $temp 	= "$ku";
		#Util::print_message("ABC Check point ... GeneralInfo::generate_table_topics_by_course() ...");  exit;
		my $ku_label	= Common::format_ku_label($lang, $ku);
		my $pdflink 	= Common::get_small_icon("none.gif", "");

		#Util::print_warning("ku_info{$lang}{$ku}{ka}=$Common::ku_info{$lang}{$ku}{ka}");
		#print Dumper(\%{$Common::ku_info{$lang}{$ku}});
		#print Dumper(\%{$Common::bok{$lang}{$ka}{KU}{$ku}});
		if( $Common::bok{$lang}{$ka}{KU}{$ku}{nhTier1} > 0 || $Common::bok{$lang}{$ka}{KU}{$ku}{nhTier2} > 0 )
		{	$pdflink = Common::get_small_icon("star.gif", $Common::config{dictionary}{MandatoryUnit});		}

		if(not defined($Common::config{ref}{$ku}))
		{	Util::print_error("Common::config{ref}{$ku} not defined ..."); #exit;
		}
		my $ContainsMandatoryHours = "~";
		my $star_msg = '
	\latexhtml{<STAR_LATEX>}{%
		\begin{htmlonly}
			\begin{rawhtml}
				<img src="./figs/<STAR_ICON>" style="border: 0px solid ; width: 16px; height: 16px;">
			\end{rawhtml}
		\end{htmlonly}
	}';

		if( $Common::bok{$lang}{$ka}{KU}{$ku}{nhTier1} > 0 || $Common::bok{$lang}{$ka}{KU}{$ku}{nhTier2} > 0 )
		{	
			$star_msg =~ s/<STAR_LATEX>/\$\\bigstar\$/g;
			$star_msg =~ s/<STAR_ICON>/star.gif/g;
			#$ContainsMandatoryHours = "\$\\bigstar\$";
		}
		else
		{	$star_msg =~ s/<STAR_LATEX>/~/g;
			$star_msg =~ s/<STAR_ICON>/none.gif/g;
		}
		$current_row  =~ s/--mandatory--/$star_msg/g;

 		#my $unit_cell = "$pdflink\\htmlref{$ContainsMandatoryHours$ku_label}{$Common::config{ref}{$ku}}";
 		#my $unit_cell = "$pdflink\\htmlref{$ku_label}{$Common::config{ref}{$ku}}";
 		my $unit_cell = "\\htmlref{$ku_label}{$Common::config{ref}{$ku}}";
		$current_row  =~ s/--unit--/$unit_cell/g;
		my $sum_row = 0;
		#Util::print_message("row_text=$row_text");
		while($current_row =~ m/--(.*?)--/g)
		{
			my $codcour = $1;
			my $label = $ku."-".$codcour;
			#print Dumper (\%{$Common::map_hours_unit_by_course{$lang}{DSSetsRelationsandFunctions}}); exit;

			if(defined($Common::map_hours_unit_by_course{$lang}{$ku}{$codcour}))
			{	$current_row =~ s/--$codcour--/\\htmlref{$Common::map_hours_unit_by_course{$lang}{$ku}{$codcour}}{sec:$codcour}/;
				$sum_row += $Common::map_hours_unit_by_course{$lang}{$ku}{$codcour};
			}
			else # There is no information for this cell
			{	$current_row =~ s/--$codcour--/~/;
			}
			if(defined($Common::map_hours_unit_by_course{$lang}{$ku}{$codcour}))
			{	$Common::data{hours_by_course}{$codcour} += $Common::map_hours_unit_by_course{$lang}{$ku}{$codcour};
			}
		}
		#Util::print_message("current_row=$current_row");

		if( $sum_row > 0 )
		{
			$row_counter++;
			$current_row =~ s/<Sum>/$sum_row/g;

			my $txt = "";
			$txt = $Common::config{row2} if($background == 1 && $Common::config{graph_version} >= 2);
			$current_row =~ s/<color>/$txt/g;
			$background = 1-$background;

			$table_body .= $current_row;
			if( $row_counter % $rows_per_page == 0 )
			{
				$output_text .= $table_begin;
				$output_text .= "$col_header$sem_header$first_row_text";
				$output_text .= $table_body;
				$output_text .= $table_end1;

				$output_text .= get_bigtables_by_course_caption($init_sem, $final_sem, $part_count, "TableOfTopicByCourseCaption");
				$output_text .= $table_end2;
				$table_body   = "";
				$part_count++;
				$background = $first_backgroud_flag;
			}
		}
	}
	#$table_text .= "\\multicolumn{8}{|l|}{\\textbf{$Common::config{dictionary}{semester_ordinal}{$semester} Semester}} \\\\ \\hline\n";
	#$table_text .= "Cdigo & Curso & HT & HP & HL & Cr & T & Requisitos             \\\\ \\hline\n";

 	foreach my $codcour2 (keys %{$Common::data{hours_by_course}})
	{	$sum_row_text =~ s/--$codcour2--/$Common::data{hours_by_course}{$codcour2}/g;	}
	$output_text .= $table_begin;
	$output_text .= "$col_header$sem_header$first_row_text";
	$output_text .= $table_body;
	$output_text .= $sum_row_text;
	$output_text .= $table_end1;
	if($size eq "book")
	{    $output_text .= get_bigtables_by_course_caption($init_sem, $final_sem, $part_count, "TableOfTopicByCourseCaption");	}

	$output_text .= $table_end2;
	$output_text =~ s/<NPARTS>/$part_count/g;
	$output_text =~ s/\s*\(1\/1\)//g;
	Util::write_file("$outfile", $output_text);
	Util::print_message("generate_table_topics_by_course($init_sem, $sem_per_page, $rows_per_page,$outfile,$angle,$size) OK!");
}

# ok
sub generate_all_topics_by_course($)
{
	my ($lang) = (@_);
	my $prefix = "topics";
 	my $rows_per_page = $Common::config{topics_rows_per_page}-2;
 	my $sem_per_page  = $Common::config{topics_sem_per_page};

	my $file_name_base = "$prefix-by-course";
	my $output_file		= Common::get_template("OutputTexDir")."/$file_name_base";
	
	# First files for the pdf
	my $output_txt		= "";
	for(my $i = 1; $i <= $Common::config{n_semesters} ; $i += $sem_per_page)
	{
		#Util::print_message("Generating $output_file-$i.tex OK");
		generate_table_topics_by_course($lang, $i, $sem_per_page, $rows_per_page, "$output_file-$i.tex", 90, "book");
		$rows_per_page	= $Common::config{topics_rows_per_page};
		$output_txt	.= "\\input{$output_file-$i}\n";
		$Common::config{change_file}{"$file_name_base-$i"}    = "$file_name_base-$i-web";
	}
	Util::write_file("$output_file.tex", $output_txt);

	#Second: files for web
	$output_txt	= "";
	$rows_per_page	= $Common::config{topics_rows_per_page};
	for(my $i = 1; $i <= $Common::config{n_semesters} ; $i += $sem_per_page)
	{
		generate_table_topics_by_course($lang, $i, $sem_per_page, 500, "$output_file-$i-web.tex", 0, "book");
		$output_txt	.= "\\input{$output_file-$i-web}\n";
	}
	Util::print_message("Generating $output_file-web.tex OK");
	Util::write_file("$output_file-web.tex", $output_txt);

	#my $big_file 	= Common::get_template("OutputTexDir")."/all-$prefix-by-course";
	#generate_table_topics_by_course($lang, 1, 10, 500, "$big_file.tex", 90, "poster");
	Util::print_message("generate_all_topics_by_course() OK!");
	#print Dumper(\%{$Common::config{change_file}});
	#exit;
}

sub generate_list_of_outcomes()
{
	my $version 	= $Common::config{OutcomesVersion};
	my @outcomes_list = split(",", $Common::config{outcomes_list}{$version});
	my $output_tex  = "\\begin{description}\n";
	foreach my $outcome (@outcomes_list)
	{	$output_tex  .= "\\item \\textbf{$outcome)} \\ShowOutcomeText{$outcome}\\label{out:Outcome$outcome}\n";		}
	$output_tex  .= "\\end{description}\n";
	my $output_file	= Common::get_template("out-list-of-outcomes");
	Util::print_message("generate_list_of_outcomes OK! ($output_file)");
	Util::write_file($output_file, $output_tex);
}

sub generate_list_of_courses_by_outcome($)
{
    my ($lang) = (@_);
	my $output_txt = "";
	my $version = $Common::config{OutcomesVersion};
	foreach my $outcome (split(",", $Common::config{outcomes_list}{$version}))
	{
		my $counter = 0;
		my $this_outcome_txt = "";
		foreach my $codcour ( sort  { $Common::codcour_list_priority{$a} <=> $Common::codcour_list_priority{$b} }
							  keys %{ $Common::config{course_by_outcome}{$outcome} } 
							)
		{
			$counter++;
			$this_outcome_txt .= "\t\\item ". Common::get_course_link($codcour, $lang)."\n";
		}
		#Util::print_message("ABC outcome=$outcome ($counter)...");
		if($counter > 0)
		{
			my $outcome  = "";
			if( defined($Common::config{macros}{"outcome$outcome"}) )
			{	$outcome = "(Outcome not defined!)";	}
			$output_txt .= "\\subsection{Outcome: $outcome) $outcome}\n";
			$output_txt .= "\\begin{itemize}\n";
			$output_txt .= "$Common::nolistsep\n";
			$output_txt .= $this_outcome_txt;
			$output_txt .= "\\end{itemize}\n";
			my $filename = get_outcome_map_name($outcome, "big", $lang);
			#Util::print_message("($outcome, big, $lang) => $filename");
			my $courses_by_outcome = $Common::svg_in_html;
			$courses_by_outcome =~ s/<filename>/$filename/g;
			$courses_by_outcome =~ s/<WIDTH>/1341pt/g;   # 70% de 1916
			$courses_by_outcome =~ s/"<HEIGHT>"/853pt/g; #70% de 1218
			$output_txt .= $courses_by_outcome; # size is 50%
		}
		$output_txt .= "\n";
	}
	my $output_file = Common::get_expanded_template("list-of-courses-by-outcome", $lang);
	Util::print_message("Generating list_of_courses_by_outcome ok ($output_file)");
	Util::write_file($output_file, $output_txt);
	#exit;
}

#$Common::config{course_by_specificoutcome}{$params[0]}{$params[1]}{$codcour} = "";
#$config{specificoutcome}{$lang}{$outcome}{$number}{label}    = $2;
#$config{specificoutcome}{$lang}{$outcome}{$number}{priority} 
sub generate_list_of_courses_by_specific_outcome($)
{
    my ($lang) = (@_);
	my $output_txt = "% Generated by generate_list_of_courses_by_specific_outcome($lang)\n";
	my $version = $Common::config{OutcomesVersion};
	foreach my $outcome (split(",", $Common::config{outcomes_list}{$version}))
	{
		my $this_outcome  = "";
		#$this_outcome .= "\\section{Outcome: $outcome ".$Common::config{macros}{$lang}{"outcome$outcome"}."}\n";
		foreach my $number  ( sort  {$Common::config{specificoutcome}{$lang}{$outcome}{$a}{priority} <=> $Common::config{specificoutcome}{$lang}{$outcome}{$b}{priority}}
							  keys %{$Common::config{course_by_specificoutcome}{$outcome}}
							)
		{
			my $courses_counter = 0;
			my ($this_specific_outcome_txt, $list_of_courses) = ("", "");
			my @courses = keys %{ $Common::config{course_by_specificoutcome}{$outcome}{$number} };
			#Util::print_message("Outcome $outcome, suboutcome: $Common::config{specificoutcome}{$lang}{$outcome}{$number}{label}, priority=$Common::config{specificoutcome}{$lang}{$outcome}{$number}{priority}");
			#print Dumper (\@courses);
			
			foreach my $codcour ( sort  { $Common::codcour_list_priority{$a} <=> $Common::codcour_list_priority{$b} }
								  keys %{ $Common::config{course_by_specificoutcome}{$outcome}{$number} } 
								)
			{
				$courses_counter++;
				$list_of_courses .= "\t\\item ". Common::get_course_link($codcour, $lang)."\n";
			}
			#Util::print_message("ABC outcome=$outcome ($courses_counter)...");
			#if($courses_counter > 0)
			#{
				$this_specific_outcome_txt .= "\\subsection{$Common::config{specificoutcome}{$lang}{$outcome}{$number}{label}) $Common::config{specificoutcome}{$lang}{$outcome}{$number}{txt}}\n";
				$this_specific_outcome_txt .= "\\begin{itemize}\n";
				$this_specific_outcome_txt .= $list_of_courses;
				$this_specific_outcome_txt .= "\\end{itemize}\n";
				$this_specific_outcome_txt .= "\n";
				
				$this_outcome .= $this_specific_outcome_txt;
			#}
		}
		$output_txt .= "\\section{$outcome) ";
		if( defined($Common::config{macros}{"outcome$outcome"}) )
		{	$output_txt .= $Common::config{macros}{"outcome$outcome"};	}
		else
		{	$output_txt .= "Outcome not defined (generate_list_of_courses_by_specific_outcome)";	}
		$output_txt .= "}\n";
		$output_txt .= $this_outcome;
	}
	my $output_file = Common::get_expanded_template("list-of-courses-by-specific-outcome", $lang);
	Util::print_message("Generating list_of_courses_by_specific_outcome ok ($output_file, $lang)");
	Util::write_file($output_file, $output_txt);
	#exit;
}

sub generate_table_of_courses_for_one_outcome($$)
{
	my ($outcome, $lang) = (@_);
	my $OutputCompetencesDir = Common::get_expanded_template("OutputCompetencesDir", $lang);
	my ($pagesize, $firstrowsize, $halfpage) = ("23cm", "22.5cm", "10.5cm");
	my $nchars_by_row = 79;
	my $max_nrows   = 30;
	my $begin_table = "%". ("*"x50) ."\n";
	$begin_table   .= "\\begin{tabularx}{$pagesize}{|p{0.5cm}X|X|} \\hline\n";
	my $end_table   = "\\end{tabularx}\n\n";

	#$output_txt .= $begin_table;
	my $tmp_output  = "";
	my $header 		= "";
	#$output_txt .= "\\textbf{$Common::config{dictionaries}{$lang}{Outcomes}} & \\textbf{$Common::config{dictionaries}{$lang}{SpecificCompetences}} & \\textbf{$Common::config{dictionaries}{$lang}{Course}} \\\\ \\hline\n";
	my $counter 	= 0;
	my $one_line_template = "%".("*"x50)." <<SpecificOutcomeLabel>> ". ("*"x50)."\n";
	$one_line_template   .= "<<SpecificOutcomeLabel>>\n& <<SpecificOutcome>> \\vspace{0.1cm} &\n\n<<Courses>> \\\\ \\hline\n\n";
	my %map = ();

	if( defined($Common::config{macros}{"outcome$outcome"}))
	{	($map{Outcome} = "$outcome) ".$Common::config{macros}{"outcome$outcome"}) =~ s/\\xspace//g;	}
	else
	{	$map{Outcome} = "$outcome) Not defined (generate_table_of_courses_for_one_outcome)";	}
	my $this_outcome = "";
	my $first_time   = 1;
	foreach my $number  ( sort  {$Common::config{specificoutcome}{$lang}{$outcome}{$a}{priority} <=> $Common::config{specificoutcome}{$lang}{$outcome}{$b}{priority}}
							keys %{$Common::config{course_by_specificoutcome}{$outcome}}
						)
	{
		my ($label, $txt) = ($Common::config{specificoutcome}{$lang}{$outcome}{$number}{label},
							 $Common::config{specificoutcome}{$lang}{$outcome}{$number}{txt}
							);
		$map{SpecificOutcomeLabel}   = "\\textbf{$label)}";
		$map{SpecificOutcome}  		 = "\\begin{minipage}{$halfpage}\n";
		$map{SpecificOutcome} 	    .= "\\vspace{0.1cm}\n";
		#Util::print_message("label: $label, length:". (length($txt)));
		my $nlines_SpecificOutcome   = int((length($txt)+$nchars_by_row-1)/$nchars_by_row);
		$map{SpecificOutcome} 		.= "$txt\n";
		$map{SpecificOutcome} 	   	.= "\\vspace{0.1cm}\n";
		$map{SpecificOutcome} 		.= "\\end{minipage}\n";
		$map{SpecificOutcome}        =~ s/\\xspace//g;
		my $courses_counter = keys %{ $Common::config{course_by_specificoutcome}{$outcome}{$number} };
		my $nlines = max($nlines_SpecificOutcome, $courses_counter);
		$counter += $nlines;
		my $list_of_courses = "";
		foreach my $codcour ( sort  { $Common::codcour_list_priority{$a} <=> $Common::codcour_list_priority{$b} }
								keys %{ $Common::config{course_by_specificoutcome}{$outcome}{$number} } 
							)
		{	$list_of_courses .= "\t\\item ". Common::get_course_link($codcour, $lang)."\n";
		}
		$map{Courses} = "";
		if($courses_counter > 0)
		{
			$map{Courses}  = "\\begin{minipage}{$halfpage}\n";
			$map{Courses} .= "\\vspace{0.1cm}\n";
			$map{Courses} .= "$Common::nolistsep\n";
			$map{Courses} .= "\\begin{itemize}\n";
			$map{Courses} .= $list_of_courses;
			$map{Courses} .= "\\end{itemize}\n";
			$map{Courses} .= "\\vspace{0.1cm}\n";
			$map{Courses} .= "\\end{minipage}";
		}
		my $this_line = $one_line_template;
		if( $first_time == 1 )
		{	$header = "\\multicolumn{3}{|l|}{\n";
			$header .= "\\begin{minipage}{$firstrowsize}\n";
			$header .= "\\vspace{0.1cm}\n";
			$header .= "\\cellcolor{black!25} \\color{black}{\\textbf{$Common::config{dictionaries}{$lang}{Outcome}: } <<Outcome>>}\n";
			$header .= "\\vspace{0.1cm}\n";
			$header .= "\\end{minipage}\n";
			$header .= "} \\\\ \\hline\n";
			$this_line = $header . $this_line;
			$first_time = 0; 
			$counter++;	
		}
		$tmp_output .= Common::replace_tags_from_hash($this_line, "<<", ">>", %map);
		if( $counter >= ($max_nrows-5) )
		{
			$this_outcome .= "$begin_table$tmp_output$end_table";
		#	my $file = Common::save_courses_by_competence("$begin_table$tmp_output$end_table", $outcome, $lang);
		#	$output_txt .= "\\input{$file}\n";
		#	#$output_txt .= "$begin_table$tmp_output$end_table";
			$tmp_output  = "";
			$counter     = 0;
		}
	}
	my $file = "";
	if( $counter > 0 )
	{	
		$this_outcome .= "$begin_table$tmp_output$end_table";
		$file       = Common::save_courses_by_competence($this_outcome, $outcome, $lang);
	}
	return ($file, $counter);
}

sub generate_table_of_courses_by_specific_outcome($)
{
    my ($lang) = (@_);
	my $output_txt = "% Generated by generate_table_of_courses_by_specific_outcome($lang)\n";
	
	my $version 			 = $Common::config{OutcomesVersion};
	foreach my $outcome (split(",", $Common::config{outcomes_list}{$version}))
	{
		my ($file, $counter) = generate_table_of_courses_for_one_outcome($outcome, $lang);
		if($counter > 0)
		{	$output_txt   .= "\\input{$file}\n";	}
	}
	my $output_file = Common::get_expanded_template("table-of-courses-by-specific-outcome", $lang);
	Util::print_message("Generating table_of_courses_by_specific_outcome ok ($output_file, $lang)");
	Util::write_file($output_file, $output_txt);
}

# ok
sub generate_outcomes_by_course($$$$$$$$)
{
	my ($lang, $init_sem, $sem_per_page, $rows_per_page, $outfile, $angle, $size, $show_all_rows) = (@_);
	my ($sep, $hline) = ($Common::config{sep}, $Common::config{hline});
	my $col_header     = $sep."rX$sep";
	my $sem_header     = " & ";
	my $row_text       = "<color>--outcome-- ";
	my $first_row_text = "";
# 	$first_row_text  = "$Common::config{row2} " if($Common::config{graph_version}>= 2);
	$first_row_text .= "& \\textbf{$Common::config{dictionaries}{$lang}{Skill}/$Common::config{dictionaries}{$lang}{Course}} ";
	#my $sum_row_text   = "Total ";
	my %sem_per_course = ();

	my $first_backgroud_flag = $Common::config{first_backgroud_flag};
	my $background_flag 	 = 1;
	my $part_count 		 = 1;
	my $semester;
	my $ncourses 		 = 0;
	my $extra_header	 = "";
	my $flag		 = 1;
	
	for($semester=$init_sem; $semester < $init_sem+$sem_per_page && $semester <= $Common::config{n_semesters}; $semester++)
	{
		$sem_per_course{$semester} = 0;
		foreach my $codcour ( @{$Common::courses_by_semester{$semester}} )
		{
			#my $codcour_label = Common::get_label($codcour);
			my $codcour_label = $codcour;
			$extra_header = "";
 			$extra_header = "$Common::config{column2}" if($flag == 1 && $Common::config{graph_version}>= 2);
			 $flag = 1 - $flag;
			$col_header     	.= "$sep$extra_header"."c";

			my $color 		 = $Common::course_info{$codcour}{bgcolor};
			if( not $color )
			{	Util::print_error("Course $codcour (Alias: $codcour_label) ($semester Sem) has NOT color");	}

			my $label 		 = Common::format_course_label($codcour_label, $color);
			$first_row_text .= "& ";
			if( $angle > 0 ) {$first_row_text .= "\\rotatebox[origin=lb,units=360]{$angle}{$label} ";}
			else {		  $first_row_text .= "$label ";	}
			$row_text       .= "& --$codcour-- ";
			#$sum_row_text   .= "& --$codcour-- ";
			#$Common::data{hours_by_course}{$codcour} = 0;
			$sem_per_course{$semester}++;
			$ncourses++;
		}
		$col_header     .= "$sep";
		$first_row_text	.= "\n";
		$row_text	.= "\n";
		#my $header_label = "$semester\$^$Common::config{ordinal_postfix}{$semester}\$";

		$extra_header = "";
		$extra_header = "$Common::config{column2}" if($semester % 2 == 1 && $Common::config{graph_version}>= 2);
		my $header_label = "$Common::config{dictionaries}{$lang}{semester_ordinal}{$semester} $Common::config{dictionaries}{$lang}{Sem}";
		$sem_header .= "& \\multicolumn{$sem_per_course{$semester}}{$sep$extra_header"."c$sep}{$header_label} ";
	}
	my $final_sem = $semester-1;
	#$col_header    .= "|c|} $hline\n";
	$col_header    .= "$sep} $hline\n";
	#$sem_header    .= "& . \\\\ \\hline\n";
	$sem_header    .= " \\\\ $hline\n";
	#$first_row_text.= "& \\rotatebox[origin=lb,units=360]{$angle}{SP\\footnote{Suma Parcial}} \\\\ \\hline\n";
	$first_row_text.= " \\\\ $hline\n";
	#$row_text      .= "& <Sum> \\\\ \\hline\n";
	$row_text      .= " \\\\ $hline\n";
	#$sum_row_text  .= "&        \\\\ \\hline\n";

	my $current_row = "";
	my $table_text  = "";
	my $table_begin = "";
	#$table_begin   .= "\\begin{landscape}\n";
	if($size eq "book")
	{	$table_begin   .= "\\begin{center}\n";
		$table_begin   .= "\\begin{table}[H]\n";
	}
	my $tabsize 		= "";
	$tabsize 		= "24cm" if($size eq "book");
	$tabsize 		= "\\SkillsTableWidth" if($size eq "poster");
	$table_begin   .= "\\begin{tabularx}{$tabsize}{";
	my $table_end1  = "\\end{tabularx}\n";
	my $table_end2  = "";
	if($size eq "book")
	{	$table_end2    .= "\\end{table}\n";
		$table_end2    .= "\\end{center}\n\n";
	}
	#$table_end     .= "\\end{landscape}\n\n";
	my $row_counter = 0;
	my $output_text = "";
	my $table_body  = "";
# 	my $check_label = "\$\\bullet\$";
	my $check_label = $Common::config{check_for_active_outcome};
	#foreach my $main_areax (sort keys %map_hours_unit_by_course)
	#{	print "\"$main_areax\"->$Common::areas_priority{$main_areax}\n";
	#}
	#print "Antes do foreach ...\n";
	#@outcome_acro_array
	$background_flag 		 = $first_backgroud_flag;
	my $version = $Common::config{OutcomesVersion};
	foreach my $outcome (split(",", $Common::config{outcomes_list}{$version}))
	{
		#print "main_area = $main_area \n";
		#print "unit_name=$unit_name ...\n";
		$current_row = $row_text; 
		my $new_txt = "";
		my $outcome_label = "";
		if( defined($Common::config{macros}{$lang}{"outcome$outcome"."Short"}) )
		{	$outcome_label = $Common::config{macros}{$lang}{"outcome$outcome"."Short"};		}
		else
		{	$outcome_label = "outcome$outcome Not defined (generate_outcomes_by_course)";	}	
		if($background_flag == 1 && $Common::config{graph_version}>= 2)
									   #$Common::config{macros}{$lang}}{keys %outcomes_macros}
		{	$new_txt = "$outcome) & ". $outcome_label;		}
		#{	$new_txt = "$outcome) & ". $Common::config{macros}{$lang}{outcomes}{"outcome$outcome"."Short"};		}
		else{	$new_txt = "$Common::config{cell} $outcome) & $Common::config{cell} ". $outcome_label;		}

		$current_row =~ s/--outcome--/$new_txt/g;
		my $sum_row = 1;
		my $courses_with_this_outcome = 0;
		while($current_row =~ m/--(.*?)--/g)
		{
			my $codcour = $1;
			my $background_color = "$Common::config{cell} ";
			if($background_flag == 1 && $Common::config{graph_version}>= 2)
			{	$background_color = "";	}
			# ERNESTO TODO
			#$Common::course_info{$codcour}{$lang}{$env}{$version}{$params[0]}
			#$Common::course_info{$codcour}{$lang}{$env}{$version}{$specificoutcome} = $params[2];
			#$Common::course_info{$codcour}{$lang}{outcomes}{$version}{specificoutcomes}{$specificoutcome} = $params[2];
			if( defined($Common::course_info{$codcour}{$lang}{outcomes}{$version}{$outcome}) )
			{
				#$current_row =~ s/--$codcour--/\$\\checkmark\$/;		  $Common::config{macros}{$lang}}{keys %outcomes_macros}
				$current_row =~ s/--$codcour--/$background_color\\htmlref{$Common::course_info{$codcour}{$lang}{outcomes}{$version}{$outcome}}{sec:$codcour}/;
				$courses_with_this_outcome++;
			}
			else # There is no information for this cell
			{	$current_row =~ s/--$codcour--/$background_color/;
			}
		}
		if( $sum_row > 0 )
		{
			$row_counter++;
			my $txt = "";
			if($background_flag == 1 && $Common::config{graph_version}>= 2)
			{	#$txt = $Common::config{row2};
			}
			$current_row =~ s/<color>/$txt/g;
			$background_flag = 1-$background_flag;

			if( $show_all_rows == 1 || $courses_with_this_outcome > 0 )
			{	$table_body .= $current_row;	}
			if( $row_counter % $rows_per_page == 0 )
			{
				$output_text .= $table_begin;
				$output_text .= "$col_header$sem_header$first_row_text";
				$output_text .= $table_body;
				$output_text .= $table_end1;
				$output_text .= get_bigtables_by_course_caption($init_sem, $final_sem, $part_count, "TableOfOutcomesByCourseCaption");
				$output_text .= $table_end2;
				$table_body   = "";
			}
		}
		#$table_text .= "\\multicolumn{8}{|l|}{\\textbf{$Common::config{dictionary}{semester_ordinal}{$semester} Semester}} \\\\ \\hline\n";
		#$table_text .= "Cdigo & Curso & HT & HP & HL & Cr & T & Requisitos             \\\\ \\hline\n";
	}
 	#foreach my $codcour2 (keys %hours_by_course)
	#{	$sum_row_text =~ s/--$codcour2--/$Common::data{hours_by_course}{$codcour2}/g;	}
	$output_text .= $table_begin;
	$output_text .= "$col_header$sem_header$first_row_text";
	$output_text .= $table_body;
	$output_text .= $table_end1;
	if($size eq "book")
	{
		$output_text .= get_bigtables_by_course_caption($init_sem, $final_sem, $part_count, "TableOfOutcomesByCourseCaption");
	}
	$output_text .= $table_end2;
	#$output_text .= $sum_row_text;

	Util::write_file($outfile, $output_text);
	Util::print_message("Writing $outfile ... ok!");
# 	Util::print_message("generate_outcomes_by_course($init_sem, $sem_per_page, $rows_per_page,$outfile,$angle,$size,$show_all_rows) OK! ...");
}

# ok
sub generate_all_outcomes_by_course($)
{
	my ($lang) = (@_);
	my $lang_prefix 	= $Common::config{dictionaries}{$lang}{lang_prefix};
	my $rows_per_page 	= $Common::config{outcomes_rows_per_page};
	my $sem_per_page  	= $Common::config{outcomes_sem_per_page};
	my $angle	  		= 90;
	my $outfile 	  	= Common::get_template("OutputTexDir")."/outcomes-by-course-$lang_prefix";
	my $output_txt	  	= "";

	#$output_txt	.= "\\begin{landscape}\n";
	for(my $i = 1; $i <= $Common::config{n_semesters} ; $i += $sem_per_page)
	{
		generate_outcomes_by_course($lang, $i, $sem_per_page, $rows_per_page, "$outfile-$i.tex", $angle, "book", 1);
		$output_txt	.= "\\input{$outfile-$i}\n";
	}
	#$output_txt	.= "\\end{landscape}\n";
	Util::write_file("$outfile.tex", $output_txt);

	my $big_file 	= Common::get_expanded_template("in-all-outcomes-by-course-poster", $lang);
	generate_outcomes_by_course($lang, 1, 10, 500, $big_file, 90, "poster", 1);
	Util::print_message("generate_all_outcomes_by_course($lang_prefix) OK!");
}

# ok
sub generate_list_of_courses_by_area($)
{
    my ($lang) = (@_);
	my $output_txt = "\\begin{enumerate}\n";
	foreach my $axe (sort {$Common::config{sub_areas_priority}{$a} <=> $Common::config{sub_areas_priority}{$b}}
		keys %{$Common::config{dictionary}{all_areas}})
	{
		my $i = 0;
		my $this_topic = "";
		foreach my $codcour (@{$Common::list_of_courses_per_area{$axe}})
		{
			$i++;
			#my $codcour_label = Common::get_label($codcour);
			my $codcour_label = $codcour;

# 			print "$codcour -> $codcour_label\n";
			my $semester	= $Common::course_info{$codcour}{semester};
# 			print Dumper \%{$Common::course_info{$codcour}{$lang}{course_name}};
# 			Util::print_message("Common::config{language_without_accents}=$Common::config{language_without_accents}");
# 			Util::print_message("Common::course_info{$codcour}{$lang}{course_name}=$Common::course_info{$codcour}{$lang}{course_name}");

			$this_topic .= "\t\t\\item ". Common::get_course_link($codcour, $lang)."\n";
# 			$this_topic .= "\t\t\\item \\htmlref{$codcour_label. $Common::course_info{$codcour}{$lang}{course_name}}{sec:$codcour_label} ";
# 			$this_topic .= " ($semester";
# 			$this_topic .= "$Common::config{dictionary}{ordinal_postfix}{$semester} $Common::config{dictionary}{Sem}, ";
# 			$this_topic .= "$Common::config{dictionary}{Pag}~\\pageref{sec:$codcour_label}";
# 			$this_topic .= ")\n";
		}
		my $area_title = $Common::config{dictionary}{all_areas}{$axe};
 		$area_title =~ s/<ENTER>/ /g;
		$output_txt .= "\\item $area_title";
		if($i > 0)
		{
		      my $crlabel = Util::round($Common::counts{credits}{areas}{$axe});
		      $output_txt .= " ($crlabel $Common::config{dictionary}{Credits})";
		}
		$output_txt .= "\n";
		$output_txt .= "\t\\begin{itemize}\n";
		if($i > 0)
		{	$output_txt .= $this_topic;		}
		else
		{	$output_txt .= "\t\t\\item $Common::config{dictionary}{None}\n";	}
		$output_txt .= "\t\\end{itemize}\n";
	}
	$output_txt .= "\\end{enumerate}\n";

	my $output_file = Common::get_template("out-list-of-courses-per-area-file");
	Util::write_file($output_file, $output_txt);
	Util::print_message("generate_list_of_courses_by_area($lang) OK!");

}

my $Min_Color        = "red";
# my $Min_Color        = "green";
my $Max_Color        = "blue";
my $ThisSchool_Color = "black";

my %line_style          = ("min"  => "linecolor=$Min_Color,linestyle=dashed,linewidth=0.8pt",
			   "max"  => "linecolor=$Max_Color,linestyle=dashed,linewidth=0.8pt",
			   "univ" => "linecolor=$ThisSchool_Color,linewidth=0.8pt");

# Generate legends
sub get_legend($$$$$)
{
	my ($x1, $y1, $x2, $y2, $standard) = (@_);
	my ($xline) = ($x1+1);
	my $output_txt = "";
	$output_txt .= "\t\\psframe[shadow=true,linecolor=black]($x1,$y1)($x2,$y2)\n";
	($x1, $y1) = ($x1+0.1, $y1-0.3);
	$output_txt .= "\t\\psline[arrows=-, $line_style{max}]($x1, $y1)($xline, $y1)\n";
	$output_txt .= "\t\\rput[l]($xline,$y1){$standard Max}\n";

	$y1 -= 0.4;
	$output_txt .= "\t\\psline[arrows=-, $line_style{univ}]($x1, $y1)($xline, $y1)\n";
        $output_txt .= "\t\\rput[l]($xline,$y1){$Common::config{area}-\\siglas}\n";

	$y1 -= 0.4;
	$output_txt .= "\t\\psline[arrows=-, $line_style{min}]($x1, $y1)($xline, $y1)\n";
	$output_txt .= "\t\\rput[l]($xline,$y1){$standard Min}\n";

	return $output_txt;
}

# ok
sub generate_background_figure_for_one_standard($$$$)
{
	my ($standard, $nareas, $ang_base, $leftright) = (@_);

	#Util::print_message("axe=CS, data{counts_per_standard}{CS} = $Common::data{counts_per_standard}{CS}"); exit;
 	my @mma        = ("min", "max");
					# linearc=0.5,
	my %out_tex    = ("min" => "\n\t\\psline[arrows=-,$line_style{min}]",
			  "max" => "\t\\psline[arrows=-,$line_style{max}]",
			  "univ" => "\t\\psline[arrows=-,$line_style{univ}]");
	my %first      = ("min" => "", "max" => "", "univ" => "");
	my $ang   = 0;

	my @list_of_values = ();
	my $count = 0;
 	foreach my $axe (sort {$Common::config{sub_areas_priority}{$a} <=>
                               $Common::config{sub_areas_priority}{$b}}
                           keys %{$Common::config{dictionary}{all_areas}})
	{
	    my ($x,  $y, $xp, $yp);
	    foreach my $mm ("min", "max")
	    {
		my ( $x, $y) = (100*$Common::config{StdInfo}{$standard}{$axe}{$mm}/$Common::config{StdInfo}{$standard}{max}, 0);
		#my ($xp,$yp) = ($x, $y);
		($xp,$yp) = Util::rotate($leftright*$x, $y, $leftright*$ang); # Aqui change left, right
		($xp,$yp) = (Util::round($xp)/10, Util::round($yp)/10);
		($list_of_values[$count]{$mm}{x}, $list_of_values[$count]{$mm}{y}) = ($xp,$yp);
		$out_tex{$mm} .= "($xp,$yp)";
	    }
	    # This university
	    ($x, $y)   = (100 * $Common::data{counts_per_standard}{$axe}/$Common::counts{credits}{count}, 0);
	    ($xp, $yp) = Util::rotate($leftright*$x, $y, $leftright*$ang);
	    ($xp, $yp) = (Util::round($xp)/10.0, Util::round($yp)/10.);
	    $out_tex{univ} .= "($xp,$yp)";
	    ($list_of_values[$count]{univ}{x}, $list_of_values[$count]{univ}{y}) = ($xp,$yp);

	    $ang += $ang_base;
	    $count++;
	}
	foreach my $mm ("min", "max", "univ")
	{	$out_tex{$mm} .= "($list_of_values[0]{$mm}{x}, $list_of_values[0]{$mm}{y})\n";		}

# 	#print Dumper (\@list_of_values); exit;
# 	print "max = ";
# 	for( $count = 0; $count < $nareas ; $count++ )
# 	{    printf("(%5.2f,%5.2f)  ", $list_of_values[$count]{max}{x}, $list_of_values[$count]{max}{y});		}
# 	print "\n";
# 	print "min = ";
# 	for( $count = 0; $count < $nareas ; $count++ )
# 	{    printf("(%5.2f,%5.2f)  ", $list_of_values[$count]{min}{x}, $list_of_values[$count]{min}{y});		}
# 	print "\n";
# 	exit;

	#(0,0)(2,3)(3,2.5)
	my $output_polygon = "";
	$count = 0;
 	foreach my $axe (sort {$Common::config{sub_areas_priority}{$a} <=> $Common::config{sub_areas_priority}{$b}}
                           keys %{$Common::config{dictionary}{all_areas}})
	{
	    my ($axe1,  $axe2) = ($count, ($count+1)%$nareas);
	    $output_polygon .= "\t\\pspolygon[fillcolor=yellow,fillstyle=solid,linecolor=yellow]";
	    $output_polygon .= "($list_of_values[$axe1]{min}{x}, $list_of_values[$axe1]{min}{y})($list_of_values[$axe1]{max}{x}, $list_of_values[$axe1]{max}{y})";
	    $output_polygon .= "($list_of_values[$axe2]{max}{x}, $list_of_values[$axe2]{max}{y})($list_of_values[$axe2]{min}{x}, $list_of_values[$axe2]{min}{y})\n";
	    $count++;
	}
	foreach my $mm ("min", "max", "univ")
	{	$output_polygon .= $out_tex{$mm};	}
	return $output_polygon;
}

sub generate_spider_with_one_standard($$$)
{
	my ($standard, $lang, $output_file) = (@_);
	my $output_txt	= "";

	my $range   	 = 5;
	my $circles 	 = $range - 1;
	$output_txt 	.= "\\begin{center}\n";
	$output_txt 	.= "\\psset{unit=0.9cm}\n";
	my $bottom   	 = -$range-1.5;
	my $limits	 = "(-".($range+4).",".$bottom.")(".($range+4).",".($range+0.5).")";
	$output_txt 	.= "\\begin{pspicture}$limits\n";
	$limits	 	 = "(-".($range+4).",".$bottom.")(".($range+4).",".($range+0.5).")";
	$output_txt 	.= "\t\\psframe*[linecolor=white]$limits\n";

	my $nareas   = 0;
	foreach my $axe (keys %{$Common::config{dictionary}{all_areas}})
	{	$nareas++;	}
	my $ang_base = Util::get_ang_base($nareas);
	my $leftright = 1;

	my $graph_base = generate_background_figure_for_one_standard($standard, $nareas, $ang_base, $leftright); # -
	$output_txt .= "$graph_base\n";

	# Draw the circles
	my $i = 1;
	for(; $i <= $circles ; $i++)
	{
		$output_txt .= "	\\pscircle[linestyle=dotted](0,0){$i}\t\t";
		my $label = $i*10;
		$output_txt .= "\\rput[t](".($leftright*$i).",0){\\small $label\\\%}\n";
	#	$output_txt .= "	\\pscircle[](0,0){$i}\n";
	}

	my $ang		= 0;
	#Draw axes
	$i = 0;
	my $this_univ	= "";
	foreach my $axe (sort {$Common::config{sub_areas_priority}{$a} <=> $Common::config{sub_areas_priority}{$b}}
			keys %{$Common::config{dictionary}{all_areas}})
	{
		# Dibujar los ejes
		my ($x, $y)  = ($leftright*$range, 0);
		my ($xp,$yp) = Util::rotate($x, $y, $ang);
		($xp,$yp) = (Util::round($xp), Util::round($yp));
		$output_txt .= "\t\\psline[arrows=->,linestyle=dotted](0,0)($xp,$yp)\t\t";

		# Draw labels for each area
		my $tb = "b";
		$tb = "t" if($yp < 0);

		my $xpe=$xp;
		#if($i<($nareas/4))||($i>($nareas-$nareas/4)))
 		if ($xp < 0)	{	$xpe-=1;	}
 		else			{	$xpe+=1;	}

		my $area_title = $Common::config{dictionaries}{$lang}{all_areas}{$axe};
		#Util::print_message("area_title=$area_title"); exit;
 		$area_title =~ s/<ENTER>/ /g;
		$output_txt .= "\t\\rput[$tb]($xpe,$yp){$area_title}\n";
		$ang += $leftright*$ang_base;
		$i++;
	}
	$output_txt .= "\n";

	# Generate legends
	$output_txt .= get_legend(4, -$range+2*$Common::config{legend_space}, 5, -$range+2*$Common::config{legend_space}, $standard);

	$output_txt .= "\\end{pspicture}\n";
	$output_txt .= "\\end{center}\n";

	Util::write_file_to_gen_fig($output_file, $output_txt);
	Util::print_message("generate_spider_with_one_standard($standard) OK!  $output_file");
	#print Dumper (%{$Common::config{dictionary}{all_areas}}); exit;
	#Util::print_message("nareas=$nareas, ang_base=$ang_base");
}

sub generate_curves_with_one_standard($$$)
{
	my ($standard, $lang, $output_file) = (@_);
	my $output_txt	= "";

	my $range    = 5;
	my $bottom   = -3.3;
	my $nareas   = 0;
	my $margin = 0.3;
	foreach my $axe (keys %{$Common::config{dictionaries}{$lang}{all_areas}})
	{	$nareas++;	}

	my $circles 	 = $range - 1;
	$output_txt 	.= "\\begin{center}\n";
	$output_txt 	.= "\\psset{unit=0.9cm}\n";
	$output_txt 	.= "\\begin{pspicture}(-$margin,$bottom)(".($nareas+1).",".($range+$margin).")\n";
	$output_txt 	.= "\t\\psframe*[linecolor=white](-1,$bottom)(".($nareas+1).",".($range+0.5).")\n";
	$output_txt 	.= "\t\\psframe[shadow=true](0,0)(".($nareas+$margin).",$range)\n";
	$output_txt 	.= "\t\\psgrid[gridcolor=lightgray,subgriddiv=1,subgridcolor=lightgray,griddots=10,gridlabelcolor=white](0,0)(".($nareas+$margin).",$range)\n\n";

	my $i = 1;
	for(; $i <= $range ; $i++)
	{
		my $label = $i*10;
		$output_txt .= "\t\\rput[r](0, $i){\\small $label\\\%}\n";
	}

	#Draw axes
	$i = 1;
	my %out_tex    = ("min" => "",
			  "max" => "",
			  "univ" => "");

	foreach my $axe (sort {$Common::config{sub_areas_priority}{$a} <=> $Common::config{sub_areas_priority}{$b}}
			         keys %{$Common::config{dictionary}{all_areas}})
	{
# 		# Draw labels for each area: \rput[r]{90}(1,-0.2){Hardware y Arquitectura}
		my @lines = split("<ENTER>", $Common::config{dictionaries}{$lang}{all_areas}{$axe});
		my $nlines = @lines;
		my $linewidth = 0.4;
		my $base = $i-($linewidth*($nlines-1)/2);
		for(my $i = 0; $i < $nlines ; $i++)
		{
			$output_txt .= "\t\\rput[r]{90}($base,-0.2){$lines[$i]}\n";
			$base += $linewidth;
		}
# 		Util::print_message("Label=$Common::config{dictionary}{all_areas}{$axe}, nlines=$nlines"); exit;
#  		$output_txt .= "\t\\rput[r]{90}($i,-0.2){$Common::config{dictionary}{all_areas}{$axe}}\n";
		my ($x,  $y);
		($x, $y) = ($i, Util::round(10*$Common::config{StdInfo}{$standard}{$axe}{max}/$Common::config{StdInfo}{$standard}{max}));
		$out_tex{max} .= "($x,$y)";
		($x, $y) = ($i, Util::round(10*$Common::config{StdInfo}{$standard}{$axe}{min}/$Common::config{StdInfo}{$standard}{max}));
		$out_tex{min}  = "($x,$y)".$out_tex{min};

		($x, $y) = ($i, 100 * $Common::data{counts_per_standard}{$axe}/$Common::counts{credits}{count});
		($x, $y) = ($x, Util::round($y)/10);
		$out_tex{univ} .= "($x,$y)";
 		$i++;
 	}
	my $pstype = "psline";
	my %pscmd = ("min"  => "\\$pstype"."[$line_style{min}, arrows=-,showpoints=true]$out_tex{min}",
		     "max"  => "\\$pstype"."[$line_style{max}, arrows=-,showpoints=true]$out_tex{max}",
		     "univ" => "\\$pstype"."[$line_style{univ},arrows=-,showpoints=true]$out_tex{univ}"
		    );
	$output_txt .= "\n";
	my $fillcolor="yellow";
	$output_txt .= "\t\\pscustom[linecolor=$fillcolor";
	$output_txt .= "]{%\n";
	$output_txt .= "\t\t$pscmd{max}\n";
	$output_txt .= "\t\t$pscmd{min}\n";
	$output_txt .= "\t\t\\fill[fillstyle=solid,fillcolor=$fillcolor]\n";
	$output_txt .= "\t}\n";
	$output_txt .= "\t$pscmd{univ}\n";
	$output_txt .= "\t$pscmd{max}\n";
	$output_txt .= "\t$pscmd{min}\n";

# 	my $graph_base = generate_background_figure_for_one_standard($standard, $nareas, $ang_base);
# 	$output_txt .= $graph_base;
	$output_txt .= "\n";

	# Generate legends
	$output_txt .= get_legend($nareas-2.9, 4.8, $nareas, 3.3, $standard);

	$output_txt .= "\\end{pspicture}\n";
	$output_txt .= "\\end{center}\n";

	Util::write_file_to_gen_fig($output_file, $output_txt);
	Util::print_message("generate_curves_with_one_standard($standard) OK!  $output_file");
}

sub generate_latex_include_for_this_standard($$$)
{
	my ($standard, $output_file_without_extension, $label) = (@_);

	my $output_txt .= "\\begin{figure}[H]\n";
	$output_txt .= "\\centering\n";
	$output_txt .= "\\includegraphics[scale=1.0]{$output_file_without_extension}\n";

	my $caption = Common::get_standard_title($standard);
	$output_txt .= "	\\caption{$caption}\n";
	$output_txt .= "	\\label{fig:comparing-$label}\n";
	$output_txt .= "\\end{figure}\n";
	return $output_txt;
}

# ok
sub generate_compatibility_with_standards($)
{
	my ($lang) = (@_);
	my $lang_prefix = $Common::config{dictionaries}{$lang}{lang_prefix};
	# First: initialize counter for each standard
	foreach my $axe (sort {$Common::config{sub_areas_priority}{$a} <=> $Common::config{sub_areas_priority}{$b}} keys %{$Common::config{dictionary}{all_areas}})
	{	if(not defined($Common::data{counts_per_standard}{$axe}))
		{	$Common::data{counts_per_standard}{$axe}	= 0;
			$Common::list_of_courses_per_area{$axe}		= [];
		}
	}
	# Gen figure file itself
    # Util::print_message("generate_spider_with_one_standard($standard)");
	$Common::config{legend_space} = 0.5;

	my $OutputTexDir = Common::get_template("OutputTexDir");
	my $OutputFigsDir = Common::get_template("OutputFigsDir");
	my $output_txt = "";
	foreach my $standard (split(",", $Common::config{Standards}))
	{
		foreach my $type_of_graph (sort keys %{$Common::config{type_of_graph}})
		{
			my $output_file = "$type_of_graph-$Common::area-with-$standard-$lang_prefix";
			Util::print_color("Generating $output_file ...");
			$output_txt .= "\\begin{latexonly}\n";
			if($type_of_graph eq "spider" && $Common::config{type_of_graph}{spider} == 1)
			{	generate_spider_with_one_standard($standard, $lang, "$OutputTexDir/$output_file.tex");	}			
			elsif($type_of_graph eq "curves" && $Common::config{type_of_graph}{curves} == 1)				
			{	generate_curves_with_one_standard($standard, $lang, "$OutputTexDir/$output_file.tex");	}
			$output_txt .= generate_latex_include_for_this_standard($standard, "$OutputFigsDir/$output_file", $output_file);
			$output_txt .= "\\end{latexonly}\n\n";	

			my $one_standard = <<'STANDARD_MESSAGE';
\begin{htmlonly}
	\begin{rawhtml}
		<p style="text-align:center;">
		<img src="./figs/<STD_FIG>.png" style="border: 0px solid ; width: 20cm;">
		<b><Figure>:</b> <STD_FIG_TITLE>
        </p>
	\end{rawhtml}
\end{htmlonly}

STANDARD_MESSAGE
			my $caption = Common::get_standard_title($standard);
			$one_standard =~ s/<STD_FIG>/$output_file/g;
			$one_standard =~ s/<STD_FIG_TITLE>/$caption/g;
			$output_txt .= $one_standard;
		}
	}
	my $output_file = Common::get_expanded_template("out-comparing-with-standards-file", $lang);
	Util::write_file($output_file, $output_txt);
	Util::print_message("generate_compatibility_with_standards($output_file) OK!");
}

sub generate_pie_by_levels()
{
	my $output_file = Common::get_template("out-pie-by-levels-file");
	my $output_txt = "";

	# Pending: This code must be in parse_courses (?)
	my $total_credits = 0;
	for(my $semester=1; $semester <= $Common::config{n_semesters} ; $semester++)
	{
		my $maxE = 0;
		my $levelE = 1;
		foreach my $codcour ( @{$Common::courses_by_semester{$semester}} )
		{
			#print "$semester: $codcour;  ";
			if($codcour =~ m/..(.).*/)
			{
				my $level = $1;
				if( not defined($Common::config{colors}{colors_per_level}{$level}) )
				{
				      my $wrong_level = $level;
				      if( $level < $Common::config{course_min_level} ) {	$level = $Common::config{course_min_level};	}
				      if( $level > $Common::config{course_max_level} ) {	$level = $Common::config{course_max_level};	}
				      Util::print_warning("Course $codcour, (Sem $Common::course_info{$codcour}{semester}) has a level ($wrong_level) out of range ... assuming $level");
				}
				if(not defined($Common::data{credits_per_level}{$level}))
				{	$Common::data{credits_per_level}{$level} = 0;		}

				if( $Common::course_info{$codcour}{course_type} eq "Elective" )
				{	$maxE   = $Common::course_info{$codcour}{cr} if($Common::course_info{$codcour}{cr} > $maxE);
					$levelE = $level;
				}
				else
				{	$Common::data{credits_per_level}{$level} += $Common::course_info{$codcour}{cr};
					$total_credits 		      				 += $Common::course_info{$codcour}{cr};
				}
				#if( $semester == 8 )
				#{	my $cr = $Common::course_info{$codcour}{cr};
				#	print "Sem=$semester, $codcour($cr), creditos=$total_credits\n";
				#}
			}
		}
		$Common::data{credits_per_level}{$levelE} += $maxE;
		$total_credits 		    += $maxE;
	}
	$output_txt .= "\\begin{center}\n";
	$output_txt .= "\\psset{framesep=1.5pt,unit=2cm}\n";
	$output_txt .= "\\begin{pspicture}(-4.3,-2.5)(4.3,2.5)\n";
	$output_txt 	.= "\t\\psframe*[linecolor=white](-4,-2.5)(4.3,2.5)\n";
	$output_txt .= "\\SpecialCoor\n";
	$output_txt .= "\\degrees[$total_credits]\n";
	my $first = 0;
	foreach my $level (sort {$a <=> $b} keys  %{$Common::data{credits_per_level}})
	{
		#print "level = $level\n";
		my $last = $first + $Common::data{credits_per_level}{$level};
		my $mid = ($first + $last)/2;
		my $percent = Util::calc_percent($Common::data{credits_per_level}{$level}, $total_credits);
		#Util::print_message("Common::config{colors}{colors_per_level}{$level}]{2}{$first}{$last}=$Common::config{colors}{colors_per_level}{$level}]{2}{$first}{$last}");
		$output_txt .= "\\pswedge[shadow=true,fillstyle=solid,fillcolor=$Common::config{colors}{colors_per_level}{$level}]{2}{$first}{$last}\n";
		$output_txt .= "\\rput(1.2; $mid ){\\Large $percent \\\%}\n";
		$output_txt .= "\\uput{2.2}[$mid](0;0){\\Large $Common::config{dictionary}{labels_per_level}{$level} ($Common::data{credits_per_level}{$level})}\n\n";
		$first = $last;
	}
	$output_txt .= "\\end{pspicture}\n";
	$output_txt .= "\\end{center}\n";
	Util::write_file_to_gen_fig($output_file, $output_txt);
	Util::print_message("generate_pie_by_levels() ... OK!");

}

sub generate_equivalence_old2new($)
{
	my ($old_curricula) = (@_);
	my $new_curricula = $Common::config{Plan};

	my $infile      	= Common::get_template("InEquivDir")    ."/$old_curricula.txt";
	my $outfile_short	= "equivalence$old_curricula-$new_curricula";
	my $outfile     	= Common::get_template("OutputTexDir")."/$outfile_short.tex";

	Util::print_message("Generating Equivalence $old_curricula->$new_curricula ...\nInput: $infile\nOutput: $outfile");
	if(not -e $infile )
	{	Util::print_message("File \"$infile\" does not exist ... ignoring this equivalence !");
		return;
	}
	my ($bg, $textcolor) = ($Common::config{colors}{change_highlight_background}, $Common::config{colors}{change_highlight_text});
	my $infile_txt = Util::read_file($infile);
	my $in_txt 		= Util::read_file($infile);
	my $output_txt = "";
	my $current_semester = 0;

	                   #{1}{CS105}{Discretas I}{5}{CS1D1}%Estructuras Discretas I,5
	while($in_txt =~ m/\{(.*)\}\{(.*)\}\{(.*)\}\{(.*)\}\{(.*)\}(.*)/g)
	{
		my ($semester, $old_course_codcour, $old_course_name, $old_course_cr, $codcour) = ($1, $2, $3, $4, $5);

		#print "$semester -- $old_course_codcour -- $old_course_name -- $old_course_cr -- $codcour \n";

		$Common::general_info{equivalences}{$old_curricula}{$semester}{$old_course_codcour}{old_course_name} 	= $old_course_name;
		$Common::general_info{equivalences}{$old_curricula}{$semester}{$old_course_codcour}{old_course_cr} 	= $old_course_cr;
		$Common::general_info{equivalences}{$old_curricula}{$semester}{$old_course_codcour}{codcour} 		= $codcour; # into the new curricula

		if( $semester eq "" )
		{
		    Util::print_message("Wrong equivalence format? {$semester}{$old_course_codcour}{$old_course_name}{$old_course_cr}{$codcour}");
		}
		else
		{   my $old_course_semester_label = Common::format_semester_label($semester);
		    if( $old_course_semester_label eq "" )
		    {	$Common::course_info{$codcour}{equivalences}{$old_curricula}     = "{}{}{}{}";		}
		    else{   $Common::course_info{$codcour}{equivalences}{$old_curricula} = "{$semester}{$old_course_codcour}{$old_course_name}{$old_course_cr}";		}
		}
	}
	my $endtable = "\\end{tabularx}\n";
	$endtable   .= "\n";
	                   #{1}{CS105}{Discretas I}{5}{CS1D1}%Estructuras Discretas I,5
	foreach my $semester (sort {$a <=> $b} keys %{$Common::general_info{equivalences}{$old_curricula}}	)
	{
		my $begintable  	= "";
		$begintable .= "\\begin{tabularx}{23cm}{|p{1.3cm}|X|p{0.6cm}||p{1.3cm}|X|p{0.7cm}|p{0.6cm}|}\\hline\n";
		$begintable .= "\\multicolumn{3}{|c||}{\\textbf{$Common::config{dictionary}{semester_ordinal}{$semester} $Common::config{dictionary}{Semester}} -- \\textbf{$Common::config{dictionary}{Plan} $old_curricula}} & \\multicolumn{4}{|c|}{\\textbf{$Common::config{dictionary}{Plan} $new_curricula}} \\\\ \\hline\n";
		$begintable .= "\\textbf{$Common::config{dictionary}{COURSECODE}} & ";
		$begintable .= "\\textbf{$Common::config{dictionary}{COURSENAME}} & ";
		$begintable .= "\\textbf{$Common::config{dictionary}{CREDITS}}    & ";
		$begintable .= "\\textbf{$Common::config{dictionary}{COURSECODE}} & ";
		$begintable .= "\\textbf{$Common::config{dictionary}{COURSENAME}} & ";
		$begintable .= "\\textbf{$Common::config{dictionary}{Sem}}        & ";
		$begintable .= "\\textbf{$Common::config{dictionary}{CREDITS}} ";
		$begintable .= "\\\\ \\hline\n";
		$output_txt .= $begintable;
		my $line_tpl = "<OLD_COURSE_CODE> & <OLD_COURSE_NAME> & <OLD_COURSE_CREDITS> & <COURSE_CODE> & <COURSE_NAME> & <COURSE_SEM> & <COURSE_CREDITS> \\\\ \\hline\n";

		foreach my $old_course_codcour ( keys %{$Common::general_info{equivalences}{$old_curricula}{$semester}} )
		{
			my %tags = ();
# 			my $this_line 	= $Common::general_info{equivalences}{$old_curricula}{$semester}{$old_course_codcour}{oldfirstcols};
			$tags{OLD_COURSE_CODE} 		= $old_course_codcour;
			$tags{OLD_COURSE_NAME} 		= $Common::general_info{equivalences}{$old_curricula}{$semester}{$old_course_codcour}{old_course_name};
			my $old_course_cr = $Common::general_info{equivalences}{$old_curricula}{$semester}{$old_course_codcour}{old_course_cr};

			my $codcour 	= $Common::general_info{equivalences}{$old_curricula}{$semester}{$old_course_codcour}{codcour};
			#my $codcour_label = Common::get_label($codcour);
			my $codcour_label = $codcour;

			if($Common::course_info{$codcour}{bgcolor})
			{
				$tags{COURSE_CODE} = "\\htmlref{\\colorbox{$Common::course_info{$codcour}{bgcolor}}{$codcour_label}}{sec:$codcour}";
				$tags{COURSE_NAME} = "\\htmlref{$Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name}}{sec:$codcour}";
				my $semester_label 	= Common::format_semester_label($Common::course_info{$codcour}{semester});
				if($semester != $Common::course_info{$codcour}{semester})
				{	$semester_label = "\\colorbox{honeydew3}{\\textcolor{black}{$semester_label}}";		}
				$tags{COURSE_SEM}	= $semester_label;
				#Util::print_message("old_course_codcour= $old_course_codcour, old_course_cr=$old_course_cr, new_cr = $Common::course_info{$codcour}{cr} ");
				if( not $old_course_cr eq "" and not $old_course_cr eq $Common::course_info{$codcour}{cr} )
				{	$tags{OLD_COURSE_CREDITS}	= "\\colorbox{honeydew3}{\\textcolor{black}{$old_course_cr}}";
					$tags{COURSE_CREDITS} 		= "\\colorbox{honeydew3}{\\textcolor{black}{$Common::course_info{$codcour}{cr}}}";
				}
				else{	$tags{COURSE_CREDITS} 		= "$Common::course_info{$codcour}{cr}";
					$tags{OLD_COURSE_CREDITS}	=  $old_course_cr;
				}
			}
			else
			{	#Util::print_warning("Common::course_info{$codcour}{bgcolor} not defined");
				$tags{COURSE_CODE} = "";
				$tags{COURSE_NAME} = "";
				$tags{COURSE_SEM}  = "";
				$tags{COURSE_CREDITS} 	  = "";
				$tags{OLD_COURSE_CREDITS} = "";
			}

			$output_txt .= Common::replace_tags_from_hash($line_tpl, "<", ">", %tags);
		}
		$output_txt .= "$endtable";
	}
#  	exit;
	Util::write_file($outfile, $output_txt);
        Util::check_point("generate_equivalence_old2new $old_curricula->$new_curricula");
	Util::print_message("generate_equivalence_old2new $old_curricula->$new_curricula OK!");
	return $outfile_short;
}

sub generate_equivalence_new2old($)
{
	my ($old_curricula) = (@_);
	my $new_curricula = $Common::config{Plan};

	Util::precondition("generate_equivalence_old2new $old_curricula->$new_curricula");
	my $infile      	= Common::get_template("InEquivDir")    ."/$old_curricula.txt";
	my $outfile_short	= "equivalence$new_curricula-$old_curricula";
	my $outfile     	= Common::get_template("OutputTexDir")."/$outfile_short.tex";
	Util::print_message("Generating Equivalence $new_curricula->$old_curricula ...\nInput: $infile\nOutput: $outfile");

	my $output_txt	= "";
	my ($bg, $textcolor) = ($Common::config{colors}{change_highlight_background}, $Common::config{colors}{change_highlight_text});
	for(my $semester = $Common::config{SemMin}; $semester <= $Common::config{SemMax} ; $semester++)
	{
		my $begintable  	= "";
		$begintable .= "\\begin{tabularx}{23cm}{|p{1.3cm}|X|p{0.7cm}|p{1.3cm}|X|p{0.6cm}|p{0.6cm}|}\\hline\n";
		$begintable .= "\\multicolumn{3}{|c||}{\\textbf{$Common::config{dictionary}{semester_ordinal}{$semester} $Common::config{dictionary}{Semester} -- $Common::config{dictionary}{Plan} $new_curricula}} & \\multicolumn{4}{|c|}{\\textbf{$Common::config{dictionary}{Plan} $old_curricula}} \\\\ \\hline\n";
		$begintable .= "\\textbf{$Common::config{dictionary}{COURSECODE}} & ";
		$begintable .= "\\textbf{$Common::config{dictionary}{COURSENAME}} & ";
		$begintable .= "\\textbf{$Common::config{dictionary}{CREDITS}}    & ";

		$begintable .= "\\textbf{$Common::config{dictionary}{COURSECODE}} & ";
		$begintable .= "\\textbf{$Common::config{dictionary}{COURSENAME}} & ";
		$begintable .= "\\textbf{$Common::config{dictionary}{Sem}}        & ";
		$begintable .= "\\textbf{$Common::config{dictionary}{CREDITS}} ";
		$begintable .= "\\\\ \\hline\n";
		$output_txt .= $begintable;
		my $endtable    = "\\end{tabularx}\n";
		$endtable      .= "\n";
		my $line_tpl = "<COURSE_CODE> & <COURSE_NAME> & <COURSE_CREDITS> & <OLD_COURSE_CODE> & <OLD_COURSE_NAME> & <OLD_COURSE_SEM> & <OLD_COURSE_CREDITS> \\\\ \\hline\n";

		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
		{
			my %tags = ();
			$tags{COURSE_CODE} 	= "\\htmlref{\\colorbox{$Common::course_info{$codcour}{bgcolor}}{$codcour}}{sec:$codcour}";
			$tags{COURSE_NAME} 	= "\\htmlref{$Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name}}{sec:$codcour}";
			#$Common::course_info{$codcour}{equivalences}{$old_curricula} = "{$semester}{$old_course_codcour}{$old_course_name}{$old_course_cr}
			if( not $Common::course_info{$codcour}{equivalences}{$old_curricula} )
			{	$Common::course_info{$codcour}{equivalences}{$old_curricula} = "{}{}{}{}";
				Util::print_warning("Course: $codcour (Sem $semester) does not contain equivalence ... assuming empty ...");
			}
			my ($old_semester, $old_course_codcour, $old_course_name, $old_course_cr) = ("", "", "", "");
			if( $Common::course_info{$codcour}{equivalences}{$old_curricula} =~ m/\{(.*)\}\{(.*)\}\{(.*)\}\{(.*)\}/ )
			{     ($old_semester, $old_course_codcour, $old_course_name, $old_course_cr)  = ($1, $2, $3, $4);		}
			else{	Util::halt("This line must never be reached ... ********************************* ($codcour, $Common::course_info{$codcour}{equivalences}{$old_curricula})");	}

			  #Util::print_message("old_course_codcour= $old_course_codcour, old_course_cr=$old_course_cr, new_cr = $Common::course_info{$codcour}{cr} ");
			if( not $old_course_cr eq "" and not $old_course_cr eq $Common::course_info{$codcour}{cr} )
			{	$tags{OLD_COURSE_CREDITS}	= "\\colorbox{honeydew3}{\\textcolor{black}{$old_course_cr}}";
				$tags{COURSE_CREDITS} 		= "\\colorbox{honeydew3}{\\textcolor{black}{$Common::course_info{$codcour}{cr}}}";
			}
			else{	$tags{COURSE_CREDITS} 		= "$Common::course_info{$codcour}{cr}";
				$tags{OLD_COURSE_CREDITS}	=  $old_course_cr;
			}

			$tags{OLD_COURSE_CODE} 		= $old_course_codcour;
			$tags{OLD_COURSE_NAME} 		= $old_course_name;
			my $old_semester_label 	= Common::format_semester_label($old_semester);
			if($Common::course_info{$codcour}{semester} != $old_semester)
			{	$old_semester_label = "\\colorbox{honeydew3}{\\textcolor{black}{$old_semester_label}}";		}
			$tags{OLD_COURSE_SEM}		= $old_semester_label;

			$output_txt .= Common::replace_tags_from_hash($line_tpl, "<", ">", %tags);

		}
# 		foreach my $old_course (@{$Common::config{equivalences}{$old_curricula}{empty_equivalences}{$semester}})
# 		{
# 			if( $old_course =~ m/{(.*)}{(.*)}/ )
# 			{
# 				my ($old_course_name, $credits) = ($1, $2);
# 				$output_txt .= " & & & $old_course_name & $credits \\\\ \\hline\n";
# 			}
# 		}
		$output_txt .= $endtable;
	}

	Util::write_file($outfile, $output_txt);
        Util::check_point("generate_equivalence_new2old $new_curricula->$old_curricula");
	Util::print_message("generate_equivalence_new2old $new_curricula->$old_curricula OK!");
	return $outfile_short;

}

sub process_equivalences()
{
	my $equivalences_file_txt = "";
	my $OutputTexDir = Common::get_template("OutputTexDir");
	my $newpage = "";
	foreach my $equiv (split(",", $Common::config{equivalences}))
	{
	      my $outfile_short = generate_equivalence_old2new($equiv);
	      $equivalences_file_txt .= "$newpage\\section{Equivalencia del Plan $equiv al Plan $Common::config{Plan}}\n";
	      $equivalences_file_txt .= "\\input{$OutputTexDir/$outfile_short}\n\n";
	      $newpage = "\\newpage";

 	      $outfile_short	= generate_equivalence_new2old($equiv);
	      $equivalences_file_txt .= "$newpage\\section{Equivalencia del Plan $Common::config{Plan} al Plan $equiv}\n";
	      $equivalences_file_txt .= "\\input{$OutputTexDir/$outfile_short} \n\n";

	}
	my $output_equivalences_file = Common::get_template("out-equivalences-file");
	Util::write_file($output_equivalences_file, $equivalences_file_txt);
	Util::print_message("Generating equivalences: $output_equivalences_file OK!");
}

sub generate_information_4_professor($)
{
      my ($email) = (@_);
      if( scalar (keys %{$Common::config{faculty}{$email}{fields}{courses_assigned}}) == 0 )
      {	return "";	}
      my $this_professor = $Common::config{faculty_tpl_txt};
      my $more = "";
      my $OutputFacultyFigDir = Common::get_template("OutputFacultyFigDir");

      if( -e "$Common::config{InFacultyPhotosDir}/$email.jpg" )
      {
		system("cp $Common::config{InFacultyPhotosDir}/$email.jpg $OutputFacultyFigDir/.");
		$Common::config{faculty}{$email}{fields}{photo} = "fig/$email.jpg";
      }
      else
      {		system("cp $Common::config{NoFaceFile} $OutputFacultyFigDir/.");
		$Common::config{faculty}{$email}{fields}{photo} = "fig/noface.gif";
      }
      my $email_png = "$OutputFacultyFigDir/$Common::config{faculty}{$email}{fields}{emailwithoutat}.png";
      #http://www.imagemagick.org/script/convert.php
      my $email_length = length($email);
      my $width = int($email_length * 8.6);
      system("convert -size $width"."x16 canvas:none -background white -font Bookman-Demi -pointsize 14 -draw \"text 0,12 '$email'\" $email_png&");

      my $concentration = $Common::config{faculty}{$email}{concentration};
      my $degreelevel	= $Common::config{faculty}{$email}{fields}{degreelevel};

      if(not defined($Common::config{faculty_groups}{$concentration}{$degreelevel}) )
      {		 $Common::config{faculty_groups}{$concentration}{$degreelevel} = [];	      }
      push(@{$Common::config{faculty_groups}{$concentration}{$degreelevel}}, $email);

      #my $cict = $Common::config{faculty}{"ecuadros\@ucsp.edu.pe"}{fields}{courses_i_could_teach};
      #Util::print_message("Courses I could teach: $cict"); exit;
      my $codcour = "";
      foreach $codcour ( keys %{$Common::config{faculty}{$email}{fields}{courses_assigned}} )
      {
	    #Util::print_message("config{faculty}{$email}{fields}{courses_assigned}: $codcour");
	    if( not defined($Common::config{faculty}{$email}{fields}{courses_i_could_teach}{$codcour} ) )
	    {	$Common::config{faculty}{$email}{fields}{courses_i_could_teach}{$codcour} = "";
		Util::print_warning("Professor $email has assigned course $codcour but he is not able to teach that course ...");
	    }
      }

      foreach $codcour (keys %{$Common::config{faculty}{$email}{fields}{courses_i_could_teach}} )
      {		if( not defined($Common::course_info{$codcour}) )
		{
		    Util::print_warning("Course $codcour assigned to $email does not exist ...");
		}
      }

      foreach $codcour ( sort  {$Common::course_info{$a}{semester} <=> $Common::course_info{$b}{semester}}
                         keys %{$Common::config{faculty}{$email}{fields}{courses_i_could_teach}} )
      {
	    my $link = $Common::course_info{$codcour}{link};
	    if( defined($Common::config{faculty}{$email}{fields}{courses_assigned}{$codcour} ) )
	    {	$Common::config{faculty}{$email}{fields}{list_of_courses_assigned}    .= Common::GetCourseHyperLink($codcour, $link);	}
	    else
	    {	$Common::config{faculty}{$email}{fields}{other_courses_he_may_teach}  .= Common::GetCourseHyperLink($codcour, $link);	}
      }
      foreach my $field (keys %{$Common::config{faculty}{$email}{fields}})
      {
		my ($before, $after) = ("", "");
		$before = $Common::config{faculty_icons}{before}{$field} if( defined($Common::config{faculty_icons}{before}{$field}) );
		$after  = $Common::config{faculty_icons}{after}{$field} if( defined($Common::config{faculty_icons}{after}{$field}) );
		my $field_formatted = "$before";
		$field_formatted .= "$Common::config{faculty}{$email}{fields}{$field}";
		$field_formatted .= "$after";
		if( $this_professor =~ m/--$field--/g )
		{
		    $this_professor =~ s/--$field--/$field_formatted/g;
		}
		else
		{
		    $this_professor =~ s/--$field--//g;
		}
      }
      $this_professor =~ s/--.*?--//g;
      return $this_professor;
}

sub generate_courses_by_professor($)
{
	my ($lang) = (@_);
	my $out_txt         = "";
	my $professor_count = 0;
	#print Dumper(%{$Common::config{faculty}}); exit;
	#foreach my $email (	sort { $Common::config{faculty}{$a}{priority} <=> $Common::config{faculty}{$b}{priority}}
	#					keys %{$Common::config{faculty}} )
	#{
	#	Util::print_message("Processing professor: $Common::config{faculty}{$email}{fields}{name} ($email)");
	#	Util::print_message("Position=\"$Common::config{faculty}{$email}{fields}{position}\", Dedication=\"$Common::config{faculty}{$email}{fields}{dedication}\"");
	#	Util::print_message("dedication_ranking{$Common::config{faculty}{$email}{fields}{dedication}}=$dedication_ranking{$Common::config{faculty}{$email}{fields}{dedication}}");
	#}
	foreach my $email (	sort { $Common::config{faculty}{$a}{priority} <=> $Common::config{faculty}{$b}{priority}  }
						keys %{$Common::config{faculty}} )
	{	my $name = $Common::config{faculty}{$email}{fields}{name};
		my $number_of_courses_assigned = scalar keys %{$Common::config{faculty}{$email}{fields}{courses_assigned}};
		if( $number_of_courses_assigned == 0 )
		{	Util::print_warning("* Jumping professor: $name ($email) (No courses assigned ...)");
			next;	
		}
		Util::print_message("Processing professor: $name ($email)");
		my $courses_by_professor_count =  0;
		my $this_professor_list        = "";
		
		foreach my $codcour (sort  {$Common::codcour_list_priority{$a} <=> $Common::codcour_list_priority{$b}}
							 keys %{$Common::config{faculty}{$email}{fields}{courses_i_could_teach}})
		{
			$this_professor_list .= "\t\\item ".Common::GetCourseNameWithLink($codcour, $lang, 1, "")."\n";
			$courses_by_professor_count++;
		}
		if($courses_by_professor_count > 0)
		{
			$out_txt .= "\\textbf{$name}\n";
			$out_txt .= "\\begin{itemize}\n$this_professor_list\\end{itemize}\n";
			$professor_count++;
		}
	}
	my $output_tex = "%Generated by generate_courses_by_professor ... do not touch !!!\n";
	#Util::print_message("Common::config{dictionaries}{$lang}{CoursesAProfessorCouldTeach}=$Common::config{dictionaries}{$lang}{CoursesAProfessorCouldTeach}}");
	if( $professor_count > 0 )
	{	$output_tex .= "\\section{$Common::config{dictionaries}{$lang}{CoursesAProfessorCouldTeach}}\\label{sec:CoursesAProfessorCouldTeach}\n";
		#$output_tex .= "\\begin{itemize}\n";
	    $output_tex .= $out_txt;
		#$output_tex .= "\\end{itemize}\n";
	}
	my $out_file = Common::get_expanded_template("out-courses-by-professor-file", $lang);
	Util::print_message("generate_courses_by_professor: Generating ($out_file) OK");
	Util::write_file($out_file, $output_tex); 
	#print Dumper(\%{$Common::config{faculty}{"ecuadros\@utec.edu.pe"}});
}

sub generate_professor_by_course($)
{
	my ($lang) = (@_);
	my $output_txt  = "% Generated by generate_professor_by_course ... Do not touch !!!\n";
	   $output_txt .= "\\section{$Common::config{dictionaries}{$lang}{ProfessorSkilledToTeachACourse}}\\label{sec:ProfessorSkilledToTeachACourse}\n";
	my $current_semester = 0;
	foreach my $codcour (@Common::codcour_list_sorted)
	{
		my $semester = $Common::course_info{$codcour}{semester};
		if($current_semester != $semester)
		{
			$current_semester = $semester;
			$output_txt .= "\n\\subsection{$Common::config{dictionaries}{$lang}{semester_ordinal}{$semester} $Common::config{dictionaries}{$lang}{Semester}}\n";
		}
		$output_txt .= "\\subsubsection{$codcour. $Common::course_info{$codcour}{$lang}{course_name}}\n";
		my $nprofessors_for_this_course = 0;
		my $professor_list = "";
		foreach my $email (sort  { $Common::config{faculty}{$a}{priority} <=> $Common::config{faculty}{$b}{priority} 	}
						   keys %{ $Common::config{courses_i_could_teach}{$codcour}} )
		{
			my $number_of_courses_assigned = scalar keys %{$Common::config{faculty}{$email}{fields}{courses_assigned}};
			if( $number_of_courses_assigned == 0 )
			{	$professor_list .= "\t\\item $Common::config{faculty}{$email}{fields}{name} ($email) (\\textbf{***})\n";
				next;	
			}
			$professor_list .= "\t\\item $Common::config{faculty}{$email}{fields}{name} ($email)\n";
			$nprofessors_for_this_course++;
		}
		if($nprofessors_for_this_course == 0)
		{	$output_txt .= "$Common::config{dictionaries}{$lang}{ThereIsNoProfessorSkilledForThisCourse}\n";	}
		else
		{	$output_txt .= "\\begin{itemize}\n$professor_list\\end{itemize}\n";
		}
		$output_txt .= "\n";
	}
	my $out_file = Common::get_expanded_template("out-professor-by-course-file", $lang);
	Util::print_message("generate_professor_by_course: Generating ($out_file) OK");
	Util::write_file($out_file, $output_txt); 
}

# sub generate_tables_for_advance()
# {
# 	$Common::advances_dir = "$Common::html/$Common::area-$Common::institution-advances";
# 	mkdir("$Common::advances_dir");
# 	my $advances = "$Common::advances_dir/advances.html";
# 	open(OUT, ">$advances") or die "Unable to open $advances";
#
# 	for(my $semester=1; $semester <= $Common::config{n_semesters} ; $semester++)
# 	{
# 		print OUT "<hr>\n";
# 		print OUT "<table width=\"100\%\" border=\"0\" cellpadding=\"0\">\n";
# 		print OUT "<tr>\n";
# 		print OUT "	<td bgcolor=\"$table_color\" align=\"center\">\n";
# 		print OUT "	<h2><a name=\"A\"></a><B>$Common::config{dictionary}{semester_ordinal}{$semester} Semester</B>\n";
# 		print OUT "	</h2>\n";
# 		print OUT "	</td>\n";
# 		print OUT "</tr>\n";
# 		print OUT "</table>\n";
#
# 		my $this_sem_text = "<table width=\"100\%\" border=\"1\" cellpadding=\"1\">\n";
# 		$this_sem_text .= "<tr>\n";
# 		$this_sem_text .= "	<th align=\"left\">Cdigo</th>\n";
# 		$this_sem_text .= "	<th align=\"left\">Nombre</th>\n";
# 		$this_sem_text .= "	<th align=\"left\">HT</th>\n";
# 		$this_sem_text .= "	<th align=\"left\">HP</th>\n";
# 		$this_sem_text .= "	<th align=\"left\">HL</th>\n";
# 		$this_sem_text .= "	<th align=\"left\">Cr</th>\n";
# 		$this_sem_text .= "	<th align=\"left\">T</th>\n";
# 		$this_sem_text .= "	<th align=\"left\">Requisitos</th>\n";
# 		$this_sem_text .= "</tr>\n";
# 		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
# 		{
# 			$this_sem_text .= "<tr>\n";
# 			$this_sem_text .= "	<td>$codcour</td>\n";
# 			$this_sem_text .= "	<td>$Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name}</td>\n";
# 			$this_sem_text .= "	<td>$Common::course_info{$codcour}{th}</td>\n";
# 			$this_sem_text .= "	<td>$Common::course_info{$codcour}{ph}</td>\n";
# 			$this_sem_text .= "	<td>$Common::course_info{$codcour}{lh}</td>\n";
# 			$this_sem_text .= "	<td>$Common::course_info{$codcour}{cr}</td>\n";
# 			$this_sem_text .= "	<td>$Common::course_info{$codcour}{tipo}</td>\n";
# 			my @reqarray = split ",", $Common::course_info{$codcour}{fullrequisitos};
# 			my ($tmp, $sep) = ("", "");
# 			foreach my $req (@reqarray)
# 			{
# 				if(defined($Common::course_info{$req}))
# 				{
# 					$tmp .= "$sep$req($Common::course_info{$req}{semester}";
# 					$tmp .= "<sup>$Common::config{ordinal_postfix}{$Common::course_info{$req}{semester}}</sup>)\n";
# 					$sep = ",<br>";
# 				}
# 			}
# 			$this_sem_text .= "	<td>$tmp</td>\n";
# 			$this_sem_text .= "</tr>\n";
# 		}
# 		$this_sem_text .= "</table>\n\n";
# 		print OUT $this_sem_text;
# 	}
# 	close(OUT);
# }
#
# sub generate_courses_for_advance()
# {
# 	Common::printerror("Generando cursos para control de avances ...\n");
# 	my $html_base = Common::get_template("in-web-course-template.html-file");
# 	#print "$html_base !\n";
# 	open(IN, "<$html_base") or die "Unable to open $html_base";
# 	my $html_base_txt = join('', <IN>);
# 	#print "$html_base_txt";
# 	close(IN);
# 	for(my $semester=1; $semester <= $Common::config{n_semesters} ; $semester++)
# 	{
# 		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
# 		{
# 			print "Generando $codcour (Sem: $semester)     \r";
# 			my $out_text = $html_base_txt;
# 			my $html_file = "$Common::advances_dir/$codcour.html";
# 			open(OUT, ">$html_file") or die "Unable to open $html_file";
#
# 			my $unit_template = "";
# 			if($out_text =~ m/--BEGINUNIT--((?:.|\n)*)--ENDUNIT--/)
# 			{
# 				$unit_template = $1;
# 				$out_text =~ s/--BEGINUNIT--((?:.|\n)*)--ENDUNIT--/--UNITS--/g;
# 			}
# 			#$out_text =~ s/--INSTITUTION--/$Common::institution/g;
# 			$out_text =~ s/--CODCUR--/$codcour/g;
# 			$out_text =~ s/--CURSO--/$Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name}/g;
# 			$out_text =~ s/--TIPO--/$Common::course_info{$codcour}{tipo}/g;
# 			$out_text =~ s/--SEMESTRE--/$Common::course_info{$codcour}{semester}/g;
# 			$out_text =~ s/--CREDITOS--/$Common::course_info{$codcour}{cr}/g;
# 			$out_text =~ s/--HT--/$Common::course_info{$codcour}{th}/g;
# 			$out_text =~ s/--HP--/$Common::course_info{$codcour}{ph}/g;
# 			$out_text =~ s/--HL--/$Common::course_info{$codcour}{lh}/g;
#
# 			my @reqarray = split ",", $Common::course_info{$codcour}{fullrequisitos};
# 			my ($tmp, $sep) = ("", "");
# 			foreach my $req (@reqarray)
# 			{
# 				if(defined($Common::course_info{$req}))
# 				{
# 					$tmp .= "$sep$req. $Common::course_info{$req}{$Common::config{language_without_accents}}{course_name} ";
# 					$tmp .= "($Common::course_info{$req}{semester}";
# 					$tmp .= "<sup>";
# 					$tmp .= "$Common::config{ordinal_postfix}{$Common::course_info{$req}{semester}}";
# 					$tmp .= "</sup>)\n";
# 					$sep = ", ";
# 				}
# 			}
# 			if( $tmp eq "")
# 			{	$out_text =~ s/--PREREQUISITOS--/Ninguno/g; }
# 			else
# 			{	$out_text =~ s/--PREREQUISITOS--/$tmp/g; }
#
# 			my $all_units = "";
# 			my $i = 0;
# 			my $top_count = 0;
# 			my $obj_count = 0;
#
# 			for($i = 0; $i < $Common::course_info{$codcour}{n_units}; $i++)
# 			{
# 				my $this_unit = $unit_template;
# 				my $unit_title = "UNIDAD ".($i+1).": $Common::course_info{$codcour}{units}{unit_caption}[$i]";
# 				$this_unit =~ s/--UNIT--/$unit_title/g;
# 				$this_unit =~ s/--HOURS--/$Common::course_info{$codcour}{units}{hours}[$i]/g;
# 				#$this_unit =~ s/--BIB--/$Common::course_info{$codcour}{units}{bib_items}[$i]/g;
#
# 				# TOPICOS
# 				my $topicos   = "";
# 				my $top_tmp   = $Common::course_info{$codcour}{units}{topics}[$i];
# 				my @top_arr   = split("\n", $top_tmp);
# 				foreach my $this_top (@top_arr)
# 				{
# 					if($this_top =~ /\\item\s(.*)/g)
# 					{	$topicos .= "<INPUT type=\"checkbox\" name=\"Top$top_count\">$1<br>\n";
# 						$top_count++;
# 					}
# 				}
# 				$this_unit =~ s/--TOPICOS-DE-LA-UNIDAD--/$topicos/g;
#
# 				# OBJETIVOS
# 				my $objetivos = "";
# 				my $obj_tmp = $Common::course_info{$codcour}{units}{unitgoals}[$i];
# 				my @obj_arr   = split("\n", $obj_tmp);
# 				foreach my $this_obj (@obj_arr)
# 				{
# 					if($this_obj =~ /\\item\s(.*)/g)
# 					{	$objetivos .= "<INPUT type=\"checkbox\" name=\"Obj$obj_count\">$1<br>\n";
# 						$obj_count++;
# 					}
# 				}
# 				$this_unit =~ s/--OBJETIVOS-DE-LA-UNIDAD--/$objetivos/g;
# 				my $count = 0;
# 				($this_unit, $count) = Common::expand_macros($this_unit);
# 				$all_units .= $this_unit;
#
# 			}
# 			$out_text =~ s/--UNITS--/$all_units/g;
# # 			if($unit_body =~ m/\\begin{$tag}((?:.|\n)*?)\\end{$tag}/g)
# # 			{
# # 				$body = $1;
# # 				my @lines = split("\n",$body);
# # 				foreach my $line (@lines)
# # 				if($line =~ m/\\item\s*(.*)/g)
# # 				{	#my $itemtxt = $1;
# #
# # 				}
# # 			}
# 			#$Common::course_info{$codcour}{n_units}++;
# 			#push(@{$Common::course_info{$codcour}{units}{topics}, $topicos);
# 			#push(@{$Common::course_info{$codcour}{units}{unitgoals}, $objetivos);
# 			$out_text = Common::replace_accents($out_text);
# 			print OUT $out_text;
# 			close(OUT);
# 		}
# 	}
# 	print "\n";
# 	Common::printerror("End: Generating courses on the web\n");
# }
#
# sub generate_sql_for_new_courses()
# {
# 	#INSERT INTO weather (city, temp_lo, temp_hi, prcp, date)
# 	#     VALUES ('San Francisco', 43, 57, 0.0, '1994-11-29');
# 	print "Generando sql para nuevos cursos ...\n";
# 	my $sql_file = "$Common::out_sql_dir/insertcourses.sql";
# 	open(OUT, ">$sql_file") or die "Unable to open $sql_file ($@)";
# 	my $out_text = "";
# 	for(my $semester=1; $semester <= $Common::config{n_semesters} ; $semester++)
# 	{
# 		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
# 		{
# 			print "Sem :$semester, $codcour ...     \r";
# 			$out_text .= "-- Inicio: $codcour (sem: $semester)\n";
# 			$out_text .= "select create_course('$codcour', '$Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name}');\n";
#
# 			my $ins_plan_course = "select create_course_plan(";
# 			$ins_plan_course   .= "'ht', 'hp', 'hl', 'cr', 'type', 'semester')\n";
# 			$ins_plan_course   .= "VALUES(--HT--, --HP--, --HL--, ";
# 			$ins_plan_course   .= "--CREDITOS--, '--TIPO--', --SEMESTRE--);\n";
#
# 			#$out_text =~ s/--INSTITUTION--/$Common::institution/g;
# 			#$out_text =~ s/--CODCUR--/$codcour/g;
# 			#$out_text =~ s/--CURSO--/$Common::course_info{$codcour}{$Common::config{language_without_accents}}{course_name}/g;
# 			$ins_plan_course =~ s/--HT--/$Common::course_info{$codcour}{th}/g;
# 			$ins_plan_course =~ s/--HP--/$Common::course_info{$codcour}{ph}/g;
# 			$ins_plan_course =~ s/--HL--/$Common::course_info{$codcour}{lh}/g;
# 			$ins_plan_course =~ s/--CREDITOS--/$Common::course_info{$codcour}{cr}/g;
# 			$ins_plan_course =~ s/--TIPO--/$Common::course_info{$codcour}{short_type}/g;
# 			$ins_plan_course =~ s/--SEMESTRE--/$Common::course_info{$codcour}{semester}/g;
#
# 			$out_text .= $ins_plan_course;
#
# # 			my @reqarray = split ",", $Common::course_info{$codcour}{fullrequisitos};
# # 			my ($tmp, $sep) = ("", "");
# # 			foreach my $req (@reqarray)
# # 			{
# # 				if(defined($Common::course_info{$req}))
# # 				{
# # 					$tmp .= "$sep$req. $Common::course_info{$req}{$Common::config{language_without_accents}}{course_name} ";
# # 					$tmp .= "($Common::course_info{$req}{semester}";
# # 					$tmp .= "<sup>";
# # 					$tmp .= "$Common::config{ordinal_postfix}{$Common::course_info{$req}{semester}}";
# # 					$tmp .= "</sup>)\n";
# # 					$sep = ", ";
# # 				}
# # 			}
# # 			if( $tmp eq "")
# # 			{	$out_text =~ s/--PREREQUISITOS--/Ninguno/g; }
# # 			else
# # 			{	$out_text =~ s/--PREREQUISITOS--/$tmp/g; }
# #
# # 			my $all_units = "";
# # 			my $i = 0;
# # 			my $top_count = 0;
# # 			my $obj_count = 0;
# #
# # 			for($i = 0; $i < $Common::course_info{$codcour}{n_units}; $i++)
# # 			{
# # 				my $this_unit = $unit_template;
# # 				my $unit_title = "UNIDAD ".($i+1).": $Common::course_info{$codcour}{units}{unit_caption}[$i]";
# # 				$this_unit =~ s/--UNIT--/$unit_title/g;
# # 				$this_unit =~ s/--HOURS--/$Common::course_info{$codcour}{units}{hours}[$i]/g;
# # 				#$this_unit =~ s/--BIB--/$Common::course_info{$codcour}{units}{bib_items}[$i]/g;
# #
# # 				# TOPICOS
# # 				my $topicos   = "";
# # 				my $top_tmp   = $Common::course_info{$codcour}{units}{topics}[$i];
# # 				my @top_arr   = split("\n", $top_tmp);
# # 				foreach my $this_top (@top_arr)
# # 				{
# # 					if($this_top =~ /\\item\s(.*)/g)
# # 					{	$topicos .= "<INPUT type=\"checkbox\" name=\"Top$top_count\">$1<br>\n";
# # 						$top_count++;
# # 					}
# # 				}
# # 				$this_unit =~ s/--TOPICOS-DE-LA-UNIDAD--/$topicos/g;
# #
# # 				# OBJETIVOS
# # 				my $objetivos = "";
# # 				my $obj_tmp = $Common::course_info{$codcour}{units}{unitgoals}[$i];
# # 				my @obj_arr   = split("\n", $obj_tmp);
# # 				foreach my $this_obj (@obj_arr)
# # 				{
# # 					if($this_obj =~ /\\item\s(.*)/g)
# # 					{	$objetivos .= "<INPUT type=\"checkbox\" name=\"Obj$obj_count\">$1<br>\n";
# # 						$obj_count++;
# # 					}
# # 				}
# # 				$this_unit =~ s/--OBJETIVOS-DE-LA-UNIDAD--/$objetivos/g;
# # 				my $count = 0;
# # 				($this_unit, $count) = Common::expand_macros($this_unit);
# # 				$all_units .= $this_unit;
# #
# # 			}
# # 			$out_text =~ s/--UNITS--/$all_units/g;
# # # 			if($unit_body =~ m/\\begin{$tag}((?:.|\n)*?)\\end{$tag}/g)
# # # 			{
# # # 				$body = $1;
# # # 				my @lines = split("\n",$body);
# # # 				foreach my $line (@lines)
# # # 				if($line =~ m/\\item\s*(.*)/g)
# # # 				{	#my $itemtxt = $1;
# # #
# # # 				}
# # # 			}
# # 			#$Common::course_info{$codcour}{n_units}++;
# # 			#push(@{$Common::course_info{$codcour}{units}{topics}, $topicos);
# # 			#push(@{$Common::course_info{$codcour}{units}{unitgoals}, $objetivos);
# # 			$out_text = Common::replace_accents($out_text);
# 			$out_text .= "\n";
# 		}
# 	}
# 	print OUT $out_text;
# 	close(OUT);
# 	print "Fin de generacion de cursos en la web\n";
# }
#
# sub generate_course_into_the_web()
# {
# 	for(my $semester=1; $semester <= $Common::config{n_semesters} ; $semester++)
# 	{
# 		foreach my $codcour (@{$Common::courses_by_semester{$semester}})
# 		{
# 			my $file = "$Common::silabos_dir/$codcour-sumilla.tex";
# 		}
# 	}
# }

1;

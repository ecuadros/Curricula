package Common;
use Carp::Assert;
use Data::Dumper;
use Clone 'clone';
use Lib::Util;
use Cwd;
use strict;

our $command     = "";
our $institution = "";
our $filter      = "";
our $area	 = "";
our $version	 = "";
our $discipline  = "";

our $institutions_info_root	= "";
our $inst_list_file 		= "";
our %list_of_areas		= ();
our %list_of_courses_per_area   = ();
our %config 			= ();
our %general_info		= ();
our %dictionary			= ();
our %path_map			= ();
our %data			= ();
our %inst_list			= ();
our %map_hours_unit_by_course   = ();
our %ku_info			= ();
our %acc_hours_by_course	= ();
our %acc_hours_by_unit		= ();

our $prefix_area 		= "";
our $only_macros_file		= "";
our $compileall_file    	= "";

# our @macro_files 		= ();
our %course_info          	= ();
our @codcour_list_sorted;
our %courses_by_semester 	= ();
our %counts              	= ();
our %antialias_info 	 	= ();
our %list_of_courses_per_axe	= ();

my %Numbers2Text 		= (0 => "OH",   1 => "ONE", 2 => "TWO", 3 => "THREE", 4 => "FOUR",
				   5 => "FIVE", 6 => "SIX", 7 => "SEVEN", 8 => "EIGHT", 9 => "NINE"
				  );
our %template_files = (	"Syllabus" 		=> "in-syllabus-template-file"
# 			"DeliveryControl" 	=> "in-syllabus-delivery-control-file",
		      );

# flush stdout with every print -- gives better feedback during
# long computations
$| = 1;

# ok
sub replace_accents($)
{
	my ($text) = (@_);
	$text =~ s/\\'A/Á/g;		$text =~ s/\\'a/á/g;		$text =~ s/\\'\{a\}/á/g;
	$text =~ s/\\'E/É/g;		$text =~ s/\\'e/é/g;		$text =~ s/\\'\{e\}/é/g;
	$text =~ s/\\'I/Í/g;		$text =~ s/\\'i/í/g;		$text =~ s/\\'\{i\}/í/g;
	$text =~ s/\\'O/Ó/g;		$text =~ s/\\'o/ó/g;		$text =~ s/\\'\{o\}/ó/g;
	$text =~ s/\\'U/U/g;		$text =~ s/\\'u/ú/g;		$text =~ s/\\'\{u\}/ú/g;
	$text =~ s/\\~N/Ñ/g;		$text =~ s/\\~n/ñ/g;		$text =~ s/\\~\{n\}/n/g;
	return $text;
}

sub replace_latex_babel_to_latex_standard($)
{
	my ($text) = (@_);
	$text =~ s/Á/\\'A/g;		$text =~ s/á/\\'a/g;
	$text =~ s/É/\\'E/g;		$text =~ s/é/\\'e/g;
	$text =~ s/Í/\\'\{I\}/g;	$text =~ s/í/\\'\{i\}/g;
	$text =~ s/Ó/\\'O/g;		$text =~ s/ó/\\'o/g;
	$text =~ s/Ú/\\'U/g;		$text =~ s/ú/\\'u/g;		$text =~ s/ü/\\"u/g;
	$text =~ s/Ñ/\\~N/g;		$text =~ s/ñ/\\~n/g;
	return $text;
}

# ok
sub no_accents($)
{
	my ($text) = (@_);
	$text =~ s/Á/A/g;		$text =~ s/á/a/g;
	$text =~ s/É/E/g;		$text =~ s/é/e/g;
	$text =~ s/Í/I/g;		$text =~ s/í/i/g;
	$text =~ s/Ó/O/g;		$text =~ s/ó/o/g;
	$text =~ s/Ú/U/g;		$text =~ s/ú/u/g;
	$text =~ s/Ñ/N/g;		$text =~ s/ñ/n/g;
	return $text;
}

# http://www.htmlhelp.com/reference/html40/entities/latin1.html
# http://symbolcodes.tlt.psu.edu/web/codehtml.html
sub special_chars_to_html($)
{
	my ($text) = (@_);
	$text =~ s/Á/&Aacute;/g;		$text =~ s/á/&aacute;/g;
	$text =~ s/É/&Eacute;/g;		$text =~ s/é/&eacute;/g;
	$text =~ s/Í/&Iacute;/g;		$text =~ s/í/&iacute;/g;
	$text =~ s/Ó/&Oacute;/g;		$text =~ s/ó/&oacute;/g;
	$text =~ s/Ú/&Uacute;/g;		$text =~ s/ú/&uacute;/g;
	$text =~ s/Ñ/&Ntilde;/g;		$text =~ s/ñ/&ntilde;/g;
	return $text;
}

sub replace_special_chars($)
{
	my ($text) = (@_);
	$text =~ s/\\/\\\\/g;
	$text =~ s/\./\\./g;
	$text =~ s/\&/\\&/g;
	$text =~ s/\(/\\(/g;	$text =~ s/\)/\\)/g;
	$text =~ s/\[/\\[/g;	$text =~ s/\]/\\]/g;
	$text =~ s/\{/\\{/g;	$text =~ s/\}/\\}/g;
	$text =~ s/\+/\\\+/g;
	$text =~ s/\$/\\\$/g;
	$text =~ s/\^/\\\^/g;
	#$text =~ s/\-/\\\-/g;
	$text =~ s/\?/\\\?/g;
	$text =~ s/\*/\\\*/g;
        $text =~ s/\|/\\\|/g;
	return $text;
}

sub GetInCountryBaseDir($)
{
    my ($country) =  (@_);
    return $path_map{InDir}."/country/".filter_non_valid_chars($country);
}

sub GetOutCountryBaseDir($)
{
    my ($country) =  (@_);
    return $path_map{InDir}."/country/".filter_non_valid_chars($country);
}

sub GetInstDir($$$$)
{
	my ($country, $discipline, $area, $inst) = (@_);
	return GetInCountryBaseDir($country)."/$discipline/$area/$inst";
}

sub GetInstitutionInfo($$$$)
{
	my ($country, $discipline, $area, $inst) = (@_);
	return GetInstDir($country, $discipline, $area, $inst)."/institution-info.tex";
}

sub filter_non_valid_chars($)
{
        my ($text) = (@_);
        $text = no_accents($text);
        $text =~ s/ //g;
        return $text;
}

# ok
sub get_alias($)
{
	my ($codcour) = (@_);
# 	if(defined($course_info{$codcour}))
# 	{
	    if( defined($course_info{$codcour}{alias}) )
	    {	return $course_info{$codcour}{alias};		}
# 	}
	else{	return "";	}
}

sub detect_codcour($)
{
	my ($cc) = (@_);
	my $codcour = $cc;
	if(defined($antialias_info{$cc}))
	{	$codcour = $antialias_info{$cc}		}
	if( not defined($course_info{$codcour}) )
	{     Util::print_error("codcour \"$codcour\" does not exist ... ");		}
	return $codcour;
}

# ok
sub get_label($)
{
	my ($codcour) = (@_);
    if( defined($config{map_file_to_course}{$codcour}) )
    {   $codcour = $config{map_file_to_course}{$codcour};   }

    if(defined($antialias_info{$codcour})) #ok
	{	$codcour = $antialias_info{$codcour};		}
	$codcour = get_alias($codcour); # ok
	return $codcour; #ok
}

# ok
sub get_prefix($)
{
	my ($codcour) = (@_);
# 	print "x$codcour, alias=$course_info{$codcour}{alias}\n";
	$codcour = $course_info{$codcour}{alias};
	if($codcour =~ m/(..).*/)
	{	return $1;	}
	return "";
}

sub get_syllabi_language_icons($$)
{
        my ($prev_tex, $codcour) = (@_);
	my $link  = "";
	my $sep   = "";
	foreach my $lang (@{$Common::config{SyllabusLangsList}})
	{
	    my $lang_prefix = $Common::config{dictionaries}{$lang}{lang_prefix};
	    $link .= $prev_tex;
	    $link .= "$sep<a href=\"syllabi/$codcour-$lang_prefix.pdf\">";
	    $link .= "<img alt=\"$codcour-$lang_prefix\" src=\"./figs/pdf.jpeg\" style=\"border: 0px solid ; width: 16px; height: 16px;\">";
	    $link .= "<img alt=\"$codcour-$lang_prefix\" src=\"./figs/$lang_prefix.png\" style=\"border: 0px solid ; width: 16px; height: 16px;\">";
	    $link .= "</a>\n";
	    $sep = ", ";
	}
    return $link;
}

sub get_language_icon($)
{
        my ($lang) = (@_);
	my $lang_prefix = $Common::config{dictionaries}{$lang}{lang_prefix};
	my $link  = "<img src=\"./figs/pdf.jpeg\" style=\"border: 0px solid ; width: 16px; height: 16px;\">";
	   $link .= "<img src=\"./figs/$lang_prefix.png\" style=\"border: 0px solid ; width: 16px; height: 16px;\">";
        return $link;
}

sub get_small_icon($$)
{
        my ($icon, $alt) = (@_);
	my $pdflink .= "\\latexhtml{}{%\n";
	$pdflink    .= "\t\\begin{htmlonly}\n";
	$pdflink    .= "\t\t\\begin{rawhtml}\n";
	$pdflink    .=  "\t\t\t<img alt=\"$alt\" src=\"./figs/$icon\" style=\"border: 0px solid ; width: 16px; height: 16px;\">\n";
	$pdflink    .=  "\t\t\\end{rawhtml}\n";
	$pdflink    .=  "\t\\end{htmlonly}\n";
	$pdflink    .= "}";
        return $pdflink;
}

sub format_semester_label($)
{
      my ($semester) = (@_);
      if($semester)
      {		return "$semester\$^{$config{dictionary}{ordinal_postfix}{$semester}}\$";	}
      else{	Util::halt("");		}
      return "";
}

sub get_course_link($$)
{
	my ($codcour, $lang) = (@_);
	#print $codcour;
	if($codcour eq "")
	{	assert(0);	}

	my $course_full_label	= "$codcour. $course_info{$codcour}{course_name}{$lang}";
	my $course_link	   = "\\htmlref{$course_full_label}{sec:$codcour}~";
	   $course_link   .= "($course_info{$codcour}{semester}\$^{$config{dictionaries}{$lang}{ordinal_postfix}{$course_info{$codcour}{semester}}}\$ $config{dictionaries}{$lang}{Sem}-$config{dictionaries}{$lang}{Pag}~\\pageref{sec:$codcour})";
	return $course_link;
}

sub GetCourseHyperLink($$)
{
    my ($codcour, $link) = (@_);
#     my $link = Common::get_template("LinkToCurriculaBase");
    my $semester = $Common::course_info{$codcour}{semester};
    my $SemesterInfo = "$Common::course_info{$codcour}{semester}$Common::config{dictionary}{ordinal_postfix}{$semester} $Common::config{dictionary}{Sem}";
    my $hyperlink = "<li><a href=\"$link\">$codcour. $course_info{$codcour}{course_name}{$config{language_without_accents}} ($SemesterInfo)</a></li>\n";
    return $hyperlink;
}

sub InsertSeparator($)
{
    my ($input) = (@_);
    my $output  = "|";
    my $count = 0;
    while($input =~ m/([c|l|r|X|p])/g)
    {
        my $c    = $1;
        if($c eq "p")
        {       if($input =~ m/({.*?})/g)
                {   $output .= "$c$1|";       }
        }
        else
        {   $output .= "$c|";       }
        #Util::print_message("$input->$output");
        $count++;
        #exit if($count == 20);
    }
    return $output;
}

sub read_pages()
{
        my $filename    = Common::get_template("file_for_page_numbers");
        %{$config{pages_map}}   = ();

	if(-e $filename)
        {
	    my $file_txt    = Util::read_file($filename);
	    # \newlabel{sec:FG102}{{4}{133}{Contenido detallado por curso\relax }{section*.69}{}}
	    while($file_txt =~ m/\\newlabel\{(.*?)\}\{\{(.*?)\{(.*?)\}/g)
	    {
		    my ($label, $ref, $page) = ($1, $2, $3);
		    $config{pages_map}{$label} = $page;
		    # Util::print_message("pages_map{$label} = $page");
	    }
	}
        #return %pages_map;
}

sub read_outcomes_labels()
{
        my $filename     = Common::get_template("file_for_page_numbers");
        $config{outcomes_map} = ();

	if(-e $filename)
        {
	    my $file_txt     = Util::read_file($filename);
	    while($file_txt =~ m/\\newlabel\{out:Outcome(.*?)\}\{\{(.*?)\}/g)
	    {
		    my ($outcome, $letter) = ($1, $2);
		    if($outcome eq "\\IeC {\\~n}"){	$outcome = "ñ";		}
		    $config{outcomes_map}{$outcome} = $letter;
		    if( $letter =~ m/\\.n/)
		    {       $config{outcomes_map}{$outcome} = "ñ";          }
	    }
	}
}

sub read_pagerefs()
{
    #%{$config{pages_map}}     =
    Common::read_pages();
    #%{$config{outcomes_map}}  =
    Common::read_outcomes_labels();
    #print Dumper(%{$Common::config{outcomes_map}}); exit;
    Util::check_point("read_pagerefs");
}

# ok
sub sem_label($)
{
	my ($sem) = (@_);
# 	print "$sem\n";
	my $rpta  = "\"$sem$config{dictionary}{ordinal_postfix}{$sem} $config{dictionary}{Sem} ";
	$rpta    .= "($config{credits_this_semester}{$sem} $config{dictionary}{cr})\"";
	return  $rpta;
}

sub set_version($)
{
	my ($version) = (@_);
	$config{graph_version} = $version;
	if($config{graph_version} == 1)
	{
	      $config{sep} = "|";
	      $config{hline} = "\\hline";
	}
	elsif($config{graph_version} == 2)
	{
	      $config{sep} = "";
	      $config{hline} = "";
	}
	else
	{	Util::halt("Version \"$version\" is not supported ...");	}
}

sub set_global_variables()
{
	$config{bibstyle}   = "apalike";
	$config{InScriptsDir}	= "$config{in}/scripts";

	system("mkdir -p $config{OutputInstDir}");

	$config{OutputTexDir} 	= "$config{OutputInstDir}/tex";
	system("mkdir -p $config{OutputInstDir}/syllabi");

	#                             ./Curricula.out/html/Peru/CS-UTEC/Plan 2018
	$config{OutputHtmlDir} 	   = "$config{OutHtmlBase}/$config{country_without_accents}/$config{area}-$config{institution}/Plan$config{Plan}";
    $config{OutputHtmlFigsDir} = "$config{OutputHtmlDir}/figs";
    system("mkdir -p $config{OutputHtmlFigsDir}");

	my $cwd = getcwd();
	my $cmd = "ln -f -s $cwd/$config{OutputHtmlDir} $config{OutputInstDir}/html";
# 	Util::print_message($cmd);
    system($cmd);

	$config{OutputPrereqDir} 	= "$config{OutputTexDir}/prereq";
	system("mkdir -p $config{OutputPrereqDir}");

	$config{OutputDotDir} 	= "$config{OutputInstDir}/dot";
	system("mkdir -p $config{OutputDotDir}");

	$config{OutputBinDir} 		= "$config{OutputInstDir}/bin";
	system("mkdir -p $config{OutputBinDir}");

	$config{OutputSqlDir}        		= "$config{OutputInstDir}/gen-sql";
	system("mkdir -p $config{OutputSqlDir}");

	$config{OutputMain4FigDir}   	= "$config{OutputInstDir}/tex/main4figs";
	system("mkdir -p $config{OutputMain4FigDir}");

	$config{OutputFigDir}         = "$config{OutputInstDir}/fig";
	system("mkdir -p $config{OutputFigDir}");

	$config{OutputAdvancesDir}   		= "$config{OutputInstDir}/advances";
	system("mkdir -p $config{OutputAdvancesDir}");

# 	$config{OutputPrereqDir}      	= "$config{OutputInstDir}/pre-prerequisites";
# 	system("mkdir -p $config{OutputPrereqDir}");

	$config{OutputScriptsDir}	= "$config{OutputInstDir}/scripts";
	system("mkdir -p $config{OutputScriptsDir}");

	$config{InLangBaseDir}	 	= "$config{in}/lang";
	$config{InLangDir}	 	= "$config{InLangBaseDir}/$config{language_without_accents}";
	#$config{in_html_dir}      	= $config{InLangDir}."/templates";

	$config{InPeopleDir}		= $config{in}."/people";
	system("mkdir -p $config{out}/pdfs");
	Util::check_point("set_global_variables");
}

# OK
sub set_initial_paths()
{
	Util::precondition("set_global_variables");
	assert(defined($config{language_without_accents}) and defined($config{discipline}));

	$path_map{"curricula-main"}			= "curricula-main.tex";
	$path_map{"unified-main-file"}			= "unified-curricula-main.tex";
        $path_map{"file_for_page_numbers"}		= "curricula-main.aux";

	$path_map{"country"}				= $config{country};
	$path_map{"country_without_accents"}		= $config{country_without_accents};
	$path_map{"language"}				= $config{language};
	$path_map{"language_without_accents"}		= $config{language_without_accents};

################################################################################################################
# InputsDirs
	$path_map{InLangDir}				= $config{InLangDir};
	$path_map{InLangBaseDir}			= $config{InLangBaseDir};
	$path_map{InAllTexDir}				= $path_map{InDir}."/All.tex";
	$path_map{InTexDir}				= $path_map{InLangDir}."/$config{area}.tex";
	$path_map{InStyDir}				= $path_map{InLangDir}."/$config{area}.sty";
	$path_map{InStyAllDir}				= $path_map{InDir}."/All.sty";
	$path_map{InSyllabiContainerDir}		= $path_map{InLangDir}."/cycle/$config{Semester}/Syllabi";

        $path_map{InFigDir}                             = $path_map{InLangDir}."/figs";
	$path_map{InOthersDir}				= $path_map{InLangDir}."/$config{area}.others";
	$path_map{InHtmlDir}				= $path_map{InLangDir}."/All.html";
	$path_map{InTexAllDir}				= $path_map{InLangDir}."/All.tex";
	$path_map{InDisciplineDir}			= $path_map{InLangDir}."/$config{discipline}.tex";
	$path_map{InScriptsDir}				= "./scripts";
	$path_map{InCountryDir}				= GetInCountryBaseDir($path_map{country_without_accents});
	$path_map{InCountryTexDir}			= GetInCountryBaseDir($path_map{country_without_accents})."/$config{discipline}/$config{area}/$config{area}.tex";
	$path_map{InInstDir}				= $path_map{InCountryDir}."/$config{discipline}/$config{area}/$config{institution}";
	$path_map{InInstUCSPDir}			= GetInstDir("Peru", "Computing", "CS", "UCSP");

	$path_map{InEquivDir}				= $path_map{InInstDir}."/equivalences";
	$path_map{InLogosDir}				= $path_map{InCountryDir}."/logos";
	$path_map{InTemplatesDot}			= $path_map{InCountryDir}."/dot";
	$path_map{InPeopleDir}				= $config{InPeopleDir};
	$path_map{InFacultyPhotosDir}			= $path_map{InInstDir}."/photos";
	$path_map{InFacultyIconsDir}			= $path_map{InDir}."/html";

#############################################################################################################################
# OutputsDirs
        $path_map{OutHtmlBase}				= "$config{out}/html";
        $path_map{OutputInstDir}			= $config{OutputInstDir};
        $path_map{OutputTexDir}				= $config{OutputTexDir}; #Plan$config{Plan}
        $path_map{OutputBinDir}				= $config{OutputBinDir};
        $path_map{OutputLogDir}				= $config{out}."/log";
        $path_map{OutputHtmlDir}			= $config{OutputHtmlDir};
        $path_map{OutputHtmlFigsDir}		= $config{OutputHtmlFigsDir};
        $path_map{OutputHtmlSyllabiDir}		= $config{OutputHtmlDir}."/syllabi";
        $path_map{OutputFigDir}             = $config{OutputFigDir};
        $path_map{OutputScriptsDir}			= $config{OutputScriptsDir};
        $path_map{OutputPrereqDir}          = $config{OutputTexDir}."/prereq";
        $path_map{OutputDotDir}             = $config{OutputDotDir};
        $path_map{OutputMain4FigDir}		= $config{OutputMain4FigDir};
        $path_map{OutputSyllabiDir}			= $config{OutputInstDir}."/syllabi";
		$path_map{OutputFullSyllabiDir}		= $config{OutputInstDir}."/full-syllabi";
        $path_map{OutputFacultyDir}			= $config{OutputInstDir}."/faculty";
        $path_map{OutputFacultyFigDir}		= $path_map{OutputFacultyDir}."/fig";			system("mkdir -p $path_map{OutputFacultyFigDir}");
        $path_map{OutputFacultyIconDir}		= $path_map{OutputFacultyDir}."/icon";			system("mkdir -p $path_map{OutputFacultyIconDir}");
        $path_map{LinkToCurriculaBase}		= $config{LinkToCurriculaBase};

################################################################################################################################33
# Input and Output files

        # People Files

        # Tex files
        $path_map{"out-current-institution-file"}	= $path_map{OutputInstDir}."/tex/current-institution.tex";
        $path_map{"preamble0-file"}                  = $path_map{InAllTexDir}."/preamble0.tex";
        $path_map{"list-of-courses"}		   	= $path_map{InTexDir}."/$area$config{CurriculaVersion}-dependencies.tex";

        $path_map{"in-acronyms-base-file"}		= $path_map{InDisciplineDir}."/$config{discipline}-acronyms.tex";
        $path_map{"out-acronym-file"}			= $path_map{OutputTexDir}."/acronyms.tex";
        $path_map{"out-ncredits-file"}                  = $path_map{OutputTexDir}."/ncredits.tex";
        $path_map{"out-nsemesters-file"}                = $path_map{OutputTexDir}."/nsemesters.tex";


        $path_map{"in-outcomes-macros-file"}		= $path_map{InLangBaseDir}."/<LANG>/$config{area}.tex/outcomes-macros.tex";
        $path_map{"in-bok-file"}			= $path_map{InTexDir}."/bok.tex";
        $path_map{"in-bok-macros-file"}			= $path_map{InLangBaseDir}."/<LANG>/$config{area}.sty/bok-macros.sty";
        $path_map{"in-bok-macros-V0-file"}		= $path_map{InLangBaseDir}."/<LANG>/$config{area}.sty/bok-macros-V0.sty";

        $path_map{"in-LU-file"}				= $path_map{InTexDir}."/LU.tex";

        $path_map{"out-bok-index-file"}			= $path_map{OutputTexDir}."/BodyOfKnowledge-Index.tex";
        $path_map{"out-bok-body-file"}			= $path_map{OutputTexDir}."/BodyOfKnowledge-Body.tex";
        $path_map{"in-macros-order-file"}		= $path_map{InOthersDir}."/macros-order.txt";

        $path_map{"in-main-to-gen-fig"}			= $path_map{InTexAllDir}."/main-to-gen-fig.tex";

        $path_map{"out-tables-foreach-semester-file"}	= $path_map{OutputTexDir}."/tables-by-semester.tex";
        $path_map{"out-distribution-area-by-semester-file"}= $path_map{OutputTexDir}."/distribution-area-by-semester.tex";
        $path_map{"out-distribution-of-credits-by-area-by-semester-file"}= $path_map{OutputTexDir}."/distribution-credits-by-area-by-semester.tex";


        $path_map{"out-pie-credits-file"}		= $path_map{OutputTexDir}."/pie-credits.tex";
        $path_map{"out-pie-hours-file"}			= $path_map{OutputTexDir}."/pie-hours.tex";
        $path_map{"out-pie-by-levels-file"}		= $path_map{OutputTexDir}."/pie-by-levels.tex";

        $path_map{"out-list-of-courses-per-area-file"}	= $path_map{OutputTexDir}."/list-of-courses-per-area.tex";
        $path_map{"out-comparing-with-standards-file"}	= $path_map{OutputTexDir}."/comparing-with-standards.tex";
        $path_map{"in-all-outcomes-by-course-poster"}	= $path_map{OutputTexDir}."/all-outcomes-by-course-poster.tex";
        $path_map{"out-list-of-outcomes"}		= $path_map{OutputTexDir}."/list-of-outcomes.tex";
        $path_map{"list-of-courses-by-outcome"}		= $path_map{OutputTexDir}."/courses-by-outcome.tex";

        $path_map{"out-list-of-syllabi-include-file"}   = $path_map{OutputTexDir}."/list-of-syllabi.tex";
        $path_map{"out-laboratories-by-course-file"}	= $path_map{OutputTexDir}."/laboratories-by-course.tex";
        $path_map{"out-equivalences-file"}		= $path_map{OutputTexDir}."/equivalences.tex";

        $path_map{"in-Book-of-Syllabi-main-file"}	= $path_map{InTexAllDir}."/BookOfSyllabi.tex";
        $path_map{"out-Book-of-Syllabi-main-file"}		= $path_map{OutputTexDir}."/BookOfSyllabi-<LANG>.tex";
        $path_map{"in-Book-of-Syllabi-face-file"}	= $path_map{InTexAllDir}."/Book-Face.tex";
        $path_map{"out-Syllabi-includelist-file"}	= $path_map{OutputTexDir}."/pdf-syllabi-includelist-<LANG>.tex";

        $path_map{"in-Book-of-Syllabi-delivery-control-file"}		= $path_map{InTexAllDir}."/BookOfDeliveryControl.tex";
        $path_map{"in-Book-of-Syllabi-delivery-control-face-file"}	= $path_map{InTexAllDir}."/Book-Face.tex";

        $path_map{"in-Book-of-Descriptions-main-file"}	= $path_map{InTexAllDir}."/BookOfDescriptions.tex";
        $path_map{"out-Book-of-Descriptions-main-file"}	= $path_map{OutputTexDir}."/BookOfDescriptions-<LANG>.tex";
        $path_map{"in-Book-of-Descriptions-face-file"}	= $path_map{InTexAllDir}."/Book-Face.tex";
        $path_map{"out-Descriptions-includelist-file"}	= $path_map{OutputTexDir}."/short-descriptions-<LANG>.tex";

        $path_map{"in-Book-of-Bibliography-main-file"}	= $path_map{InTexAllDir}."/BookOfBibliography.tex";
        $path_map{"out-Book-of-Bibliography-main-file"}	= $path_map{OutputTexDir}."/BookOfBibliography-<LANG>.tex";
        $path_map{"in-Book-of-Bibliography-face-file"}	= $path_map{InTexAllDir}."/Book-Face.tex";
        $path_map{"out-Bibliography-includelist-file"}	= $path_map{OutputTexDir}."/bibliography-list-<LANG>.tex";

        $path_map{"in-Book-of-units-by-course-main-file"}= $path_map{InTexAllDir}."/BookOfUnitsByCourse.tex";
        $path_map{"in-Book-of-units-by-course-face-file"}= $path_map{InTexAllDir}."/Book-Face.tex";
        $path_map{"out-Syllabi-delivery-control-includelist-file"}= $path_map{OutputTexDir}."/pdf-syllabi-delivery-control-includelist.tex";

        $path_map{"in-pdf-icon-file"}			= $path_map{InFigDir}."/pdf.jpeg";

        $path_map{"out-list-of-unit-by-course-file"}	= $path_map{OutputTexDir}."/list-of-units-by-course.tex";

        $path_map{"in-description-foreach-area-file"}   = $path_map{InTexDir}."/description-foreach-area.tex";
        $path_map{"out-description-foreach-area-file"}  = $path_map{OutputTexDir}."/area-description.tex";

        $path_map{"in-description-foreach-prefix-file"}   = $path_map{InTexDir}."/description-foreach-prefix.tex";
        $path_map{"out-description-foreach-prefix-file"}  = $path_map{OutputTexDir}."/prefix-description.tex";

        $path_map{"in-sumilla-template-file"}		= $path_map{InInstDir}."/sumilla-template.tex";
        $path_map{"in-syllabus-template-file"}		= $path_map{InInstDir}."/syllabus-template.tex";
        $path_map{"in-syllabus-delivery-control-file"}	= $path_map{InInstDir}."/syllabus-delivery-control.tex";
        $path_map{"in-additional-institution-info-file"}= $path_map{InInstDir}."/extra/additional-info $config{Semester}.txt";
        $path_map{"in-distribution-dir"}		= $path_map{InInstDir}."/cycle/$config{Semester}/Plan$config{Plan}";
        $path_map{"in-this-semester-dir"}		= $path_map{InInstDir}."/cycle/$config{Semester}/Plan$config{Plan}";
        $path_map{"in-distribution-file"}		= $path_map{"in-distribution-dir"}."/distribution.txt";
        $path_map{"in-this-semester-evaluation-dir"}	= $path_map{"in-this-semester-dir"}."/evaluation";
        $path_map{"in-specific-evaluation-file"}	= $path_map{"in-distribution-dir"}."/Specific-Evaluation.tex";
        $path_map{"out-only-macros-file"}		= $path_map{OutputTexDir}."/macros-only.tex";

        $path_map{"faculty-file"}			= $path_map{InInstDir}."/cycle/$config{Semester}/faculty.txt";

        $path_map{"faculty-template.html"}		= $path_map{InFacultyIconsDir}."/faculty.html";
        $path_map{"NoFace-file"}			= $path_map{InFacultyIconsDir}."/noface.gif";

        $path_map{"faculty-general-output-html"}	= $path_map{OutputFacultyDir}."/faculty.html";
        $path_map{"in-replacements-file"}		= $path_map{InStyDir}."/replacements.txt";

        $path_map{"output-curricula-html-file"}		= "$path_map{OutputHtmlDir}/Curricula_$config{area}_$config{institution}.html";
        $path_map{"output-index-html-file"}		= "$path_map{OutputHtmlDir}/index.html";

        # Batch files
        $path_map{"out-compileall-file"}		= "compileall";
        $path_map{"in-compile1institucion-base-file"}	= $path_map{InDir}."/base-scripts/compile1institucion.sh";
        $path_map{"out-compile1institucion-file"}  	= $path_map{OutputScriptsDir}."/compile1institucion.sh";
        $path_map{"in-gen-html-1institution-base-file"}	= $path_map{InDir}."/base-scripts/gen-html-1institution.sh";
        $path_map{"out-gen-html-1institution-file"} 	= $path_map{OutputScriptsDir}."/gen-html-1institution.sh";
        $path_map{"in-gen-eps-files-base-file"}		= $path_map{InDir}."/base-scripts/gen-eps-files.sh";
        $path_map{"out-gen-eps-files-file"} 		= $path_map{OutputScriptsDir}."/gen-eps-files.sh";
        $path_map{"in-gen-graph-base-file"}		= $path_map{InDir}."/base-scripts/gen-graph.sh";
        $path_map{"out-gen-graph-file"} 		= $path_map{OutputScriptsDir}."/gen-graph.sh";
        $path_map{"in-gen-book-base-file"}		= $path_map{InDir}."/base-scripts/gen-book.sh";
        $path_map{"out-gen-book-file"} 			= $path_map{OutputScriptsDir}."/gen-book.sh";
        $path_map{"in-CompileTexFile-base-file"}	= $path_map{InDir}."/base-scripts/CompileTexFile.sh";
        $path_map{"out-CompileTexFile-file"} 		= $path_map{OutputScriptsDir}."/CompileTexFile.sh";
        $path_map{"in-compile-simple-latex-base-file"}	= $path_map{InDir}."/base-scripts/compile-simple-latex.sh";
        $path_map{"out-compile-simple-latex-file"} 	= $path_map{OutputScriptsDir}."/compile-simple-latex.sh";
        $path_map{"update-page-numbers"}	 	= $path_map{InScriptsDir}."/update-page-numbers.pl";

        $path_map{"out-batch-to-gen-figs-file"}         = $path_map{OutputScriptsDir}."/gen-fig-files.sh";
        $path_map{"out-gen-syllabi.sh-file"}		= $path_map{OutputScriptsDir}."/gen-syllabi.sh";
        $path_map{"out-gen-map-for-course"}		= $path_map{OutputScriptsDir}."/gen-map-for-course.sh";

        # Dot files
        $path_map{"in-small-graph-item.dot"}		= $path_map{InTemplatesDot}."/small-graph-item$config{graph_version}.dot";
        $path_map{"in-big-graph-item.dot"}		= $path_map{InTemplatesDot}."/big-graph-item$config{graph_version}.dot";
        $path_map{"out-small-graph-curricula-dot-file"} = $config{OutputDotDir}."/small-graph-curricula.dot";
        $path_map{"out-big-graph-curricula-dot-file"}	= $config{OutputDotDir}."/big-graph-curricula.dot";

        # Poster files
        $path_map{"in-poster-file"}			= $path_map{InDisciplineDir}."/$config{discipline}-poster.tex";
        $path_map{"out-poster-file"}			= $path_map{OutputTexDir}."/$config{discipline}-poster.tex";
        $path_map{"in-a0poster-sty-file"}               = $path_map{InStyAllDir}."/a0poster.sty";
        $path_map{"in-poster-macros-sty-file"}          = $path_map{InStyAllDir}."/poster-macros.sty";
        $path_map{"in-small-graph-curricula-file"}      = $path_map{InTexAllDir}."/small-graph-curricula.tex";
        $path_map{"out-small-graph-curricula-file"}      = $path_map{OutputTexDir}."/small-graph-curricula.tex";

        # Html
        $path_map{"in-web-course-template.html-file"} 	= $path_map{InHtmlDir}."/web-course-template.html";
        $path_map{"in-analytics.js-file"}               = $path_map{InDir}."/analytics.js";

        # Config files
        $path_map{"all-config"}				= $path_map{InDir}."/config/all.config";
        $path_map{"colors"}				= $path_map{InDir}."/config/colors.config";
        $path_map{"discipline-config"}		   	= $path_map{InLangDir}."/$config{discipline}.config/$config{discipline}.config";
        $path_map{"in-area-all-config-file"}		= $path_map{InLangDir}."/$config{area}.config/$config{area}-All.config";
        $path_map{"in-area-config-file"}		= $path_map{InLangDir}."/$config{area}.config/$config{area}.config";
        $path_map{"in-country-config-file"}		= GetInCountryBaseDir($config{country_without_accents})."/country.config";
        $path_map{"in-institution-config-file"}		= $path_map{InInstDir}."/institution.config";
        $path_map{"in-country-environments-to-insert-file"}	= GetInCountryBaseDir($config{country_without_accents})."/country-environments-to-insert.tex";
        $path_map{"dictionary"}				= $path_map{InLangDir}."/dictionary.txt";
        $path_map{SpiderChartInfoDir}			= $path_map{InDisciplineDir}."/SpiderChartInfo";

        $path_map{"OutputDisciplinesList-file"}	= $path_map{OutHtmlBase}."/disciplines.html";

	Util::check_point("set_initial_paths");
}

sub get_file_name($)
{
	my ($tpl) = (@_);
	return get_template($tpl);
}

# ok
sub read_discipline_config()
{
	my %discipline_cfg	= read_config_file("discipline-config");
	#print Dumper (\%discipline_cfg); exit;
	my ($key, $value);
	while ( ($key, $value)  = each(%discipline_cfg) )
	{
# 		print "country-info: key=$key, value=$value\n";
		$config{$key} = $value;
	}

	@{$config{SyllabiDirs}} = ();
	foreach my $dir (split(",", $config{SyllabusListOfDirs}))
	{
		push(@{$config{SyllabiDirs}}, $dir);
	}

	%{$config{sub_areas_priority}} = ();
	my $count = 0;
	foreach my $axe (split(",", $config{SpiderChartAxes}))
	{
		$config{sub_areas_priority}{$axe} = $count++;
	}
	$config{NumberOfAxes} = $count;
}

# ok
sub get_syllabus_dir($)
{
	my ($codcour) = (@_);
	my $syllabus_base_dir = get_template("InSyllabiContainerDir");
	my $codcourfile = $course_info{$codcour}{coursefile};
	foreach my $dir (@{$config{SyllabiDirs}})
	{
		my $file = "$syllabus_base_dir/$dir/$codcourfile";
		if(-e $file.".tex" or -e $file.".bib")
		{	return "$syllabus_base_dir/$dir";	}
	}
	Util::halt("I can not find syllabus/bib file for $codcour");
}

# ok
sub get_syllabus_full_path($$$)
{
	my ($codcour, $semester, $lang) = (@_);
	my $syllabus_base_dir = get_template("InSyllabiContainerDir");
	$syllabus_base_dir =~ s/$config{language_without_accents}/$lang/;
	my $codcourfile = $course_info{$codcour}{coursefile};

# 	if($lang eq "English")
# 	{	Util::print_message("$syllabus_base_dir");
#		$syllabus_base_dir =~ s/$config{language_without_accents}/$lang/;
# 		Util::print_message("$syllabus_base_dir");
# 		exit;
# 	}
	foreach my $dir (@{$config{SyllabiDirs}})
	{
		my $file = "$syllabus_base_dir/$dir/$codcourfile";
  		#Util::print_message("Trying file= $syllabus_base_dir + $dir + $codcour ...");
		if(-e $file.".tex")
		{	return $file.".tex";	}
		if(-e $file.".bib")
		{	return $file.".bib";	}
	}
# 	Util::print_message("syllabus_base_dir=$syllabus_base_dir ...");
# 	print Dumper(\@{$config{SyllabiDirs}});
	Util::print_message("I could not find course $codcour proposed at $config{dictionary}{Sem} #$semester ... VERIFY file: \"$syllabus_base_dir/$codcour\"");
	my $dirlist = "";
	foreach my $dir (@{$config{SyllabiDirs}})
	{	$dirlist .= "$syllabus_base_dir/$dir/$codcourfile.tex\n";		}
	Util::halt("Verify this list of dirs where I was looking for that file:\n$dirlist");
}

# ok
sub get_template($)
{
	my ($acro) = (@_);
	if(defined($path_map{$acro}))
	{	return $path_map{$acro};	}
	Util::halt("get_template: Template not recognized ($acro), Did you define it?");
}

sub read_config_file_details($)
{
	my ($filename) 		= (@_);
	my %map 		= ();
 	Util::print_message("Reading config file: \"$filename\"");
	my $txt = Util::read_file($filename);

	while($txt =~ m/<HASH name=(.*?)>((?:.|\n)*?)<\/HASH>/)
	{
		my ($name, $body) = ($1, $2);
		my $body_tmp = replace_special_chars($body);
		$txt =~ s/<HASH name=$name>$body_tmp<\/HASH>//g;
		while($body =~ m/\s*(\w*)\s*=>\s*(.*?)\s*\n/g)
		{
			$map{$name}{$1} = $2;
# 			if($2 eq "Segundo")
# 			{	Util::print_message("map{$name}{$1} = $2; file = $filename");
# 				exit;
# 			}
# 			Util::print_message("map{$name}{$1} = $2; ");
		}
# 		Util::halt("hash $name ...");
	}
# 	foreach my $line (split("\n", $txt))

	while($txt =~ m/\s*(.*?)\s*=\s*(.*)\s*/g)
	{	$map{$1} = $2;
 		if($1 eq "ComparisonWithStandardCaption")
		{ 	#print "map{$1}=\"$2\"; ($tpl) \n";
			#exit;
		}
	}
        return %map;
}

# ok
sub read_config_file($)
{
	my ($tpl) 		= (@_);
 	my $filename 		= get_template($tpl);
	return read_config_file_details($filename);
}

sub read_dictionary_file($)
{
	my ($lang) = (@_);
	my $filename = get_template("InLangBaseDir")."/$lang/dictionary.txt";
	return read_config_file_details($filename);
}

# ok
sub read_config($)
{
	my ($tpl) = (@_);
	my %map = read_config_file($tpl);
	my ($key, $value);
	while ( ($key, $value) = each(%map))
	{
		$config{$key} = $value;
# 		if( $key eq "SyllabusListOfDirs" )
#  		{	Util::print_message("$config{$key} = $value"); exit; 	}
	}
}

sub get_dictionary_term($)
{
    my ($word) = (@_);
    return $config{dictionary}{language_without_accents}{$word};
}

sub sort_macros()
{
    @{$config{sorted_macros}} = [];
    @{$config{sorted_macros}} = sort {length($b) <=> length($a)} keys %{$config{macros}};
    Util::check_point("sort_macros");
}

# ok
sub read_macros($)
{
    my ($file_name) = (@_);
    my $bok_txt 	  = clean_file(Util::read_file($file_name));

    my $count = 0;
    while($bok_txt =~ m/\\newcommand\{\\(.*?)\}((\s|\n)*?)\{/g)
    {
	my ($cmd)  = ($1);
	my $cPar   = 1;
	my $body   = "";
	while($cPar > 0)
	{
		$bok_txt =~ m/((.|\s))/g;
		$cPar++ if($1 eq "{");
		$cPar-- if($1 eq "}");
		$body      .= $1 if($cPar > 0);
	}
	$Common::config{macros}{$cmd} = $body;
# 	if( $cmd eq "SPONEAllTopics")
# 	{	Util::print_message("*****\n$body\n*****");	exit;	}
	$count++;
    }
    Util::print_message("read_macros ($file_name) $count macros processed ... OK!");
}

sub read_special_macros($$)
{
    my ($file_name, $macro) = (@_);
    my $txt 	  = clean_file(Util::read_file($file_name));

    my $count = 0;
    while($txt =~ m/\\Define$macro\{(.*?)\}\{/g)
    {
	my ($cmd)  = ($1);
	my $cPar   = 1;
	my $body   = "";
	while($cPar > 0)
	{
		$txt =~ m/((.|\s))/g;
		$cPar++ if($1 eq "{");
		$cPar-- if($1 eq "}");
		$body      .= $1 if($cPar > 0);
	}
	$Common::config{$macro}{$cmd} = $body;
# 	if( $cmd eq "SPONEAllTopics")
# 	{	Util::print_message("*****\n$body\n*****");	exit;	}
	$count++;
    }
    Util::print_message("read_special_macros($macro) ($file_name) $count macros processed ... OK!");
}

sub read_bok($)
{
    my ($lang) = (@_);
    my $bok_macros_file = Common::get_template("in-bok-macros-file");
    $bok_macros_file =~ s/<LANG>/$lang/g;
    read_macros($bok_macros_file);
}

sub read_replacements()
{
	my $replacements_file = Common::get_template("in-replacements-file");
	%{$config{replacements}} = ();
	if( not -e $replacements_file )
	{
	      Util::print_message("I did not find replacements ($replacements_file) just ignoring this process ... ");
	      return;
	}
        my $txt = Util::read_file($replacements_file);
	foreach my $line (split("\n", $txt))
	{
		if($line =~ m/\s*(.*)\s*=>\s*(.*)\s*/g )
		{
		      $config{replacements}{$1} = $2;
		}
	}
}

sub replace_old_macros($)
{
      my ($syllabus_in) = (@_);
      my $count = 0;
      foreach my $key (sort {length($b) <=> length($a)} keys %{$config{replacements}})
      {
	    $count += $syllabus_in =~ s/\\$key/\\$config{replacements}{$key}/g;
      }
      return ($syllabus_in, $count);
}

# ok
sub process_config_vars()
{
#  	print "config{macros_file} = \"$config{macros_file}\"\n";
        my $InStyDir = get_template("InStyDir");
	my $InLangDir = get_template("InLangDir");
	foreach my $file (split(",", $config{macros_file}))
	{
		$file =~ s/<STY-AREA>/$InStyDir/g;
		$file =~ s/<LANG-AREA>/$InLangDir/g;
	}

# 	PrefixPriority=CS,IS,SE,HW,IT,MC,OG,CB,CF,CM,CQ,HU,ET,ID
	my $count = 0;
	$config{PrefixPriority} =~ s/ //g;
	foreach my $prefix (split(",",$config{PrefixPriority}))
	{	$config{prefix_priority}{$prefix} = ++$count;		}

# 	AreaPriority=AF,AE,AB,AC
	$count = 0;
	foreach my $area (split(",", $config{AreaPriority}))
	{	$config{area_priority}{$area} = ++$count;		}

	%{$config{colors}{colors_per_level}}   = %{$config{temp_colors}{colors_per_level}};
	undef(%{$config{temp_colors}{colors_per_level}});
	foreach my $prefix (keys %{$config{temp_colors}})
	{
		# Util::print_message("$config{temp_colors}{$prefix}");
		if(ref($config{temp_colors}{$prefix}) eq "HASH")
		{
			Util::print_message("***** Ignoring config{temp_colors}{$prefix}");
		}
		else
		{
# 			Util::print_message("config{temp_colors}{$prefix}");
			if($config{temp_colors}{$prefix} =~ m/(.*),(.*)/g)
			{
				$config{colors}{$prefix}{textcolor} = $1;
				$config{colors}{$prefix}{bgcolor}   = $2;
			}
		}
	}
	$config{colors}{change_highlight_background} = "honeydew3";
	$config{colors}{change_highlight_text}       = "black";
}

# ok
sub read_institutions_list()
{
	my $inst_list_file 	= get_template("institutions-list");
	open(IN, "<$inst_list_file") or Util::halt("read_inst_list: $inst_list_file does not open");
	my @lines = <IN>;
	close(IN);
	my $count = 0;
	foreach my $line (@lines)
	{
		#                   CS-SPC     : Peru	   : Computing : SPC       : Plan2010 : final
		if($line =~ m/\s*(.*?)-(.*?)\s*:\s*(.*?)\s*:\s*(.*?)\s*:\s*(.*?)\s*:\s*(.*?)\s*:\s*(.*?)\s*$/)
		{
			my ($_area, $inst, $country, $discipline, $filter, $plan, $version)= ($1, $2, $3, $4, $5, $6, $7);
			if( $_area eq $config{area})
			{
				$inst_list{$2}{area}       = $_area;
				$inst_list{$2}{country}    = $country;
				$inst_list{$2}{discipline} = $discipline;
				$inst_list{$2}{filter}     = $filter;
				$inst_list{$2}{plan}       = $plan;
				$inst_list{$2}{version}    = $version;
				$count++;
				#print "Area = $1, Inst = $2, Filter = $3, version = $4\n";
			}
			else
			{
				if(not defined($inst_list{$2}))
				{
					$inst_list{$2}{area}       = "";
					$inst_list{$2}{country}    = "";
					$inst_list{$2}{discipline} = "";
					$inst_list{$2}{filter}     = "";
					$inst_list{$2}{version}    = "";
					$count++;
					#print "No definido: $line";
				}
			}
 			# $country = filter_non_valid_chars($country);
			@{$config{list_of_countries}{$country}} = [];

			# By Discipline
			$config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{order} = $count++;
			if(not defined($config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{Plans}))
			{	$config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{Plans} = [];	}
			push(@{$config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{Plans}}, $plan);

			# By Country
			$config{Curriculas}{country}{$country}{$discipline}{$area}{$inst}{order} = $count;
			#$config{Curriculas}{country}{$country}{$discipline}{$area}{$inst}{Plans}{$plan} = ();
			$config{Curriculas}{country}{$country}{$discipline}{$area}{$inst}{Plans}{$plan}{version} = $version;
			$count++;

			$list_of_areas{$_area} = "";
		}
		else
		{
			#print "No match \"$line\"\n";
		}
	}
	Util::print_message("read_inst_list ($count)");
	Util::check_point("read_institutions_list");
}

sub generate_html_index_by_country()
{
      #       $config{Curriculas}{country}{$country}{$discipline}{$area}{$inst}{order} = $count++;
      my $countries_list_html = "";
      my $list_of_institutions_html = "";
      foreach my $country (sort keys %{$config{Curriculas}{country}})
      {
	    my $list_of_institutions_by_country_in_html_global = "";
	    my @list_of_institutions_by_country_in_html = ("", "");
	    my $country_no_accents = no_accents($country);
	    my $country_in_html = special_chars_to_html($country);

	    Util::print_message("Processing country: $country ...");
	    my @counter_by_country = (0, 0);

	    foreach my $discipline (sort keys %{$config{Curriculas}{country}{$country}})
	    {
		  Util::print_message("  Processing discipline: $discipline ...");
		  foreach my $area (sort keys %{$config{Curriculas}{country}{$country}{$discipline}})
		  {
			foreach my $inst (sort keys %{$config{Curriculas}{country}{$country}{$discipline}{$area}})
			{
			      my @list_of_plans = ("", "");
			      my @sep = ("", "");
			      my @counter_by_inst = (0, 0);
			      foreach my $plan (sort keys %{$config{Curriculas}{country}{$country}{$discipline}{$area}{$inst}{Plans}})
			      {
				    if( $config{Curriculas}{country}{$country}{$discipline}{$area}{$inst}{Plans}{$plan}{version} eq "final" )
				    {
					  Util::print_message("\tProcessing institution: $area/$inst ($plan) ...");
					  $list_of_plans[0] .= " $sep[0]<a href=\"$country/$area/$inst/$plan\">$plan</a>";
					  $counter_by_country[0]++;
					  $counter_by_inst[0]++;
					  $sep[0] = ",";
				    }
				    else
				    {
					  $list_of_plans[1] .= " $sep[1]$plan (draft version)";
					  #Util::print_message("\t  Ignoring $area/$inst ($plan) (draft version) ...");
					  $counter_by_country[1]++;
					  $counter_by_inst[1]++;
					  $sep[1] = ",";
				    }
			      }
			      foreach my $i (0, 1)
			      {
				    if( $counter_by_inst[$i] > 0 )
				    {	  #$list_of_institutions_by_country_in_html .= "\t<ul>\n";
					  $list_of_institutions_by_country_in_html[$i] .= "\t<li>$area/$inst: $list_of_plans[$i]</li>\n";
					  #$list_of_institutions_by_country_in_html .= "\t</ul>\n";
				    }
			      }
			}
		  }
	    }
	    # Create the anchor ...
	    $countries_list_html .= "<a href=\"#$country_no_accents\">$country_in_html</a>\n ";

	    $country_no_accents =~ s/ //g;
	    my $country_lcase = lc($country_no_accents);
	    $list_of_institutions_by_country_in_html_global .= "<a name=\"$country_no_accents\"></a>\n ";
	    my $cmd = "cp \"".GetInCountryBaseDir($country)."/$country_lcase.gif\" ".get_template("OutHtmlBase")."/.";
	    system($cmd);
	    my $flag = "<img src=\"$country_lcase.gif\">";
	    $list_of_institutions_by_country_in_html_global .= "<h1>$country_in_html $flag</h1>\n ";
	    $list_of_institutions_by_country_in_html_global .= "<ul>\n";
	    #$list_of_institutions_by_country_in_html_global .= "\t<li>$discipline</li>\n";
	    $list_of_institutions_by_country_in_html_global .= $list_of_institutions_by_country_in_html[0];
	    $list_of_institutions_by_country_in_html_global .= $list_of_institutions_by_country_in_html[1];
	    $list_of_institutions_by_country_in_html_global .= "</ul>\n";
	    $list_of_institutions_by_country_in_html_global .= "\n";

	    if( $counter_by_country[0] + $counter_by_country[1] > 0 )
	    {	$list_of_institutions_html .= $list_of_institutions_by_country_in_html_global;	}
# 	    Util::write_file(get_template("OutHtmlBase")."/$country.html", $list_of_institutions_by_country_in_html);
      }
      my $output_html = "$countries_list_html\n\n";
      $output_html .= $list_of_institutions_html;

      Util::write_file(get_template("OutHtmlBase")."/countries.html", $output_html);
#       $path_map{"OutputDisciplinesList-file"}	= $config{OutputHtmlDir}."/disciplines.html";

#       $config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{order} = $count++;
#       $config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{short_description} = "";
}

sub generate_index_for_this_discipline()
{
      my $disciplines_list_html = "";
      foreach my $discipline (keys %{$config{Curriculas}{disc}})
      {
	    Util::print_message("Processing discipline: $discipline ...");
	    my $countries_list_html = "";
	    foreach my $country (sort keys %{$config{Curriculas}{disc}{$discipline}})
	    {
		  Util::print_message("  Processing country: $country ...");

		  my $area_list_html = "";
		  foreach my $area (keys %{$config{Curriculas}{disc}{$discipline}{$country}})
		  {
			if(not $area eq $config{area})
			{    next;		}
			foreach my $inst (keys %{$config{Curriculas}{disc}{$discipline}{$country}{$area}})
			{
			      Util::print_message("      Processing institution: $inst ...");
			      foreach my $Plan (keys %{$config{Curriculas}{disc}{$discipline}{$country}{$area}{Plan}})
			      {
			      }
			      $countries_list_html .= "<a href=\" value=\"$country\">$country</option>\n";
			}
		  }
		  my $area_list_html_final .= "<SELECT NAME=\"$discipline-$country\">\n";
		  $area_list_html_final    .= "$area_list_html";
		  $area_list_html_final    .= "</SELECT>\n";
		  Util::write_file(get_template("OutHtmlBase")."/$discipline-$country.html", $area_list_html_final);
	    }
	    Util::write_file(get_template("OutHtmlBase")."/$discipline-countries.html", $countries_list_html);
      }
      Util::write_file(get_template("OutputDisciplinesList-file"), $disciplines_list_html);
#       $path_map{"OutputDisciplinesList-file"}	= $config{OutputHtmlDir}."/disciplines.html";

#       $config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{order} = $count++;
#       $config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{short_description} = "";
}

sub generate_index_for_this_area_old()
{
      my $disciplines_list_html = "";
      foreach my $discipline (keys %{$config{Curriculas}{disc}})
      {
	    Util::print_message("Processing discipline: $discipline ...");
	    my $countries_list_html = "";
	    foreach my $country (sort keys %{$config{Curriculas}{disc}{$discipline}})
	    {
		  Util::print_message("  Processing country: $country ...");
		  $countries_list_html .= "<a href=\" value=\"$country\">$country</option>\n";
		  my $area_list_html = "";
		  foreach my $area (keys %{$config{Curriculas}{disc}{$discipline}{$country}})
		  {
			Util::print_message("    Processing area: $area ...");
			$area_list_html .= "\t<option value=\"$area\">$area</option>\n";
			my $insts_output = "";
			foreach my $inst (keys %{$config{Curriculas}{disc}{$discipline}{$country}{$area}})
			{
			      Util::print_message("      Processing institution: $inst ...");
			}
		  }
		  my $area_list_html_final .= "<SELECT NAME=\"$discipline-$country\">\n";
		  $area_list_html_final    .= "$area_list_html";
		  $area_list_html_final    .= "</SELECT>\n";
		  Util::write_file(get_template("OutHtmlBase")."/$discipline-$country.html", $area_list_html_final);
	    }
	    Util::write_file(get_template("OutHtmlBase")."/$discipline-countries.html", $countries_list_html);
      }
      Util::write_file(get_template("OutputDisciplinesList-file"), $disciplines_list_html);
#       $path_map{"OutputDisciplinesList-file"}	= $config{OutputHtmlDir}."/disciplines.html";

#       $config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{order} = $count++;
#       $config{Curriculas}{disc}{$discipline}{$country}{$area}{$inst}{short_description} = "";
}

sub read_copyrights($)
{
	my ($file) = (@_);
	my $txt  = Util::read_file($file);
	my %file_info = ();
	# Read the HTMLFootnote
	if($txt =~ m/\\newcommand\{\\HTMLFootnote\}\{\{(\s*(?:.|\n)*?)\}\}/)
	{
		$file_info{HTMLFootnote} = $1;
		$file_info{HTMLFootnote} =~ s/\n/ /g;
		$file_info{HTMLFootnote} =~ s/\t/ /g;
		$file_info{HTMLFootnote} =~ s/\s\s/ /g;
	}
	else
	{	Util::print_error("(read_copyrights): there is not \\HTMLFootnote configured in \"$file\" ...\n");
	}
	Util::check_point("read_copyrights");
	Util::print_message("read_copyrights ($file) ... OK !");
	return %file_info;
}

# ok
sub read_institution_info($)
{
	my ($file) = (@_);
	my $txt  = Util::read_file($file);
	my %this_inst_info = ();
	Util::print_message("Reading read_institution_info ($file) ... ");
# 	print "^^^^^^^^^^^^^^^^^^^^^^^^^\n$txt\n^^^^^^^^^^^^^^^^^^^^^^^^^^\n";
	# Read the Semester
	if($txt =~ m/\\newcommand\{\\Semester\}\{(.*?)\\.*?\}/)
	{	$this_inst_info{Semester} = $1;			}
	else
	{	Util::print_error("Error (read_institution_info): there is no Semester configured in \"$file\"\n");	}

	# Read the Active Plan
	if($txt =~ m/\\newcommand\{\\YYYY\}\{(.*?)\\.*?\}/)
	{	$this_inst_info{YYYY} = $1;
		$this_inst_info{Plan} = $1;
	}
	else
	{	Util::print_error("Error (read_institution_info): there is no YYYY (Plan) configured in \"$file\"\n");	}

	# Read the Range of semesters to generate
	if($txt =~ m/\\newcommand\{\\Range\}\{(.*?)-(.*?)\}/) # \newcommand{\Range}{4-7} %Plan
	{	$this_inst_info{SemMin} = $1;
		$this_inst_info{SemMax} = $2;
	}
	else
	{	Util::print_warning("(read_institution_info): does not contain Range of semesters to generate (assuming all) \n");	}

	# Read the dictionary
	if($txt =~ m/\\newcommand\{\\dictionary\}\{(.*?)\\.*?\}/)
	{	$this_inst_info{language_without_accents} 	= no_accents($1);
		$this_inst_info{language} 			= $1;
	}
	else
	{	Util::print_error("read_institution_info: there is not \\dictionary configured in \"$file\"\n");	}

	# Read the dictionary
	if($txt =~ m/\\newcommand\{\\SyllabusLangs\}\{(.*?)\}/)
	{	$this_inst_info{SyllabusLangs} 			= $1;
		$this_inst_info{SyllabusLangs} 			=~ s/ //g;
		$this_inst_info{SyllabusLangs_without_accents} 	= no_accents($this_inst_info{SyllabusLangs});
		foreach my $lang (split(",", $this_inst_info{SyllabusLangs_without_accents}))
		{	push( @{$this_inst_info{SyllabusLangsList}}, $lang);	}
	}
	else
	{	Util::print_error("read_institution_info: there is not \\SyllabusLang defined in \"$file\"\n");	}

	# Read the country
	if($txt =~ m/\\newcommand\{\\country\}\{(.*?)\\.*?\}/)
	{
                $this_inst_info{country}                      = $1;
                $this_inst_info{country_without_accents} 	= filter_non_valid_chars($this_inst_info{country});
 		#Util::print_message("country=$this_inst_info{country}, country_without_accents=$this_inst_info{country_without_accents}\n"); exit;
	}
	else
	{	Util::print_error("Error (read_institution_info): there is not \\country configured in \"$file\"\n");	}

	# Read the GraphVersion
	$this_inst_info{graph_version} = 1;
	$this_inst_info{sep} = "|";
	$this_inst_info{hline} = "\\hline";
	if($txt =~ m/\\newcommand\{\\GraphVersion\}\{(.*?)\\.*?\}/)
	{	$this_inst_info{graph_version} = $1;
		if($this_inst_info{graph_version} == 2)
		{
		      $this_inst_info{sep} = "";
		      $this_inst_info{hline} = "";
		}
	}
	else
	{	Util::print_warning("(read_institution_info): there is not \\GraphVersion configured in \"$file\" ... assuming 1 ...\n");
	}

	# Read the CurriculaVersion
	if($txt =~ m/\\newcommand\{\\CurriculaVersion\}\{(.*?)\\.*?\}/)
	{	$this_inst_info{CurriculaVersion} = $1;		}
	else
	{	Util::print_warning("(read_institution_info): there is not \\CurriculaVersion configured in \"$file\" ... assuming 3 ...\n");
		$this_inst_info{CurriculaVersion} = 3;
	}

	# Read the outcomes list
	my $OutcomesError = "(read_institution_info): there is not \\OutcomesList configured in \"$file\" ...\n";

	my $txt_copy = $txt;
	my @outcomes_array = $txt_copy =~ m/\\OutcomesList(\{.*?)\n/g;
	foreach my $params (@outcomes_array)
	{
		my ($version, $outcomeslist) = ($config{OutcomesVersionDefault}, "");
		if( $params =~ m/\{(.*?)\}\{(.*?)\}/g )
		{	($version, $outcomeslist) = ($1, $2);		}
		elsif( $params =~ m/\{(.*?)\}/g )
		{	$outcomeslist = $1;
			$txt_copy =~ s/\\OutcomesList\{$outcomeslist\}/\\OutcomesList\{$version\}\{$outcomeslist\}/g;
		}
		else{	Util::print_error($OutcomesError);	}
		Util::print_message("this_inst_info{outcomes_list}{$version} = $outcomeslist");
		if( defined($this_inst_info{outcomes_list}{$version}) && not $this_inst_info{outcomes_list}{$version} eq "" )
		{	Util::print_error("Many \\OutcomesList for the same version??? (\"$file\")");	}
		$this_inst_info{outcomes_list}{$version} = $outcomeslist;
	}
	#print Dumper(\%this_inst_info); 	exit;
	$txt = $txt_copy;
	# Read the CurriculaVersion
	if($txt =~ m/\\newcommand\{\\OutcomesVersion\}\{(.*?)\}/g)
	{	$this_inst_info{OutcomesVersion} = $1;		}
	else
	{	Util::print_warning("(read_institution_info): there is not \\OutcomesVersion configured in \"$file\" ... assuming $config{OutcomesVersionDefault} ...\n");
		$txt .= "\n\\newcommand\{\\OutcomesVersion\}\{$config{OutcomesVersionDefault}\}\n";
		$this_inst_info{OutcomesVersion} = $config{OutcomesVersionDefault};
	}

        # Read the outcomes list
        if($txt =~ m/\\newcommand\{\\logowidth\}\{(\d*)(.*?)\}/)
        {       $this_inst_info{logowidth}       = $1;
                $this_inst_info{logowidth_units} = $2;
                #Util::print_message("this_inst_info{logowidth}=$this_inst_info{logowidth}, this_inst_info{logowidth_units}=$this_inst_info{logowidth_units}"); exit;
        }
        else
        {       Util::print_error("(read_institution_info): there is not \\logowidth configured in \"$file\" ...\n");
        }

#         if($txt =~ m/\\newcommand{\\Copyrights}{(.*?)}/)
#         {       $this_inst_info{Copyrights} = $1;             }
#         else
#         {       Util::print_error("(read_institution_info): there is not \\Copyrights configured in \"$file\" ...\n");
#         }
	# Read equivalences
	$this_inst_info{equivalences} = "";
	if($txt =~ m/\\newcommand\{\\equivalences\}\{(.*?)\}/)
	{
                $this_inst_info{equivalences}	= $1;
		#Util::print_message("this_inst_info{equivalences} = $this_inst_info{equivalences}"); exit;
	}
	else
	{	Util::print_warning("(read_institution_info): there is not \\equivalences in \"$file\"\n");	}

# 	Util::print_message("After ($file)\n$txt");
	#print Dumper(\%this_inst_info); 	exit;

	Util::write_file($file, $txt);
	Util::check_point("read_institution_info");
	Util::print_message("institution_info ($file) ... OK !");
	return %this_inst_info;
}

sub read_specific_evaluacion_info()
{
	Util::precondition("filter_courses");
	my $specific_evaluation_file = get_template("in-specific-evaluation-file");
	#Util::print_message("Common::config{SyllabusLangs_without_accents} = $Common::config{SyllabusLangs_without_accents}");
	if(not -e $specific_evaluation_file)
	{	Util::print_warning("No specific evaluation file ($specific_evaluation_file) ... you may create one to specify criteria for each course ...");	}
	else
	{
	      Util::print_message("Reading specific evaluation file ($specific_evaluation_file) ...");
	      my $specific_evaluation = Util::read_file($specific_evaluation_file);
	      while($specific_evaluation =~ m/\\begin\{evaluation\}\{(.*?)\}((?:.|\n)*?)\\end\{evaluation\}/g)
	      {
		      my ($cc, $this_evaluation_body) = ($1, $2);
		      my $codcour = detect_codcour($cc);
		      #Util::print_message("this_evaluation_body=\n$this_evaluation_body");
		      if ( $this_evaluation_body  =~ m/\{(.*?)\}\{(.*?)\}\s*\n((?:.|\n)*)/g)
		      {
			    my ($listoflangs, $parts, $eval) = ($1, $2, $3);
			    $parts =~ s/ //g;	$listoflangs =~ s/ //g;
			    #Util::print_message("listoflangs=$listoflangs, $parts$parts, eval=\n$eval");
			    if( $listoflangs eq "*" ){	$listoflangs = $Common::config{SyllabusLangs_without_accents};		}
			    my $output_parts = "";
			    foreach my $onepart (split(",", $parts))
			    {
				  $output_parts .= "{\\noindent\\bf <<$onepart-SESSIONS>>:}\\\\\n";
				  $output_parts .= "<<$onepart-SESSIONS-CONTENT>>\n";
				  $output_parts .= "\n\\vspace{2mm}\n";
			    }
			    foreach my $lang (split(",", $listoflangs))
			    {
				  if(not defined($config{dictionaries}{$lang}{lang_prefix}) )
				  {	Util::print_error("$cc($codcour) has an undefined Language($lang) !...");		}
				  my $evaluation_header = "\\vspace{2mm}\n";
				  $evaluation_header .= "{\\noindent\\bf <<EVALUATION-SYSTEM>>:}\\\\\n";
				  $Common::course_info{$codcour}{$lang}{specific_evaluation} = "$output_parts\n$evaluation_header$eval\n";
				  #$Common::course_info{$codcour}{$lang}{specific_evaluation} = "$output_parts\n$eval\n";

				  Util::print_warning("$cc($codcour) specific_evaluation ($lang) detected!");
				  #Util::print_message("$Common::course_info{$codcour}{$lang}{specific_evaluation}"); exit;
				  #if($codcour eq "CS111") { 	Util::print_message("C. Common::course_info{$codcour}{specific_evaluation}=\n$Common::course_info{$codcour}{specific_evaluation}");	exit;}
				  #Util::print_message("$Common::course_info{$codcour}{specific_evaluation}");
			    }
		      }
		      else
		      {
			    Util::print_error("Specific Evaluation for $cc($codcour) out of format?\nfile: $specific_evaluation_file ");
		      }

	      }
	}
}

# ok
sub parse_input_command($)
{
	my ($command) = (@_);
	if($command =~ m/(.*)-(.*)/)
	{
		($area, $institution) 	= ($1, $2);
		#print "Institution = $institution\n";
		#print "Area        = $area\n";
                ($config{area}, $config{institution}) = ($area, $institution);
	}
	else
	{	Util::halt("There is no command to process (i.e AREA-INST)");
	}
}

sub process_filters()
{
	$inst_list{$institution}{filter} =~ s/ //g;
	my $priority = 100;
	foreach my $inst (split(",", $inst_list{$institution}{filter}))
	{
		$config{valid_institutions}{$inst}	= $priority;
		$config{filter_priority}{$inst}		= $priority;
		$priority--;
	}
}

sub verify_dependencies()
{
    my @files_to_verify = (get_template("InTexDir")."/abstract-$config{language_without_accents}.tex"    );
    foreach my $flag (keys %template_files)
    {
	my $file = get_template($template_files{$flag});
	if(-e $file)
	{	$config{flags}{$flag} = 1;	}
	else
	{	$config{flags}{$flag} = 0;	}
    }
}

# First Parameter is something such as CS-SPC
sub set_initial_configuration($)
{
	my ($command) = (@_);
	$config{projectname} = "Curricula";
	($config{in}, $config{out})		= ("../$config{projectname}.in", "../$config{projectname}.out");
	$config{OutcomesVersionDefault} = "V1";
	($path_map{InDir}, $path_map{OutDir})	= ($config{in}, $config{out});
	$config{macros_file} = "";

	$config{encoding} 	= "latin1";
	$config{tex_encoding} 	= "utf8";
	$config{lang_for_latex}{Espanol} = "spanish";
	$config{lang_for_latex}{English} = "english";
	$config{COL4LABS} = "lh";

        system("mkdir -p $config{out}/tex");

	# Parse the command
	parse_input_command($command);
	$path_map{"institutions-list"}	= "$config{in}/institutions-list.txt";
	read_institutions_list();
	$config{discipline}	  	= $inst_list{$config{institution}}{discipline};

	$config{InInstDir} 				= GetInstDir($inst_list{$config{institution}}{country}, $config{discipline}, $config{area}, $config{institution});
	$path_map{"this-institutions-info-file"}	= GetInstitutionInfo($inst_list{$config{institution}}{country}, $config{discipline}, $config{area}, $config{institution});
	$path_map{"copyrights"}				= "$config{in}/copyrights.tex";

	# Read copyrights
	my %copyrights_vars = read_copyrights( get_template("copyrights") );
	foreach my $key (keys %copyrights_vars)
	{	$config{$key} = $copyrights_vars{$key};	}

	# Read the config for this institution (lang, country, etc)
	my %inst_vars = read_institution_info( get_template("this-institutions-info-file") );
	foreach my $key (keys %inst_vars)
	{	$config{$key} = $inst_vars{$key};	}
# 	print Dumper(\%config); exit;

	$config{equivalences} =~ s/ //g;
# 	Util::print_message("config{equivalences} = \"$config{equivalences}\""); exit;

	$config{OutputInstDir}	    	= "$config{out}/$inst_list{$config{institution}}{country}/$config{area}-$config{institution}/cycle/$config{Semester}/Plan$config{Plan}";
	$config{LinkToCurriculaBase} 	= "http://education.spc.org.pe/$inst_list{$config{institution}}{country}/$config{area}-$config{institution}/Plan$config{Plan}";
	$config{OutHtmlBase}	    	= "$config{out}/html";

	# Set global variables, first phase
	set_global_variables();        #1st Phase

	# Parse filters for this institution
	process_filters();

	# set_initial_paths (useful for get_template)
	set_initial_paths();

	# Verify dependencies
	verify_dependencies();

	# Read configuration for this discipline
	read_discipline_config();
# 	print Dumper(\@{$config{SyllabiDirs}}); exit;

	read_config("all-config");


	$path_map{"crossed-reference-file"}		= $config{main_file}.".aux";
	read_config("in-area-all-config-file"); # i.e. CS-All.config
 	read_config("in-area-config-file");     # i.e. CS.config
	read_config("in-institution-config-file");     # i.e. institution.config
	#Util::print_message("CS=$config{dictionary}{AreaDescription}{CS}"); exit;

	%{$config{temp_colors}} = read_config_file("colors");

	# Read dictionary for this language

	%{$config{dictionary}} = read_config_file("dictionary");
	foreach my $lang (@{$config{SyllabusLangsList}})
	{
	      my $lang_prefix = "";
	      if( $lang =~ m/(..)/g )
	      {		$lang_prefix = uc($1);	      }
	      %{$config{dictionaries}{$lang}} 		= read_dictionary_file($lang);
	      $config{dictionaries}{$lang}{lang_prefix} = $lang_prefix;
	      #Util::print_message("config{dictionaries}{$lang}{lang_prefix} = $config{dictionaries}{$lang}{lang_prefix}");
	}
# 	print Dumper(\%{$config{dictionary}});
# 	print Dumper(\%{$config{dictionaries}{Espanol}});
# 	print Dumper(\%{$config{dictionaries}{English}});

	# Read specific config for its country
	my %countryvars = read_config_file("in-country-config-file");
	while ( my ($key, $value) = each(%countryvars) )
	{	$config{dictionary}{$key} = $value; 	}

	# Read customize vars for this institution (optional)
	my $inst_config_file = get_template("in-institution-config-file");
	if( -e $inst_config_file )
	{
	    my %instvars = read_config_file("in-institution-config-file");
	    while ( my ($key, $value) = each(%instvars) )
	    {	$config{$key} = $value; 	}
	}
	#Util::print_message("config{COL4LABS}=$config{COL4LABS}"); exit;

	$config{"country-environments-to-insert"} = "";
	my $file_to_insert = Common::get_template("in-country-environments-to-insert-file");
	if(-e $file_to_insert)
        {	$config{"country-environments-to-insert"} = Util::read_file($file_to_insert);		}

        #Util::print_message($config{"country-environments-to-insert"}); exit;
 	process_config_vars();
	read_crossed_references();

	my $InStyDir = get_template("InStyDir");
	my $InLangDir = get_template("InLangDir");

	foreach my $file (split(",", $config{macros_file})) # read_bok is here
	{
		$file =~ s/<STY-AREA>/$InStyDir/g;
		$file =~ s/<LANG-AREA>/$InLangDir/g;

		read_macros($file);
	}

	my $outcomes_macros_file = Common::get_template("in-outcomes-macros-file");
	$outcomes_macros_file =~ s/<LANG>/$Common::config{language_without_accents}/g;
	read_macros($outcomes_macros_file);

# 	read_macros(Common::get_template("in-outcomes-macros-file"));
# 	print Dumper(\%{$Common::config{macros}}); exit;

	read_macros(Common::get_template("out-current-institution-file")) if(-e Common::get_template("out-current-institution-file"));
	read_replacements();

	$config{macros}{siglas}        = $institution;
	$config{macros}{spcbibstyle}   = $config{bibstyle};
	sort_macros();

	$config{recommended_prereq} = 1;
	$config{corequisites}       = 1;
	$config{verbose}            = 1;
	$config{except_file}{"config-hdr-foot.tex"}     = "";
	$config{except_file}{"current-institution.tex"} = "";
	$config{except_file}{"outcomes-macros.tex"}     = "";
	$config{except_file}{"custom-colors.tex"}       = "";

	#$config{change_file}{"topics-by-course.tex"}    = "topics-by-course-web.tex";
# 	@{$config{bib_files}}	                        = [];

	$config{subsection_label}	= "subsection";
	$config{bold_label}		= "textbf";

    $config{main_to_gen_fig}        = Util::read_file(get_template("in-main-to-gen-fig"));
    Util::check_point("set_initial_configuration");
}

sub read_crossed_references()
{
      my $crf = Common::get_template("crossed-reference-file");
      return if(not -e $crf);
      my $txt = Util::read_file($crf);
      # \newlabel{out:Outcomed}{{d}{5}}
      while($txt =~ m/\\newlabel\{(.*?)\}\{\{(.*?)\}\{(.*?)\}\}/g)
      {
	    $config{references}{$1}{content}	= $2;
	    $config{references}{$1}{page}	= $3;
	    #Util::print_message("$1 value is $2");
      }
}

# ok
sub gen_only_macros()
{
	my $output_txt = "";

	$output_txt .= "% 1st by countries ...\n";
	foreach my $country (keys %{$config{list_of_countries}})
	{
		$country =~ s/ //g;
                $output_txt .= "\\newcommand{\\Only$country}[1]{";
                if($country eq $config{country_without_accents})
                {       $output_txt .= "\#1";   }
                $output_txt .= "\\xspace}\n";
                $output_txt .= "\\newcommand{\\Not$country}[1]{";
                if(not $country eq $config{country_without_accents})
                {       $output_txt .= "\#1";   }
                $output_txt .= "\\xspace}\n\n";
        }

        $output_txt .= "% 2st by areas ...\n";
	foreach my $onearea (keys %list_of_areas)
        {
                $output_txt .= "\\newcommand{\\Only$onearea}[1]{";
                if($onearea eq $area)
                {       $output_txt .= "\#1";   }
                $output_txt .= "\\xspace}\n";

                $output_txt .= "\\newcommand{\\Not$onearea}[1]{";
                if(not $onearea eq $area)
                {       $output_txt .= "\#1";   }
                $output_txt .= "\\xspace}\n\n";
        }

	$output_txt .= "% And now by institutions ...\n";
	foreach my $inst (keys %inst_list)
        {
                $output_txt .= "\\newcommand{\\Only$inst}[1]{";
                if($inst eq $institution)
                {       $output_txt .= "\#1";   }
                $output_txt .= "\\xspace}\n";
                $output_txt .= "\\newcommand{\\Not$inst}[1]{";
                if(not $inst eq $institution)
                {       $output_txt .= "\#1";   }
                $output_txt .= "\\xspace}\n\n";
        }
	my $only_macros_file = get_template("out-only-macros-file");
	Util::write_file($only_macros_file, $output_txt);
	Util::print_message("gen_only_macros ($only_macros_file) OK!");
}

sub gen_faculty_sql()
{
	my $output_sql = "";
	my ($user_count, $professor_count) = (10, 10);
	foreach my $email (keys %{$config{faculty}})
	{
		my ($username, $firstname, $lastname) = ("", "", "");
		if($email =~ /(.*)@.*/g)
		{	$username = $1;		}
		if($config{faculty}{$email}{name} =~ m/(.*?)\s(.*)\r/)
		{
			($firstname, $lastname) = ($1, $2);
		}
		$user_count++;
		$output_sql .= "INSERT INTO auth_user(id, username, first_name, last_name, email, password, ";
		$output_sql .= "is_staff, is_active, is_superuser)\n";
		$output_sql .= "\tVALUES($user_count, '$username', '$firstname', '$lastname', '$email', PASSWORD, 0, 0, 0);\n\n";

		my $shortcv = "";
		if( $config{faculty}{$email}{shortcv} =~ /(\\begin\{itemize\}(?:.|\n)*?\\end\{itemize\})/g )
		{	$shortcv = $1;	}
		my $title = "";
		if( $config{faculty}{$email}{title} =~ /(.*)\r/g )
		{	$title = $1;	}
		$professor_count++;
		$output_sql .= "INSERT INTO curricula_professor(id, user_id, shortBio, prefix_id)\n";
		$output_sql .= "\tVALUES($professor_count, $user_count, ";
		$output_sql .= "'$shortcv', '$title');\n\n";

	}
	Util::write_file("$config{OutputSqlDir}/docentes.sql", $output_sql);
}

# ok
sub read_faculty()
{
	my $faculty_file    		= get_template("faculty-file");

	%{$config{degrees}} 		= ("PosDoc" => 7, "Doctor" => 6,      	"DoctorPT" => 5,
					   "Master" => 4, "MasterPT" => 3,
					   "Title"  => 2, "Degree" => 1,	"Bachelor" => 0);
	%{$config{degrees_description}} = (0 => "Bachelor",      1 => "Degree", 	1 => "Title",
					   2 => "Master (Part Time)", 	3 => "Master (Full Time)",
					   4 => "Doctor (Part Time)", 5 => "Doctor (Full Time)", 6 => "PosDoc");
	%{$config{prefix}}  		= ("Bachelor" => "Bach", "Degree" => "Prof.", "Title" => "Prof.",
					   "MasterPT" => "Mag.", "Master" => "Mag.",
					   "DoctorPT" => "Dr.", "Doctor" => "Dr.", "PosDoc" => "Post Doc.");
	%{$config{sort_areas}} 		= ("Computing" => 1, "Mathematics" => 2, "Science" => 3, "Engineering" => 4, "Enterpreneurship" => 5, "Business" => 6, "Humanities" => 7, "Empty" => 8 );

	%{$config{faculty}} = ();
	return if(not -e $faculty_file);
	my $input = Util::read_file($faculty_file);
	my $copy_input = $input;
	Util::print_message("Faculty file: $faculty_file found! processing now ...");
	while($input =~ m/--BEGIN-PROFESSOR--\s*\n\\email\{(.*?)\}((?:.|\n)*?)--END-PROFESSOR--?/g)
	{
		my ($email, $emailkey) = ($1, $1);
		if( $email eq "" )
		{    next;	}
		my $body  = "\\email{$email}\n$2";
		$emailkey =~ s/\@/./g;
 		# Util::print_message("Reading $email ...");
		($config{faculty}{$email}{fields}{prefix}, $config{faculty}{$email}{fields}{name}) 		= ("Prof.", "");

		foreach my $lang (@{$config{SyllabusLangsList}})
		{
		      ($config{faculty}{$email}{fields}{shortcv}{$lang}, $config{faculty}{$email}{fields}{shortcvhtml}{$lang})   	= ("", "");
		}
		my $emailwithoutat = $email; $emailwithoutat =~ s/[@\.]//g;
		$config{faculty}{$email}{fields}{emailwithoutat} = $emailwithoutat;

		$config{faculty}{$email}{fields}{degreelevel} = -1;
		$config{faculty}{$email}{fields}{degreelevel_description} = "";
		$config{faculty}{$email}{concentration} = "";
		$config{faculty}{$email}{sub_area_specialization} = ""; # Computing
		$config{faculty}{$email}{fields}{anchor} = "$emailwithoutat";
		$config{faculty}{$email}{fields}{active} = "No";
		%{$config{faculty}{$email}{fields}{courses_assigned}} = ();

		my ($titles_raw, $others) = ("", "");
		my $new_titles = "\\begin{titles}\n";
		if($body =~ m/\\begin\{titles\}\s*\n((?:.|\n)*?)\\end\{titles\}\s*\n((?:.|\n)*?)/g)
		{
			($titles_raw, $others) = ($1, $2);

			# First remove titles and process them separately
			#Util::print_message("Body Antes ...");
			#print Dumper(\$body);
			$body =~ s/\\begin\{titles\}\s*\n((?:.|\n)*?)\\end\{titles\}//g;
			#Util::print_message("Body despues ...");
			#print Dumper(\$body);
			#exit;
			my $count = 0;
			foreach my $line ( split("\n", $titles_raw) )
			{
			    $line =~ s/\n//g; $line =~ s/\r//g;
			    if( $line =~ m/\\(.*?)(\{.*)/g )
			    {
				my ($degreelevel, $tail) = ($1, $2);
				if( not defined($config{degrees}{$degreelevel}) )
				{
				    Util::print_soft_error("I do not recognize this degree level ($email): \"\\$degreelevel\"\n");
				    $new_titles .= $line;
				}
				else
				{
# 				    Util::print_message("Processing $email tail ($tail)");
				    my ($lang, $concentration, $area, $sub_area_specialization, $institution_of_degree, $country, $year) = ("", "", "", "", "", "", "");
				    if( $tail =~ m/\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}/g )
				    {	($lang, $concentration, $area, $sub_area_specialization, $institution_of_degree, $country, $year) = ($1, $2, $3, $4, $5, $6, $7);

					if(not defined($Common::config{dictionaries}{$lang}) )
					{
					      Util::print_warning("Fixing language $lang->$Common::config{SyllabusLangsList}[0] in $line");
					      $lang = $Common::config{SyllabusLangsList}[0];
					}
				    }
				    elsif ( $tail =~ m/\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}/g )
				    {
					($concentration, $area, $sub_area_specialization, $institution_of_degree, $country, $year) = ($1, $2, $3, $4, $5, $6, $7);
					Util::print_warning("Adding language $Common::config{SyllabusLangsList}[0] in $line");
					$lang = $Common::config{SyllabusLangsList}[0];
				    }
				    else{
					Util::print_soft_error("Faculty $email has an error in the degree \\$degreelevel ... $tail\n");
					$new_titles .= $line;
					next;
				    }
				    if( $concentration eq "" )
				    {	$concentration = "Empty";	}
				    if($config{degrees}{$degreelevel} > $config{faculty}{$email}{fields}{degreelevel})
				    {
					  $config{faculty}{$email}{fields}{degreelevel}			= $config{degrees}{$degreelevel};
					  $config{faculty}{$email}{fields}{degreelevel_description}	= $config{degrees_description}{$config{degrees}{$degreelevel}};
					  $config{faculty}{$email}{fields}{prefix} 			= $config{prefix}{$degreelevel};
					  $config{faculty}{$email}{concentration} 			= $concentration;
					  $config{faculty}{$email}{sub_area_specialization}	 	= $sub_area_specialization;
				    }

				    # Add 1 to the counter of Doctors, Magisters, etc
				    if( not defined($config{counters}{$degreelevel}) ) {	$config{counters}{$degreelevel} = 0;}
				    $config{counters}{$degreelevel}++;
				    $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{txt} = "$area, $institution_of_degree, $country, $year.";
				    $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{concentration}	= $concentration;
				    $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{area}		= $area;
				    $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{sub_area_specialization}		= $sub_area_specialization;
				    $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{institution_of_degree}= $institution_of_degree;
				    $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{country}		= $country;
				    $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{year}		= $year;

				    $count++;
				    $new_titles .= "\t\\$degreelevel"."{$lang}{$concentration}{$area}{$sub_area_specialization}{$institution_of_degree}{$country}{$year}\n";
				}
			    }
			    else{ 	$new_titles .= $line;	}
			}
 			if( $count == 0 )
 			{
 				Util::print_soft_error("Professor $email does not contain recognized degrees ...\n")
 			}

			# Second, process the rest of fields such as name, WebPage, Phone, courses, facebook, twitter, etc
			while( $body =~ m/\\(.*?)\{(.*?)\}/g )
			{
			      my ($field, $val) = ($1, $2);
			      $field =~ s/ //g;
			      $field = lc $field;
			      if( $val ne "" )
			      {		$config{faculty}{$email}{fields}{$field} = $val;
			      }
			}
		}
		my $base_lang = $config{SyllabusLangsList}[0];
		foreach my $lang (@{$config{SyllabusLangsList}})
		{
			foreach my $degreelevel (sort {$config{degrees}{$b} <=> $config{degrees}{$a}}
						  keys %{$config{faculty}{$email}{fields}{shortcvline}})
			{
				if( not defined($config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}) )
				{
					%{$config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}} = %{ clone(\%{$config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$base_lang}})};

					my $concentration		= $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{concentration};
					my $area			= $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{area};
					my $sub_area_specialization	= $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{sub_area_specialization};
					my $institution_of_degree	= $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{institution_of_degree};
					my $country		= $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{country};
					my $year			= $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{year};

					$config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{txt} = "$area, $institution_of_degree, $country, $year.";
					$new_titles 	       .= "\t\\$degreelevel"."{$lang}{$concentration}{$area}{$sub_area_specialization}{$institution_of_degree}{$country}{$year}\n";
				}
				if( $Common::config{degrees}{$degreelevel} >= $Common::config{degrees}{MasterPT} )
				{
					my $degree_prefix = "<<".$degreelevel."In>>";
					$config{faculty}{$email}{fields}{shortcv}{$lang}     .= "\\item $degree_prefix $config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{txt}\n";
					$config{faculty}{$email}{fields}{shortcvhtml}{$lang} .= "\t<li>$config{faculty}{$email}{fields}{shortcvline}{$degreelevel}{$lang}{txt}</li>\n";
				}
			}
		}
		#print Dumper(\%{$config{faculty}{$email}{fields}{shortcvline}}); exit;
		$new_titles .= "\\end{titles}";
		$titles_raw = Common::replace_special_chars($titles_raw);
		$copy_input =~ s/\\begin\{titles\}\s*\n$titles_raw\\end\{titles\}/$new_titles/g;
 		#Util::print_message($new_titles);

		if( not defined($config{faculty}{$email}{fields}{courses}) )
		{	$config{faculty}{$email}{fields}{courses} = "";		}
		my $originalListOfCourses = $config{faculty}{$email}{fields}{courses};
		$config{faculty}{$email}{fields}{courses} 			=~ s/ //g;
		%{$config{faculty}{$email}{fields}{courses_assigned}} = ();
		my ($newListOfCourses, $sep) = ("", "");
		foreach my $codcour ( split(",", $config{faculty}{$email}{fields}{courses} ) )
		{
		      if( defined($config{map_file_to_course}{$codcour}) )
		      {
			    $newListOfCourses .= "$sep$config{map_file_to_course}{$codcour}";
		      }
		      else{
			    $newListOfCourses .= "$sep$codcour";
			    if( not defined($course_info{$codcour}) )
			    {	Util::print_warning("$email course: \"$codcour\" is not recognized ! ... just ignoring it !");	}
		      }
		      $sep = ",";
		}

		#print Dumper (%{$config{map_file_to_course}}); exit;
		#$copy_input =~ s/CS111,CS402/CS1100,CS4002/s;
		#Util::print_warning("$email Before: $config{faculty}{$email}{fields}{courses}. After: $newListOfCourses");
		$copy_input =~ s/\\courses\{$originalListOfCourses\}/\\courses\{$newListOfCourses\}/g;
		$config{faculty}{$email}{fields}{courses} = $newListOfCourses;
		foreach my $codcour ( split(",", $config{faculty}{$email}{fields}{courses} ) )
		{	$Common::config{faculty}{$email}{fields}{courses_i_could_teach}{$codcour} = "";
		}
# 		{
# 		      $onecodcour = get_label($onecodcour);
# 		      Util::print_message("get_label($onecodcour)=".get_label($onecodcour));
# 		      $config{faculty}{$email}{fields}{courses_i_could_teach}{$onecodcour} = "";
# 		}
		#Util::print_message("$config{faculty}{$email}{fields}{shortcv}");
	}
	#Util::print_message("$copy_input");
	Util::write_file($faculty_file, $copy_input);
	Util::check_point("read_faculty");
#    	print Dumper(\%{$config{faculty}{"ecuadros\@ucsp.edu.pe"}});
}

our %professor_role_order = ("T" => 1,
			     			 "L" => 2,
			     			 "-" => 3,
			    			);
sub read_distribution()
{
	Util::precondition("set_initial_paths");
	my $distribution_file = get_template("in-distribution-file");
	Util::uncheck_point("read_distribution");
	if( not -e "$distribution_file" )
	{
	    my $distribution_dir = get_template("in-distribution-dir");
	    system("mkdir -p \"$distribution_dir\"");
	    Util::write_file($distribution_file, "");
	    Util::print_warning("read_distribution: \"$distribution_file\" does not exist ... I created a new one :)");
	}
	if( not open(IN, "<$distribution_file") )
	{
	    Util::print_error("read_distribution: I can not open \"$distribution_file\"");
	    exit;
	}

	my $count   = 0;
	my $line_number = 0;
	my $codcour = "";
	my $codcour_alias   = "";
    my %ignored_email = ();
	while(<IN>)
	{
		$line_number++;
		my $line = $_;
		$line =~ s/\r//g;
		if($line =~ m/\s*(.*)\s*->\s*(.*)\s*/)
		{
			$codcour   = $1;
			my $emails = $2;
			$codcour =~ s/\s//g;
			$emails  =~ s/\s//g;
			$codcour_alias = $codcour;
			$codcour = get_label($codcour);

			if( not defined($course_info{$codcour}) )
			{
			      Util::print_error("codcour \"$codcour\" assigned in \"$distribution_file\" does not exist (line: $line_number)... ");
			}
			$codcour = get_alias($codcour);
			if( $codcour eq "" )
			{
			      Util::print_error("$codcour_alias is empty ! codcour=$codcour, $course_info{$codcour}{name}=$course_info{$codcour}{alias}");
			}
#
			if(not defined($config{distribution}{$codcour}))
			{

				$config{distribution}{$codcour} = ();
				#Util::print_message("Initializing $codcour($codcour_alias) ---");
				#Util::print_message("I found professor for course $codcour($codcour_alias): $emails ...");
			}
			#print "\$config{distribution}{$codcour} ... = ";
			my $sequence = 1;
			foreach my $one_professor_assignment ( split(",", $emails) )
			{
				my $professor_email = "";
				my $professor_role  = "-";
				if($one_professor_assignment =~ m/(.*):(.*)/)
				{	$professor_email = $1;
					$professor_role  = $2;
				}
				else{
				      $professor_email = $one_professor_assignment;
				      Util::print_soft_error("distribution error($distribution_file) ... $codcour($codcour_alias):$one_professor_assignment ... no role assigned?");
				}
 				if( defined($config{faculty}{$professor_email}) )
				{
				      if(not defined($config{distribution}{$codcour}{$professor_email}))
				      {		$config{distribution}{$codcour}{$professor_role}{$professor_email} = $sequence;
						    $config{faculty}{$professor_email}{$codcour}{role} = $professor_role;
							$config{faculty}{$professor_email}{$codcour}{sequence} = $sequence;
							$sequence++;
				      }
        		}
				else
				{
				    Util::print_warning("No professor information for email:\"$professor_email\" $codcour($codcour_alias) ... just commenting it");
                    $ignored_email{$codcour}  = "" if(not defined($ignored_email{$codcour}));
                    $ignored_email{$codcour} .= ",$professor_email";
				}
				#print "$professor_email ";
			}

			#print "\$config{distribution}{$codcour} .= ";
			#foreach my $email (%{$config{distribution}{$codcour}})
			#{
			#	print "$email ** ";
			#}
			#print "\n";
		}
		$count++;
	}
	close IN;
	#system("rm $distribution_file");
	my $output_txt = "";
	for(my $semester= 1; $semester <= $config{n_semesters} ; $semester++)
	{
		my $this_sem_text  = "";
		my $this_sem_count = 0;
		my $ncourses       = 0;

		foreach my $codcour (@{$courses_by_semester{$semester}})
		{
			#Util::print_message("Regenerating distribution for $codcour ...");
			$codcour = get_alias($codcour);
			if( not defined($config{distribution}{$codcour}) )
			{
				Util::print_warning("I do not find professor for course $codcour ($codcour_alias) ($semester sem) $course_info{$codcour}{course_name}{$config{language_without_accents}} ...");
			}
			else
			{	my $sep = "";
				$this_sem_text .= "% $codcour. $course_info{$codcour}{course_name}{$config{language_without_accents}} ($config{dictionary}{$course_info{$codcour}{course_type}})\n";
				$this_sem_text .= "$codcour->";
				my $faculty_list_of_emails = "";
				foreach my $role (sort  { $professor_role_order{$a} <=> $professor_role_order{$b} }
						  		  keys %{ $Common::config{distribution}{$codcour}})
				{
					#$config{distribution}{$codcour}{$professor_role}{$professor_email} = $sequence++;
					foreach my $professor_email (sort {$config{faculty}{$b}{fields}{degreelevel} <=> $config{faculty}{$a}{fields}{degreelevel} ||
														$config{faculty}{$a}{$codcour}{sequence} <=> $config{faculty}{$b}{$codcour}{sequence}
													  }
								     			 keys %{$config{distribution}{$codcour}{$role}}
								    )
					{
						$this_sem_text .= "$sep$professor_email:";
						$faculty_list_of_emails .= "$sep$professor_email";
						if(defined($config{faculty}{$professor_email}{$codcour}{role}))
						{	$this_sem_text .= $config{faculty}{$professor_email}{$codcour}{role};	}
						else{	$this_sem_text .= "-";		}

						$sep = ",";
						$config{faculty}{$professor_email}{fields}{active} 			= "Yes";
						$config{faculty}{$professor_email}{fields}{courses_assigned}{$codcour} 	= "";
					}
				}
				Util::print_message("$this_sem_text ...");
				print "\n";
				$this_sem_text .= "\n";
				if( defined($ignored_email{$codcour}) )
				{		$this_sem_text .= "%IGNORED $codcour->$ignored_email{$codcour}\n";			}

				# Set priority among professors
				$config{faculty_list_of_emails}{$codcour} = $faculty_list_of_emails;
				$ncourses++;
			}
		}
		if( $ncourses > 0 )
		{
			$output_txt .= "\n% Semester #$semester .\n";
			$output_txt .= "$this_sem_text\n";
		}
		
	}
	Util::write_file("$distribution_file", $output_txt);
	Util::print_message("read_distribution($distribution_file) OK!");
	Util::check_point("read_distribution");
}

# ok
sub read_aditional_info_for_silabos()
{
	my $file = get_template("in-additional-institution-info-file");
	Util::print_message("Reading $file ...");
	open(IN, "<$file") or return;
	my $codcour = "";
	while(<IN>)
	{
		if(m/\s*(.*)\s*=\s*(.*)/)
		{
			my $label = $1;
			my $body  = $2;
			if( $label eq "COURSE" )
			{	$codcour = $body;	}
			else
			{
				$course_info{$codcour}{extra_tags}{$label} = "\\specialcell{$body}";
				#print "Aditional $codcour > $label=\"$body\"\n";
			}
		}
	}
	close IN;
}

# ok
sub replace_accents_in_file($)
{
	my ($filename) = (@_);
	my $fulltxt = Util::read_file($filename);
	$fulltxt = replace_accents($fulltxt);
	Util::write_file($filename, $fulltxt);
}

# sub read_outcomes_involved($$)
# {
# 	my ($codcour, $fulltxt) = (@_);
#  	if($fulltxt =~ m/\\begin\{outcomes\}\s*((?:.|\n)*?)\\end\{outcomes\}/)
# 	{
# 	    my $body = $1;
# 	    foreach my $line (split("\n", $body))
# 	    {
# 		if($line =~ m/\\ExpandOutcome(.*?)\}\{(.*?)\}/)
# 		{
# 		    $course_info{$codcour}{outcomes}{$1} = $2;
# 		}
# 	    }
# 	}
# }

# # ok
# sub preprocess_syllabus($)
# {
# 	Util::precondition("parse_courses");
# 	my ($filename) = (@_);
# # 	print "filename = $filename\n";
# 	my $codcour = "";
# 	if($filename =~ m/.*\/(.*)\.tex/)
# 	{	$codcour = $1;		}
# 	my @contents;
# 	my $line = "";
#
# 	my $fulltxt = Util::read_file($filename);
# # 	$fulltxt = replace_accents($fulltxt);
# # 	while($fulltxt =~ m/\n\n\n/)
# # 	{	$fulltxt =~ s/\n\n\n/\n\n/g;	}
#
# # 	Util::print_message("Verifying accents in: $codcour, $course_info{$codcour}{course_name}{$Common::config{language_without_accents}}");
# # 	if( not defined($course_info{$codcour}{course_type}) )
# # 	{	print "$codcour\n".Dumper(\%{$course_info{$codcour}}); exit;
# # 	}
# # 	my $codcour_label       = get_alias($codcour);
# # 	my $course_name = $course_info{$codcour}{course_name}{$config{language_without_accents}};
# # 	my $course_type = $Common::config{dictionary}{$course_info{$codcour}{course_type}};
# # 	my $header      = "\n\\course{$codcour_label. $course_name}{$course_type}{$codcour_label} % Common.pm";
# # 	my $newhead 	= "\\begin{syllabus}\n$header\n\n\\begin{justification}";
# # 	$fulltxt 	=~ s/\\begin\{syllabus\}\s*((?:.|\n)*?)\\begin\{justification\}/$newhead/g;
# 	read_outcomes_involved($codcour, $fulltxt);
#
# 	#system("rm $filename");
# 	@contents = split("\n", $fulltxt);
# 	my ($count,$inunit)  = (0, 0);
# 	my $output_txt = "";
# 	foreach $line (@contents)
# 	{
# 		$line =~ s/\\\s/\\/g;
# 		$output_txt .= "$line\n";
# 		$count++;
# 	}
#         my $country_environments_to_insert = $Common::config{"country-environments-to-insert"};
#         $country_environments_to_insert =~ s/<AREA>/$Common::course_info{$codcour}{prefix}/g;
#         #$country_environments_to_insert = "hola raton abc";
#
#         my $newtext = "$country_environments_to_insert\n\n\\begin{coursebibliography}";
#         $output_txt =~ s/\\begin\{coursebibliography\}/$newtext/g;
#
# 	Util::write_file($filename, $output_txt);
#         #Util::print_message($filename); exit;
# }

# ok
# sub replace_special_characters_in_syllabi()
# {
# 	my $base_syllabi = get_template("InSyllabiContainerDir");
#
# # 	foreach my $codcour (@codcour_list_sorted)
# 	foreach my $localdir (@{$config{SyllabiDirs}})
# 	{
# 		my $dir = "$base_syllabi/$localdir";
# 		my @filelist = ();
# 		if( -d $dir )
# 		{	opendir DIR, $dir;
# 			@filelist = readdir DIR;
# 			closedir DIR;
# 		}
# 		else
# 		{
# 			Util::print_error("I can not open directory: $dir ...");
# 		}
# 		foreach my $texfile (@filelist)
# 		{
# 			if($texfile=~ m/(.*)\.tex$/)
# 			{
# # 				my $codcour = $1;
# # 				if(defined($course_info{$codcour}))
# # 				{
#  					preprocess_syllabus("$dir/$texfile");
# # 					generate_prerequisitos($texfile);
# # 				}
# 			}
# 			elsif($texfile=~ m/(.*)\.bib$/)
# 			{
# 				replace_accents_in_file("$dir/$texfile");
# 			}
# 		}
# 	}
# }

sub replace_acronyms($)
{
	my ($label) = (@_);
	foreach my $acro (keys %{$config{dictionary}{Acronyms}})
	{
		$label =~ s/$config{dictionary}{Acronyms}{$acro}/$acro/g;
	}
	return $label;
}

# ok
sub wrap_label($)
{
	my ($label) = (@_);
	$label = replace_acronyms($label);
	$label =~ s/  / /g;
	my @words 		= split(" ", $label);
	my $output 		= "";
	my $acu_length 	= 0;
	my $nwords     	= 0;
	my $sep 		= "";
	my $nlines 		= 1;
	foreach my $word (@words)
	{
		if($acu_length+length($word)+1 > $config{label_size} and $nwords >0)
		{
			$output    .= "\\n";
			$acu_length = 0;
			$nwords 	= 0;
			$nlines++;
			$sep 		= "";
		}
		$nwords++;
		$output     .= "$sep$word";
		$acu_length += length($word)+length($sep);
		$sep 		 = " ";
	}
	return ($output,$nlines);
}

#
# sub change_number_by_text($)
# {
# 	my ($txt) = (@_);
# 	while($txt =~ m/(\d)/)
# 	{
# 		my $digit = $1;
# 		$txt =~ s/$digit/$numbersmap{$digit}/g;
# 	}
# 	$txt =~ s/\./x/g;
# 	return $txt;
# }

sub replace_tags($$$%)
{
 	my ($txt, $before, $after, %map) = (@_);
	my $count = 1;

	while($txt =~ m/$before(.*?)$after/g)
	{
		my $tag=$1;
  # 		print "tag=$tag\n";
		if(defined($map{$tag}))
		{
		      $txt =~ s/$before$tag$after/$map{$tag}/g;
		      if($map{$tag} =~ m/$before$tag$after/g)
		      {
			    Util::print_error("Recursive tag ! $map{$tag} contains \"$before$tag$after\"");
		      }
		      #Util::print_warning("($count) $before$tag$after => $map{$tag}");
		      $count++;
		}
		else
		{
# 		      $txt =~ s/$before$tag$after/** $tag **/g;
		      #Util::print_warning("(replace_tags: $count) There is no translation for tag \"$before$tag$after\"");
		}
# 		if( $count > 50 )
# 		{
# 			print Dumper (\$txt);
# 		}
	}
	return $txt;
}

# ok
sub count_number_of_tags($)
{
	my ($course_line) = (@_);
	my $count = 0;
	while($course_line =~ m/<(.*?)>/g)
	{
		$count++;
	}
	return $count;
}

# ok
sub find_credit_column($)
{
	my ($course_line) = (@_);
	my $count = 1;
	while($course_line =~ m/<<(.*?)>>/g)
	{
		my $tag = $1;
 		#Util::print_message("tag=$tag");
		if($tag eq "CR")
		{
#			Util::print_message("count=$count"); exit;
			return $count;
		}
		$count++;
	}
	#Util::print_message("$course_line"); exit;
	return 1;
}

# ok
sub read_bok_order()
{
	my $file = get_template("in-macros-order-file");
	my $txt  = Util::read_file($file);

	my $count = 0;
	foreach my $line (split("\n", $txt))
	{
		if($line =~ m/(([a-z]|[A-Z])*)/)
		{
			$config{topics_priority}{$1} = $count++;
 		}
	}
	Util::print_message("read_bok_order: $count topics read ...");
}

# my $sql_topic  = "<prefix>INSERT INTO curricula_knowledgetopic(id, \"name\", unit_id, \"topicParent_id\")\n";
#    $sql_topic .= "<prefix>\t\tVALUES (<ctopic>, \'<body>\', <cunit>, <parent>);\n";
#
# sub gen_bok_normal_topic($$$$$)
# {
# 	my ($ctopic, $body, $cunit, $prefix, $parent) = (@_);
# 	while($body =~ m/  /)
# 	{	$body =~ s/  / /g;	}
# 	my $secret = "xyz1y2b3ytr";
# 	$body .= $secret;
#
# # 	print "0:\"$body\"\n"	if($body =~ m/pigeonhole/);
# 	if($body =~ m/(.*) $secret/) #delete spaces at the end
# 	{	$body = "$1$secret";	}
# # 	print "s:\"$body\"\n"	if($body =~ m/pigeonhole/);
#
# 	if($body =~ m/(.*)\.$secret/) #delete the point
# 	{	$body = "$1";		}
# # 	print "p:\"$body\"\n"	if($body =~ m/pigeonhole/);
#
# 	$body =~ s/$secret//g;
# # 	print "f:\"$body\"\n"	if($body =~ m/pigeonhole/);
#
# 	$ctopic++;
# 	my $this_sql = $sql_topic;
# 	$this_sql =~ s/<prefix>/$prefix/g;
# 	$this_sql =~ s/<ctopic>/$ctopic/g;
# 	$this_sql =~ s/<body>/$body/g;
# 	$this_sql =~ s/<cunit>/$cunit/g;
# 	$this_sql =~ s/<parent>/$parent/g;
# 	return ($this_sql, $ctopic);
# }
#
# sub gen_bok_subtopic($$$$$)
# {
# 	my ($ctopic, $body, $cunit, $prefix, $parent) = (@_);
# 	my $this_sql = "";
# 	my $sub_body = "";
#
# 	my @lines = split("\n", $body);
# 	foreach my $line (@lines)
# 	{
# 		if( $line =~ m/\\item\s+(.*?)\.\s*%/)
# 		{
# 			my $sql_tmp = "";
# 			($sql_tmp, $ctopic) = gen_bok_normal_topic($ctopic, $1, $cunit, "$prefix   ", $parent);
# 			$this_sql              .= $sql_tmp;
# 		}
# 	}
# 	return ($this_sql, $ctopic);
# }
#
# sub gen_bok_topic($$$$)
# {
# 	my ($ctopic, $body, $cunit, $prefix) = (@_);
# 	my ($sql, $this_sql) = ("", "");
# 	my $sub_body = "";
# 	if($body =~ m/\s*((?:.|\n)*?)\s*\\begin{inparaenum}\[.*?\]\s*((?:.|\n)*?)\s*\\end{inparaenum}/)
# 	{
# 		$body     = $1;
# 		$sub_body = $2;
#
# # 		print "\"$body\"\n";
# # 		print "\"$sub_body\"";  exit;
# 		($this_sql, $ctopic) = gen_bok_normal_topic($ctopic, $body, $cunit, $prefix, "null");
# 		$sql .= $this_sql;
# 		($this_sql, $ctopic) = gen_bok_subtopic($ctopic, $sub_body, $cunit, "$prefix   ", $ctopic);
# 		$sql .= $this_sql;
# 	}
# 	else
# 	{
# 		($this_sql, $ctopic) = gen_bok_normal_topic($ctopic, $body, $cunit, $prefix, "null");
# 		$sql .= $this_sql;
# 	}
# 	return ($sql, $ctopic);
# }
#
# sub generate_bok_sql($$)
# {
# 	my ($filename, $outfile) = (@_);
# 	my $txt_file = Util::read_file($filename);
# # 	print $txt_file;exit;
# 	my $sql = "";
#
# 	# Config
# 	my $bok_id = 1; #CS=1
# 	my ($carea, $cunit, $ctopic) = (0, 0, 0);
# 	# End config
# 	# Generate areas
# 	my $this_sql = "";
# 	foreach my $area (sort {$areas_priority{$a} <=> $areas_priority{$b}} keys %areas_priority)
# 	{
# 		$carea++;
# 		$this_sql = "INSERT INTO curricula_knowledgearea(id, \"name\", acronym, bok_id)\n";
# 		$this_sql.= "                            VALUES (<id>, \'<name>\', \'<acro>\', <bok_id>);\n";
# 		$this_sql =~ s/<id>/$carea/g;		$this_sql =~ s/<name>/$CS_Areas_description{$area}/g;
# 		$this_sql =~ s/<acro>/$area/g;		$this_sql =~ s/<bok_id>/$bok_id/g;
# 		$sql .= $this_sql;
#
# 	}
# 	$sql .= "\n";
#
# # 	print($sql);
# 	$carea = 0;
# 	my $curr_area = "";
# 	while($txt_file =~ m/\\newcommand{(.*?)}{/g)
# 	{
# 		my $command = $1;
# 		my $body = "";
# 		my $cPar = 1;
# 		while($cPar > 0)
# 		{
# 			$txt_file =~ m/((.|\s))/g;
# 			$cPar++ if($1 eq "{");
# 			$cPar-- if($1 eq "}");
# 			$body .= $1 if($cPar > 0);
# # 			{
# # 				if( $1 eq "\n" )
# # 				{	$body .= "\\n";		}
# # 				else{			}
# # 			}
# 		}
# # 		foreach (split("\n", $body))
# # 		{	print "\"$_\"\n";		}
# # # 		print "\"$body\"";
# # 		exit;
#
# # 		$body =~ s/\. }//g;
# # 		$body =~ s/\.}//g;
# # 		if( $body =~ m/(.*)\.(\s+)/)
# # 		{	$body = $1;		}
# 		my $subarea = "";
# 		if(	$command =~ m/\\(..).+Topic.+/)
# 		{
# 			$subarea = $1;
# 			#Flush existing header text
# 			if($this_sql =~ m/<nhoras>/)
# 			{
# 				$this_sql =~ s/<nhoras>/0/g;
# 				$sql     .= $this_sql;
# 				$this_sql = "";
# 			}
#
# 			#Process this topic
# # 			$this_sql = "   INSERT INTO curricula_knowledgetopic(id, \"name\", unit_id, \"topicParent_id\")\n";
# # 			$this_sql.= "\t\t\tVALUES ($ctopic, \"$body\", $cunit, null);\n";
# 			($this_sql, $ctopic) = gen_bok_topic($ctopic, $body, $cunit, "   ");
# 			$sql      .= $this_sql;
# 		}elsif(	$command =~ m/\\(..).*Hours/)
# 		{
# 			$this_sql =~ s/<nhoras>/$body/g;
# 			$sql     .= $this_sql;
# 			$this_sql = "";
# # 			print "H=$this_sql";exit;
# 		}elsif($command =~ m/\\(..).+Def/ )
# 		{
# 			$subarea = $1;
# 			$this_sql = "";
# 			if(not $subarea eq $curr_area)
# 			{	$carea++;
# 				$curr_area = $subarea;
# 				$this_sql  = "\n";
# # 				print "current_area=$curr_area\n";
# 			}
# 			$cunit++;
# 			$this_sql .= "\n-- $body --\n";
# 			$this_sql .= "INSERT INTO curricula_knowledgeunit(id, \"name\", area_id, hours)\n";
# 			$this_sql .= "\tVALUES ($cunit, \'$body\', $carea, <nhoras>);\n";
# # 			$sql      .= $this_sql;
#
# 		}
# 	}
# 	Util::write_file($outfile, $sql);
# }

# ok
sub remove_only_env($)
{
	my ($text_in) = (@_);
	while($text_in =~ m/\\Only([A-Z]*?)\{/g)
	{
		my $type      = $1;
		my $count = 1;
		my $body1  = "";
		while($count > 0 and $text_in =~ m/(.|\n)/g)
		{
			my $this_char = $1;
			++$count if( $this_char eq "{" );
			--$count if( $this_char eq "}" );
			$body1 .= $this_char if($count > 0 );
		}
		#print "*********************************\n";
		#print "body=<$body>\n";
		#print "*********************************\n";
        my $firstchars = $body1 =~ m/(.....)/g;
		my $body2 = replace_special_chars($body1);
		if( $type eq $institution )
		{
			$text_in =~ s/\\Only$institution\{$body2\}/$body1/g;
			print "\t\ttype =  \"$type\" \n";
            #print "\t\ttype =  \"$type\" processed\n\\Only$institution\{$body2\}\n=>$body1\n";
		}
		else
		{
			$text_in =~ s/\\Only$type\{$body2\}//g;
			#print "\t\ttype =  \"$type\" (X)\n;
		}
	}
	return $text_in;
}

sub remove_only_and_not_env($)
{
	my ($text_in) = (@_);
    foreach my $word ("Not", "Only")
    {
        while($text_in =~ m/\\$word([A-Z]*?)\{/g)
        {
            my $inst  = $1;
            my $count = 1;
            my $body1  = "";
            while($count > 0 and $text_in =~ m/(.|\n)/g)
            {
                my $this_char = $1;
                ++$count if( $this_char eq "{" );
                --$count if( $this_char eq "}" );
                $body1 .= $this_char if($count > 0 );
            }
            #print "*********************************\n";
            #print "body=<$body>\n";
            #print "*********************************\n";
            $body1 =~ m/(..........)/g;
            my $firstchars = $1;
            my $body2 = replace_special_chars($body1);
            #Util::print_message("$word eq \"Not\" && not $inst eq $institution || $word eq \"Only\" && $inst eq $institution");
            if( ($word eq "Not" && not $inst eq $institution) || ($word eq "Only" && $inst eq $institution) )
            {
                $text_in =~ s/\\$word$inst\{$body2\}/$body1/g;
                Util::print_message("\t\tKeeping \\$word$inst\{$firstchars");
            }
            else
            {
                Util::print_message("\t\t\tIgnoring \\$word$inst\{$firstchars");
                $text_in =~ s/\\$word$inst\{$body2\}//g;
            }
            if( $firstchars eq "Test Test ")
            {   Util::print_message("$body2"); }
        }
    }
	return $text_in;
}

# sub replace_Pag_pagerefs($)
# {
# 	my ($text) = (@_);
# 	my $count  = 0;
# 	$text =~ s/\($Common::config{dictionary}{Pag}\.~\\pageref{.*?}\)//g;
# 	return ($text, $count);
# }
#
# sub replace_bok_pagerefs($)
# {
# 	my ($text) = (@_);
# 	my $count  = 0;
# 	if($text =~ m/\\item\s(.*?)\s\($Common::config{dictionary}{Pag}\.\s\\pageref{(.*?)}\)/g)
# 	{
# 		#my ($label1) = ($1);
# 		#print "label=\"$label1\" ... ";
# 		my ($title1, $label1) = ($1, $2);
# 		#print "title=\"$title1\"->\"$label1\"\n";
# 		my $title2 = replace_special_chars($title1);
# 		my $label2 = replace_special_chars($label1);
# 		$text =~ s/\\item\s$title2\s\($Common::config{dictionary}{Pag}\.\s\\pageref{$label2}\)/\\item \\htmlref{$title1}{$label1}/g;
# 		$count++;
# 	}
# 	return ($text, $count);
# }
#
# sub readfile($$)
# {
# 	my ($filename, $area) = (@_);
# 	my $line;
#
# 	if(not -e "$filename")
# 	{
# 		print "readfile: \"$filename\" no existe\n";
# 		return "";
# 	}
# 	open(IN, "<$filename") or die "readfile: $filename no abre \n";
# 	my @lines = <IN>;
# 	close(IN);
# 	my $changes;
# 	my $count = 0;
# 	foreach $line (@lines)
# 	{
# 		my $extratxt = "";
# 		if( $lines[$count] =~ m/^%/)
# 		{	$lines[$count] = "\n"; }
# 		elsif($filename eq "cs-bok-body.tex")
# 		{	($lines[$count], $changes)        = replace_bok_pagerefs($line);
# 		}
# 		elsif($filename eq "cs-tabla.tex" or $filename =~ m/pre\-prerequisites/)
# 		{
# 			($lines[$count], $changes)        = replace_Pag_pagerefs($line);
# 		}
# 		elsif( $lines[$count] =~ m/(^.*)(.)%(.*)/)
# 		{	if($2 eq "\\")
# 			{}
# 			else
# 			{
# 				$lines[$count] = "$1$2\n" ;
# 				#print "$line";
# 			}
# 		}
# 		$count++;
# 	}
# 	my $filetxt = join("", @lines);
# 	$filetxt =~ s/\\setmyfancyheader\s*\n//g;
# 	$filetxt =~ s/\\setmyfancyfoot\s*\n//g;
# 	$filetxt =~ s/\\hrulefill\s*//g;
# 	$filetxt =~ s/\\newcommand{\\siglas}{\\currentinstitution}//g;
# 	$filetxt =~ s/\\renewcommand{\\Only.*\n//g;
# 	$filetxt =~ s/\\renewcommand{\\OtherKeyStones/\\newcommand{\\OtherKeyStones/g;
# 	$filetxt =~ s/\\include{empty}//g;
# 	$filetxt =~ s/\\input{caratula}/\\input{caratula-web}/g;
# 	$filetxt =~ s/\\newcommand{\\currentarea}{.*?}//g;
# 	$filetxt =~ s/\\currentarea/$area/g;
# 	#$filetxt =~ s/\\begin{landscape}//g;
# 	#$filetxt =~ s/\\end{landscape}//g;
# 	$filetxt =~ s/cs-topics-by-course/cs-all-topics-by-course/g;
# 	$filetxt =~ s/cs-outcomes-by-course/cs-all-outcomes-by-course/g;
# 	return $filetxt;
# }

sub clean_file($)
{
	my ($filetxt) = (@_);
	$filetxt .= "\n";
	$filetxt =~ s/\\%/\\PORCENTAGE/g;
	$filetxt =~ s/%.*?\n/\n/g;
	$filetxt =~ s/\\PORCENTAGE/\\%/g;

	$filetxt =~ s/\\setmyfancyheader\s*\n//g;
	$filetxt =~ s/\\setmyfancyfoot\s*\n//g;
	$filetxt =~ s/\\hrulefill\s*//g;
	$filetxt =~ s/\\newcommand\{\\siglas\}\{\\currentinstitution\}//g;
	$filetxt =~ s/\\newcommand\{\\Only.*\n//g;
    $filetxt =~ s/\\newcommand\{\\Not.*\n//g;
# 	$filetxt =~ s/\\renewcommand{\\OtherKeyStones/\\newcommand{\\OtherKeyStones/g;
	$filetxt =~ s/\\include\{empty\}//g;
	$filetxt =~ s/\\input\{caratula\}/\\input\{caratula-web\}/g;
	$filetxt =~ s/\\newcommand\{\\currentarea\}\{.*?\}//g;
	$filetxt =~ s/\\currentarea/$area/g;

	$filetxt =~ s/\\begin\{comment\}\s*(?:.|\n)*?\\end\{comment\}//g;
	#while($filetxt =~ m/\\begin{unit}\s*\n((?:.|\n)*?)\\end{unit}/g)
	#$filetxt =~ s/\\begin{landscape}//g;
	#$filetxt =~ s/\\end{landscape}//g;
# 	$filetxt =~ s/cs-topics-by-course/cs-all-topics-by-course/g;
# 	$filetxt =~ s/cs-outcomes-by-course/cs-all-outcomes-by-course/g;
	return $filetxt;
}

# ok
sub expand_macros($$)
{
	my ($file, $text) = (@_);
	my $macros_changed = 0;

# 	Util::print_message("**************************************************");
	Util::precondition("sort_macros");
	#print "siglas = $config{macros}{siglas} x5";
	if(not defined($config{macros}{siglas}))
	{	Util::halt("\$config{macros}{siglas} does not exit !!!!\n");		}

	my $changes = "";
	my $ctemp = 1;
	while($ctemp > 0)
	{
		$ctemp = 0;
		foreach my $key (sort {length($b) <=> length($a)} keys %{$config{macros}})
		{
# 			$text     =~ s/\\$key/$config{macros}{$key}/g;
			if($text =~ m/\\$key/)
			{
				$text     =~ s/\\$key/$config{macros}{$key}/g;
				$changes .= "\\$key:$config{macros}{$key}\n";
				$macros_changed++;
				$ctemp++;
			}
		}
	}
# 	print ".";
# 	Util::print_message("expand_macros ($file: $macros_changed) saliendo ...");
#  	if($macros_changed < 3)
#  	{	Util::print_message("Macros changed ($macros_changed): \n$changes");	}
	#print "siglas = $config{macros}{siglas} ... x7\n";
	return ($text, $macros_changed);
}

# ok
sub expand($$$)
{
	my ($text, $macro, $key) = (@_);
	my $count = 0;

	$text =~ s/\\Show$macro\{(.*?)}/$1) $config{$key}{$1}/g;
	#print "siglas = $config{macros}{siglas} ... x7\n";
	return ($text, $count);
}

#
sub expand_sub_file($$)
{
	my ($text, $IncludeType) = (@_);
	my $count = 0;
#     print "Expanding sub files 1\n";
    $text  = remove_only_and_not_env($text);
#     print "Expanding sub files 2\n";
#     $text  = remove_not_env($text);
#     print "Expanding sub files 3\n";


	#while($filetxt =~ m/\\begin{unit}{(.*)}{(.*)}\s*\n((?:.|\n)*?)\\end{unit}/g)
	my $prefix = "";
	#my $source_txt = "";
	while($text =~ m/\\$IncludeType\{(.*?)\}/)
	{
		my $sub_file = $1;
		#Util::print_message("Replacing \\$IncludeType\{$sub_file\}");
# 		my $source_txt = "\\\\$IncludeType"."{$sub_file}";
		if($IncludeType eq "\\include")
		{	$prefix = "\\\\newpage\n";	}

		my $JustName = $sub_file;
		$sub_file .= ".tex";
		my $JustNameWithSpecialCharactersReplaced = replace_special_chars($JustName);
		if( $JustName =~ m/.*\/(.*)/ )
		{	$JustName = $1;		}

		if(defined($config{change_file}{$JustName}))
		{
			$sub_file =~ s/$JustName/$config{change_file}{$JustName}/g;
			Util::print_message("Replacing $JustName => $config{change_file}{$JustName} in $sub_file");
		}
		#print "Reading $sub_file ...";
		if( defined($config{except_file}{"$JustName.tex"}) )
		{	print " $sub_file (X): \\$IncludeType\{$JustName\}\n";
			$text =~ s/\\$IncludeType\{$JustNameWithSpecialCharactersReplaced\}//g;
			next;
		}
                if(not -e $sub_file)
                {       Util::print_error("File \"$sub_file\" does not exists ...");    }
		my $sub_file_text = clean_file(Util::read_file($sub_file));
		   $sub_file_text = remove_only_and_not_env($sub_file_text);
#            $sub_file_text = remove_not_env($sub_file_text);
		my $macros_changed = 0;
		#print "$institution: $sub_file ";
		($sub_file_text, $macros_changed) = expand_macros($sub_file, $sub_file_text);
		$count += $macros_changed;
		#print " ($macros_changed macros changed)\n" if($macros_changed > 0);
		#print "\n";
		$text =~ s/\\$IncludeType\{$JustNameWithSpecialCharactersReplaced\}/$prefix$sub_file_text/g;
		$count++;
	}
	return ($text, $count);
}

# ok
sub expand_sub_files($)
{
	my ($text) = (@_);
	my ($count1, $count2) = (0, 0);
	($text, $count1) = expand_sub_file($text, "input");
	($text, $count2) = expand_sub_file($text, "include");
	return ($text, $count1+$count2);
}

sub parse_courses()
{
	Util::precondition("set_initial_configuration");
	my $input_file    = get_template("list-of-courses");
	Util::print_message("Reading courses ($input_file) ...");

 	my $courses_count 		= 0;
	$config{n_semesters}		= 0;

 	my $file_txt = Util::read_file($input_file);
# 	my @lines = split("\n", $files_txt);
# 	if(not open(IN, "<$input_file"))
# 	{  Util::halt("parse_courses: $input_file does not open ...");	}
# 	print Dumper(\%{$config{valid_institutions}});

	my $flag = 0;
	my $active_semester = 0;
	while($file_txt =~ m/\\course(.*)\n/g)
	{
	      my ($course_params) = ($1);
	      $course_params =~ s/\n//g; $course_params =~ s/\r//g;
	      #                       {sem}{course_type}{area_country}{area_pie}{dpto}{cod}{alias}{name} {cr}{th}  {ph}  {lh} {ti}{Tot} {labtype}  {req} {rec} {corq}{grp} {axe} %filter
	      if($course_params =~ m/\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}%(.*)/g)
	      {
		  my ($semester, $course_type, $area, $area_pie, $department)      = ($1, $2, $3, $4, $5);
		  my ($codcour, $codcour_alias, $course_name_es, $course_name_en)  = ($6, $7, $8, $9);
		  my ($credits, $ht, $hp, $hl, $ti, $tot, $labtype)   		       = ($10, $11, $12, $13, $14, $15, $16);
		  my ($prerequisites, $recommended, $coreq, $group)   		       = ($17, $18, $19, $20);
		  my ($axes, $inst_wildcard)			      		               = ($21, $22);
		  my $coursefile = $codcour;

		  #if( $codcour eq "CS221" )	{	$flag = 1; 	Util::print_warning("codcour = $codcour");	}
		  $inst_wildcard =~ s/\n//g; 	$inst_wildcard =~ s/\r//g;
# 		  Util::print_message("$axes");
# 		  Util::print_message("Labtype: $labtype");
# 		  Util::print_message("Wilcard: $inst_wildcard ");

		  my @inst_array        = split(",", $inst_wildcard);
		  my $count             = 0;
		  my $priority 		= 0;
		  if( $active_semester != $semester )
		  {
			$active_semester = $semester;
			print "\n";
			Util::print_color("$semester: ");
		  }
		  foreach my $inst (@inst_array)
		  {
			  if( defined($config{valid_institutions}{$inst}) )
			  {
				$count++;	
				#if( $codcour eq "CS221" )	{	$flag = 1; 	Util::print_warning("codcour = $codcour - $count ");	}
				if($config{filter_priority}{$inst} > $priority)
				{		$priority = $config{filter_priority}{$inst};		}
				#Util::print_message("$inst matches ...");
			  }
			  #else{	Util::print_message("$inst does not match ...");	}
		  }
		  if( $count == 0 ){	 #Util::print_warning("$codcour ignored $inst_wildcard");
			#Util::print_warning("\\course$course_params ignored! (filter:$inst_list{$institution}{filter})");
			next;
		  }

# 		  Util::print_warning("codcour=$codcour, codcour_alias=$codcour_alias ...");
		  if($codcour_alias eq "") {	$codcour_alias = $codcour; 	}
		  else
		  {   $codcour = $codcour_alias;
		      $antialias_info{$codcour_alias} 	= $codcour;
		  }
#  		  Util::print_warning("codcour=$codcour, codcour_alias=$codcour_alias ..."); exit;

# 		  if( $flag == 1 )	{	Util::print_warning("codcour = $codcour");
#  						print Dumper(\%{$course_info{$codcour}});	exit;
# 					}

# 		  my $codcour_alias = get_alias($codcour);
		  if( $course_info{$codcour} ) # This course already exist, then verify if the new course has a higher priority
		  {
 			  Util::print_message("priority = $priority");
 			  Util::print_message("course_info{$codcour}{priority} = $course_info{$codcour}{priority}");
			  #if( defined($course_info{$codcour}{priority}) )
			  #{
			      if( $priority <= $course_info{$codcour}{priority} )
			      {
				      print "\n";
					  if($course_info{$codcour}{semester} != $semester){
						  Util::print_error("Course $codcour (Sem #$course_info{$codcour}{semester},\"$course_info{$codcour}{inst_list}\"), has different semester than $codcour (Sem #$semester, \"$inst_wildcard\")  ... this cant happen... ERROR!!!");
					  }
				      Util::print_warning("Course $codcour (Sem #$course_info{$codcour}{semester},\"$course_info{$codcour}{inst_list}\"), has higher priority than $codcour (Sem #$semester, \"$inst_wildcard\")  ... ignoring the last one !!!");
					  
				      next;
				  }
			  #}
		  }
		  $config{n_semesters} = $semester if($semester > $config{n_semesters});

		  $course_info{$codcour}{coursefile}	= $coursefile;
		  if($axes eq "")
		  {
			  Util::halt("Course $codcour (Sem: $semester) has not area defined, see dependencies");
		  }
		  $courses_count++;
		  #print "wildcards = $inst_wildcard\n";
		  #Util::print_message("coursecode = $codcour, semester = $semester\n");
		  $prerequisites =~ s/ //g;
		  $recommended   =~ s/ //g;
		  $coreq	       =~ s/ //g;

		  $course_info{$codcour}{priority}	= $priority;
		  $course_info{$codcour}{semester}      = $semester;
		  $course_info{$codcour}{course_type}   = $course_type; # $config{dictionary}{$course_type};
		  $course_info{$codcour}{short_type}    = $config{dictionary}{MandatoryShort};
		  $course_info{$codcour}{short_type}	= $config{dictionary}{ElectiveShort} if($course_info{$codcour}{course_type} eq $Common::config{dictionary}{Elective});
		  $course_info{$codcour}{alias}		= $codcour_alias;

		  if(not $codcour_alias eq $codcour)
		  {	print "$codcour_alias($codcour) ";	}
		  else{	print "$codcour ";	}
		  push(@codcour_list_sorted, $codcour);

# 			print ".";
# 		  print "*" if($courses_count % 10 == 0);

		  $course_info{$codcour}{axes}           	= $axes;
		  $course_info{$codcour}{naxes}		= 0;

		  my $prefix = get_prefix($codcour);
		  $course_info{$codcour}{prefix}		= $prefix;

		  # print "coursecode= $codcour, area= $course_info{$codcour}{axe}\n";
# 			$area_priority{$codcour}		= $axes;
		  $course_info{$codcour}{textcolor}	= $config{colors}{$prefix}{textcolor};
		  $course_info{$codcour}{bgcolor}		= $config{colors}{$prefix}{bgcolor};
		  $course_info{$codcour}{course_name}{Espanol} = $course_name_es;
		  $course_info{$codcour}{course_name}{English} = $course_name_en;
		  $course_info{$codcour}{area}		= $area;
		  $course_info{$codcour}{area_pie}	= $area_pie;
		  $course_info{$codcour}{department}	= $department;

		  $course_info{$codcour}{cr}             	= $credits;
		  ($course_info{$codcour}{th}, $course_info{$codcour}{ph}, $course_info{$codcour}{lh})		= (0, 0, 0);
		  $course_info{$codcour}{th}             	= $ht if(not $ht eq "");
		  $course_info{$codcour}{ph}             	= $hp if(not $hp eq "");
		  $course_info{$codcour}{lh}             	= $hl if(not $hl eq "");

		  ($course_info{$codcour}{ti}, $course_info{$codcour}{tot})            = (0, 0);
		  $course_info{$codcour}{ti}                      = $ti if(not $ti eq "");
		  $course_info{$codcour}{tot}                     = $tot if(not $tot eq "");

		  $course_info{$codcour}{labtype}                 = $labtype;
          $course_info{$codcour}{prerequisites}           = $prerequisites;
          foreach my $lang ( @{$config{SyllabusLangsList}} )
		  {
                $course_info{$codcour}{$lang}{full_prerequisites} = []; # # CS101F. Name1 (1st Sem, $Common::config{dictionary}{Pag} 56), CS101O. Name2 (2nd Sem, Pag 87), ...
                $course_info{$codcour}{$lang}{code_name_and_sem_prerequisites} = [];
          }
          $course_info{$codcour}{code_and_sem_prerequisites}	= "";

		  $course_info{$codcour}{prerequisites_just_codes} = "";
		  $course_info{$codcour}{prerequisites_for_this_course}	= [];
		  $course_info{$codcour}{courses_after_this_course} 	= [];
		  $course_info{$codcour}{short_prerequisites}	= ""; # CS101F (1st Sem), CS101O (2nd Sem), ...
# 		  Util::print_warning("codcour=$codcour, $recommended");
		  $course_info{$codcour}{recommended}   		= get_label($recommended);
# 		  Util::print_warning("course_info{$codcour}{recommended}=$course_info{$codcour}{recommended}"); exit;
		  $course_info{$codcour}{corequisites}			= get_label($coreq);
		  $course_info{$codcour}{group}          		= $group;
		  %{$course_info{$codcour}{extra_tags}}			= ();
		  $course_info{$codcour}{inst_list}      		= $inst_wildcard;
		  $course_info{$codcour}{equivalence}			= "";
		  $course_info{$codcour}{specific_evaluation}		= "";
	      }
	      else
	      {
		  Util::print_warning("course: \"\\course$course_params\" does not contain the right # of parameters ...");
	      }
	      #$flag = 0;
	}

# 	close(IN);

	if(not defined($config{SemMin}) and not defined($config{SemMax}) )
	{
	    $config{SemMin} = 1;
	    $config{SemMax} = $config{n_semesters};
	}
	else
	{
	    if( $config{SemMax} > $config{n_semesters} )
	    {	$config{SemMax} = $config{n_semesters};		}
	}

	Util::print_message("");
	Util::print_message("config{SemMin} = $config{SemMin}, config{SemMax} = $config{SemMax}");
	Util::check_point("parse_courses");
	Util::print_message("Read courses = $courses_count ($config{n_semesters} semesters)");
    Util::write_file(Common::get_template("out-nsemesters-file"), "$config{n_semesters}\\xspace");
}

# ok
sub filter_courses($)
{
    my ($langx) = (@_);
	Util::precondition("set_initial_configuration");
	Util::precondition("parse_courses");
	Util::precondition("sort_courses");
	my $input_file    = get_template("list-of-courses");
	Util::print_message("Filtering courses ...");

	$counts{credits}{count} 	= 0;
	$counts{hours}{count} 		= 0;
	%{$config{used_prefix}}		= ();	$config{number_of_used_prefix}	 = 0;
	%{$config{used_area_pie}}	= ();	$config{number_of_used_area_pie} = 0;

	my $courses_count 		= 0;
	my $active_semester 		= 0;
	my $maxE 			= 0;
	my ($elective_axes, $elective_naxes) = ("", 0);
	my $axe 			= "";
	$config{n_semesters}		= 0;

	foreach my $codcour (@codcour_list_sorted)
	{
		my $coursefile = $course_info{$codcour}{coursefile};
		#Util::print_message("config{map_file_to_course}{$coursefile} = $codcour;");
		$config{map_file_to_course}{$coursefile} = $codcour;
	}

	#print Dumper(\@codcour_list_sorted); exit;
	foreach my $codcour (@codcour_list_sorted)
	{
		Util::print_message("codcour()=$codcour");
		my $codcour_label = Common::get_label($codcour);
		if( not defined($course_info{$codcour}{semester}) )
		{
		      print Dumper (\%{$course_info{$codcour}});
		      Util::print_error("codcour=$codcour, semester not defined");
		}
		my $semester = $course_info{$codcour}{semester};

		$config{n_semesters} = $semester if($semester > $config{n_semesters});
		$courses_count++;
		#print "wildcards = $inst_wildcard\n";
		#Util::print_message("coursecode = $codcour, semester = $semester\n");
		#Util::print_message("$codcour($semester),");
		if($active_semester != $semester)
		{
			#print "Active Semester = $active_semester\n";
			if($active_semester != 0)
			{
				foreach $axe (split(",", $elective_axes))
				{	$counts{credits}{areas}{$axe}	+= $maxE/$elective_naxes;	}
				$counts{credits}{count}			+= $maxE;
				#print "contador hasta el $active_semester = $counts{credits}{count}, maxE = $maxE\n";
			}
			$active_semester = $semester;
			$maxE = 0;
		}

		#print_message("Processing coursecode=$codcour ...");
		my $prefix = get_prefix($codcour);
		if(not defined($config{used_prefix}{$prefix}))   # YES HERE
		{
			$config{used_prefix}{$prefix} = "";
			$config{number_of_used_prefix}++;
		}
		my $area_pie = $course_info{$codcour}{area_pie};
		if(not defined($config{used_area_pie}{$area_pie}))   # YES HERE
		{
			$config{used_area_pie}{$area_pie} = "";
			$config{number_of_used_area_pie}++;
		}

		# print "coursecode= $codcour, area= $course_info{$codcour}{axe}\n";
		$course_info{$codcour}{naxes}		= 0;
		foreach $axe (split(",", $course_info{$codcour}{axes}))
		{	$course_info{$codcour}{naxes}++;	}

		foreach $axe (split(",", $course_info{$codcour}{axes}))
		{
		      if(not defined($data{counts_per_standard}{$axe}))
		      {		$data{counts_per_standard}{$axe} 		= 0;
				$list_of_courses_per_axe{$axe}{courses} 	= [];
		      }
		      $data{counts_per_standard}{$axe}     += $course_info{$codcour}{cr}/$course_info{$codcour}{naxes};
		      push(@{$list_of_courses_per_axe{$axe}{courses}}, $codcour);
		}
		if($course_info{$codcour}{course_type} eq "Elective")
		{
			$elective_axes 	= $course_info{$codcour}{axes};
			$elective_naxes = $course_info{$codcour}{naxes};
# 			my $credits = $course_info{$codcour}{cr};
# 			if($credits > $maxE)
# 			{	$maxE = $credits;
# 			}
                        my $group = $Common::course_info{$codcour}{group};
			if( $group eq "" )
                        {
			      Util::print_error("Course $codcour, Sem: $semester has NOT group being elective");
			}
                        if( not defined($config{electives}{$semester}{$group}{cr}) )
                        {
                                $config{electives}{$semester}{$group}{cr}    = $Common::course_info{$codcour}{cr};
                                $config{electives}{$semester}{$group}{prefix}= $Common::course_info{$codcour}{prefix};
                                $config{electives}{$semester}{$group}{area_pie} = $Common::course_info{$codcour}{area_pie};
                                #Util::print_message("config{electives}{$semester}{$group}{cr}=$config{electives}{$semester}{$group}{cr}");
                                #$electives{$group}{prefix}= $Common::course_info{$codcour}{prefix};
                                $counts{credits}{prefix}{$prefix}     += $Common::course_info{$codcour}{cr};
                                $counts{credits}{area_pie}{$area_pie} += $Common::course_info{$codcour}{cr};
                        }
                        else
                        {       #Util::halt("config{electives}{$semester}{$group}{cr}=$electives{$group}{cr},  Common::course_info{$codcour}{cr}=$Common::course_info{$codcour}{cr}");
                                #Util::print_message("electives{$group}{prefix}=$electives{$group}{prefix}, Common::course_info{$codcour}{prefix}=$Common::course_info{$codcour}{prefix}");
                        }
		}
		if($course_info{$codcour}{course_type} eq "Mandatory")
		{
			#Util::print_message("codcour=$codcour, cr=$toadd");
			foreach $axe (split(",", $course_info{$codcour}{axes}))
			{	$counts{credits}{areas}{$axe} += $course_info{$codcour}{cr}/$course_info{$codcour}{naxes};
				#print "$axe -> $course_info{$codcour}{cr}/$course_info{$codcour}{naxes}\n" if($codcour eq "CS225T");
			}
			$counts{credits}{count}	      += $course_info{$codcour}{cr};
			$counts{credits}{prefix}{$prefix}     += $Common::course_info{$codcour}{cr};
			$counts{credits}{area_pie}{$area_pie} += $Common::course_info{$codcour}{cr};
		}
		#print "codcour = $codcour, cr=$course_info{$codcour}{cr}, ($course_info{$codcour}{course_type}) $counts{credits}{count}, maxE = $maxE\n";
		#print "contador hasta el $active_semester = $counts{credits}{count}, maxE = $maxE\n";

		my $sep 		= "";
		$course_info{$codcour}{n_prereq} = 0;
		my $new_prerequisites = "";
		foreach my $codreq (split(",", $course_info{$codcour}{prerequisites}))
		{
					$codreq =~ s/ //g;
					if($codreq =~ m/(.*?)=(.*)/)
					{
		                my ($inst, $prereq) = ($1, $2);
		                if( $inst eq $institution)
		                {
							$new_prerequisites .= "$sep$inst=$prereq";
		                    $course_info{$codcour}{prerequisites_just_codes} .= "$sep$inst=$prereq";
		                    foreach my $lang ( @{$config{SyllabusLangsList}} )
		                    {       push(@{$course_info{$codcour}{$lang}{full_prerequisites}}, $prereq);
		                            push(@{$course_info{$codcour}{$lang}{code_name_and_sem_prerequisites}}, $prereq );
		                    }
		                    $course_info{$codcour}{short_prerequisites}         .= "$sep$prereq";
		                    $course_info{$codcour}{code_and_sem_prerequisites}  .= "$sep$prereq";
		                    push( @{$course_info{$codcour}{prerequisites_for_this_course}}, "$sep$inst=$prereq");
		                    $course_info{$codcour}{n_prereq}++;
							$codreq = $prereq;
		                }
		                else
		                {	 	Util::print_warning("It seems that course $codcour ($semester$config{dictionary}{ordinal_postfix}{$semester} $config{dictionary}{Sem}) has an invalid req ($codreq) ... ignoring");

						}
					}
					else
		      {
				  Util::print_message("codcour=$codcour,codreq=$codreq");
				          $codreq = get_label($codreq);
						  Util::print_message("codcour=$codcour,codreq=$codreq");
						$new_prerequisites .= "$sep$codreq";
				          $course_info{$codcour}{prerequisites_just_codes} .= "$sep$codreq";
				          if(defined($course_info{$codreq}))
				          {
				              my $codreq_label = Common::get_label($codreq);
				              #Util::print_message("codreq=$codreq, codreq_label=$codreq_label");
				              my $semester_prereq = $course_info{$codreq}{semester};

							
				              foreach my $lang ( @{$config{SyllabusLangsList}} )
				              {
				                      push(@{$course_info{$codcour}{$lang}{full_prerequisites}}, get_course_link($codreq, $lang));
				                      my $temp  = "\\htmlref{$codreq. $course_info{$codreq}{course_name}{$lang}}{sec:$codcour_label}.~";
				                         $temp .= "($semester_prereq\$^{$config{dictionaries}{$lang}{ordinal_postfix}{$semester_prereq}}\$~$config{dictionary}{Sem})";

				                      push( @{$course_info{$codcour}{$lang}{code_name_and_sem_prerequisites}}, $temp );
				              }

				              $course_info{$codcour}{short_prerequisites}        .= "$sep\\htmlref{$codreq_label}{sec:$codreq_label} ";
				              $course_info{$codcour}{short_prerequisites}        .= "(\$$semester_prereq^{$config{dictionary}{ordinal_postfix}{$semester_prereq}}\$~";
				              $course_info{$codcour}{short_prerequisites}        .= "$config{dictionary}{Sem})";
				              $course_info{$codcour}{code_and_sem_prerequisites} .= "$sep\\htmlref{$codreq_label}{sec:$codreq_label} ";
				              $course_info{$codcour}{code_and_sem_prerequisites} .= "(\$$semester_prereq^{$config{dictionary}{ordinal_postfix}{$semester_prereq}}\$~";
				              $course_info{$codcour}{code_and_sem_prerequisites} .= "$config{dictionary}{Sem})";

				              push( @{$course_info{$codcour}{prerequisites_for_this_course}}, $codreq);
				              push( @{$course_info{$codreq}{courses_after_this_course}}, $codcour);
				              $course_info{$codcour}{n_prereq}++;
				          }
				          else
				          {
				              print Dumper(\%{$course_info{$codcour}});
				              Util::halt("parse_courses: Course $codcour (sem #$semester) has a prerequisite \"$codreq\" not defined");
				          }
		      }
					$sep = ",";
		}
		$course_info{$codcour}{prerequisites} = $new_prerequisites;
		#if( $codcour eq "FG601" )
		#{		Util::print_message("course_info{$codcour}{prerequisites}=$course_info{$codcour}{prerequisites}, new=$new_prerequisites");
		#		exit;
		#}
#                 print Dumper( \%{$Common::course_info{$codcour}} );
#                 Util::print_message("Common::course_info{$codcour}{n_prereq} = $Common::course_info{$codcour}{n_prereq}");
#                 #print Dumper( \%{$config{map_file_to_course}} );
#                 Util::print_message("parse_courses(): prerequisites=$course_info{$codcour}{prerequisites},label=". get_label($course_info{$codcour}{prerequisites}));
#                 exit;

		if($course_info{$codcour}{n_prereq} == 0)
		{	    foreach my $lang ( @{$config{SyllabusLangsList}} )
                {   $course_info{$codcour}{$lang}{full_prerequisites} = $config{dictionary}{None};	}
        }
		# Hours Accumulator
		my $hours = 0;
		$hours += $course_info{$codcour}{th} if( not $course_info{$codcour}{th} eq "" );
		$hours += $course_info{$codcour}{ph} if( not $course_info{$codcour}{ph} eq "" );
		$hours += $course_info{$codcour}{lh} if( not $course_info{$codcour}{lh} eq "" );

		foreach $axe (split(",", $course_info{$codcour}{axes}))
		{
			if(not defined($counts{hours}{areas}{$axe}))
			{	$counts{hours}{areas}{$axe} = 0;		}
			$counts{hours}{areas}{$axe} += $hours/$course_info{$codcour}{naxes};
		}
		$counts{hours}{count} += $hours;
#         if( $codcour eq "CS2101" )
#         {
#                 print Dumper( \%{$Common::course_info{$codcour}} );
#                 Util::print_message("Common::course_info{$codcour}{n_prereq} = $Common::course_info{$codcour}{n_prereq}");
#                 #print Dumper( \%map );
#                 # $config{map_file_to_course}{$coursefile} = $codcour;
#                 print Dumper( \%{$config{map_file_to_course}} );
#                 exit;
#         }
	}

	foreach $axe (split(",", $elective_axes))
	{	$counts{credits}{areas}{$axe}	+= $maxE/$elective_naxes;	}
	$counts{credits}{count}		 	+= $maxE;

	my $semester;
	for($semester=1; $semester <= $config{n_semesters} ; $semester++)
	{	$config{semester_electives}{$semester} = ();		}

	for($semester=1; $semester <= $config{n_semesters} ; $semester++)
	{
                $config{credits_this_semester}{$semester} = 0;

		foreach my $codcour (@{$courses_by_semester{$semester}})
		{
                        if($course_info{$codcour}{course_type} eq "Mandatory")
                        {
                              assert($course_info{$codcour}{group} eq "");
                              $Common::config{credits_this_semester}{$semester} += $course_info{$codcour}{cr};
                              #Util::print_message("Sem=$semester,acu=$Common::config{credits_this_semester}{$semester}, course_info{$codcour}{cr}=$course_info{$codcour}{cr}");
                        }
                        else
                        {
                            assert(not $course_info{$codcour}{group} eq "");
                            my $group = $course_info{$codcour}{group};
                            if( not defined($config{semester_electives}{$semester}{$group}{list}) )
                            {	$config{semester_electives}{$semester}{$group}{list} = [];	}
                            push(@{$config{semester_electives}{$semester}{$group}{list}}, $codcour);
                        }
			foreach $axe (split(",", $course_info{$codcour}{axes}))
			{
			      if(not defined($list_of_courses_per_area{$axe}))
			      {	$list_of_courses_per_area{$axe} = [];	}
			      push(@{$list_of_courses_per_area{$axe}}, $codcour);
                              $counts{credits}{areas}{$axe} += $course_info{$codcour}{cr}/$course_info{$codcour}{naxes};
			      #Util::print_message("codcour=$codcour, axe=$axe");
			}

		}
                #Util::print_message("config{credits_this_semester}{$semester}=$config{credits_this_semester}{$semester}");
                if( defined($config{electives}{$semester}) )
                {
                      foreach my $group (keys %{$config{electives}{$semester}})
                      {
                          #Util::print_message("config{electives}{$semester}{$group}{cr} = $config{electives}{$semester}{$group}{cr}");
                          $config{credits_this_semester}{$semester}                    += $config{electives}{$semester}{$group}{cr};
                      }
                }
                #Util::print_message("config{credits_this_semester}{$semester}=$config{credits_this_semester}{$semester}");
	}
	if($courses_count < 1)
	{
	      Util::halt("It seems that I did not read many courses ($courses_count) ... verify file \"$input_file\" ...");
	}
	$config{ncourses} = $courses_count;
	Util::check_point("filter_courses");
	Util::print_message("Read courses = $courses_count ($config{n_semesters} semesters)");
#     print Dumper( \%{$config{map_file_to_course}} );
#     exit;
}

sub sort_courses()
{
	@codcour_list_sorted = sort {$Common::course_info{$a}{semester} <=> $Common::course_info{$b}{semester} ||
 				     $Common::config{prefix_priority}{$Common::course_info{$a}{prefix}} <=> $Common::config{prefix_priority}{$Common::course_info{$b}{prefix}} ||
 				     $Common::course_info{$b}{course_type} cmp $Common::course_info{$a}{course_type} ||
					   $a cmp $b
				}
				@codcour_list_sorted;
	#@{$Common::courses_by_semester{$semester}})
        #$codcour_label
	#print Dumper(\@codcour_list_sorted); exit;
	foreach my $codcour (@codcour_list_sorted)
	{
	      my $semester = $course_info{$codcour}{semester};
	      #Util::print_message("$codcour, Sem:$course_info{$codcour}{semester}");
	      if(not defined($courses_by_semester{$semester}))
		{	$courses_by_semester{$semester} = [];		}
		push(@{$courses_by_semester{$semester}}, $codcour);
	}
	Util::check_point("sort_courses");
}

sub get_list_of_bib_files()
{
    Util::precondition("gen_syllabi");
    my $syllabus_container_dir 	= Common::get_template("InSyllabiContainerDir");
    for(my $semester = 1; $semester <= $Common::config{n_semesters}; $semester++)
    {
	foreach my $codcour (@{$Common::courses_by_semester{$semester}})
	{
# 		Util::print_message("codcour = $codcour, bibfiles=$Common::course_info{$codcour}{bibfiles}");
		foreach (split(",", $Common::course_info{$codcour}{bibfiles}))
		{
			$Common::config{allbibfiles}{"$syllabus_container_dir/$_"} = "";
		}
	}
    }
    my ($all_bib_items, $sep) = ("", "");
    foreach my $bibfile (keys %{$Common::config{allbibfiles}})
    {
	$all_bib_items .= "$sep$bibfile";
	$sep = ",";
    }
    return $all_bib_items;
}

sub read_min_max($$)
{
	my ($SpiderChartInfoDir,$standard) = (@_);
	my $input_file = "$SpiderChartInfoDir/$standard-MinMax.tex";
	my $filetxt = Util::read_file("$input_file");

	Util::print_message("read_min_max: reading $input_file");
	# This accumulator is only to calculate the final % compared with the total
	$config{StdInfo}{$standard}{min} = 0;
	$config{StdInfo}{$standard}{max} = 0;
	my $axe;
	foreach $axe (split(",", $config{SpiderChartAxes}))
	{
		$config{StdInfo}{$standard}{$axe}{min} = 0;
		$config{StdInfo}{$standard}{$axe}{max} = 0;
	}

	while($filetxt =~ m/\\topic\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}/g)
	{
		$axe = $1;
		$config{StdInfo}{$standard}{$axe}{min} += $3;
		$config{StdInfo}{$standard}{$axe}{max} += $4;

		# This accumulator is only to calculate the final % compared with the total
		$config{StdInfo}{$standard}{min} += $3;
		$config{StdInfo}{$standard}{max} += $4;
	}
}

sub read_all_min_max()
{
	my $SpiderChartInfoDir = get_template("SpiderChartInfoDir");
	foreach (split(",", $config{Standards}))
	{
		read_min_max($SpiderChartInfoDir, $_);
	}
	Util::print_message("read_all_min_max() OK!");
}

# ok
sub replace_generic_environments($$$$$)
{
	my ($text, $env_name, $label_text, $label_type, $new_env_name) = (@_);
	my $count  = 0;
	#Replace environment
	#print "(2) $env_name being processed ... \n" if($env_name eq "outcomes");
	while($text =~ m/\\begin\{$env_name\}\s*\n((.|\t|\s|\n)*?)\\end\{$env_name\}/g)
	{
 		#print "(3) $env_name processed OK !\n" if($env_name eq "outcomes");
		$count++;
		my $env_body_in  = $1;
		my $env_body_out = $env_body_in;
		$env_body_in = replace_special_chars($env_body_in);
		my $out_text = "\\$label_type\{$label_text\}";
		$text =~ s/\\begin\{$env_name\}\s*\n$env_body_in\\end\{$env_name\}/$out_text\n\\begin\{$new_env_name\}\n$env_body_out\\end\{$new_env_name\}/g;
	}
	return ($text, $count);
}

# ok
sub replace_bold_environments($$$$)
{
	my ($text, $env_name, $label_text, $label_type) = (@_);
	my $count  = 0;
	#Replace Sumillas
	while($text =~ m/\\begin\{$env_name\}\s*\n((?:.|\n)*?)\\end\{$env_name\}/g)
	{
		my $env_body_in = $1;
		my $env_body_out = $env_body_in;
		#print "### ($count)\n$env_body\n---\n";
		$env_body_in = Common::replace_special_chars($env_body_in);
		my $text_out = "\\$config{subsection_label}"."{$label_text}\n\n$env_body_out";
		$text =~ s/\\begin\{$env_name\}\s*\n$env_body_in\\end\{$env_name\}/$text_out/g;
		#print "*";
		$count++;
	}
	return ($text, $count);
}

sub replace_enumerate_environments($$$$)
{
	my ($text, $env_name, $label_text, $label_type) = (@_);
	my $count = 0;
	#print "(1) $env_name being processed ... $env_name, $label_text, $label_type,\n";
	($text, $count) = replace_generic_environments($text, $env_name, $label_text, $label_type, "enumerate");
	#print "(3) $env_name being processed ... $env_name, $label_text, $label_type,   (text, $count)\n";
	return ($text, $count);
}

sub replace_description_environments($$$$)
{
	my ($text, $env_name, $label_text, $label_type) = (@_);
	#print "(1) $env_name being processed ...\n" if($env_name eq "outcomes");
	return replace_generic_environments($text, $env_name, $label_text, $label_type, "description");
}

sub check_preconditions()
{
	for(my $semester = 1; $semester <= $Common::config{n_semesters}; $semester++)
	{
                foreach my $codcour ( @{$Common::courses_by_semester{$semester}} )
		{
			#Util::print_message("$codcour=>\"$Common::course_info{$codcour}{prefix}\"");
			if(not defined($Common::config{prefix_priority}{$Common::course_info{$codcour}{prefix}}))
			{
				my $area_all_config = get_template("in-area-all-config-file");
				Util::print_error("Course $codcour has an unknown prefix \"$Common::course_info{$codcour}{prefix}\" ... VERIFY $area_all_config");
			}
		}
	}
}

sub change_number_by_text($)
{
      my ($label) = (@_);
      my $count = 0;
      $count = $label =~ s/(\d)/$Numbers2Text{$1}/g;
      #Util::print_message($count);
      return $label;
}

sub generate_course_info_in_dot($$$)
{
	my ($codcour, $this_item, $lang) = (@_);
	print "$codcour ...\n";
	#if($codcour eq "60Cr") {assert(0);}
	my %map = ();

	$map{CODE}	= $codcour;
	my $codcour_name = $course_info{$codcour}{course_name}{$config{language_without_accents}};
	my ($newlabel,$nlines) = wrap_label("$codcour. $codcour_name");
	my @height = (0, 0, 0.6, 0.9, 1.2, 1.5);
# 	my $height = 0.3*$nlines+0.1*($nlines-1) + 0.3*$config{extralevels}+0.05*($config{extralevels}-1);
	$map{FULLNAME}	= $newlabel;
# 	Util::print_message("$nlines+$config{dictionary}{extralevels}");
	$map{HEIGHT}	= 0.3*($nlines+$config{dictionary}{extralevels});
	$map{FONTCOLOR}	= $course_info{$codcour}{textcolor};

	if($config{graph_version} >= 2)
	{
		if( $course_info{$codcour}{short_type} eq $config{dictionary}{MandatoryShort})
		{	$map{PERIPHERIES}	= 2;
			$map{SHAPE}			= "record";
		}
		else
		{	$map{PERIPHERIES}	= 1;
			$map{SHAPE}			= "Mrecord";
		}
		$map{SHORTTYPE}	= $course_info{$codcour}{short_type};
	}
	$map{BORDERCOLOR} = "white";
	$map{FILLCOLOR}	= $course_info{$codcour}{bgcolor};
	$map{CR}		= $course_info{$codcour}{cr};

	if($course_info{$codcour}{th} > 0)
	{		$map{HT}	= $course_info{$codcour}{th};	}
	else{	$map{HT}	= "";	}
	if($course_info{$codcour}{ph} > 0)
	{		$map{HP}	= $course_info{$codcour}{ph};	}
	else{	$map{HP}	= "";	}
	if($course_info{$codcour}{lh} > 0)
	{		$map{HL}	= $course_info{$codcour}{lh};	}
	else{	$map{HL} 	= "";	}

	$map{NAME}	= $course_info{$codcour}{course_name}{$lang};
	$map{TYPE}	= $config{dictionary}{$course_info{$codcour}{course_type}};
	$map{PAGE}	= "--PAGE$codcour--";

	my ($outcome_txt, $sep) = ("", "");
	foreach my $outcome (@{$course_info{$codcour}{outcomes_array}})
	{	$outcome_txt	.= "$sep\\outcome{$outcome}";
		$sep 		 = ",";
	}
	$map{OUTCOMES}	= $outcome_txt;
	return replace_tags($this_item, "<", ">", %map);
}

sub generate_course_info_in_dot_with_sem($$$)
{
	my ($codcour, $this_item, $lang) = (@_);
	my $output_txt = generate_course_info_in_dot($codcour, $this_item, $lang);

	my $sem_label = "$Common::course_info{$codcour}{semester}$Common::config{dictionary}{ordinal_postfix}{$Common::course_info{$codcour}{semester}} $Common::config{dictionary}{Sem}";
# 	$output_txt  =~ s/\(<SEM>\)/\($sem_label\)/g;
	return $output_txt;
}

sub update_page_numbers($)
{
	my ($file)     = (@_);
        Util::precondition("read_pagerefs");
	my $file_txt  = Util::read_file($file);
# 	Util::print_message("update_page_numbers: replacing $file ... pages replaced ok !");
	#$file_txt =~ s/--PAGEFG102--/$Common::config{pages_map}{"sec:FG102"}/g;
	while( $file_txt =~ m/--PAGE(.*?)--/)
	{
		my $course = $1;
		#Util::print_message("Replacing $course ...");
		if( defined($Common::config{pages_map}{"sec:$course"}) )
		{	$file_txt =~ s/--PAGE$course--/$Common::config{pages_map}{"sec:$course"}/g;	}
		else
		{	$file_txt =~ s/--PAGE$course--/  /g;	}
 	}
	#$file_txt =~ s/--PAGE(.*?)--/$Common::config{pages_map}{"sec:$1"}/g;
	foreach my $outcome (keys %{$Common::config{outcomes_map}})
	{
# 		Util::print_message("Outcome: $outcome being replaced ...");
		$file_txt =~ s/\\outcome\{$outcome\}/$Common::config{outcomes_map}{$outcome}/g;
	}
# 	print Dumper(\%{$Common::config{outcomes_map}});
	Util::write_file($file, $file_txt);
	Util::print_message("File $file ... pages replaced ok !");
}

sub update_page_numbers_for_all_courses_maps()
{
	my $OutputDotDir  = Common::get_template("OutputDotDir");
	foreach my $codcour (@codcour_list_sorted)
	{
		Common::update_page_numbers("$OutputDotDir/$codcour.dot");
	}
}

our %bok = ();
sub parse_bok($)
{
	my ($lang) = (@_);
	my ($bok_in_file) = (Common::get_template("in-bok-macros-V0-file"));
	$bok_in_file =~ s/<LANG>/$lang/g;
 	Util::print_message("Processing $bok_in_file ...");
	my $bok_in = Util::read_file($bok_in_file);
	my $output_txt = "";

	my %counts = ();
	my $KAorder = 0;
	while($bok_in =~ m/\\(.*?)\{(.*?)\}/g)
	{
	    my ($cmd, $ka)  = ($1, $2);
	    if($cmd eq "KA") # \KA{AL}{<<Algoritmos y Complejidad>>}{crossref}
	    {
		$bok_in =~ m/\{<<(.*?)>>\}\{(.*?)\}/g;
		my ($body, $crossref)  = ($1, $2);
		if( $body =~ m/(.*)\.$/ )
		{	$body = $1;	}

		$bok{$lang}{$ka}{name} 	= $body;
		$bok{$lang}{$ka}{order} 	= $KAorder++;
		($bok{$lang}{$ka}{nhTier1}, $bok{$lang}{$ka}{nhTier2}) = (0, 0);
		$counts{$cmd}++;

		#if( not $crossref eq "" )
		#{	Util::print_message("Area: $ka, cros$bok_output_filesref: \"$crossref\"");		}
 		#Util::print_message("$body");
	    }
	    elsif( $cmd eq "KADescription")
	    {
		$bok_in =~ m/{<<((.|\n)*?)>>}/g;
		my ($body)  = ($1);
# 		if( $body =~ m/(.*)\.$/ )
# 		{	$body = $1;	}

		$bok{$lang}{$ka}{description} = $body;
		$counts{$cmd}++;
	    }
	    elsif( $cmd eq "KU") # \KU{AL}{BasicAnalysis}{<<Análisis Básico>>}{}{#hours Tier1}{#hours Tier2}
	    {
		$bok_in =~ m/\{(.*?)\}\{<<(.*?)>>\}\{(.*?)\}\{(.*?)\}\{(.*?)\}/g;
		my ($p2, $body, $crossref, $nhTier1, $nhTier2)  = ($1, $2, $3, $4, $5);
		if( $body =~ m/(.*)\.$/ )
		{	$body = $1;	}

		my $ku 			= "$ka$p2";
		%{$bok{$lang}{$ka}{KU}{$ku}} 	= ();
		my $KUPos 		= scalar keys %{$bok{$lang}{$ka}{KU}};
		$bok{$lang}{$ka}{KU}{$ku}{name}= $ku;
		$bok{$lang}{$ka}{KU}{$ku}{order}= $KUPos;
		$bok{$lang}{$ka}{KU}{$ku}{body} = $body;
		$bok{$lang}{$ka}{KU}{$ku}{nhTier1} 	 = $nhTier1;
		#Util::print_message("bok{$ka}{nhTier1} 		+= $nhTier1;");
		$bok{$lang}{$ka}{nhTier1} 		+= $nhTier1;
		$bok{$lang}{$ka}{KU}{$ku}{nhTier2} 	 = $nhTier2;
		$bok{$lang}{$ka}{nhTier2} 		+= $nhTier2;

		$ku_info{$lang}{$ku}{ka} 	= $ka;
		$ku_info{$lang}{$ku}{nhTier1}	= $nhTier1;
		$ku_info{$lang}{$ku}{nhTier2}	= $nhTier2;

		$counts{$cmd}++;
# 		Util::print_message("KU ($ka, $ku, $KUPos, $crossref, Tier1=$nhTier1, Tier2=$nhTier2) ...");
	    }
	    elsif( $cmd eq "KUDescription") # \KUDescription{AL}{BasicAnalysis}{<<~>>}
	    {
		$bok_in =~ m/\{(.*?)\}\{<<((.|\n)*?)>>\}/g;
		my ($p2, $body)  = ($1, $2);
		#if( $body =~ m/(.*)\.$/ )
		#{	$body = $1;	}

		my $ku			= "$ka$p2";
		$bok{$lang}{$ka}{KU}{$ku}{description}= $body;
		$counts{$cmd}++;
# 		Util::print_message("KU ($ka, $ku, KUDescription) ...");
	    }
	    elsif( $cmd eq "KUItem") # \KUItem{AL}{BasicAnalysis}{Core-Tier2}{Recurrence}{crossrefs}{<<Relaciones recurrentes \begion{topic} ... \n \end{topic}.>>}
	    {
		$bok_in =~ m/\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{<<((.|\n)*?)>>\}/g;
		my ($kubase, $tier, $kuposfix, $crossref, $body)  = ($1, $2, $3, $4, $5);
		#if( $body =~ m/(.*)\.$/ )
		#{	$body = $1;	}

		my $ku 			= "$ka$kubase";
		my $kuitem		= $ku."Topic".$kuposfix;
		my $KUItemPos 		= scalar keys %{$bok{$lang}{$ka}{KU}{$ku}{items}{$tier}};
		$bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{body}  = $body;
		$bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{order} = $KUItemPos;
# 		$crossref =~ s/\s//g;
		$bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{crossref} = $crossref;
# 		if( not $bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{crossref} eq "" )
# 		{	Util::print_message("kuitem = $kuitem, bok{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{crossref} = $bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{crossref} ... ");
# 			exit;
# 		}
		$counts{$cmd}++;

		#Util::print_message("$cmd, $ka, $kubase, $kuposfix, $tier, $body ...");
	    }
	    elsif( $cmd eq "LO") # \LO{AL}{BasicAnalysis}{Core-Tier1}{Familiarity}{State}{<<Indique la definicion formal de Big O.>>}
	    {
		$bok_in =~ m/\{(.*?)\}\{(.*?)\}\{(.*?)\}\{(.*?)\}\{<<((.|\n)*?)>>\}/g;
		my ($kubase, $tier, $lolevel, $kuposfix, $body)  = ($1, $2, $3, $4, $5);
		if( $body =~ m/(.*)\.$/ )
		{	$body = $1;	}

		my $ku 			= "$ka$kubase";
		my $LOitem		= $ku."LO".$kuposfix;
		my $LOItemPos 		= scalar keys %{$bok{$lang}{$ka}{KU}{$ku}{LO}{$tier}};
		$bok{$lang}{$ka}{KU}{$ku}{LO}{$tier}{$LOitem}{body}  	= $body; 		# $tier = Core-Tier1, Core-Tier2, Elective
		$bok{$lang}{$ka}{KU}{$ku}{LO}{$tier}{$LOitem}{lolevel} = $lolevel; 		# $lolevel = Familiarity
		$bok{$lang}{$ka}{KU}{$ku}{LO}{$tier}{$LOitem}{order} 	= $LOItemPos;
		$counts{$cmd}++;
		#Util::print_message("$cmd, $ka, $kubase, $kuposfix, $tier, $lolevel ...");
		#Util::print_message("KU ($ka, $ku, $KUPos) ...");
	    }
	    #Util::print_message("Processing macro #$count: $cmd ...");
	}
	foreach (keys %counts)
	{	Util::print_message("counts{$_} = $counts{$_} ...");	}
	Util::check_point("parse_bok");
	#print Dumper(\%bok);
	#Util::print_message("parse_bok($bok_in_file) $count macros processed ... OK!");
	#Util::print_message("bok{SE}{order} = $bok{$lang}{SE}{order}");
# 	Util::print_message("bok{$lang}");
# 	foreach my $key (keys %{$bok{Espanol}{SP}{KU}})
# 	{	Util::print_warning("key=$key");	}
 	#print Dumper (\%{$Common::bok{"Espanol"}{DS}{KU}});
 	#exit;
}

sub format_ku_label($$)
{
	my ($lang, $ku) = (@_);
	my $ka = $Common::ku_info{$lang}{$ku}{ka};

	my $ku_label = "$ka \\$bok{$lang}{$ka}{KU}{$ku}{name}";
	my $nhours_txt = "";
	my $sep = "";

	#my $ku_line = "\\ref{sec:BOK:$ku_macro} \\htmlref{\\$ku_macro}{$Common::config{ref}{$ku}}\\xspace ($Common::config{dictionary}{Pag}.~\\pageref{sec:BOK:$ku_macro}) & <CORETIER1> & <CORETIER2> & <ELECTIVES> \\\\ \\hline\n";
	#$bok_index_txt .= "\\item \\ref{sec:BOK:$ku_macro} \\htmlref{\\$ku_macro}{sec:BOK:$ku_macro}\\xspace ($Common::config{dictionary}{Pag}.~\\pageref{sec:BOK:$ku_macro})\n";
	if( $bok{$lang}{$ka}{KU}{$ku}{nhTier1} > 0 )
	{	$nhours_txt .= "$sep$bok{$lang}{$ka}{KU}{$ku}{nhTier1} $Common::config{dictionary}{hours} Core-Tier1";	$sep = ",~";
	}
	if( $bok{$lang}{$ka}{KU}{$ku}{nhTier2} > 0 )
	{	$nhours_txt .= "$sep$bok{$lang}{$ka}{KU}{$ku}{nhTier2} $Common::config{dictionary}{hours} Core-Tier2";	$sep = ",~";
	}

	if( not $nhours_txt eq "" )
	{	$ku_label .= " ($nhours_txt)";
	}
	return $ku_label ;
}

sub gen_bok($)
{
	my ($lang) = (@_);
	Util::precondition("parse_bok");
	#foreach my $key (sort {$config{degrees}{$b} <=> $config{degrees}{$a}} keys %{$config{faculty}{$email}{fields}{shortcvline}})
	my $macros_txt = "";
	my $bok_index_txt = "";
	my $bok_output_txt = "";

	$bok_index_txt .= "\\begin{multicols}{2}\n";
	$bok_index_txt .= "\\scriptsize\n";
	$bok_index_txt .= "\\noindent\n";
	my ($max_ntopics, $maxLO) = (0, 0);
	my $topics_priority = 0;
	foreach my $ka (sort {$bok{$lang}{$a}{order} <=> $bok{$lang}{$b}{order}} keys %{$bok{$lang}})
	{
		#til::print_message("Generating KA: $ka (order=$bok{$lang}{$ka}{order} ...)");
		my $macro = $ka;
		$macros_txt .= "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
		$macros_txt .= "% Knowledge Area: $ka\n";
		$macros_txt .= "\\newcommand{\\$macro}{$bok{$lang}{$ka}{name} ($ka)\\xspace}\n";

		$bok_output_txt .= "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
		$bok_output_txt .= "% Knowledge Area: $ka\n";
		$bok_output_txt .= "\\section{\\$macro}\\label{sec:BOK:$ka}\n";
		$bok_index_txt .= "{\\bf \\ref{sec:BOK:$ka} \\htmlref{\\$macro}{sec:BOK:$ka}\\xspace ($Common::config{dictionary}{Pag}.~\\pageref{sec:BOK:$ka})}\n";
		my $hours_by_ku_file = "$ka-hours-by-ku";

		$macro = $ka."BOKDescription";
		$macros_txt .= "\\newcommand{\\$macro}{$bok{$lang}{$ka}{description}\\xspace}\n\n";
		$bok_output_txt .= "\\$macro\n\n";

		my $hours_by_ku_rows = "";
		$bok_output_txt .= "\\input{\\OutputTexDir/$hours_by_ku_file}\n";

# 		my $ku 			= "$ka$p2";
# 		%{$bok{$lang}{$ka}{KU}{$ku}} 	= ();
# 		my $KUPos 		= scalar keys %{$bok{$lang}{$ka}{KU}};
# 		$bok{$lang}{$ka}{KU}{$ku}{name}= $ku;
# 		$bok{$lang}{$ka}{KU}{$ku}{order}= $KUPos;
		#Util::print_message("");
		$bok_index_txt .= "\\begin{itemize}\n";
		foreach my $ku (sort {$bok{$lang}{$ka}{KU}{$a}{order} <=> $bok{$lang}{$ka}{KU}{$b}{order}}
				keys %{$bok{$lang}{$ka}{KU}})
		{
		      #print Dumper(\%{$bok{$lang}{$ka}{KU}{$ku}});
		      #Util::print_message("bok{$ka}{KU}{$ku}{order} = $bok{$lang}{$ka}{KU}{$ku}{order}");
		      $Common::config{topics_priority}{$ku} = $topics_priority++;

		      my $ku_macro = "$bok{$lang}{$ka}{KU}{$ku}{name}";
		      $macros_txt .= "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
		      $macros_txt .= "% KU: $ka:$bok{$lang}{$ka}{KU}{$ku}{body}\n";
		      $macros_txt .= "\\newcommand{\\$ku_macro}{$bok{$lang}{$ka}{KU}{$ku}{body}\\xspace}\n";

		      my ($nhours_txt, $sep) = ("", "");
		      #Util::print_message("bok{$ka}{KU}{$ku}{nhTier1}=$bok{$lang}{$ka}{KU}{$ku}{nhTier1} ...");
		      $Common::config{ref}{$ku} = "sec:BOK:$ku_macro";
		      my $ku_line = "\\ref{sec:BOK:$ku_macro} \\htmlref{\\$ku_macro}{$Common::config{ref}{$ku}}\\xspace ($Common::config{dictionary}{Pag}.~\\pageref{sec:BOK:$ku_macro}) & <CORETIER1> & <CORETIER2> & <ELECTIVES> \\\\ \\hline\n";
		      $bok_index_txt .= "\\item \\ref{sec:BOK:$ku_macro} \\htmlref{\\$ku_macro}{sec:BOK:$ku_macro}\\xspace ($Common::config{dictionary}{Pag}.~\\pageref{sec:BOK:$ku_macro})\n";
		      if( $bok{$lang}{$ka}{KU}{$ku}{nhTier1} > 0 )
		      {		$nhours_txt .= "$sep$bok{$lang}{$ka}{KU}{$ku}{nhTier1} $Common::config{dictionary}{hours} Core-Tier1";	$sep = ",~";
				$ku_line     =~ s/<CORETIER1>/$bok{$lang}{$ka}{KU}{$ku}{nhTier1}/g;
		      }
		      if( $bok{$lang}{$ka}{KU}{$ku}{nhTier2} > 0 )
		      {		$nhours_txt .= "$sep$bok{$lang}{$ka}{KU}{$ku}{nhTier2} $Common::config{dictionary}{hours} Core-Tier2";	$sep = ",~";
				$ku_line     =~ s/<CORETIER2>/$bok{$lang}{$ka}{KU}{$ku}{nhTier2}/g;
		      }

		      if( defined($bok{$lang}{$ka}{KU}{$ku}{items}{Elective}) )
		      {		$ku_line     =~ s/<ELECTIVES>/$Common::config{dictionary}{Yes}/g;      }
		      else{ 	$ku_line     =~ s/<ELECTIVES>/$Common::config{dictionary}{No}/g;	}
		      $ku_line =~ s/<CORETIER.?>/~/g;

		      $hours_by_ku_rows .= $ku_line;

		      if( not $nhours_txt eq "" )
		      {		$nhours_txt = "~($nhours_txt)";	}

		      $bok_output_txt .= "\\subsection{$ka/\\$ku_macro$nhours_txt}\\label{sec:BOK:$ku_macro}\n";

		      my $ku_description_macro = "$bok{$lang}{$ka}{KU}{$ku}{name}Description";
		      $bok{$lang}{$ka}{KU}{$ku}{description} =~ s/_/\\_/g;

		      $macros_txt .= "\\newcommand{\\$ku_description_macro}{$bok{$lang}{$ka}{KU}{$ku}{description}\\xspace}\n";
		      if( not $bok{$lang}{$ka}{KU}{$ku}{description} eq "~" )
		      {  	$bok_output_txt .= "\\$ku_description_macro\\\\\n";	}

		      #my $kuitem		= $ku."Topic".$p3;
# 		      $bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{body}  = $body;
# 		      $bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{order} = $KUItemPos;
		      my $level 	= "";
		      my $level_txt 	= "";
		      #$bok{$lang}{$ka}{KU}{$ku}{items}{$tier}{$kuitem}{body}
		      my $alltopics = "";
		      $bok_output_txt .= "\\noindent {\\bf $Common::config{dictionary}{Topics}:}\\\\\n";
		      foreach my $level (sort {$a cmp $b}
				         keys %{$bok{$lang}{$ka}{KU}{$ku}{items}})
		      {
				#Util::print_message("Generating $level ...");
				my $list_of_items = "";
			       	foreach my $kuitem (sort { $bok{$lang}{$ka}{KU}{$ku}{items}{$level}{$a}{order} <=> $bok{$lang}{$ka}{KU}{$ku}{items}{$level}{$b}{order} }
						    keys %{$bok{$lang}{$ka}{KU}{$ku}{items}{$level}} )
				{
					$bok{$lang}{$ka}{KU}{$ku}{items}{$level}{$kuitem}{crossref} =~ s/\s//g;
					my $xref_txt = "";
					if( not $bok{$lang}{$ka}{KU}{$ku}{items}{$level}{$kuitem}{crossref} eq "" )
					{
						#Util::print_message("bok{$ka}{KU}{$ku}{items}{$level}{$kuitem}{crossref} = $bok{$lang}{$ka}{KU}{$ku}{items}{$level}{$kuitem}{crossref} ... ");
						my $sep = "";
						foreach my $xref (split(",", $bok{$lang}{$ka}{KU}{$ku}{items}{$level}{$kuitem}{crossref}))
						{	$xref_txt .= "$sep\\xref{$xref}";
							$sep = ", ";
						}
						#Util::print_message("xref_txt = $xref_txt"); exit;
					}
					if( not $xref_txt eq "" )
					{	$xref_txt = "\\xspace \\\\ {\\bf Ref:} $xref_txt";		}
					$list_of_items .= "\t\\item \\$kuitem$xref_txt\\label{sec:BOK:$kuitem}\n";
					$macros_txt	.= "\\newcommand{\\$kuitem}{$bok{$lang}{$ka}{KU}{$ku}{items}{$level}{$kuitem}{body}\\xspace}\n";
					$alltopics 	.= "\t\\item \\$kuitem\\xspace\n";
					#$macros_txt	.= "\\newcommand{\\$kuitem"."Level}{$level}\n";
				}
				$bok_output_txt .= "\\noindent {\\bf $Common::config{dictionary}{$level}}\n";
				$bok_output_txt .= "\\begin{itemize}\n";
				$bok_output_txt .= $list_of_items;
				$bok_output_txt .= "\\end{itemize}\n\n";
				$macros_txt	.= "\n";
		      }
		      $macros_txt	.= "\\newcommand{\\$ku_macro"."AllTopics}{%\n";
		      $macros_txt	.= "\\begin{topics}%\n";
		      $macros_txt	.= $alltopics;
		      $macros_txt	.= "\\end{topics}\n}\n";
		      $bok_output_txt .= "\n";

		      #$bok{$lang}{$ka}{KU}{$ku}{LO}{$p4}{$LOitem}{body}  = $body; 	# $p4 = Familiarity
		      #$bok{$lang}{$ka}{KU}{$ku}{LO}{$p4}{$LOitem}{order} = $LOItemPos;
		      my $all_lo = "";
		      $bok_output_txt .= "\\noindent {\\bf $Common::config{dictionary}{LearningOutcomes}:}\\\\\n";
		      my $count_of_items = 0;
		      foreach my $level (sort {	$bok{$lang}{$ka}{KU}{$ku}{LO}{$a} cmp $bok{$lang}{$ka}{KU}{$ku}{LO}{$b} }
				         keys %{$bok{$lang}{$ka}{KU}{$ku}{LO}})
		      {
				$bok_output_txt .= "\\noindent {\\bf $level:}\n";
				my $all_the_items = "";
				my $count_of_items_local = 0;
			       	foreach my $loitem (sort { $bok{$lang}{$ka}{KU}{$ku}{LO}{$level}{$a}{order} <=> $bok{$lang}{$ka}{KU}{$ku}{LO}{$level}{$b}{order} }
						    keys %{$bok{$lang}{$ka}{KU}{$ku}{LO}{$level}} )
				{
					$all_the_items .= "\t\\item \\$loitem\\xspace[\\".$loitem."Level]\\label{sec:BOK:$loitem}\n";
					$macros_txt	.= "\\newcommand{\\$loitem}{$bok{$lang}{$ka}{KU}{$ku}{LO}{$level}{$loitem}{body}\\xspace}\n";
					my $loitemlevel  = $loitem."Level";
					my $thisloitemlevel = $Common::config{dictionaries}{$lang}{$bok{$lang}{$ka}{KU}{$ku}{LO}{$level}{$loitem}{lolevel}};
					$macros_txt	.= "\\newcommand{\\$loitemlevel}{$thisloitemlevel}\n";
					$all_lo 	.= "\t\\item \\$loitem\\xspace[\\".$loitem."Level] %\n";
					$count_of_items_local++;
				}
				$bok_output_txt .= "\\begin{enumerate}\n";
				$bok_output_txt .= "\t\\setcounter{enumi}{$count_of_items}\n";
				$bok_output_txt .= $all_the_items;
				$bok_output_txt .= "\\end{enumerate}\n";
				$count_of_items += $count_of_items_local;
				$macros_txt	.= "\n";
		      }
		      $macros_txt	.= "\\newcommand{\\$ku_macro"."AllLearningOutcomes}{%\n";
		      $macros_txt	.= "\\begin{learningoutcomes}%\n";
		      $macros_txt	.= $all_lo;
		      $macros_txt	.= "\\end{learningoutcomes}%\n}\n\n";
		      $bok_output_txt .= "\n\n";
		} # ku loop
		$bok_index_txt .= "\\end{itemize}\n\n";

		$macros_txt     .= "\n\n";
		$bok_output_txt .= "\n\n";

		$hours_by_ku_file = Common::get_template("OutputTexDir")."/$hours_by_ku_file.tex";
		#Util::print_message("Generating $hours_by_ku_file ...");
		my $hours_by_ku_table = "\\begin{center}\n";
		$hours_by_ku_table .= "\\begin{tabularx}{\\textwidth}{|X|p{1cm}|p{1cm}|p{1.4cm}|}\\hline\n";
		$hours_by_ku_table .=  "{\\bf \\acf{KA}} & {\\bf ".$Common::config{dictionary}{"Core-Tier1"}."} & {\\bf ".$Common::config{dictionary}{"Core-Tier2"}."} & {\\bf $Common::config{dictionary}{Elective}} \\\\ \\hline\n";
		$hours_by_ku_table .=  $hours_by_ku_rows;
		$hours_by_ku_table .= "\\end{tabularx}\n";
		$hours_by_ku_table .= "\\end{center}\n";

		Util::write_file($hours_by_ku_file, $hours_by_ku_table);
	}
	$bok_index_txt .= "\\end{multicols}\n";

	my $bok_index_file = Common::get_template("out-bok-index-file");
	Util::print_message("Creating BOK index file ($bok_index_file) ...");
	Util::write_file($bok_index_file, $bok_index_txt);

	my $bok_output_file = Common::get_template("out-bok-body-file");
	Util::print_message("Creating BOK file ($bok_output_file) ...");
	Util::write_file($bok_output_file, $bok_output_txt);

	my $bok_macros_output_file = Common::get_template("in-bok-macros-file");
	$bok_macros_output_file =~ s/<LANG>/$lang/g;
	Util::print_message("Creating BOK macros file ($bok_macros_output_file) ...");
	Util::write_file($bok_macros_output_file, $macros_txt);

	Util::check_point("generate_bok");
# 	Util::write_file();
 	#print Dumper(\%{$Common::config{topics_priority}});
}

sub generate_books_links()
{
	my $output_links = "";
	my $tabs = "\t\t";
	my $poster_link	 = <<"TEXT";
		<CENTER>
		<TABLE BORDER=0 BORDERCOLOR=RED>
		<TR> <TD colspan="3" align="center"> <a href="$config{area}-$config{institution}-poster.pdf">
		      <IMG SRC="$config{area}-$config{institution}-poster.png" border="1" ALT="Ver p&oacute;ster de toda la carrera en PDF" height ="280"><BR>P&oacute;ster</a>
		      </TD>
		</TR>
		</TABLE>
TEXT
	$output_links .= $poster_link;
	foreach my $book ("Syllabi", "Bibliography", "Descriptions")
	{
	      $output_links .= "$tabs<TABLE>\n";
	      $output_links .= "$tabs<TR>\n";
	      my $book_link = "";
	      foreach my $lang (@{$Common::config{SyllabusLangsList}})
	      {
		    my $lang_prefix 	 = $Common::config{dictionaries}{$lang}{lang_prefix};
		    my $BookTitle = special_chars_to_html("$config{dictionaries}{$lang}{BookOf} $config{dictionaries}{$lang}{$book}");
		    $book_link .= "$tabs\t<TD align=\"center\">\n";
		    $book_link .= "$tabs\t\t<A HREF=\"BookOf$book-$lang_prefix.pdf\">\n";
		    $book_link .= "$tabs\t\t<IMG SRC=\"BookOf$book-$lang_prefix-P1.png\" BORDER=\"1\" BORDERCOLOR=RED ALT=\"$BookTitle\" height=\"500\"><br>$BookTitle\n";
		    $book_link .= "$tabs\t\t".get_language_icon($lang)."\n";
		    $book_link .= "$tabs\t\t</A>\n";
		    $book_link .= "$tabs\t</TD>\n";
	      }
	      $output_links .= $book_link;
	      $output_links .= "$tabs</TR>\n";
	      $output_links .= "$tabs</TABLE>\n";
 	      $output_links .= "$tabs<BR>\n";
	      $output_links .= "$tabs<BR>\n\n";
	}
	$output_links .= "</CENTER>";
	return $output_links;
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

sub generate_faculty_info()
{
	Util::precondition("read_distribution");
 	%{$Common::config{faculty_icons}{before}} = ("shortcvhtml" => "<ul>\n",
						     "email" => "<img style=\"width: 16px; height: 16px;\" title=\"email\" alt=\"email\" src=\"icon/email.png\">",
						     "emailwithoutat" => "<img style=\"width: 16px; height: 16px;\" title=\"email\" alt=\"email\" src=\"icon/email.png\">\n\t<img style=\"height: 16px;\" title=\"email\" alt=\"email\" src=\"fig/",
						     "phone" => " <img style=\"width: 16px; height: 16px;\" title=\"phone\" alt=\"phone\" src=\"icon/phone.png\">",
						     "mobile" => " <img style=\"width: 16px; height: 16px;\" title=\"mobile\" alt=\"mobile\" src=\"icon/mobile.png\">",
					         "office" => " <img style=\"width: 16px; height: 16px;\" title=\"office\" alt=\"office\" src=\"icon/office.png\"> ",
						     "webpage" => "  <a title=\"Webpage\" href=\"",
					         "facebook" => " <a title=\"Facebook\" href=\"",
						     "twitter" => " <a title=\"Twitter\" href=\"https://www.twitter.com/",
						     "blog" => " <a title=\"Blog\" href=\"",
					         "research" => " <img style=\"width: 16px; height: 16px;\" title=\"email\" alt=\"email\" src=\"icon/research.png\">",
					         "courses" => " <img style=\"width: 16px; height: 16px;\" title=\"email\" alt=\"email\" src=\"icon/courses.png\">",
					         "list_of_courses_assigned" => "<b>Courses assigned:</b>\n<ul>\n",
					         "other_courses_he_may_teach" => "<b>Other courses he/she can teach:</b>\n<ul>\n"
	);
	%{$Common::config{faculty_icons}{after}}  = ("shortcvhtml" => "\t</ul>",
						     "email" => "",
						     "emailwithoutat" => ".png\">",
						     "phone" => "<br>",
						     "mobile" => "",
						     "office" => "<br>",
					             "webpage"  => "\"> <img style=\"width: 16px; height: 16px;\" title=\"webpage\" alt=\"webpage\" src=\"icon/webpage.png\">Webpage</a> ",
					             "facebook" => "\"> <img style=\"width: 16px; height: 16px;\" title=\"facebook\" alt=\"facebook\" src=\"icon/facebook.png\"></a> ",
						     "twitter" => "\"> <img style=\"width: 16px; height: 16px;\" title=\"twitter\" alt=\"twitter\" src=\"icon/twitter.png\"></a> ",
						     "blog" => "\"> <img style=\"width: 16px; height: 16px;\" title=\"blog\" alt=\"blog\" src=\"icon/blog.png\"></a> ",
					             "research" => "",
					             "courses" => "",
					             "list_of_courses_assigned" => "</ul>\n",
					             "other_courses_he_may_teach" => "</ul>\n"
	);

	my $faculty_tpl_file 		= Common::get_template("faculty-template.html");

	$Common::config{faculty_tpl_txt}= Util::read_file($faculty_tpl_file);

	$Common::config{InFacultyPhotosDir} 		= Common::get_template("InFacultyPhotosDir");
	$Common::config{InFacultyIconsDir}		= Common::get_template("InFacultyIconsDir");
	$Common::config{NoFaceFile}			= Common::get_template("NoFace-file");
	$Common::config{OutputFacultyDir} 		= Common::get_template("OutputFacultyDir");

	#my $faculty_output_general_txt 	= "<table style=\"width: 600px;\" border=\"0\" align=\"center\">\n";
	my $faculty_output_general_txt 	= "\n";
	my $faculty_general_output 	= Common::get_template("faculty-general-output-html");
	my $email = "";
	Util::print_message("Generating faculty file: $faculty_general_output  ...");

	# 1st verify if all professors have concentration ...
	my $count_of_errors = 0;
	my $concentration_rank = 100;
	foreach $email (keys %{$Common::config{faculty}})
	{
	      my $concentration = $Common::config{faculty}{$email}{concentration};
	      if($concentration eq "" or not defined($Common::config{sort_areas}{$concentration}) )
	      {		Util::print_warning("Professor $email:  I do not recognize this concentration area (\"$concentration\") ...");
			$count_of_errors++;
			$Common::config{faculty}{$email}{concentration_rank} 	= $concentration_rank;
			$Common::config{sort_areas}{$concentration} 		= $concentration_rank++;
	      }
	      else{
			$Common::config{faculty}{$email}{concentration_rank} = $Common::config{sort_areas}{$concentration};
	      }
	}

	if($count_of_errors > 0)
	{	Util::print_warning("Some professors ($count_of_errors in total) have not concentration area or have invalid ones ...");		}

	# 2nd sort them by areas, degreelevel, name
	my @faculty_sorted_by_priority = sort {  ($Common::config{faculty}{$a}{concentration_rank} <=> $Common::config{faculty}{$b}{concentration_rank}) ||
			     ($Common::config{faculty}{$b}{fields}{degreelevel} <=> $Common::config{faculty}{$a}{fields}{degreelevel}) ||
			     ($Common::config{faculty}{$a}{fields}{name} cmp $Common::config{faculty}{$b}{fields}{name})
			  } keys %{$Common::config{faculty}};
	my $concentration 		= "";
	my $degreelevel;

	# 3rd Generate information for each professor
	my $OutputFacultyIconDir = Common::get_template("OutputFacultyIconDir");
	system("cp $Common::config{InFacultyIconsDir}/*.png $OutputFacultyIconDir");
	foreach $email ( @faculty_sorted_by_priority )
	{
	    my $this_professor = generate_information_4_professor($email);
	    if( scalar (keys %{$Common::config{faculty}{$email}{fields}{courses_assigned}}) > 0 )
	    {	      $faculty_output_general_txt .= $this_professor;		}
	}

	# 4th Generate information for the main index of professors by area, etc
# 	push(@{$Common::config{faculty_groups}{$concentration}{$degreelevel}}, $email);

# my @faculty_sorted_by_priority = sort {  ($Common::config{sort_areas}{$Common::config{faculty}{$a}{concentration}} <=> $Common::config{sort_areas}{$Common::config{faculty}{$b}{concentration}}) ||
# 			     ($Common::config{faculty}{$b}{fields}{degreelevel} <=> $Common::config{faculty}{$a}{fields}{degreelevel}) ||
# 			     ($Common::config{faculty}{$a}{fields}{name} cmp $Common::config{faculty}{$b}{fields}{name})
# 			  } keys %{$Common::config{faculty}};

# 	print Dumper (\%{$Common::config{faculty_groups}});
	foreach $concentration (keys %{$Common::config{faculty_groups}})
	{
	      if(not defined($Common::config{sort_areas}{$concentration}) )
	      {		Util::print_warning("Concentration area \"$concentration\" not defined ...");		}
	}

	my $index_of_professors = "<table border=\"1\" align=\"center\">\n";
	foreach $concentration (sort {$Common::config{sort_areas}{$a} <=> $Common::config{sort_areas}{$b}} keys %{$Common::config{faculty_groups}})
 	{	$index_of_professors .= "<th>$concentration</th>\n";		}


	$index_of_professors .= "<tr>\n";
 	foreach $concentration (sort {$Common::config{sort_areas}{$a} <=> $Common::config{sort_areas}{$b}} keys %{$Common::config{faculty_groups}})
 	{
	      $index_of_professors .= "<td>\n";
	      foreach $degreelevel ( sort {$b <=> $a} keys %{$Common::config{faculty_groups}{$concentration}} )
	      {
		    my $count = 0;
		    my $this_group_txt = "";
		    foreach $email ( @{$Common::config{faculty_groups}{$concentration}{$degreelevel}} )
		    {
			  if( scalar (keys %{$Common::config{faculty}{$email}{fields}{courses_assigned}}) > 0 )
			  {
				$this_group_txt .= "<li>";
				$this_group_txt .= "<a href=\"#$Common::config{faculty}{$email}{fields}{emailwithoutat}\">";
				$this_group_txt .= "$Common::config{faculty}{$email}{fields}{prefix} $Common::config{faculty}{$email}{fields}{name}";
				$this_group_txt .= "</a>";
				$this_group_txt .= "</li>\n";
				$count++;
			  }
		    }
		    if( $count > 0 )
		    {
			$index_of_professors .= "<ul>\n";
			$index_of_professors .= $this_group_txt;
			$index_of_professors .= "</ul>\n";
		    }
	      }
	      #$Common::config{faculty}{$email}{fields}{anchor}

	      $index_of_professors .= "</td>\n";
 	}
 	$index_of_professors .= "</tr>\n";
 	$index_of_professors .= "</table>\n";

	Util::print_message("Generating file: $faculty_general_output ...");
	#$faculty_output_general_txt 	.= "</table>\n";
	$faculty_output_general_txt 	.= "\n";
	my $html_output  = "<h2 id=\"top\"></h2>";
	   $html_output .= "$index_of_professors\n";
	   $html_output .= "$faculty_output_general_txt";

	Util::write_file($faculty_general_output, $html_output);
	Util::check_point("generate_faculty_info");
	Util::print_message("generate_faculty_info OK! ...");
}

sub generate_link_for_courses()
{
      my $html_index 	= Common::get_template("output-curricula-html-file");
      if( not -e $html_index )
      {		Util::print_error("File $html_index does not exist ! ... Run latex2html first ... ");
      }
      Util::print_message("Reading $html_index");
      my $html_file_input 	= Util::read_file($html_index);

      for(my $semester= 1; $semester <= $Common::config{n_semesters} ; $semester++)
      {
	    Util::print_message("Sem: $semester");
	    foreach my $codcour (@{$Common::courses_by_semester{$semester}})
	    {
		  if(defined($Common::antialias_info{$codcour}))
		  {	$codcour = $Common::antialias_info{$codcour}	}
		  my $courselabel = Common::get_alias($codcour);
		  my $link = "";
#                 <A NAME="tex2html315" HREF="4_1_CS105_Estructuras_Discr.html"><SPAN CLASS="arabic">4</SPAN>.<SPAN CLASS="arabic">1</SPAN> CS105. Estructuras Discretas I (Obligatorio)</A>

		  $Common::course_info{$codcour}{link} = "";
# 		  <A NAME="tex2html972"
#   HREF="5_65_CS3P2_Cloud_Computing_.html"><SPAN CLASS="arabic">5</SPAN>.<SPAN CLASS="arabic">65</SPAN> CS3P2. Cloud Computing (Obligatorio)</A>
		  #print Dumper(\$Common::course_info{$codcour}{course_name}{$Common::config{language_without_accents}});
		  my $course_type = $Common::config{dictionary}{$Common::course_info{$codcour}{course_type}};
		  my $coursefullname = "$courselabel. $Common::course_info{$codcour}{course_name}{$Common::config{language_without_accents}} ($course_type)";

		  printf("Searching link for: %-s ", $coursefullname);
# 		  while( $html_file =~ m/HREF="(.*?$courselabel.*?html)">/g)
# 		  {
# 		      $link = $1;
# 		      Util::print_soft_error("$link");
# 		  }
		  #exit;
		  my $html_file = $html_file_input;
		  if( $html_file =~ m/HREF="(.*?$courselabel.*?html)">/g)
		  {
			$link = $1;
			$Common::course_info{$codcour}{link} = $link;

			Util::print_success("$link");
# 			Util::print_message("codcour=$codcour ($Common::config{dictionary}{$Common::course_info{$codcour}{course_type}}), link = $link");
		  }
		  else
		  {
		        Util::print_error("Not found ($Common::course_info{$codcour}{semester} Sem) ... ");
		        #exit;
		  }
		  #print "\n";
	    }
       }
      print "\n";
#       exit;
}

sub process_courses()
{
    parse_courses();
# 	print Dumper(\%{$course_info{"MA102"}});
	sort_courses();
	filter_courses($config{language_without_accents});
}

sub setup()
{
	print "\x1b[44m***********************************************************************\x1b[49m\n";
	print "\x1b[44m**                     Curricula generator                           **\x1b[49m\n";
	print "\x1b[44m***********************************************************************\x1b[49m\n";

	set_initial_configuration($Common::command);

	read_pagerefs();
	process_courses();

	$Common::config{parallel} 	= 0;
}

sub shutdown()
{
	print "\x1b[44m***********************************************************************\x1b[49m\n";
	print "\x1b[44m**                     Finishing                                     **\x1b[49m\n";
	print "\x1b[44m***********************************************************************\x1b[49m\n";
}

1;

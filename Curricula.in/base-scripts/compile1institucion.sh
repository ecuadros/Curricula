#!/bin/csh
set pdfparam=$1
set htmlparam=$2
set syllabiparam=$3
set pdf=0
set html=0
set syllabi=0

if($pdfparam == "y" || $pdfparam == "Y" || $pdfparam == "yes" || $pdfparam == "Yes" || $pdfparam == "YES") then
    set pdf=1
else if($pdfparam == "n" || $pdfparam == "N" || $pdfparam == "no" || $pdfparam == "No" || $pdfparam == "NO") then
    set pdf=0
else
    echo "Error in pdf param"
    exit
endif

if($htmlparam == "y" || $htmlparam == "Y" || $htmlparam == "yes" || $htmlparam == "Yes" || $htmlparam == "YES") then
    set html=1
else if($htmlparam == "n" || $htmlparam == "N" || $htmlparam == "no" || $htmlparam == "No" || $htmlparam == "NO") then
    set html=0
else
    echo "Error in html param"
    exit
endif

if($syllabiparam == "y" || $syllabiparam == "Y" || $syllabiparam == "yes" || $syllabiparam == "Yes" || $syllabiparam == "YES") then
    set syllabi=1
else if($syllabiparam == "n" || $syllabiparam == "N" || $syllabiparam == "no" || $syllabiparam == "No" || $syllabiparam == "NO") then
    set syllabi=0
else
    echo "Error in syllabi param"
    exit
endif

echo "pdf=$pdf, html=$html, syllabi=$syllabi"

set LogDir=<OUT_LOG_DIR>
date > <OUT_LOG_DIR>/<COUNTRY>-<AREA>-<INST>-time.txt
#--BEGIN-FILTERS--
set institution=<INST>
setenv CC_Institution <INST>
set filter=<FILTER>
setenv CC_Filter <FILTER>
set version=<VERSION>
setenv CC_Version <VERSION>
set area=<AREA>
setenv CC_Area <AREA>
set CurriculaParam=<AREA>-<INST>
#--END-FILTERS--
set curriculamain=<MAIN_FILE>
setenv CC_Main <MAIN_FILE>
set current_dir = `pwd`

set Country=<COUNTRY>
set InLogosDir=<IN_COUNTRY_DIR>/logos
set OutputDir=<OUTPUT_DIR>
set OutputInstDir=<OUTPUT_INST_DIR>
set OutputTexDir=<OUTPUT_TEX_DIR>
set OutputScriptsDir=<OUTPUT_SCRIPTS_DIR>
set OutputHtmlDir=<OUTPUT_HTML_DIR>

rm *.ps *.pdf *.log *.dvi *.aux *.bcf *.xml *.bbl *.blg *.toc *.out *.xref *.lof *.log *.lot *.brf *~ *.tmp;
# ls IS*.tex | xargs -0 perl -pi -e 's/CATORCE/UNOCUATRO/g'

# sudo addgroup curricula
#sudo chown -R ecuadros:curricula ./Curricula

mkdir -p <OUT_LOG_DIR>;
./scripts/process-curricula.pl <AREA>-<INST> ;
<OUTPUT_SCRIPTS_DIR>/gen-eps-files.sh;
foreach lang (<LIST_OF_LANGS>)
    <OUTPUT_SCRIPTS_DIR>/gen-graph.sh small $lang;
end

if($pdf == 1) then
    # latex -interaction=nonstopmode <MAIN_FILE>
    rm *.ps *.log *.dvi *.aux *.bcf *.xml *.bbl *.blg *.toc *.out *.xref *.lof *.log *.lot *.brf *~ *.tmp;
    latex <MAIN_FILE>;

    mkdir -p <OUT_LOG_DIR>;
    ./scripts/compbib.sh <MAIN_FILE> > <OUT_LOG_DIR>/<COUNTRY>-<AREA>-<INST>-errors-bib.txt;

    latex <MAIN_FILE>;
    latex <MAIN_FILE>;

    echo <AREA>-<INST>;
    dvips <MAIN_FILE>.dvi -o <AREA>-<INST>.ps;
    echo <AREA>-<INST>;
    ps2pdf <AREA>-<INST>.ps <AREA>-<INST>.pdf;
    rm -rf <AREA>-<INST>.ps;
endif

./scripts/update-outcome-itemizes.pl <AREA>-<INST>
./scripts/update-page-numbers.pl <AREA>-<INST>;
mkdir -p <OUTPUT_HTML_DIR>/figs;

if($syllabi == 1) then
    <OUTPUT_INST_DIR>/scripts/gen-syllabi.sh all;
endif

mkdir -p "<OUTPUT_DIR>/pdfs/<AREA>-<INST>/<PLAN>";
mutool convert -o <OUTPUT_HTML_DIR>/<AREA>-<INST>-P%d.png <AREA>-<INST>.pdf 1-1;
cp <AREA>-<INST>.pdf "<OUTPUT_DIR>/pdfs/<AREA>-<INST>/<PLAN>/<AREA>-<INST> <PLAN>.pdf";

<OUTPUT_SCRIPTS_DIR>/gen-book.sh  BookOfSyllabi-ES  	 pdflatex "<AREA>-<INST> <SEM_ACAD> BookOfSyllabi-ES (<PLAN>) <FIRST_SEM>-<LAST_SEM>";
<OUTPUT_SCRIPTS_DIR>/gen-book.sh  BookOfSyllabi-EN  	 pdflatex "<AREA>-<INST> <SEM_ACAD> BookOfSyllabi-EN (<PLAN>) <FIRST_SEM>-<LAST_SEM>";
<OUTPUT_SCRIPTS_DIR>/gen-book.sh  BookOfBibliography-ES  pdflatex "<AREA>-<INST> <SEM_ACAD> BookOfBibliography-ES (<PLAN>) <FIRST_SEM>-<LAST_SEM>";
<OUTPUT_SCRIPTS_DIR>/gen-book.sh  BookOfBibliography-EN  pdflatex "<AREA>-<INST> <SEM_ACAD> BookOfBibliography-EN (<PLAN>) <FIRST_SEM>-<LAST_SEM>";
<OUTPUT_SCRIPTS_DIR>/gen-book.sh  BookOfDescriptions-ES  pdflatex "<AREA>-<INST> <SEM_ACAD> BookOfDescriptions-ES (<PLAN>) <FIRST_SEM>-<LAST_SEM>";
<OUTPUT_SCRIPTS_DIR>/gen-book.sh  BookOfDescriptions-EN  pdflatex "<AREA>-<INST> <SEM_ACAD> BookOfDescriptions-EN (<PLAN>) <FIRST_SEM>-<LAST_SEM>";

if($html == 1) then
    rm <UNIFIED_MAIN_FILE>* ;
    ./scripts/gen-html-main.pl <AREA>-<INST>;
    cp <IN_DIR>/css/<MAIN_FILE>.css <UNIFIED_MAIN_FILE>.css;

    latex <UNIFIED_MAIN_FILE>;
    bibtex <UNIFIED_MAIN_FILE>;
    latex <UNIFIED_MAIN_FILE>;
    latex <UNIFIED_MAIN_FILE>;

    dvips -o <UNIFIED_MAIN_FILE>.ps <UNIFIED_MAIN_FILE>.dvi;
    rm <UNIFIED_MAIN_FILE>.ps <UNIFIED_MAIN_FILE>.dvi <UNIFIED_MAIN_FILE>.pdf;
    rm -rf <OUTPUT_HTML_DIR>;

    latex2html -t "Curricula <AREA>-<INST>" \
    -dir "<OUTPUT_HTML_DIR>/" -mkdir -toc_depth 4 \
    -toc_stars -local_icons -no_footnode \
    -show_section_numbers -long_title 5 \
    -address "<HTML_FOOTNOTE>" \
    -white <UNIFIED_MAIN_FILE>;

    mkdir -p <OUTPUT_HTML_DIR>/figs;
    cp "<OUTPUT_CURRICULA_HTML_FILE>" "<OUTPUT_INDEX_HTML_FILE>";
    sed 's/max-width:50em; //g' <OUTPUT_HTML_DIR>/<UNIFIED_MAIN_FILE>.css > <OUTPUT_HTML_DIR>/<UNIFIED_MAIN_FILE>.css1;
    mv <OUTPUT_HTML_DIR>/<UNIFIED_MAIN_FILE>.css1 <OUTPUT_HTML_DIR>/<UNIFIED_MAIN_FILE>.css;

    cp <IN_LANG_DIR>/figs/pdf.jpeg <IN_LANG_DIR>/figs/star.gif <IN_LANG_DIR>/figs/none.gif <IN_LANG_DIR>/figs/*.png <OUTPUT_HTML_FIGS_DIR>/.;
    cp <OUTPUT_FIGS_DIR>/*.png <OUTPUT_HTML_FIGS_DIR>/.;
    cp <IN_COUNTRY_DIR>/logos/<INST>.jpg <OUTPUT_HTML_FIGS_DIR>/.;
    
    ./scripts/post-processing.pl <AREA>-<INST>;
    <OUTPUT_SCRIPTS_DIR>/gen-map-for-course.sh;
    ./scripts/update-cvs-files.pl <AREA>-<INST>;

    ./scripts/update-analytic-info.pl <AREA>-<INST>;
endif

mkdir -p <OUTPUT_HTML_DIR>/figs;
foreach lang (<LIST_OF_LANGS>)
    <OUTPUT_SCRIPTS_DIR>/gen-graph.sh big $lang;
end

foreach lang (<LIST_OF_LANGS>)
    <OUTPUT_SCRIPTS_DIR>/compile-simple-latex.sh small-graph-curricula-$lang <AREA>-<INST>-small-graph-curricula <OUTPUT_TEX_DIR>;
    <OUTPUT_SCRIPTS_DIR>/gen-poster.sh $lang;
end

mkdir -p <OUTPUT_HTML_DIR>/syllabi;
mkdir -p <OUTPUT_HTML_DOCS_DIR>;
cp <OUTPUT_INST_DIR>/syllabi/* <OUTPUT_HTML_DIR>/syllabi/.;
mv <AREA>-<INST>.pdf "<OUTPUT_HTML_DIR>/<AREA>-<INST> <PLAN>.pdf";
cp <OUTPUT_PDF_INST_DIR>/*.pdf <OUTPUT_HTML_DOCS_DIR>/.;
cp <OUTPUT_PDF_INST_DIR>/*.png <OUTPUT_HTML_FIGS_DIR>/.;

#       <OUTPUT_SCRIPTS_DIR>/gen-book.sh  BookOfUnitsByCourse 	latex    "<AREA>-<INST> <SEM_ACAD> BookOfUnitsByCourse (<PLAN>) <FIRST_SEM>-<LAST_SEM>";
#       <OUTPUT_SCRIPTS_DIR>/gen-book.sh  BookOfDeliveryControl  pdflatex "<AREA>-<INST> <SEM_ACAD> BookOfDeliveryControl (<PLAN>) <FIRST_SEM>-<LAST_SEM>";
# Generate Books
#
# foreach auxbook (<OUTPUT_TEX_DIR>/BookOf*-*.tex)
#    set book = `echo $auxbook | sed s/.tex//`
#    $book = `echo $book | sed s|<OUTPUT_TEX_DIR>/||`
#    echo $book
#    #bibtex $auxfile
#    <OUTPUT_SCRIPTS_DIR>/gen-book.sh  $book       	pdflatex "<AREA>-<INST> <SEM_ACAD> $book (<PLAN>) <FIRST_SEM>-<LAST_SEM>";
# end

date >> <OUT_LOG_DIR>/<COUNTRY>-<AREA>-<INST>-time.txt;
more <OUT_LOG_DIR>/<COUNTRY>-<AREA>-<INST>-time.txt;
#./scripts/testenv.pl
beep;
beep;

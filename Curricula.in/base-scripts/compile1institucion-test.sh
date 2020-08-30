#!/bin/csh
set pdfparam=$1
set htmlparam=$2
set pdf=0
set html=0

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
echo "pdf=$pdf, html=$html"

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
set OutputDir=<OUTPUT_DIR>
set OutputInstDir=<OUTPUT_INST_DIR>
set OutputTexDir=<OUTPUT_TEX_DIR>
set OutputScriptsDir=<OUTPUT_SCRIPTS_DIR>
set OutputHtmlDir=<OUTPUT_HTML_DIR>

./clean
# ls IS*.tex | xargs -0 perl -pi -e 's/CATORCE/UNOCUATRO/g'

mkdir -p <OUT_LOG_DIR>
./scripts/process-curricula.pl <AREA>-<INST> ;
<OUTPUT_SCRIPTS_DIR>/gen-eps-files.sh;
<OUTPUT_SCRIPTS_DIR>/gen-graph.sh small &

if($pdf == 1) then
      # latex -interaction=nonstopmode <MAIN_FILE>
      latex <MAIN_FILE>;
      bibtex <MAIN_FILE>1;

      ./scripts/compbib.sh <MAIN_FILE> > <OUT_LOG_DIR>/<COUNTRY>-<AREA>-<INST>-errors-bib.txt;

      latex <MAIN_FILE>;
      latex <MAIN_FILE>;

      echo <AREA>-<INST>;
      dvips <MAIN_FILE>.dvi -o <AREA>-<INST>.ps;
      echo <AREA>-<INST>;
      ps2pdf <AREA>-<INST>.ps <AREA>-<INST>.pdf;

#     Generate the first page and place it at html dir
      pdftk A=<AREA>-<INST>.pdf cat A1-1 output <AREA>-<INST>-P1.pdf;
      convert <AREA>-<INST>-P1.pdf <AREA>-<INST>-P1.png;
      rm <AREA>-<INST>-P1.pdf;
      mv <AREA>-<INST>-P1.png <OUTPUT_HTML_DIR>/CurriculaMain-P1.png;
      cp <AREA>-<INST>.pdf <OUTPUT_HTML_DIR>/CurriculaMain.pdf;

      mv <AREA>-<INST>.pdf "<OUTPUT_DIR>/pdfs/<AREA>-<INST> Plan<PLAN>.pdf";
      rm -rf <AREA>-<INST>.ps;
endif

./scripts/update-outcome-itemizes.pl <AREA>-<INST> &
./scripts/update-page-numbers.pl <AREA>-<INST>;
<OUTPUT_SCRIPTS_DIR>/gen-graph.sh big &
<OUTPUT_SCRIPTS_DIR>/gen-dot-maps.sh &

if($html == 1) then
      rm <UNIFIED_MAIN_FILE>* ;
      ./scripts/gen-html-main.pl <AREA>-<INST>;

      latex <UNIFIED_MAIN_FILE>;
      bibtex <UNIFIED_MAIN_FILE>;
      latex <UNIFIED_MAIN_FILE>;
      latex <UNIFIED_MAIN_FILE>;

      dvips -o <UNIFIED_MAIN_FILE>.ps <UNIFIED_MAIN_FILE>.dvi;
      ps2pdf <UNIFIED_MAIN_FILE>.ps <UNIFIED_MAIN_FILE>.pdf;
      rm <UNIFIED_MAIN_FILE>.ps <UNIFIED_MAIN_FILE>.dvi;

      rm -rf <OUTPUT_HTML_DIR>;
      mkdir -p <OUTPUT_HTML_DIR>;
      mkdir <OUTPUT_HTML_DIR>/figs;
      cp ./in/lang.<LANG>/figs/pdf.jpeg ./in/lang.<LANG>/figs/star.gif ./in/lang.<LANG>/figs/none.gif <OUTPUT_HTML_DIR>/figs/.;

      latex2html -t "Curricula <AREA>-<INST>" \
      -dir "<OUTPUT_HTML_DIR>/" -mkdir \
      -toc_stars -local_icons -no_footnode -show_section_numbers -long_title 5 \
      -address "<HTML_FOOTNOTE>" \
      -white <UNIFIED_MAIN_FILE>;
      cp "<OUTPUT_CURRICULA_HTML_FILE>" "<OUTPUT_INDEX_HTML_FILE>";
      #-split 3 -numbered_footnotes -images_only -timing -html_version latin1 -antialias -no_transparent \

      ./scripts/update-analytic-info.pl <AREA>-<INST>
      ./scripts/gen-faculty-info.pl <AREA>-<INST>
endif

<OUTPUT_SCRIPTS_DIR>/compile-simple-latex.sh small-graph-curricula <AREA>-<INST>-small-graph-curricula <OUTPUT_TEX_DIR>;
<OUTPUT_SCRIPTS_DIR>/compile-simple-latex.sh Computing-poster <AREA>-<INST>-poster <OUTPUT_TEX_DIR>;
convert <OUTPUT_DIR>/pdfs/<AREA>-<INST>-poster.pdf <OUTPUT_HTML_DIR>/<AREA>-<INST>-poster.png;

<OUTPUT_INST_DIR>/scripts/gen-syllabi.sh all;

# Generate Books
<OUTPUT_SCRIPTS_DIR>/gen-book.sh  BookOfSyllabi       	pdflatex "<AREA>-<INST> <SEM_ACAD> BookOfSyllabi (Plan<PLAN>) <FIRST_SEM>-<LAST_SEM>";
<OUTPUT_SCRIPTS_DIR>/gen-book.sh  BookOfDescriptions  	pdflatex "<AREA>-<INST> <SEM_ACAD> BookOfDescriptions (Plan<PLAN>) <FIRST_SEM>-<LAST_SEM>";
<OUTPUT_SCRIPTS_DIR>/gen-book.sh  BookOfBibliography  	pdflatex "<AREA>-<INST> <SEM_ACAD> BookOfBibliography (Plan<PLAN>) <FIRST_SEM>-<LAST_SEM>";
#       <OUTPUT_SCRIPTS_DIR>/gen-book.sh  BookOfUnitsByCourse 	latex    "<AREA>-<INST> <SEM_ACAD> BookOfUnitsByCourse (Plan<PLAN>) <FIRST_SEM>-<LAST_SEM>";
#       <OUTPUT_SCRIPTS_DIR>/gen-book.sh  BookOfDeliveryControl  pdflatex "<AREA>-<INST> <SEM_ACAD> BookOfDeliveryControl (Plan<PLAN>) <FIRST_SEM>-<LAST_SEM>";

if($html == 1) then
      #<OUTPUT_DIR>/scripts/gen-syllabi.sh
      mkdir -p <OUTPUT_HTML_DIR>/syllabi;
      cp <OUTPUT_INST_DIR>/syllabi/* <OUTPUT_HTML_DIR>/syllabi/.;
endif

date >> <OUT_LOG_DIR>/<COUNTRY>-<AREA>-<INST>-time.txt;
more <OUT_LOG_DIR>/<COUNTRY>-<AREA>-<INST>-time.txt;
#./scripts/testenv.pl
beep;
beep;

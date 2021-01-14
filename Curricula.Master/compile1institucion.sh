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

set LogDir=./log
date > ./log/Peru-CS-UPCH-time.txt
#--BEGIN-FILTERS--
set institution=UPCH
setenv CC_Institution UPCH
set filter=SPC
setenv CC_Filter SPC
set version=final
setenv CC_Version final
set area=CS
setenv CC_Area CS
set CurriculaParam=CS-UPCH
#--END-FILTERS--
set curriculamain=curricula-main
setenv CC_Main curricula-main
set current_dir = `pwd`

set Country=Peru
set InLogosDir=../Curricula.in/country/Peru/logos
set OutputDir=../Curricula.out
set OutputInstDir=../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021
set OutputTexDir=../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/tex
set OutputScriptsDir=../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts
set OutputHtmlDir=../Curricula.out/html/Peru/CS-UPCH/Plan2021

rm *.ps *.pdf *.log *.dvi *.aux *.bcf *.xml *.bbl *.blg *.toc *.out *.xref *.lof *.log *.lot *.brf *~ *.tmp;
# ls IS*.tex | xargs -0 perl -pi -e 's/CATORCE/UNOCUATRO/g'

# sudo addgroup curricula
#sudo chown -R ecuadros:curricula ./Curricula

mkdir -p ./log;
./scripts/process-curricula.pl CS-UPCH ;
../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/gen-eps-files.sh;
foreach lang ('ES' 'EN')
    ../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/gen-graph.sh small $lang;
end

if($pdf == 1) then
    # latex -interaction=nonstopmode curricula-main
    rm *.ps *.log *.dvi *.aux *.bcf *.xml *.bbl *.blg *.toc *.out *.xref *.lof *.log *.lot *.brf *~ *.tmp;
    latex curricula-main;

    mkdir -p ./log;
    ./scripts/compbib.sh curricula-main > ./log/Peru-CS-UPCH-errors-bib.txt;

    latex curricula-main;
    latex curricula-main;

    echo CS-UPCH;
    dvips curricula-main.dvi -o CS-UPCH.ps;
    echo CS-UPCH;
    ps2pdf CS-UPCH.ps CS-UPCH.pdf;
    rm -rf CS-UPCH.ps;
endif

./scripts/update-outcome-itemizes.pl CS-UPCH
./scripts/update-page-numbers.pl CS-UPCH;
mkdir -p ../Curricula.out/html/Peru/CS-UPCH/Plan2021/figs;

if($syllabi == 1) then
    ../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/gen-syllabi.sh all;
endif

mkdir -p "../Curricula.out/pdfs/CS-UPCH/Plan2021";
mutool convert -o ../Curricula.out/html/Peru/CS-UPCH/Plan2021/CS-UPCH-P%d.png CS-UPCH.pdf 1-1;
cp CS-UPCH.pdf "../Curricula.out/pdfs/CS-UPCH/Plan2021/CS-UPCH Plan2021.pdf";

../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/gen-book.sh  BookOfSyllabi-ES  	 pdflatex "CS-UPCH 2021-I BookOfSyllabi-ES (Plan2021) 1-10";
../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/gen-book.sh  BookOfSyllabi-EN  	 pdflatex "CS-UPCH 2021-I BookOfSyllabi-EN (Plan2021) 1-10";
../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/gen-book.sh  BookOfBibliography-ES  pdflatex "CS-UPCH 2021-I BookOfBibliography-ES (Plan2021) 1-10";
../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/gen-book.sh  BookOfBibliography-EN  pdflatex "CS-UPCH 2021-I BookOfBibliography-EN (Plan2021) 1-10";
../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/gen-book.sh  BookOfDescriptions-ES  pdflatex "CS-UPCH 2021-I BookOfDescriptions-ES (Plan2021) 1-10";
../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/gen-book.sh  BookOfDescriptions-EN  pdflatex "CS-UPCH 2021-I BookOfDescriptions-EN (Plan2021) 1-10";

if($html == 1) then
    rm unified-curricula-main* ;
    ./scripts/gen-html-main.pl CS-UPCH;
    cp ../Curricula.in/css/curricula-main.css unified-curricula-main.css;

    latex unified-curricula-main;
    bibtex unified-curricula-main;
    latex unified-curricula-main;
    latex unified-curricula-main;

    dvips -o unified-curricula-main.ps unified-curricula-main.dvi;
    rm unified-curricula-main.ps unified-curricula-main.dvi unified-curricula-main.pdf;
    rm -rf ../Curricula.out/html/Peru/CS-UPCH/Plan2021;

    latex2html -t "Curricula CS-UPCH" \
    -dir "../Curricula.out/html/Peru/CS-UPCH/Plan2021/" -mkdir -toc_depth 4 \
    -toc_stars -local_icons -no_footnode \
    -show_section_numbers -long_title 5 \
    -address "Generado por <A HREF='http://socios.spc.org.pe/ecuadros/'>Ernesto Cuadros-Vargas</A> <ecuadros AT spc.org.pe>,               <A HREF='http://www.spc.org.pe/'>Sociedad Peruana de Computaci&oacute;n-Peru</A>,               basado en el modelo de la Computing Curricula de               <A HREF='http://www.computer.org/'>IEEE-CS</A>/<A HREF='http://www.acm.org/'>ACM</A>" \
    -white unified-curricula-main;

    mkdir -p ../Curricula.out/html/Peru/CS-UPCH/Plan2021/figs;
    cp "../Curricula.out/html/Peru/CS-UPCH/Plan2021/Curricula_CS_UPCH.html" "../Curricula.out/html/Peru/CS-UPCH/Plan2021/index.html";
    sed 's/max-width:50em; //g' ../Curricula.out/html/Peru/CS-UPCH/Plan2021/unified-curricula-main.css > ../Curricula.out/html/Peru/CS-UPCH/Plan2021/unified-curricula-main.css1;
    mv ../Curricula.out/html/Peru/CS-UPCH/Plan2021/unified-curricula-main.css1 ../Curricula.out/html/Peru/CS-UPCH/Plan2021/unified-curricula-main.css;

    cp ../Curricula.in/lang/Espanol/figs/pdf.jpeg ../Curricula.in/lang/Espanol/figs/star.gif ../Curricula.in/lang/Espanol/figs/none.gif ../Curricula.in/lang/Espanol/figs/*.png ../Curricula.out/html/Peru/CS-UPCH/Plan2021/figs/.;
    cp ../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/figs/*.png ../Curricula.out/html/Peru/CS-UPCH/Plan2021/figs/.;
    cp ../Curricula.in/country/Peru/logos/UPCH.jpg ../Curricula.out/html/Peru/CS-UPCH/Plan2021/figs/.;
    
    ./scripts/post-processing.pl CS-UPCH;
    ../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/gen-map-for-course.sh;
    ./scripts/update-cvs-files.pl CS-UPCH;

    ./scripts/update-analytic-info.pl CS-UPCH;
endif

mkdir -p ../Curricula.out/html/Peru/CS-UPCH/Plan2021/figs;
foreach lang ('ES' 'EN')
    ../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/gen-graph.sh big $lang;
end

foreach lang ('ES' 'EN')
    ../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/compile-simple-latex.sh small-graph-curricula-$lang CS-UPCH-small-graph-curricula ../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/tex;
    ../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/gen-poster.sh $lang;
end

mkdir -p ../Curricula.out/html/Peru/CS-UPCH/Plan2021/syllabi;
mkdir -p ../Curricula.out/html/Peru/CS-UPCH/Plan2021/docs;
cp ../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/syllabi/* ../Curricula.out/html/Peru/CS-UPCH/Plan2021/syllabi/.;
mv CS-UPCH.pdf "../Curricula.out/html/Peru/CS-UPCH/Plan2021/CS-UPCH Plan2021.pdf";
cp ../Curricula.out/pdfs/CS-UPCH/Plan2021/*.pdf ../Curricula.out/html/Peru/CS-UPCH/Plan2021/docs/.;
cp ../Curricula.out/pdfs/CS-UPCH/Plan2021/*.png ../Curricula.out/html/Peru/CS-UPCH/Plan2021/figs/.;

#       ../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/gen-book.sh  BookOfUnitsByCourse 	latex    "CS-UPCH 2021-I BookOfUnitsByCourse (Plan2021) 1-10";
#       ../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/gen-book.sh  BookOfDeliveryControl  pdflatex "CS-UPCH 2021-I BookOfDeliveryControl (Plan2021) 1-10";
# Generate Books
#
# foreach auxbook (../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/tex/BookOf*-*.tex)
#    set book = `echo $auxbook | sed s/.tex//`
#    $book = `echo $book | sed s|../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/tex/||`
#    echo $book
#    #bibtex $auxfile
#    ../Curricula.out/Peru/CS-UPCH/cycle/2021-I/Plan2021/scripts/gen-book.sh  $book       	pdflatex "CS-UPCH 2021-I $book (Plan2021) 1-10";
# end

date >> ./log/Peru-CS-UPCH-time.txt;
more ./log/Peru-CS-UPCH-time.txt;
#./scripts/testenv.pl
beep;
beep;

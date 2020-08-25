#!/bin/csh
# ./scripts/gen-syllabus.sh CS361 ./out/Peru/CS-UCSP/ 

#--BEGIN-FILTERS--
set course=$1
set OutputInstDir=$2
set OutputTexDir=$OutputInstDir/tex
set OutputHtmlDir=$OutputInstDir/html
set current_dir = `pwd`
#--END-FILTERS--

mkdir -p $OutputTexDir/../syllabi
mkdir -p $OutputHtmlDir/syllabi
echo "********************************* Compiling $course ***************************************"
echo `pwd`

cd $OutputTexDir
latex $course
biber $course
latex $course
latex $course
dvipdfm -o ../syllabi/$course.pdf $course.dvi 
rm $course.ps $course.log $course.dvi $course.aux $course.bbl $course.blg $course.toc
 
cd $current_dir
cp $OutputTexDir/../syllabi/$course.pdf $OutputHtmlDir/syllabi/$course.pdf
echo "Generated: $OutputHtmlDir/syllabi/$course.pdf ..."

rm *.ps *.pdf *.log *.dvi *.aux *.bcf *.xml *.bbl *.blg *.toc *.out *.xref *.lof *.log *.lot *.brf *~ *.tmp


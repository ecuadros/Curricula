#!/bin/csh

echo "CompileTexFile ..."
#--BEGIN-FILTERS--
set area	= $1
set institution	= $2
set latex_prg	= $3	#pdflatex
set MainFile	= $4   	#i.e BookOfSyllabi
set OutputFile	= "$5"
#--END-FILTERS--


set current_dir = `pwd`
echo "current_dir = $current_dir";
set OutputInstDir=<OUTPUT_INST_DIR>
echo "CompileTexFile.sh $area $institution latex_prg $MainFile $OutputInstDir"

if( ! -e $OutputInstDir/tex/$MainFile.tex ) then
  echo "**************************************************************************************************************************";
  echo "ERROR: There is no file: $OutputInstDir/tex/$MainFile.tex ... just ignoring it ...!";
  echo "**************************************************************************************************************************";
  exit;
endif

cd "<OUTPUT_TEX_DIR>";
set new_dir = `pwd`
rm *.ps *.pdf *.log *.dvi *.aux *.bbl *.blg *.toc *.out *.xref *.lof *.log *.lot *.brf *~ *.tmp

# $current_dir/scripts/clean_temp_files

mkdir -p $current_dir/<OUT_LOG_DIR>;
$latex_prg $MainFile;
echo "$current_dir/scripts/compbib.sh $MainFile > $current_dir/../Curricula.out/log/$area-$institution-$MainFile-Errors-bib.txt";
$current_dir/scripts/compbib.sh $MainFile > $current_dir/../Curricula.out/log/$area-$institution-$MainFile-Errors-bib.txt;

$latex_prg $MainFile;
$latex_prg $MainFile;
if($latex_prg == "latex") then
  dvips $MainFile.dvi -o $MainFile.ps;
  ps2pdf $MainFile.ps $MainFile.pdf;
endif

rm *.aux  *.log *.toc *.blg *.bbl $MainFile.ps $MainFile.dvi;

echo "cd $current_dir";
cd $current_dir;

mkdir -p <OUTPUT_HTML_DOCS_DIR>;
echo "cp <OUTPUT_TEX_DIR>/$MainFile.pdf <OUTPUT_HTML_DIR>/."
cp "<OUTPUT_TEX_DIR>/$MainFile.pdf" <OUTPUT_HTML_DOCS_DIR>/.;

cp "<OUTPUT_TEX_DIR>/$MainFile.pdf" "<OUTPUT_DIR>/pdfs/$OutputFile.pdf";
echo "File <OUTPUT_DIR>/pdfs/$OutputFile generated !";


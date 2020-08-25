#!/bin/csh
set lang=$1

mkdir -p <OUTPUT_PDF_INST_DIR>;
mkdir -p <OUTPUT_HTML_DOCS_DIR>;

<OUTPUT_SCRIPTS_DIR>/compile-simple-latex.sh <DISCIPLINE>-poster-$lang <AREA>-<INST>-poster-$lang <OUTPUT_TEX_DIR>;
cp <OUTPUT_TEX_DIR>/<AREA>-<INST>-poster-$lang.pdf <OUTPUT_PDF_INST_DIR>/.;
mv <OUTPUT_TEX_DIR>/<AREA>-<INST>-poster-$lang.pdf <OUTPUT_HTML_DOCS_DIR>/.;

mkdir -p <OUTPUT_FIGS_DIR>;
echo "mutool convert -o <OUTPUT_FIGS_DIR>/<AREA>-<INST>-poster-$lang-P%d.png <OUTPUT_TEX_DIR>/<AREA>-<INST>-poster-$lang.pdf 1-1";
mutool convert -o <OUTPUT_FIGS_DIR>/<AREA>-<INST>-poster-$lang-P%d.png <OUTPUT_PDF_INST_DIR>/<AREA>-<INST>-poster-$lang.pdf 1-1;
cp "<OUTPUT_FIGS_DIR>/<AREA>-<INST>-poster-$lang-P1.png" "<OUTPUT_HTML_FIGS_DIR>/.";
cp "<OUTPUT_FIGS_DIR>/<AREA>-<INST>-poster-$lang-P1.png" "<OUTPUT_PDF_INST_DIR>/.";

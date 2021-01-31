#!/bin/csh

set institution=<INST>
setenv CC_Institution <INST>
set filter=<FILTER>
setenv CC_Filter <FILTER>
set version=<VERSION>
setenv CC_Version <VERSION>
set area=<AREA>
setenv CC_Area <AREA>
set CurriculaParam=<AREA>-<INST>

./scripts/process-curricula.pl <AREA>-<INST> 

foreach lang (<LIST_OF_LANGS>)
    <OUTPUT_SCRIPTS_DIR>/gen-graph.sh big $lang;
    <OUTPUT_SCRIPTS_DIR>/compile-simple-latex.sh small-graph-curricula-$lang <AREA>-<INST>-small-graph-curricula <OUTPUT_TEX_DIR>;
    <OUTPUT_SCRIPTS_DIR>/gen-poster.sh $lang;
end


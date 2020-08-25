#!/bin/csh

set country     = $1
set discipline  = $2
set language    = $3
set area        = $4
set institution = $5
set plan        = $6
set cycle       = $7
# ./scripts/create-program.sh Peru Computing Espanol CS UDEP Plan2021 2021-I

set countryBase     = Peru
set disciplineBase  = Computing
set languageBase    = Espanol
set areaBase        = CS
set institutionBase = UTEC
set planBase        = Plan2018
set cycleBase       = 2020-I

echo "mkdir -p ../Curricula.in/country/$country/$discipline/$area/$institution/cycle/$cycle/$plan"
mkdir -p       ../Curricula.in/country/$country/$discipline/$area/$institution/cycle/$cycle/$plan

echo "cp ../Curricula.in/country/$countryBase/$disciplineBase/$areaBase/$institutionBase/program-info.tex ../Curricula.in/country/$country/$discipline/$area/$institution/."
if( -e ../Curricula.in/country/$country/$discipline/$area/$institution/program-info.tex ) then
    echo "========== File: ../Curricula.in/country/$country/$discipline/$area/$institution/program-info.tex already exist ... just ignoring this copy ..."
else
    cp ../Curricula.in/country/$countryBase/$disciplineBase/$areaBase/$institutionBase/program-info.tex ../Curricula.in/country/$country/$discipline/$area/$institution/.
endif

set source=../Curricula.in/country/$countryBase/$disciplineBase/$areaBase/$institutionBase/$planBase-Sem$cycleBase.config.tex
set target=../Curricula.in/country/$country/$discipline/$area/$institution/$plan-Sem$cycle.config.tex
if( -e $target ) then
    echo "========== File: $target already exists ... just ignoring this copy ..."
else
    cp $source $target
endif

set source=../Curricula.in/country/$countryBase/$disciplineBase/$areaBase/$institutionBase/cycle/$cycleBase
set target=../Curricula.in/country/$country/$discipline/$area/$institution/cycle/$cycle
set file=syllabus-template.tex
echo "cp $source $target"
if( -e  $target/$file ) then
    echo "========== Fie $target/$file already exists ... just ignoring this copy ..."
else
    cp $source/$file $target/$file
endif

set file=faculty.txt
if( -e  $target/$file ) then
    echo "========== Fie $target/$file already exists ... just ignoring this copy ..."
else
    echo "Creating $target/$file ... (empty)"
    echo "" > $target/$file
endif

set source=../Curricula.in/country/$countryBase/$disciplineBase/$areaBase/$institutionBase/cycle/$cycleBase/$planBase
set target=../Curricula.in/country/$country/$discipline/$area/$institution/cycle/$cycle/$plan

set file=Specific-Evaluation.tex
if( -e  $target/$file ) then
    echo "========== Fie $target/$file already exists ... just ignoring this copy ..."
else
    echo "Creating $target/$file ... (empty)"
    echo "" > $target/$file
endif

set file=distribution.txt
if( -e  $target/$file ) then
    echo "========== Fie $target/$file already exists ... just ignoring this copy ..."
else
    echo "Creating $target/$file ... (empty)"
    echo "" > $target/$file
endif

echo "cp ../Curricula.in/country/$countryBase/$disciplineBase/$areaBase/$institutionBase/team.tex ../Curricula.in/country/$country/$discipline/$area/$institution/."
cp ../Curricula.in/country/$countryBase/$disciplineBase/$areaBase/$institutionBase/team.tex ../Curricula.in/country/$country/$discipline/$area/$institution/.

echo "cp ../Curricula.in/country/$countryBase/$disciplineBase/$areaBase/$institutionBase/ack.tex  ../Curricula.in/country/$country/$discipline/$area/$institution/."
cp ../Curricula.in/country/$countryBase/$disciplineBase/$areaBase/$institutionBase/ack.tex  ../Curricula.in/country/$country/$discipline/$area/$institution/.

#echo "cp ../Curricula.in/country/$countryBase/$disciplineBase/$areaBase/$institutionBase/ack-general.tex  ../Curricula.in/country/$country/$discipline/$area/$institution/."
#cp ../Curricula.in/country/$countryBase/$disciplineBase/$areaBase/$institutionBase/ack.tex-general  ../Curricula.in/country/$country/$discipline/$area/$institution/.

echo "mkdir -p ../Curricula.in/lang/$language/$area.config/"
mkdir -p ../Curricula.in/lang/$language/$area.config/
echo "cp ../Curricula.in/lang/$languageBase/$areaBase.config/All.config         ../Curricula.in/lang/$language/$area.config/."
cp ../Curricula.in/lang/$languageBase/$areaBase.config/All.config               ../Curricula.in/lang/$language/$area.config/.
echo "cp ../Curricula.in/lang/$languageBase/$areaBase.config/Area.config        ../Curricula.in/lang/$language/$area.config/."
cp ../Curricula.in/lang/$languageBase/$areaBase.config/Area.config              ../Curricula.in/lang/$language/$area.config/.
mkdir -p ../Curricula.in/lang/$language/$area.sty/
#cp ../Curricula.in/lang/$languageBase/$areaBase.sty/bok-macros-V0.sty           ../Curricula.in/lang/$language/$area.sty/.

echo "mkdir -p ../Curricula.in/country/$countryBase/institutions"
mkdir -p ../Curricula.in/country/$countryBase/institutions
echo "cp ../Curricula.in/country/$countryBase/institutions/$institutionBase.config ../Curricula.in/country/$country/institutions/$institution.config"
cp ../Curricula.in/country/$countryBase/institutions/$institutionBase.config ../Curricula.in/country/$country/institutions/$institution.config

echo "cp ../Curricula.in/country/$countryBase/institutions/$institutionBase.tex ../Curricula.in/country/$country/institutions/$institution.tex"
if( -e ../Curricula.in/country/$country/institutions/$institution.tex ) then
    echo "============ file: ../Curricula.in/country/$country/institutions/$institution.tex already exists ... just ignoring this copy ..."
else
    cp ../Curricula.in/country/$countryBase/institutions/$institutionBase.tex ../Curricula.in/country/$country/institutions/$institution.tex
endif

echo "mkdir -p ../Curricula.in/lang/$language/$area.tex"
mkdir -p ../Curricula.in/lang/$language/$area.tex
echo "cp ../Curricula.in/lang/$languageBase/$areaBase.tex/outcomes-macros.tex         ../Curricula.in/lang/$language/$area.tex/."
cp ../Curricula.in/lang/$languageBase/$areaBase.tex/outcomes-macros.tex         ../Curricula.in/lang/$language/$area.tex/.

echo "cp ../Curricula.in/lang/$languageBase/$areaBase.tex/description-foreach-prefix.tex  ../Curricula.in/lang/$language/$area.tex/."
cp ../Curricula.in/lang/$languageBase/$areaBase.tex/description-foreach-prefix.tex  ../Curricula.in/lang/$language/$area.tex/.

echo "cp ../Curricula.in/lang/$languageBase/$areaBase.tex/other-packages.tex              ../Curricula.in/lang/$language/$area.tex/."
cp ../Curricula.in/lang/$languageBase/$areaBase.tex/other-packages.tex              ../Curricula.in/lang/$language/$area.tex/.

echo "cp ../Curricula.in/lang/$languageBase/$areaBase.tex/copyright.tex                   ../Curricula.in/lang/$language/$area.tex/."
cp ../Curricula.in/lang/$languageBase/$areaBase.tex/copyright.tex                   ../Curricula.in/lang/$language/$area.tex/.

echo "cp ../Curricula.in/lang/$languageBase/$areaBase.tex/abstract.tex            ../Curricula.in/lang/$language/$area.tex/."
cp ../Curricula.in/lang/$languageBase/$areaBase.tex/abstract.tex            ../Curricula.in/lang/$language/$area.tex/.

echo "End !"
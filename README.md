# Computing Curricula Generator 3.0

Generador de curriculas para escuelas profesionales relacionadas a la computación.

## Requerimientos

Versiones probadas utilizadas:

```
Ubuntu 16.04
Perl v5.22.1
TeX v3.14159265
```

## Instalación

### UBUNTU
```
sudo apt-get install texlive-science texlive-latex-extra texlive-bibtex-extra texlive-lang-spanish gv inkscape csh libcarp-assert-perl okular chromium-browser graphviz xpdf dot2tex texlive-pstricks biber kile ps2eps latex2html 

```
* Exportar librerías propias: `export PERL5LIB=/home/$USER/Curricula/Curricula.Master/scripts/`



## Generar Curricula

1. Revisar la configuración actual de la institución. Ejemplo: `./Curricula.in/country/Peru/Computing/CS/UNSA/institution-info.tex`
    * Modificar \newcommand{\CurriculaVersion}{2016\xspace} % Malla 2006
    * Modificar \newcommand{\YYYY}{2017\xspace} % Plan 2006
    * Modificar \newcommand{\Range}{1-10} % rango de semestres
    * Modificar \newcommand{\Semester}{2017-I\xspace} % semestre a generar
    * Modificar \newcommand{\equivalences}{2010} %  si existen equivalencias

1. Ejecutar los siguientes scripts:
    * `./scripts/gen-scripts.pl CS-UNSA` genera scripts para CS-UNSA en Curricula.out
    * `./compile1institucion.sh Y N` genera la curricula y extras (Y) en .pdf, pero no la parte HTML (N)

1. Imprimir el archivo, distribuir syllabi y descansar hasta el próximo semestre!"


## Localizaciones
Directorios y archivos importantes a considerar:

### Curricula.in/

1. Macros: ./Curricula.in/lang/{Lenguaje}/CS.sty/bok-macros.sty

1. Sílabos: ./Curricula.in/lang/{Lenguaje}/cycle/{ciclo}/Syllabi/{Área}/{Programa}

1. Dependencias (cursos): ./Curricula.in/lang/Espanol/CS.tex/CS201X-dependencies.tex

1. Lista de instituciones: ./Curricula.in/institutions-list.txt

### Curricula.Master/

1. Scripts generales: ./Curricula.Master/scripts

1. Librerías propias: ./Curricula.Master/scripts/Lib

### Curricula.out/ (Generado)

1. Curricula y Libros: ./Curricula.out/pdfs

## Fuentes

CS2013: http://ai.stanford.edu/users/sahami/CS2013/final-draft/CS2013-final-report.pdf

## Colaborar

Cualquier ayuda a este proyecto o algún bug no resuelto reportarlo!

Realizar Pull request para colaborar o presentar un Issue con los errores!

Gracias!

{smcl}
{* *! version 1.2  13oct2026}{...}
{vieweralsosee "[P] _getfilename" "help _getfilename"}{...}
{vieweralsosee "[D] filefilter" "help filefilter"}{...}
{viewerjumpto "Syntax" "filetype##syntax"}{...}
{viewerjumpto "Description" "filetype##description"}{...}
{viewerjumpto "Stored results" "filetype##results"}{...}
{viewerjumpto "Remarks" "filetype##remarks"}{...}
{viewerjumpto "Examples" "filetype##examples"}{...}
{viewerjumpto "Author" "filetype##author"}{...}

{title:Title}

{phang}
{bf:filetype} {hline 2} Split a file reference into its path, stem, and extension,
and classify its format family


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:filetype} {it:"filename"}

{pstd}
Exactly one {it:filename} may be supplied. Enclose it in double quotes: an
unquoted path containing spaces is parsed as several arguments, and
{cmd:filetype} then exits with error 110 and the message
{it:Only one file name allowed at a time.}

{pstd}
{it:filename} need not exist. {cmd:filetype} performs string manipulation only;
it does not touch the disk, and it does not inspect a file's contents or magic
number to determine its true format.


{marker description}{...}
{title:Description}

{pstd}
{cmd:filetype} divides a file reference into three pieces and returns them in
{cmd:r()}: the directory path, the bare stem, and the extension. It also
classifies the extension into a format family, returned in {cmd:r(family)}. It
is intended as a helper inside other programs; for instance, to branch on a
format so that one wrapper can read either a {cmd:.dta} or a {cmd:.csv} file, or
to build an output name that reuses an input's stem.

{pstd}
The split happens in two stages. Any directory path is removed first, by
{helpb _getfilename}. The remaining bare name is then divided at its {bf:final}
period. Doing it in that order matters: a reference such as
{cmd:my.folder/data} has a period in the directory but no extension on the
file, and splitting the undivided reference would wrongly report
{cmd:folder/data} as the extension.

{pstd}
A compound extension therefore divides at its last component only:
{cmd:archive.tar.gz} yields a stem of {cmd:archive.tar} and an extension of
{cmd:gz}.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:filetype} is {cmd:rclass} and stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(path)}}the directory portion, including the trailing separator;
empty when the reference names no directory{p_end}
{synopt:{cmd:r(filename)}}the bare stem: no directory, no extension, no
period{p_end}
{synopt:{cmd:r(extension)}}the text following the final period, without the
period; empty when the name has no extension{p_end}
{synopt:{cmd:r(family)}}the format family the extension belongs to; one of
{cmd:stata}, {cmd:delimited}, {cmd:excel}, {cmd:spss}, {cmd:sas}, or
{cmd:unknown}{p_end}
{p2colreset}{...}

{pstd}
{cmd:r(path)}, {cmd:r(filename)}, and {cmd:r(extension)} reassemble into the
original reference, so {cmd:r(path)} can be reused to write output back to the
directory an input came from. The separator
is whatever the caller supplied; {cmd:filetype} never assumes {cmd:/} or
{cmd:\} and never adds one.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:The format family.} {cmd:r(family)} exists to collapse a long chain of
tests over individual extensions into a single comparison. The vocabulary is
small and fixed:

{synoptset 14 tabbed}{...}
{synopt:{cmd:stata}}{cmd:dta}{p_end}
{synopt:{cmd:delimited}}{cmd:csv}, {cmd:tsv}, {cmd:txt}{p_end}
{synopt:{cmd:excel}}{cmd:xlsx}, {cmd:xls}, {cmd:xlsm}{p_end}
{synopt:{cmd:spss}}{cmd:sav}, {cmd:por}{p_end}
{synopt:{cmd:sas}}{cmd:sas7bdat}, {cmd:xpt}{p_end}
{synopt:{cmd:unknown}}anything else, including a name with no extension{p_end}
{p2colreset}{...}

{pstd}
Classification is done on a lowercased copy of the extension, so
{cmd:MYDATA.DTA} and {cmd:mydata.dta} both return {cmd:stata}. An unrecognised
extension returns {cmd:unknown} rather than an empty string, so there is one
value to test against rather than two.

{pstd}
The family is inferred from the extension alone. It is a statement about what
the reference claims to be, not about the bytes on disk: a CSV file misnamed
{cmd:.dta} is reported as {cmd:stata}.

{pstd}
{bf:Case is preserved.} {cmd:MYDATA.DTA} yields an extension of {cmd:DTA}, not
{cmd:dta}. Wrap comparisons in {helpb strlower()} before testing against a
literal.

{pstd}
{bf:Names with no extension} return {cmd:r(extension)} as an empty string, so
{cmd:if "`r(extension)'" == ""} is the test. Note that
{cmd:display r(extension)} prints {cmd:.} for an empty macro; that period is an
artifact of how {helpb display} evaluates an empty {cmd:r()} macro, not part of
the returned value. Use {cmd:display "`r(extension)'"} to see it as a string.

{pstd}
{bf:Dotfiles} such as {cmd:.gitignore} are treated as a name rather than as a
bare extension, following the usual convention: the stem is {cmd:.gitignore}
and the extension is empty. A leading period is only read as a separator when
the name contains a later period as well, so {cmd:.gitignore.bak} yields a stem
of {cmd:.gitignore} and an extension of {cmd:bak}.

{pstd}
{bf:A reference that names no file}, such as {cmd:C:/data/}, exits with error
198 and an explanatory message. There is nothing to parse in such a reference.

{pstd}
{bf:Windows-style paths and macro quoting.} {cmd:r(path)} ends in the caller's
separator, and a backslash immediately before a backquote suppresses macro
expansion in Stata. Concatenating naively therefore loses the separator:
{cmd:local f "`r(path)'`r(filename)'"} applied to {cmd:C:\data\win.dta} gives
{cmd:C:\datawin}. Build the string with an explicit expression instead, which
is not subject to that rule:

{phang2}{cmd:. local f = `"`r(path)'"' + `"`r(filename)'"'}{p_end}

{pstd}
Forward slashes work on all platforms Stata supports and avoid the problem
entirely.


{marker examples}{...}
{title:Examples}

{pstd}Separate a reference into its three parts{p_end}
{phang2}{cmd:. filetype "C:/data/mydata.dta"}{p_end}
{phang2}{cmd:. display "`r(path)'"}{p_end}
{phang2}{cmd:  C:/data/}{p_end}
{phang2}{cmd:. display "`r(filename)'"}{p_end}
{phang2}{cmd:  mydata}{p_end}
{phang2}{cmd:. display "`r(extension)'"}{p_end}
{phang2}{cmd:  dta}{p_end}

{pstd}Branch on the format family rather than on each extension{p_end}
{phang2}{cmd:. local infile "survey_wave1.csv"}{p_end}
{phang2}{cmd:. filetype "`infile'"}{p_end}
{phang2}{cmd:. if "`r(family)'" == "stata" use "`infile'", clear}{p_end}
{phang2}{cmd:. else if "`r(family)'" == "delimited" import delimited "`infile'", clear}{p_end}
{phang2}{cmd:. else if "`r(family)'" == "excel" import excel "`infile'", firstrow clear}{p_end}
{phang2}{cmd:. else {c -(}}{p_end}
{phang2}{cmd:.         display as error "Cannot read `r(extension)' files"}{p_end}
{phang2}{cmd:.         exit 198}{p_end}
{phang2}{cmd:. {c )-}}{p_end}

{pstd}Write output back beside its input, under a new extension{p_end}
{phang2}{cmd:. filetype "output/tables/balance.csv"}{p_end}
{phang2}{cmd:. local stem = `"`r(path)'"' + `"`r(filename)'"'}{p_end}
{phang2}{cmd:. export excel using "`stem'.xlsx", replace}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Marshall Garland{break}
Research Scientist, Center for Applied Research in Education{break}
University of Southern California{break}
garlandm@usc.edu

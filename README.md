# filetype

A small Stata utility that splits a file reference into its directory path, bare
stem, and extension, and classifies the extension into a format family. All four
pieces come back in `r()`. It is a helper for other programs: use it to branch on
a format so one wrapper can read either a `.dta` or a `.csv`, or to build an
output name that reuses an input's stem.

`filetype` does string manipulation only. It does not read the disk and does not
inspect a file's contents, so the file need not exist and the extension it
reports is whatever the caller supplied, not the file's true format.[^magic]

[^magic]: The command name is therefore slightly misleading: it parses a file
    *reference*, not a file *type*. Detecting a true format requires reading the
    file's leading bytes, which this command does not do.

## Installation

From a local clone:

```stata
net install filetype, from("/path/to/filetype-ado") replace
help filetype
```

Or directly from GitHub:

```stata
net install filetype, from("https://raw.githubusercontent.com/marshallwg/filetype-ado/main/") replace
```

## Usage

```stata
filetype "C:/data/mydata.dta"
display "`r(path)'"         // C:/data/
display "`r(filename)'"     // mydata
display "`r(extension)'"    // dta
display "`r(family)'"       // stata
```

Returns, all four as macros in `r()`:

| Result | Contents |
| --- | --- |
| `r(path)` | directory portion, including the trailing separator; empty if none |
| `r(filename)` | the bare stem: no directory, no extension, no period |
| `r(extension)` | text after the final period, without the period; empty if none |
| `r(family)` | format family: `stata`, `delimited`, `excel`, `spss`, `sas`, or `unknown` |

Quote the argument. An unquoted path containing spaces parses as several
arguments, and the command exits with error 110.

The split happens in two stages: the directory path comes off first, and only
then is the remaining bare name divided at its final period. The order matters,
because a reference like `my.folder/data` has a period in the directory but no
extension on the file.

### Format families

`r(family)` exists to collapse a long chain of tests over individual extensions
into one comparison. The vocabulary is small and fixed:

| Family | Extensions |
| --- | --- |
| `stata` | `dta` |
| `delimited` | `csv`, `tsv`, `txt` |
| `excel` | `xlsx`, `xls`, `xlsm` |
| `spss` | `sav`, `por` |
| `sas` | `sas7bdat`, `xpt` |
| `unknown` | anything else, including a name with no extension |

Classification uses a lowercased copy of the extension, so `MYDATA.DTA` and
`mydata.dta` both give `stata`. An unrecognised extension returns `unknown`
rather than an empty string, so there is one value to test against rather than
two.[^claims]

[^claims]: The family is inferred from the extension alone, so it describes what
    the reference claims to be rather than the bytes on disk: a CSV file misnamed
    `.dta` is reported as `stata`.

### Verified behavior

Actual output from Stata 19 (StataNow/MP), not expected output. The last column
confirms that path, stem, and extension reassemble into the original reference.

| Input | `r(path)` | `r(filename)` | `r(extension)` | `r(family)` | round-trips |
| --- | --- | --- | --- | --- | --- |
| `mydata.dta` |  | `mydata` | `dta` | `stata` | yes |
| `C:/data/mydata.dta` | `C:/data/` | `mydata` | `dta` | `stata` | yes |
| `/Users/me/my.folder/x.csv` | `/Users/me/my.folder/` | `x` | `csv` | `delimited` | yes |
| `my.folder/noext` | `my.folder/` | `noext` |  | `unknown` | yes |
| `archive.tar.gz` |  | `archive.tar` | `gz` | `unknown` | yes |
| `./rel.csv` | `./` | `rel` | `csv` | `delimited` | yes |
| `../up/two.dta` | `../up/` | `two` | `dta` | `stata` | yes |
| `with space.dta` |  | `with space` | `dta` | `stata` | yes |
| `.gitignore` |  | `.gitignore` |  | `unknown` | yes |
| `/dir/.gitignore` | `/dir/` | `.gitignore` |  | `unknown` | yes |
| `MYDATA.DTA` |  | `MYDATA` | `DTA` | `stata` | yes |
| `noext` |  | `noext` |  | `unknown` | yes |
| `C:/data/` | error 198 | | | | n/a |
| `a.dta b.dta` | error 110 | | | | n/a |

Four points worth knowing:

1. **Case is preserved.** `MYDATA.DTA` gives `DTA`. Wrap comparisons in
   `strlower()`.
2. **No extension gives an empty string**, so `if "`r(extension)'" == ""` is the
   test. Be aware that `display r(extension)` prints `.` for an empty macro;
   that period is an artifact of how `display` evaluates an empty `r()` macro,
   not part of the value. `display "`r(extension)'"` shows the string.
3. **Dotfiles are names, not extensions.** `.gitignore` yields that whole string
   as the stem with an empty extension. A leading period is read as a separator
   only when a later period is present, so `.gitignore.bak` splits into
   `.gitignore` and `bak`.
4. **A reference naming no file**, such as `C:/data/`, exits with error 198 and
   an explanatory message rather than Stata's bare `invalid syntax`.

### A note on backslashes

`r(path)` ends in the caller's separator, and in Stata a backslash immediately
before a backquote suppresses macro expansion. Naive concatenation therefore
drops the separator:

```stata
filetype "C:\data\win.dta"
local f "`r(path)'`r(filename)'"      // C:\datawin   <- separator lost
local f = `"`r(path)'"' + `"`r(filename)'"'   // C:\data\win   <- correct
```

Forward slashes work on every platform Stata supports and avoid this entirely.

### Example: branch on format family

```stata
local infile "survey_wave1.csv"
filetype "`infile'"
if "`r(family)'" == "stata"          use "`infile'", clear
else if "`r(family)'" == "delimited" import delimited "`infile'", clear
else if "`r(family)'" == "excel"     import excel "`infile'", firstrow clear
else {
    display as error "Cannot read `r(extension)' files"
    exit 198
}
```

## Repository structure

| File | Purpose |
| --- | --- |
| `filetype.ado` | the program |
| `filetype.sthlp` | help file (`help filetype`) |
| `filetype.pkg` | package manifest listing the files to install |
| `stata.toc` | package index that `net install` reads first |

## Known issues

- `filetype.ado` declares `version 8`; `filetype.pkg` declares
  `Requires: Stata version 9.2`. One of the two is wrong.
- `.gitignore` in this repository is a Nanoc (Ruby static-site) template and has
  nothing to do with Stata.

## Author

Marshall Garland, Research Scientist, Center for Applied Research in Education,
University of Southern California; garlandm@usc.edu

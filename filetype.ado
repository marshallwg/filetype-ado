//Created 2/14/2022 by MWG
//Version 1.2
capture program drop filetype
program define filetype, rclass
	version 8
	args
	//Disallow calls that include multiple files
	if "`2'" != "" {
		di as error "Only one file name allowed at a time."
		exit 110
	}

	//------------------------------------------------------------------------
	// Step 1: separate the directory path from the bare name.
	//------------------------------------------------------------------------
	//_getfilename strips any directory path and returns the bare name, still
	//carrying its extension, in r(filename). Capture it immediately: r() is
	//overwritten by the next command that sets it.
	//
	//_getfilename exits with error 198 on a reference that names no file at
	//all, such as "C:/data/". That message ("invalid syntax") does not explain
	//the cause, so intercept it and say what is actually wrong.
	capture _getfilename `"`1'"'
	if _rc {
		di as error `"'`1'' does not name a file."'
		di as error "A reference ending in a directory separator has no file name to parse."
		exit 198
	}
	local base `"`r(filename)'"'

	//Recover the directory portion by removing the bare name from the tail of
	//the argument. This preserves whatever separator the caller supplied, so
	//r(path) and r(filename) concatenate back into a usable reference without
	//this program having to assume "/" or "\".
	local dir `"`=substr(`"`1'"', 1, length(`"`1'"') - length(`"`base'"'))'"'

	//------------------------------------------------------------------------
	// Step 2: split the bare name at its final period.
	//------------------------------------------------------------------------
	//Locating the period on the bare name rather than on the whole argument
	//matters: a reference such as "my.folder/data" has a period in the
	//directory but no extension on the file. Splitting the whole argument
	//would wrongly report "folder/data" as the extension.
	//
	//strpos() on the reversed name finds the LAST period; converting that back
	//to a forward position keeps the substr() calls below readable and avoids
	//asking substr() for a negative length.
	local rpos=strpos(reverse(`"`base'"'), ".")
	if `rpos'==0 {
		//No period anywhere: the whole name is the stem ("README").
		local stem `"`base'"'
		local ext ""
	}
	else {
		local dotpos=length(`"`base'"')-`rpos'+1
		if `dotpos'==1 {
			//A leading period with no other period marks a dotfile, such as
			//".gitignore". By convention that is a name, not an extension, so
			//report the whole thing as the stem.
			local stem `"`base'"'
			local ext ""
		}
		else {
			local stem=substr(`"`base'"', 1, `dotpos'-1)
			local ext=substr(`"`base'"', `dotpos'+1, .)
		}
	}

	//------------------------------------------------------------------------
	// Step 3: classify the extension into a format family.
	//------------------------------------------------------------------------
	//The point of this is to collapse the usual six-arm if/else chain over
	//individual extensions into a single comparison. The vocabulary is
	//deliberately small and fixed: stata, delimited, excel, spss, sas, or
	//unknown. Anything unrecognised, including a name with no extension at
	//all, is reported as "unknown" rather than left empty, so that callers
	//have one value to test rather than two.
	//
	//Comparisons are made on a lowercased copy, so MYDATA.DTA classifies the
	//same as mydata.dta. The chain of == tests is used in preference to
	//inlist() because inlist() does not accept string arguments under the
	//version 8 interpretation declared above.
	local elow=strlower(`"`ext'"')
	local family unknown
	if `"`elow'"'=="dta" {
		local family stata
	}
	else if `"`elow'"'=="csv" | `"`elow'"'=="tsv" | `"`elow'"'=="txt" {
		local family delimited
	}
	else if `"`elow'"'=="xlsx" | `"`elow'"'=="xls" | `"`elow'"'=="xlsm" {
		local family excel
	}
	else if `"`elow'"'=="sav" | `"`elow'"'=="por" {
		local family spss
	}
	else if `"`elow'"'=="sas7bdat" | `"`elow'"'=="xpt" {
		local family sas
	}

	return local family `"`family'"'
	return local extension `"`ext'"'
	return local filename `"`stem'"'
	return local path `"`dir'"'
end

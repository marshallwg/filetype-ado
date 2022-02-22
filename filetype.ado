//Created 2/14/2022 by MWG
//Version 1.0
capture program drop filetype
program define filetype, rclass
	version 8
	args
	//Disallow calls that include multiple files
	if "`2'" != "" {
		di as error "Only one file name allowed at a time."
		exit 110
	}
	
	//Getting complete filename
	_getfilename "`1'"
	local one=reverse("`1'")
	local two=strpos("`one'", ".")+1
	//Extract extension
	local ext=reverse(substr("`one'", 1, `two'-2))
	//Extract filename
	local file=reverse(substr("`one'", `two', .))
	//Now, extracting filename and 
	return local extension `"`ext'"'
	return local filename `"`file'"'
end

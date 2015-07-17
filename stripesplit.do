capture program drop stripesplit
program stripesplit, rclass
	version 13
	syntax anything(name=terms)
	
local cvars
local fvars
foreach term of local terms {
	_ms_parse_parts `term'
	if "`r(type)'" == "factor" {
		local eqstripe `eqstripe' `term'
		local colstripe `colstripe' (none)
		local fvars `fvars' `term'
		}
		else if "`r(type)'" == "variable" {
		local eqstripe `eqstripe' (none)
		local colstripe `colstripe' `term'
		local cvars `cvars' `term'
		}
		else if "`r(type)'" == "interaction" {
			local cv
			local fv
			forvalues i = 1/`r(k_names)' {
				if "`r(op`i')'" == "c" | "`r(op`i')'" == "co"{
					if "`cv'" == "" {
						local cv `r(op`i')'.`r(name`i')'
						}
					else {
						local cv `cv'#`r(op`i')'.`r(name`i')'
						}
					local cvars `cvars' `r(op`i')'.`r(name`i')'
					}
				else {
					if "`fv'" == "" {
						local fv "`r(op`i')'.`r(name`i')'"
						}
					else {
						local fv "`fv'#`r(op`i')'.`r(name`i')'"
						}
					local fvars `fvars' `r(op`i')'.`r(name`i')'
					}
				}
			if "`fv'" == "" {
				local fv (none)
			}
			if "`cv'" == "" {
				local cv (none)
			}
			local eqstripe `eqstripe' `fv'
			local colstripe `colstripe' `cv'
		}
		
	}

local cvars : list uniq cvars
local fvars : list uniq fvars
local fterms : list uniq eqstripe

return local colstripe `colstripe'
return local eqstripe `eqstripe'
return local fterms `fterms'
return local fvars `fvars'
return local cvars `cvars'
end

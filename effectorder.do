capture program drop effectorder
program effectorder, rclass
	version 13
	syntax anything(name=terms)

	// initialize matrices to be returned
	tempname EO PO
	local nterms: word count `terms'
	matrix `EO' = J(3, `nterms', 0)
	matrix colnames `EO' = `terms'
	matrix rownames `EO' = factororder covariateorder total

	local vars : subinstr local terms "_cons" ""
	unopvar `vars'
	local vars `r(varlist)'
	local nvar : word count `vars'
	matrix `PO' = J(`nvar', `nterms'+1, 0)
	matrix colnames `PO' = `terms' max
	matrix rownames `PO' = `vars'

	local i = 0
	foreach term of local terms { // for each coefficient name
		local i = `i' + 1
		// initialize macros for this term
		local pvars
		local fvars
		local order = 0

		// examine this term's parts
		_ms_parse_parts `term'
		if "`r(type)'" == "variable" {
			matrix `EO'[3, `i'] = 1
			if "`r(name)'" == "_cons" {
				matrix `EO'[1, `i'] = 1
				}
				else {
					matrix `EO'[2, `i'] = 1
					local row : list posof "`r(name)'" in vars
					matrix `PO'[`row', `i'] = 1
				}
			}
			else if "`r(type)'" == "factor" {
				matrix `EO'[3, `i'] = 1
				matrix `EO'[1, `i'] = 1
				local row : list posof "`r(name)'" in vars
				matrix `PO'[`row', `i'] = 1
			}
			else if "`r(type)'" == "interaction" {
				matrix `EO'[3, `i'] = `r(k_names)'
				forvalues j = 1/`r(k_names)' {
					if "`r(op`j')'" == "c" | "`r(op`j')'" == "co"{ 
						local pvars `pvars' `r(name`j')'
						local order = `order' + 1
					}
					else {
						local fvars `fvars' `r(name`j')'
					}
				}
				matrix `EO'[2, `i'] = `order'
				matrix `EO'[1, `i'] = `r(k_names)' - `order'
				// find higher order vars
				local cvars : list uniq pvars
				foreach cvar of local cvars {
					local notrepeats : subinstr local pvars "`cvar'" "", all
					local notrepn : word count `notrepeats'
					local row : list posof "`cvar'" in vars
					matrix `PO'[`row', `i'] = `order' - `notrepn'
				}
				foreach fvar of local fvars {
					local row : list posof "`fvar'" in vars
					matrix `PO'[`row', `i'] = 1
				}
			}
		}
		
	// Find the maximum polynomial for each variable
	forvalues j = 1/`nterms' {
	forvalues i = 1/`nvar' {
		if el(`PO', `i', `j') > el(`PO', `i', `nterms'+1) {
			matrix `PO'[`i', `nterms'+1] = `PO'[`i', `j']
		}
	}
}
		
	return matrix Polynomial = `PO'
	return matrix Order = `EO'
	
end

	

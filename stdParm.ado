*! version 1.0.1 9Dec2015
* Doug Hemken, Social Science Computing Coop
*    Univ of Wisc - Madison
* update 9Dec2015 fixed a missing space typo in lines 230 and 291 thanks to Estie Hudes
program stdParm, rclass
	version 13
	syntax [, nodepvar store replace *] 
	// options for estimates table are allowed
	
	// check that estimate storage names are not already in use
	quietly estimates dir
	local storenames "`r(names)' Original Centered Standardized"
	local storedups : list dups storenames
	if "`storedups'" != "" & "`replace'" == "" {
		display "{error: Estimate store(s) `storedups' cannot be overwritten}"
		display "  Try using the {cmd:replace} option."
		exit
		}
	estimates store Original
	 
	// mark sample
	tempvar touse
	mark `touse' if e(sample)
	// mean and sd of depvar
	quietly summarize `e(depvar)' if `touse'
	tempname depvarmean depvarsd
	// exclude the dependent variable for some models
	if "`e(cmd)'" == "regress" {
		if "`depvar'" == "" {
			scalar `depvarmean' = r(mean)
			scalar `depvarsd' = r(sd)
			}
			else {
				scalar `depvarmean' = 0
				scalar `depvarsd' = 1
			}
		}
	else if "`e(cmd)'" == "logit" | "`e(cmd)'" == "logistic" {
			display "Assuming option {cmd:nodepvar}"
			scalar `depvarmean' = 0
			scalar `depvarsd' = 1
		}
	else if "`e(cmd)'" == "glm" {
		if "`e(varfunct)'" == "Gaussian" & "`e(linkt)'" == "Identity" {
			if "`depvar'" == "" {
				scalar `depvarmean' = r(mean)
				scalar `depvarsd' = r(sd)
				}
			else {
				scalar `depvarmean' = 0
				scalar `depvarsd' = 1
				}
			}
		else if "`e(varfunct)'" == "Bernoulli" & "`e(linkt)'" == "Logit" {
			display "Assuming option {cmd:nodepvar}"
			scalar `depvarmean' = 0
			scalar `depvarsd' = 1
			}
		else {
			if "`depvar'" == "" {
				display "Failure to specify option {cmd:nodepvar} where needed will cause errors." 
					scalar `depvarmean' = r(mean)
					scalar `depvarsd' = r(sd)
				}
				else {
					scalar `depvarmean' = 0
					scalar `depvarsd' = 1
				}
			}
		}
	else {
		display "{error: Only valid after {cmd:regress, logit, logistic, or glm}}"
		display "  Try using the stdBeta package, instead."
		exit
		}

	// make a copy of the coefficient vector
	tempname BO BC BS // for coefficient vectors
	matrix `BO' = e(b)

	// find which terms are polynomial effects
	local terms: colnames e(b)
	tempname PO
	effectorder `terms'
	matrix `PO' = r(Polynomial)
	// separate factor and continuous parts of varnames
	fvseparate `terms'

	// rename elements of the coefficient vector
	matrix coleq `BO' = `r(eqstripe)'
	matrix colnames `BO' = `r(colstripe)'

	tempname C S
	// initialize centering matrix, C
	tempname ncol
	scalar `ncol' = colsof(`BO')
	matrix `C' = J(`ncol', `ncol', 0)
	matrix coleq `C' = `r(eqstripe)'
	matrix roweq `C' = `r(eqstripe)'
	matrix colname `C' = `r(colstripe)'
	matrix rowname `C' = `r(colstripe)'
	// initialize standardizing matrix, S
	matrix `S' = I(`ncol')
	matrix coleq `S' = `r(eqstripe)'
	matrix roweq `S' = `r(eqstripe)'
	matrix colname `S' = `r(colstripe)'
	matrix rowname `S' = `r(colstripe)'

	// generate matrix of centering coefficients, Ck
	//     and matrix of standardizing coefficients, Sk
	csmatrices `r(cvars)' if `touse', po(`PO')
	tempname Ck Sk
	matrix `Ck' = r(Ck)
	matrix `Sk' = r(Sk)
	
	// for every row of C and S, distribute values of Ck and Sk
	forvalues i = 1/`=`ncol'' {
		tempname A B D E
		// pick a row in the target
		matrix `A' = `C'[`i', ....]
		local Areq: roweq `A'
			
		local Arname : rowname `A'
		local Arname : subinstr local Arname "(none)" "_cons"
		local Arname : subinstr local Arname "co." "c.", all
		local Arname : subinstr local Arname "o." "c.", all
		// find the matching row in the source
		matrix `D' = `Ck'["`Arname'", ....]
		// a quick detour to construct S
		matrix `S'[`i',`i'] = `Sk'["`Arname'", "`Arname'"]
		forvalues j = 1/`=`ncol'' {
			// pick a column in the target
			matrix `B' = `A'[...., `j']
			local Bceq: coleq `B'

			local Bcname : colname `B'
			local Bcname : subinstr local Bcname "(none)" "_cons"
			local Bcname : subinstr local Bcname "co." "c.", all
			local Bcname : subinstr local Bcname "o." "c.", all
			// find the matching column in the source
			matrix `E' = `D'[...., "`Bcname'"]
			
			if "`Areq'" == "`Bceq'" {
				matrix `C'[`i', `j'] = `E'
				}
			}
		}

	matrix `BC' = `C'*e(b)'
	matrix `BC'[`ncol',1] = `BC'[`ncol',1] - `depvarmean'

	// find the variance of the centered parameters
	tempname VC VS
	matrix `VC' = `C'*e(V)*`C''
	
	ecenter, bc(`BC') vc(`VC')
	estimates store Centered
	quietly estimates restore Original
	
	// find the variance of the standardized parameters
	matrix `BS' = (1/`depvarsd')*`S'*`BC'

	matrix `VS' = (1/`depvarsd'^2)*`S'*`VC'*`S''
	
	estd, bs(`BS') vs(`VS')
	estimates store Standardized
	quietly estimates restore Original
	
	estimates table Original Centered Standardized, modelwidth(12) `options'
	
	// clean up
	if "`store'" == "" {
		estimates drop Original Centered Standardized
		}
	
	// return tranformation matrices
	return matrix S = `S'
	return matrix C = `C'

end

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
					if "`r(op`j')'" == "c" | "`r(op`j')'" == "co" { 
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

program fvseparate, rclass
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
				if "`r(op`i')'" == "c" | "`r(op`i')'" == "co" {
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

program csmatrices, rclass
	version 13
	syntax anything(name=cvars) [if], po(name)
	*matrix dir
	*matrix list `po'
	
	// find which variables to standardize
	local cvars : subinstr local cvars "_cons" ""
	unopvar `cvars'
	local cv `r(varlist)'
	display "Recentering and rescaling:  `cv'"
	
	// find means and standard deviations
	if "`cv'" != "" {
		quietly tabstat `cv' `if', stat(mean sd) save
		tempname M
		matrix `M' = r(StatTotal)
		}

	// set up initial C and S matrices for each variable
	local i = 0
	foreach var of local cv {
		local ++i
		tempname C`var' S`var'
		matrix `C`var'' = (1,`M'[1,`i']\0,1)
		matrix `S`var'' = (1,0\0,`M'[2,`i'])
		matrix colnames `C`var'' = _ `var'
		matrix colnames `S`var'' = _ `var'
		}
	
	foreach var of local cv {
		tempname PM order
		matrix `PM' = `po'["`var'","max"]
		scalar `order' = `PM'[1,1]
		if `order' >=2 {
			kronpoly `C`var'' `order'
			matrix `C`var'' = r(CP)
			kronpoly `S`var'' `order'
			matrix `S`var'' = r(CP)
			}
		}

	tempname Ck Sk
	matrix `Ck' = (1)
	matrix `Sk' = (1)

foreach var of local cv {
	matrix `Ck' = `C`var'' # `Ck'
	matrix `Sk' = `S`var'' # `Sk'
	local cn : colfullnames `Ck'
	local cn :subinstr local cn ":" "#", all
	local cn :subinstr local cn "#c1" "", all
	matrix colnames `Ck' =`cn'
	matrix colnames `Sk' =`cn'
	}

local cn :subinstr local cn "c1" "_cons"
if "`cn'" == "" {
	local cn _cons
	}
matrix colnames `Ck' = `cn'
matrix coleq `Ck' = ""
matrix rownames `Ck' = `cn'
matrix roweq `Ck' = ""
matrix colnames `Sk' = `cn'
matrix coleq `Sk' = ""
matrix rownames `Sk' = `cn'
matrix roweq `Sk' = ""

return matrix Sk = `Sk'
return matrix Ck = `Ck'
	
end

* Kronecker polynomial function
program kronpoly, rclass
	version 13
	args Cvar order
	// Cvar is a 2x2 matrix
	// order is the polynomial degree to produce
	//   and we assume order >=2
	tempname CP C1 C2
	matrix `CP' = `Cvar'
	
	forvalues i = 2/`=`order'' {
		tempname co ck
		scalar `co' = colsof(`CP')
		matrix `CP' = `Cvar' # `CP'
	
		local cn : colfullnames `CP'
		scalar `ck' = colsof(`CP')
		
		* add paired rows
		matrix `C1' = (`CP'[1..`co',....] \ J(1,`ck',0))
		matrix `C2' = (J(1,`ck',0) \ `CP'[(`co'+1)...,....])
		matrix `CP' = `C1' + `C2'
		matrix colnames `CP' =`cn'
		
		* select columns
		matrix `CP' = (`CP'[....,1..`co'] , `CP'[....,`ck'])
		
		local cn : colfullnames `CP'
		local cn : subinstr local cn ":" "#", all
		local cn : subinstr local cn "#_" "", all
		local cn : subinstr local cn "r1" "_"
		matrix colnames `CP' =`cn'
		matrix coleq `CP' = _
		matrix rownames `CP' =`cn'
		matrix roweq `CP' = _
	}
	return matrix CP = `CP'

end

program ecenter, eclass
	version 13
	syntax , bc(name) vc(name)
	tempname bccopy vccopy
	matrix `bccopy' = `bc''
	matrix `vccopy' = `vc'
	ereturn repost b=`bccopy' V=`vccopy'
end
	
program estd, eclass
	version 13
	syntax , bs(name) vs(name)
	tempname bscopy vscopy
	matrix `bscopy' = `bs''
	matrix `vscopy' = `vs'
	ereturn repost b=`bscopy' V=`vscopy'
end

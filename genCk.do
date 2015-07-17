capture program drop genCk
program genCk, rclass
	version 13
	syntax anything(name=cvars) [if], po(name)
	*matrix dir
	*matrix list `po'
	
	// find which variables to standardize
	local cvars : subinstr local cvars "_cons" ""
	unopvar `cvars'
	local cv `r(varlist)'
	
	
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

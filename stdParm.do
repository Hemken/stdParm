capture program drop stdParm
program stdParm, rclass
	version 13
	// mark sample
	tempvar touse
	mark `touse' if e(sample)
	// mean and sd of depvar
	quietly summarize `e(depvar)' if `touse'
	tempname depvarmean depvarsd
	scalar `depvarmean' = r(mean)
	scalar `depvarsd' = r(sd)

	// make a copy of the coefficient vector
	tempname BO BC BS // for coefficient vectors
	matrix `BO' = e(b)

	// find which terms are polynomial effects
	local terms: colnames e(b)
	tempname PO
	effectorder `terms'
	matrix `PO' = r(Polynomial)
	// separate factor and continuous parts of varnames
	stripesplit `terms'

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
	*matrix list `PO'
	genCk `r(cvars)' if `touse', po(`PO')
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
	tempname VC Cse VS Sse Ose
	matrix `VC' = `C'*e(V)*`C''
	matrix `Cse' = vecdiag(`VC')

	forvalues i=1/`=`ncol'' {
		matrix `Cse'[1,`i'] = sqrt(`Cse'[1,`i'])
		}

	// find the variance of the standardized parameters
	matrix `BS' = (1/`depvarsd')*`S'*`BC'

	matrix `VS' = (1/`depvarsd'^2)*`S'*`VC'*`S''
	matrix `Sse' = vecdiag(`VS')

	forvalues i=1/`=`ncol'' {
		matrix `Sse'[1,`i'] = sqrt(`Sse'[1,`i'])
		}

	// recover the variance of the original parameters
	matrix `Ose' = vecdiag(e(V))
	forvalues i=1/`=`ncol'' {
		matrix `Ose'[1,`i'] = sqrt(`Ose'[1,`i'])
		}

	// report the results
	tempname TABLEALL TABLE
	matrix `TABLEALL' = (`BO'', `Ose'', `BC', `Cse'', `BS', `Sse'')
	matrix colname `TABLEALL' = Original (se) Centered (se) Standardized (se)
	matrix rowname `TABLEALL' = `terms'
	matrix roweq `TABLEALL' = ""
	*matrix list `TABLEALL'
	forvalues i = 1/`=`ncol'' {
		tempname val
		scalar `val' = `TABLEALL'[`i',1]
		if `val' != 0 {
			matrix `TABLE' = nullmat(`TABLE')\ `TABLEALL'[`i',....]
			}
		}
matrix list `TABLE'

	// return tranformation matrices
	return matrix S = `S'
	return matrix C = `C'

end

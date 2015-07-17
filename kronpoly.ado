* Kronecker polynomial function
capture program drop kronpoly
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

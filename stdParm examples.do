cd "Z:\PUBLIC_web\Stataworkshops\stdParm"
sysuse auto, clear
//----------------------------
// transform-data algorithm (installed in PERSONAL)
* adopath ++ "Z:\PUBLIC_web\Stataworkshops\stdBeta"

// Kronecker product algorithm
*adopath ++ "Z:\PUBLIC_web\Stataworkshops\stdParm"

//----------------------------

// Additive models
// ANOVA
regress price i.rep78
stdBeta
stdParm

regress price ib5.rep78
stdBeta
stdParm

// Regression
regress price weight displacement, be
stdBeta
stdParm

preserve
replace weight = . if runiform() < 0.1 
regress price weight displacement, be
stdBeta
stdParm
restore

// ANCOVA
regress price weight displacement i.foreign
stdBeta
stdParm

regress price weight ib5.rep78 displacement, be
stdBeta
stdParm

// Interaction models
regress price c.weight##c.mpg, be
stdBeta, se
stdParm, se

regress price rep78##c.weight##c.mpg, be
stdBeta, se
stdParm

glm price rep78##c.weight##c.mpg
stdBeta

regress price c.displacement##c.weight##c.mpg
stdBeta
stdBeta, se

regress price foreign##c.weight##c.mpg
stdBeta, se
stdParm

//------------------------------

regress price foreign##rep78##c.weight
stdCoeff
stdBeta,se

// verbosely specified
regress price i.rep78 weight i.rep78#c.weight mpg i.rep78#c.mpg c.weight#c.mpg i.rep78#c.weight#c.mpg
stdCoeff
stdBeta

// terms reordered, ascending polynomial order
regress price i.foreign weight mpg c.weight#c.mpg i.foreign#c.weight i.foreign#c.mpg i.foreign#c.weight#c.mpg
stdCoeff
stdBeta

// terms reordered, descending polynomial order
regress price i.foreign#c.weight#c.mpg c.weight#c.mpg i.foreign#c.weight i.foreign#c.mpg i.foreign weight mpg
stdCoeff
stdBeta

// terms reordered, mixed order
regress price i.foreign#c.weight#c.mpg i.foreign#c.mpg i.foreign weight mpg c.weight#c.mpg i.foreign#c.weight
stdCoeff
stdBeta

//------------------------------
log using "testrun.log", replace

// terms reordered, ascending polynomial order
regress price i.rep78 weight mpg c.weight#c.mpg i.rep78#c.weight i.rep78#c.mpg i.rep78#c.weight#c.mpg
stdCoeff
stdBeta
// terms reordered, descending polynomial order
regress price i.rep78#c.weight#c.mpg c.weight#c.mpg i.rep78#c.weight i.rep78#c.mpg i.rep78 weight mpg
stdCoeff
stdBeta

// partial factorial, ascending polynomial order
regress price i.rep78 weight mpg i.rep78#c.weight i.rep78#c.mpg
stdCoeff
stdBeta

log close
//------------------------------

// terms out of standard order
regress price weight c.mpg#foreign i.foreign mpg
stdCoeff
stdBeta

// covariates not in polynomial order
// breaks both algorithms
regress price c.mpg#rep78#c.weight c.weight#rep78 c.mpg#rep78 i.rep78 c.weight##c.mpg
stdCoeff
stdBeta

// covariates not in polynomial order
// no first order interaction 
regress price c.mpg#rep78#c.weight i.rep78 weight mpg
stdCoeff
stdBeta


regress price foreign#i(2 3).rep78#c.weight o.trunk
	// three slopes and an intercept ??
stdCoeff

// subset
quietly regress price foreign##rep78##c.weight if weight < 3000
stdBeta
stdParm

cd "Z:\PUBLIC_web\Stataworkshops\stdParm"
//----------------------------
// transform-data algorithm (installed in PERSONAL)
* adopath ++ "Z:\PUBLIC_web\Stataworkshops\stdBeta"

// Kronecker product algorithm
*adopath ++ "Z:\PUBLIC_web\Stataworkshops\stdParm"

//----------------------------

sysuse auto, clear

// 5 missing cases
summarize price i.rep78
regress price i.rep78
stdBeta
stdParm

preserve
quietly summarize weight
replace weight = . if weight > r(mean)

// 39 missing cases
regress price weight, be
stdBeta, se
stdParm, se

regress price c.weight##c.displacement
stdBeta, se
stdParm, se
restore

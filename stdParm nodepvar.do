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
summarize price i.rep78
regress price i.rep78
stdBeta
stdParm

stdBeta, nodepvar
stdParm, nodepvar

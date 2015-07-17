// this is built into "effectorder.do"
cd "X:\SSCC Staff\stdBeta"
sysuse auto, clear

regress price c.mpg##c.mpg##c.weight##foreign#rep78

local terms: colnames e(b)
effectorder `terms'
matrix list r(Order)
matrix list r(Polynomial)
 
matrix A = r(Polynomial)
local rows : rownames r(Polynomial)
matrix list A
scalar c = colsof(A)
scalar r = rowsof(A)

// initialize
matrix Max = J(`=r', 1, 0)
matrix rownames `rows'

forvalues j = 1/`=c' {
	forvalues i = 1/`=r' {
		scalar current = el(Max, `i', 1)
		scalar test    = el(A, `i', `j')
		if `=current' < `=test' {
			matrix Max[`i', 1] = test
			}
		}
	}
	
matrix list Max

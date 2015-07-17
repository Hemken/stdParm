
sysuse auto
quietly reg price i.rep78
matrix list e(b)

matrix B = e(b)
scalar ncol = colsof(B)
forvalues i = 1/`=ncol' {
	scalar val = B[1,`i']
	if val != 0 {
		matrix C = nullmat(C), B[....,`i']
		}
	}
matrix list C

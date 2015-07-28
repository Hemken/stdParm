sysuse auto

quietly regress weight displacement

graph twoway (scatter weight disp) (lfit weight disp), ///
	text(2750 350 "y = {&beta}{sub:0} + {&beta}{sub:1} * x" " " ///
	"weight = `:di %4.0f =_b[_cons]' + `:di %3.1f = _b[displacement]' * displacement") ///
	ytitle("Weight (lbs.)") legend(off) title("Original") name(g1, replace)

preserve
quietly summarize displacement
replace displacement = displacement - r(mean)
label var displacement "{&Delta} displacement (cu. in.)"

quietly regress weight disp
graph twoway (scatter weight disp) (lfit weight disp), ///
	text(2750 150 "y = {&beta}{sup: {&Delta}}{sub:0} + {&beta}{sup: {&Delta}}{sub:1} * {&Delta}x" " " ///
	"weight = `:di %4.0f =_b[_cons]' + `:di %3.1f = _b[displacement]' * displacement") ///
	ytitle("Weight (lbs.)") legend(off) title("Centered") name(g2)

quietly summarize displacement
replace displacement = displacement/r(sd)
label var displacement "{&sigma} displacement (std. dev.)"

quietly regress weight disp
graph twoway (scatter weight disp) (lfit weight disp), ///
	text(2750 1.5 "y = {&beta}{sup: {&sigma}}{sub:0} + {&beta}{sup: {&sigma}}{sub:1} * z" " " ///
	"weight = `:di %4.0f =_b[_cons]' + `:di %3.1f = _b[displacement]' * displacement") ///
	ytitle("Weight (lbs.)") legend(off) title("Standardized") name(g3)

graph combine g1 g2 g3, name(linear)
graph drop g1 g2 g3

restore
preserve

quietly regress weight c.displacement##c.displacement
estimates store Original

graph twoway (scatter weight disp) (qfit weight disp), ///
	text(2750 350 "y = {&beta}{sub:0} + {&beta}{sub:1}*x + {&beta}{sub:2}*x{sup:2}" " " ///
	"weight = `:di %4.0f =_b[_cons]' + `:di %3.1f = _b[displacement]'*displacement" ///
	"     `:di %5.3f = _b[c.displacement#c.displacement]'*displacement{sup:2}") ///
	title("Original") name(g4)
	
quietly summarize displacement
replace displacement = displacement - r(mean)
label var displacement "{&Delta} displacement (cu. in.)"

quietly regress weight c.disp##c.disp
estimates store Centered

graph twoway (scatter weight disp) (qfit weight disp), ///
	text(2750 150 "y = {&beta}{sup: {&Delta}}{sub:0} + {&beta}{sup: {&Delta}}{sub:1}*x + {&beta}{sup: {&Delta}}{sub:2}*x{sup:2}" " " ///
	"weight = `:di %4.0f =_b[_cons]' + `:di %3.1f = _b[displacement]'*displacement" ///
	"     `:di %5.3f = _b[c.displacement#c.displacement]'*displacement{sup:2}") ///
	title("Centered") name(g5)
	
graph combine g4 g5, name(quadratic)
graph drop g4 g5
restore

estimates table Original Centered, se varwidth(15)

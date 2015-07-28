* Kronecker demo

sysuse auto, clear

summarize weight, meanonly
matrix A = (1, r(mean) \ 0, 1)
matrix colnames A = _ weight

summarize displacement, meanonly
matrix B = (1, r(mean) \ 0, 1)
matrix colnames B = _ displacement

matrix list A
matrix list B

matrix C = B#A
* column/row names are given the form
*    equation(B):name(A)
matrix list C
	
local cn : colfullnames C
local cn :subinstr local cn ":" "#", all
local cn :subinstr local cn "#_" "", all
matrix coleq C = ""
matrix colnames C =`cn'
matrix list C

summarize mpg, meanonly
matrix D = (1, r(mean) \ 0, 1)
matrix colnames D = _ mpg

matrix C = D#C
local cn : colfullnames C
local cn :subinstr local cn ":" "#", all
local cn :subinstr local cn "#_" "", all
matrix coleq C = ""
matrix colnames C =`cn'
matrix list C

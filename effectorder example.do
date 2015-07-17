regress mpg c.weight##c.displacement##c.weight

local terms: colnames e(b)
effectorder `terms'
return list

matrix list r(Order)
matrix list r(Polynomial)

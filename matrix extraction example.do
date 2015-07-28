quietly regress price c.weight##c.disp

matrix A = e(b)

matrix B= A[1,1..2] // by numerical index
matrix list B

matrix B= A[1,"weight"] // by column/row names
matrix list B

// This recognizes factor notation equivalences!
matrix B= A[1,"c.weight#c.displacement"]
matrix list B
matrix B= A[1,"c.displacement#c.weight"]
matrix list B

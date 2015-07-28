* Parse factors and covariates from terms

sysuse auto, clear
quietly regress price foreign##c.weight
matrix list e(b)

_ms_parse_parts weight
return list // "variable"
_ms_parse_parts 1.foreign
return list // "factor"
_ms_parse_parts 1.foreign#c.weight
return list // "interaction"

_ms_parse_parts whatever#c.whatever
return list // polynomial as interaction

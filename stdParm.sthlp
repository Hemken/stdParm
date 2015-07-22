{smcl}
{* *! version 1.0  20jul2015}{...}
{vieweralsosee "[R] regress, beta" "help regress"}{...}
{* *! vieweralsosee "[R] estimates table" "help estimates table"}{...}
{viewerjumpto "Syntax" "stdParm##syntax"}{...}
{viewerjumpto "Description" "stdParm##description"}{...}
{viewerjumpto "Options" "stdParm##options"}{...}
{viewerjumpto "Remarks" "stdParm##remarks"}{...}
{viewerjumpto "Examples" "stdParm##examples"}{...}
{title:Title}

{phang}
{bf:stdParm} {hline 2} After estimating a regression model, calculate centered and standardized coefficients


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:stdParm}
[{cmd: , nodepvar store replace {it:estimates_table_options}}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt nodepvar}}do not center or rescale the dependent variable{p_end}
{synopt:{opt store}}store centered and standardized estimation results{p_end}
{synopt:{opt replace}}overwrite estimates already stored{p_end}
{synopt:{it:estimates_table_options}}output options to pass to {cmd:estimates table}{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:stdParm} Calculates centered and standardized coefficients, outputs the
	results using {cmd: estimates table}, and returns
	the centering and standardizing matrices.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt nodepvar} suppresses centering and rescaling the dependent variable.

{phang}
{opt store} stores ereturn statistics for all three models.  These are
{cmd: estimates store}s named Original, Centered, and Standardized.

{phang}
{opt replace} if any estimates stores named Original, Centered, and Standardized
already exist, you must replace them.

{phang}
{it:estimates_table_options} options passed to {cmd: estimates table} for
reporting.


{marker remarks}{...}
{title:Remarks}

{pstd}
Presented at 2015 Stata Conference Columbus.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. regress price c.mpg##c.weight}{p_end}

{phang}{cmd:. stdParm}{p_end}

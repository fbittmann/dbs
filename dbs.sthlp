{smcl}
{* 2020-09-16}{...}
{hi:help dbs}{...}
{right:{help dbs##syntax:Syntax} - {help dbs##desc:Description} - {help dbs##opt:Options} - {help dbs##ex:Examples} - {help dbs##eret:Stored results}}
{hline}

{title:Title}

{pstd}{hi:dbs} {hline 2} Double bootstrap confidence intervals

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:dbs} {it:{help exp_list}}
            [{cmd:,} {it:options}] {cmd::} {it:{help command}}

{synoptset 25 tabbed}{...}
{marker comopt}{synopthdr:options}
{synoptline}
{synopt :{opt reps(#)}}number of outer resamples; default is 50
  {p_end}
{synopt :{opt repsinner(#)}}number of inner resamples; default is 25; overwritten if {it:analytic} or {it:jackknife} provided
  {p_end}
{synopt :{opt analytic(string)}}providing analytic standard error(s)
  {p_end}
{synopt :{opt jackknife}}computing t-values with jackknife standard errors
  {p_end}
{synopt :{opt level(#)}}confidence level; default is 95
  {p_end}
{synopt :{opt seed(#)}}set random-number seed to #
  {p_end}
{synopt :{opt strata(varlist)}}variables identifying strata
  {p_end}
{synopt :{opt cluster(varlist)}}variables identifying resampling clusters
  {p_end}
{synopt :{opt idcluster(newvar)}}create new cluster ID variable
  {p_end}
{synopt :{opt saving(filename, ...)}}save results to filename
  {p_end}
{synopt :{opt dots(#)}}display dots every # replications; default is 10
  {p_end}
{synopt :{opt graph}}display diagnostic plots for t-values
  {p_end}
{synopt :{opt nowarn}}do not display warning messages
  {p_end}
{synopt :{opt parallel(#)}}use multiple threads; default is 1
  {p_end}

{synoptline}
{p 4 4 2}
{it:command} is any command that follows standard Stata syntax.{p_end}


{marker desc}{...}
{title:Description}

{pstd} {cmd:dbs} generates double bootstap confidence intervals of specified
    statistics (or expressions) for a Stata command or a user-written
    program.  Statistics are bootstrapped by resampling the data in memory
    with replacement. {cmd:dbs} is designed for use with nonestimation
    commands, functions of coefficients, or user-written programs.

{marker opt}{...}
{title:Options}

{marker comoptd}{it:{dlgtab:Options}}

{phang} {opt reps(#)} specifies the number of outer resamples to draw.
The default is 50. For accurate results, 1,000 or even more resamples
are recommended (Hesterberg 2015). More is always better.

{phang} {opt repsinner(#)} specifies the number of inner resamples to draw.
The default is 25. This is the number of resamples drawn for every outer
resample. The total number of bootstrap samples is thus reps * repsinner, so
be aware of the additional computational burden. While no general recommendations can
be given, 300 or more inner resamples might be required for precise estimates.

{phang} {opt analytic(string)} specifies analytic standard errors for the computation
of the t-values. This is possible if the command used provides analytic standard errors.
The order of the analytic standard errors must be identical to the order of expressions in {it:{help exp_list}}.
The provision of analytic standard errors increases the overall computation speed manifold and 
often gives highly accurate results.

{phang} {opt jackknife} specifies the usage of {help jackknife} standard errors for the computation of
the t-values. Specify either {it:repsinner}, {it:analytic} or {it:jackknife}.

{phang} {opt level(#)} specifies the confidence level, as a percentage,
for confidence intervals. The default is {cmd:level(95)} which produces
95% confidence intervals.

{phang} {opt seed(#)} sets the random-number seed.

{phang} {opt strata(varlist)} specifies the variables that identify strata. If this
option is specified, bootstrap samples are taken independently within
each stratum.
		
{phang} {opt cluster(varlist)} specifies the variables that identify resampling
clusters. If this option is specified, the sample drawn during each
replication is a bootstrap sample of clusters.

{phang} {opt idcluster(newvar)} creates a new variable containing a unique identifier
for each resampled cluster.  This option requires that cluster() also be specified.
		
{phang} {opt saving(filename)} creates a Stata data file ({cmd:.dta} file)
consisting of (for each statistic in exp_list) a variable containing
the replicates.
		
{phang} {opt dots(#)} displays dots every # replications. By default,
one dot character is displayed each ten successful replications.
When {cmd:dots(0)} is specified, no dots are displayed. No dots are displayed
when multiple threads are specified.
		
{phang} {opt graph} displays diagnostic quantile-quantile plots for the generated
t-values for each statistic of interest. If the t-values deviate from a normal
distribution the double bootstrap will produce more accurate results than the
normal-based bootstrap CIs. Of special interest are the tails of the distribution, thus
even small deviations in these regions legitimate the use of the double bootstrap
approach. The Shapiro-Francia test statistics are a numerical test for normality
and a small p-value indicates non-normality.

{phang} {opt nowarn} surpresses any warning messages. Normally, warning messages
are shown when the number of resamples is low or when the command invoked does not
set {cmd:e(sample)}. If this is not set, {cmd:dbs} uses all cases for computation,
even when missing values are present. Be careful and remove missing values (temporary)
before running {cmd:dbs}.

{phang} {opt parallel} allows the usage of multiple threads to speed up computation.
This function makes use of the Stata program {it:parallel} (Vega Yon & Quistorff 2019).
This package must be installed if more than one thread should be used.
For details refer to the example below. If more threads than actually available are
specified the computer might crash! If you want to run {it:parallel} with user-written programs,
these cannot be defined "on the fly" (in the same do file). Save the program in an .ado file and
place it in the correct folder (for example, if the program is called xcom, then in "/ado/plus/x/".
Restart Stata afterwards. Otherwise {it:parallel} cannot find the command.


{marker ex}{...}
{title:Examples}


{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}Bootstrap summary statistics{p_end}
{phang2}{cmd:. dbs r(mean) r(p50): summarize mpg, detail}{p_end}

{pstd}Higher precision, diagnostic plots{p_end}
{phang2}{cmd:. dbs r(mean), reps(1000) repsinner(50) graph: summarize mpg, meanonly}{p_end}

{pstd}Bootstrap regression coefficients{p_end}
{phang2}{cmd:. dbs _b[weight] _b[_cons]: regress mpg weight}{p_end}

{pstd}Using analytic standard errors{p_end}
{phang2}{cmd:. dbs _b[weight] _b[_cons], analytic(r(table)[2,1] r(table)[2,2]): regress mpg weight}{p_end}

{pstd}Multithreading with {it: parallel}{p_end}
{phang2}{cmd:. net install parallel, from(https://raw.github.com/gvegayon/parallel/stable/) replace}{p_end}
{phang2}{cmd:. mata mata mlib index}{p_end}
{phang2}{cmd:. dbs r(mean), reps(5000) repsinner(100) parallel(4): summarize mpg, meanonly}{p_end}


{marker eret}{...}
{title:Stored results}

{pstd} Scalars:

{p2colset 5 20 20 2}{...}
{p2col : {cmd:e(N)}} number of observations{p_end}
{p2col : {cmd:e(level)}} confidence level{p_end}
{p2col : {cmd:e(reps)}} number of outer resamples{p_end}
{p2col : {cmd:e(repsinner)}} number of inner resamples{p_end}


{pstd} Matrices:

{p2col : {cmd:e(ci_double)}} confidence interval limits{p_end}
{p2col : {cmd:e(se)}} bootstrap standard errors{p_end}
{p2col : {cmd:e(bias)}} bootstrap bias{p_end}
{p2col : {cmd:e(sfrancia)}} Shapiro-Wilk test p-values{p_end}
{p2col : {cmd:e(thetas)}} point estimates{p_end}


{marker ref}{...}
{title:References}
{phang}
	Hesterberg, T.C. (2015): What Teachers Should Know About the Bootstrap:
	Resampling in the Undergraduate Statistics Curriculum, in: The American
	Statistician 69(4): 371-386.
    {p_end}
{phang}
	Vega Yon, G.G; Quistorff, B. (2019): parallel: A command for parallel computing, in:
	The Stata Journal 19(3): 667-684.
    {p_end}
	
	
{marker ref}{...}
{title:Installation & Updates}
{pstd} Most recent files are available from Github{p_end}

{phang2}{cmd:. net install dbs, from(https://raw.github.com/fbittmann/dbs/stable) replace}{p_end}


{title:Author}

{pstd} Felix Bittmann, University of Bamberg, felix.bittmann@uni-bamberg.de

{pstd}Thanks for citing this software as follows:

{pmore}
Bittmann, Felix (2020): dbs: Stata module to compute double bootstrap confidence intervals.
Available from: https://github.com/fbittmann/dbs.


{title:Also see}

{psee} Helpfile:  {helpb bootstrap}{p_end}
{psee} Helpfile:  {helpb estat bootstrap}{p_end}

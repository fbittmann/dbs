cap program drop dbs
program define dbs, eclass
	*! version 1.1.1  Felix Bittmann  2022-08-11
	version 15
	
	*Parse command*
	*https://www.elwyndavies.com/stata-tips/create-a-stata-program-that-functions-as-a-prefix/
	gettoken left right2 : 0, parse(":")
	if `"`left'"' == ":" {
		local right `"`right2'"'
	}
	else {
		gettoken right3 right : right2, parse(":")
	}
	local 0: copy local left
	local command: copy local right
	local version : di "version " string(_caller()) ":"	//get user version
	quiet `version' set rng default	//use version default RNG
	
	*Continue with regular syntax*
	syntax [anything(name=expression)], ///
		[reps(integer 50) ///
		repsinner(integer 25) ///
		level(cilevel) ///
		seed(str) ///
		dots(integer 10) ///
		graph /// display normality test plots
		cluster(varlist max=1) ///	resample option
		idcluster(varlist max=1) ///	resample option
		strata(passthru) ///	resample option
		JACKknife ///
		saving(str) ///
		nowarn ///
		PARallel(integer 1) ///
		ANAlytic(str) ///
		]

	ereturn clear
	tempfile originaldata
	quiet save `originaldata', replace

	
	if `parallel' < 1 {
		di as error "Enter integer larger than 0 for option parallel.
		exit 100
	}
	
	*** Analytic or jackknife standard errors requested ***
	if "`analytic'" != "" | "`jackknife'" != "" {
		local repsinner = 0
	}
	
	if "`analytic'" != "" & "`jackknife'" != "" {
		di as error "Either specify analytic standard errors or the jackknife but not both."
		exit 197
	}
	
	
	quiet `version' `command'
	if e(sample) == 1 {
		quiet drop if e(sample) != 1
		quiet count if e(sample)
		local N = r(N)
	}
	else {
		local N = c(N)
		if "`warn'" == "" {
			di as text "Warning:  Because the command invoked does not set " as input "e(sample)" as text ","
			di as text "          " as input "dbs" as text " has no way to determine which observations are"
			di as text "          used incalculating the statistics and so assumes"
			di as text "          that all observations are used. Check for missing"
			di as text "          values with care."
			di ""
		}
	}
	****************************************************************************
	local exp_total : list sizeof local(expression)
	matrix empvalues = J(1, `exp_total', .)				//Stores point estimates

	qui `version' `command'
	foreach NUM of numlist 1/`exp_total' {
		local current_theta `: word `NUM' of `expression''
		matrix empvalues[1, `NUM'] = `current_theta'
		local test = empvalues[1, `NUM']
		if missing(`test') {
			di as error "Theta evaluates to missing for the entire sample for statistic ``NUM''"
			error 430
		}
	}
	
	local outgraphs ""
	if `dots' > 0 & `parallel' == 1 {
		display as text "Bootstrap replications (" as result "`reps' / `repsinner'" as text ")"
		display "{c -}{c -}{c -}{c -}{c +}{c -}{c -}{c -} 1 {c -}{c -}{c -}" /*
		*/ "{c +}{c -}{c -}{c -} 2 {c -}{c -}{c -}{c +}{c -}{c -}{c -} 3 {c -}{c -}{c -}" /*
		*/  "{c +}{c -}{c -}{c -} 4 {c -}{c -}{c -}{c +}{c -}{c -}{c -} 5"
	}
	*Run a single thread*
	if `parallel' == 1 {
		dbs_resampling, data(`originaldata') reps(`reps') repsinner(`repsinner') command(`command') ///
			totalstats(`exp_total') expression(`expression') totalinstances(1) dots(`dots') seed(`seed') ///
			`strata' cluster(`cluster') idcluster(`idcluster') analytic(`analytic') jackknife(`jackknife')
	}
	
	*Run multiple threads*
	else {
		cap parallel setclusters `parallel', force
		if _rc != 0 {
			di as error "Error:  cannot initialize starting 'parallel'. Please make sure to install or"
			di as error "        update to the most recent version. Type:"
			di as error "        . net install parallel, from(https://raw.github.com/gvegayon/parallel/stable/) replace"
			di as error "        . mata mata mlib index"
		exit 100
		}
		
		di as text "Since multiple instances work in parallel, no progress visualization is available."
		di ""
		
		if "`seed'" !=  "" {		//Prepare different seeds
			set seed `seed'
			local allseeds ""
			foreach i of numlist 1/`parallel' {
				local a = abs(round(rnormal() * 1000000))
				local allseeds `allseeds' `a'
			}
		}
		quiet parallel, seed(`allseeds'): ///
			dbs_resampling, data(`originaldata') reps(`reps') repsinner(`repsinner') command(`command') ///
			totalstats(`exp_total') expression(`expression') totalinstances(`parallel') dots(0) ///
			`strata' cluster(`cluster') idcluster(`idcluster') analytic(`analytic') jackknife(`jackknife')
	}
	

	****************************************************************************
	*From here on, the random part is done and all data are loaded in memory
	local tcrit_lower = (100 - `level' ) / 2 
	local tcrit_upper = 100 - `tcrit_lower'
	matrix boot_se = J(1, `exp_total', .)
	matrix ci_double = J(2, `exp_total', .)
	matrix rownames ci_double = ll ul
	matrix sfrancia = J(1, `exp_total', .)
	matrix bias = J(1, `exp_total', .)
	
	foreach NUM of numlist 1/`exp_total' {
		*local col = 2 * `NUM' - 1
		quiet sum theta`NUM'	//summarize theta_stars
		local thetameans = r(mean)
		matrix boot_se[1, `NUM'] = r(sd)
		local bootse = boot_se[1, `NUM']
		if missing(`bootse') | `bootse' == 0 {
			di as error "Error for statistic ``NUM''"
			di as error "No variation in bootstrap resamples!"
			matrix ci_double[1, `NUM'] = 0
			matrix ci_double[2, `NUM'] = 0
		}
		else {
			*local col = `col' + 1
			quiet centile tval`NUM', centile(`tcrit_lower' `tcrit_upper')
			local cent_lower = r(c_1)
			local cent_upper = r(c_2)
			matrix bias[1, `NUM'] = `thetameans' - empvalues[1, `NUM']
			matrix ci_double[1, `NUM'] = empvalues[1, `NUM'] - boot_se[1, `NUM'] * `cent_upper'
			matrix ci_double[2, `NUM'] = empvalues[1, `NUM'] - boot_se[1, `NUM'] * `cent_lower'
			quiet sfrancia tval`NUM'			//Test for normality of t-values
			matrix sfrancia[1, `NUM'] = r(p)
			local temp = round(sfrancia[1, `NUM'], 0.00001)
			if "`temp'" == "0" {
				local tempp "p < .00001"
			}
			else {
				local tempp "p = `temp'"
			}
			
			if "`graph'" != "" {
				tempname h`NUM'
				local outgraphs `outgraphs' `h`NUM''
				qnorm tval`NUM', name(`h`NUM'', replace) title("``NUM''") nodraw ///
					note(`tempp') ytitle("t-values")
			}
		}
	}
	
	****************************************************************************
	*** Display ***
	****************************************************************************
	di ""
	di ""
	di as text "Bootstrap results						Number of obs = " as result "`N'"
	di as text "								         Reps = " as result "`reps'"
	di as text "								 Reps (inner) = " as result "`repsinner'"
	di as text "command: `command'"
	if "`analytic'" != "" {
		di as text "analytic standard error(s) provided (shown in brackets)"
	}
	if "`jackknife'" != "" {
		di as text "Jackknife standard errors computed"
	}
	foreach NUM of numlist 1/`exp_total' {
		if "`analytic'" != "" {
			local current_theta `: word `NUM' of `expression''
			local current_se_type `: word `NUM' of `analytic''
			di as text "	_bs_`NUM': " as result "`current_theta' [`current_se_type']"
		}
		else {
			local current_theta `: word `NUM' of `expression''
			di as text "	_bs_`NUM': " as result "`current_theta'"
		}
			
	}
	di ""
	di as text "{hline 10}{c TT}{hline 70}"
	di as text "          {c |}   Observed   Bootstrap               Shapiro-"
	di as text "          {c |}     Coef.    Std. Err.      Bias     Francia    [`level'% Conf. Interval]"
	*di as text "          {c |} Obs. Coef.   Boot. Std. Err.   Bias   SFrancia   [`level'% Conf. Interval]"
	di as text "{hline 10}{c +}{hline 70}"

	foreach NUM of numlist 1/`exp_total' {
		local a = empvalues[1, `NUM']
		local b = boot_se[1, `NUM']
		local c = bias[1, `NUM']
		local d = sfrancia[1, `NUM']
		local e = ci_double[1, `NUM']
		local f = ci_double[2, `NUM']
		di as text "   _bs_`NUM'  {c |}" as result %9.4f `a' "   "%9.4f `b' /*
		*/ "   "%9.3f `c' "   "%9.3f `d' "   "%9.4f `e' "   "%9.4f `f'
		*di "	_bs_`NUM'	`a'	`b'	`c'	`d'	`e'"
	}
	di as text "{hline 10}{c BT}{hline 70}"
	if `reps' < 100 {
		di as text "Warning:  SFrancia statistic might be unreliable if number of resamples is low."
	}
	****************************************************************************
	ereturn clear
	*Return Matrices*
	ereturn matrix ci_double = ci_double
	ereturn matrix thetas = empvalues
	ereturn matrix se = boot_se
	ereturn matrix bias = bias
	ereturn matrix sfrancia = sfrancia
	
	*Return Scalars*
	ereturn scalar level = `level'
	ereturn scalar reps = `reps'
	ereturn scalar repsinner = `repsinner'
	ereturn scalar N = `N'
	if "`graph'" != "" { 
		graph combine `outgraphs'
	}
	if "`saving'" != "" {
		save `saving'
	}
	quiet use `originaldata', clear
end

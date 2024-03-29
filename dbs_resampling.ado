cap program drop dbs_resampling
program define dbs_resampling
	*! version 1.1.0  Felix Bittmann  2022-08-06
	/*This auxillary program does the resampling work so we can
	run the entire process in a parallel fashion if desired*/
syntax, data(str) ///
	reps1(int) ///
	reps2(int) ///
	command(str) ///
	totalstats(int) ///
	expression(str) ///
	totalinstances(int) ///
	[dots(integer 10) ///
	seed(str) ///
	strata(passthru) ///
	cluster(passthru) ///
	idcluster(passthru) ///
	analytical(str) ///
	]
	
	
	local version : di "version " string(_caller()) ":"	//get user version
	
	quiet use `data', clear		//Load original dataset because parallel splits it up between instances
	if "`seed'" != "" {
		`version' set seed `seed'
	}
	local reps1 = ceil(`reps1' / `totalinstances')
	local exp_total : list sizeof local(expression)
	
	*Generate unique tempfiles over all instances*
	if `totalinstances' == 1 {
		local iid = 1
	}
	else {
		local iid = $pll_instance
	}	
	tempname n`iid'
	tempfile t`iid'
	local allvars ""
	foreach NUM of numlist 1/`exp_total' {
		local allvars `allvars' theta`NUM' tval`NUM'
	}
	postfile `n`iid'' `allvars' using `t`iid''
	matrix empvalues = J(1, `exp_total', .)
	



	quiet `version' `command'
	*tokenize `expression'
	foreach NUM of numlist 1/`exp_total' {
		local current_theta `: word `NUM' of `expression''
		matrix empvalues[1, `NUM'] = `current_theta'
	}
	
	
	*** Analytical SEs provided ***
	if "`analytical'" != "" {
		forvalues R1 = 1/`reps1' {
			matrix thetas = J(1, `exp_total', .)		//Stores thetas and t-values
			matrix ses = J(1, `exp_total', .)			//Store analytical standard errors
			if `dots' > 0 & mod(`R1', `dots') == 0 {
				display "." _cont
				local c = `c' + 1
				if mod(`c', 50) == 0 {
					di " (`R1')" _cont
					di ""
				}
			}		
			`version' bsample, `cluster' `strata' `idcluster'
			quiet `version' `command'
			*tokenize `expression'
			foreach NUM of numlist 1/`exp_total' {
				local current_theta `: word `NUM' of `expression''
				matrix thetas[1, `NUM'] = `current_theta'
				local current_se `: word `NUM' of `analytical''	//access specific SE
				matrix ses[1, `NUM'] = `current_se'
			}
		
			
			local allres ""
			foreach NUM of numlist 1/`exp_total' {
				local tval = (thetas[1, `NUM'] - empvalues[1, `NUM']) / ses[1, `NUM']
				local allres `allres' (thetas[1, `NUM']) (`tval')
			}
			post `n`iid'' `allres'
			quiet use `data', clear
		}
		postclose `n`iid''
		use `t`iid'', clear		//load postfile dataset in memory
	}
	
	
	*** Double Bootstrapping ***
	else {
		forvalues R1 = 1/`reps1' {
		matrix thetas = J(1, `exp_total', .)		//Stores thetas and t-values
		if `dots' > 0 & mod(`R1', `dots') == 0 {
			display "." _cont
			local c = `c' + 1
			if mod(`c', 50) == 0 {
				di " (`R1')" _cont
				di ""
			}
		}		
		`version' bsample, `cluster' `strata' `idcluster'
		quiet `version' `command'
		*tokenize `expression'
		foreach NUM of numlist 1/`exp_total' {
			local current_theta `: word `NUM' of `expression''
			matrix thetas[1, `NUM'] = `current_theta'
		}
		
		matrix innervalues = J(`reps2', `exp_total', .)		//Stores innerthetas
		tempfile bsdata
		quiet save `bsdata', replace
		forvalues R2 = 1/`reps2' {
			`version' bsample, `cluster' `strata' `idcluster'
			quiet `version' `command'
			foreach NUM of numlist 1/`exp_total' {
				local current_theta `: word `NUM' of `expression''
				matrix innervalues[`R2', `NUM'] = `current_theta'
			}
			quiet use `bsdata', clear
		}
		
		
		mata: work = meanvariance(st_matrix("innervalues"))
		mata: means = work[1, .]'	//Compute column means
		mata: st_matrix("means", means)
		mata: sds = sqrt(diagonal(work[2::rows(work),]))	//Compute column SDs
		mata: st_matrix("sds", sds)
		
		local allres ""
		foreach NUM of numlist 1/`exp_total' {
			local tval = (thetas[1, `NUM'] - empvalues[1, `NUM']) / sds[`NUM', 1]
			local allres `allres' (thetas[1, `NUM']) (`tval')
		}
		post `n`iid'' `allres'
		quiet use `data', clear
	}
	postclose `n`iid''
	use `t`iid'', clear		//load postfile dataset in memory
	}	
end

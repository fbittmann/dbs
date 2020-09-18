dbs: Stata module for computing double bootstrap confidence intervals
=====================================================================
Double bootstrap confidence intervals promise **more precise** results with a better nominal coverage for many applications. The package is **lightweight**, easy to use
and very similar to the regular standard Stata bootstrap command. **Multithreading** allows the computation with multiple instances even without Stata-MP for massive
speed gain. Please refer to the help file for details.

Installation
============

``` stata
. net install dbs, from(https://raw.github.com/fbittmann/dbs/stable) replace
```

Examples
========

Setup and minimal example
-------------------------
``` stata
. sysuse auto, clear
(1978 Automobile Data)

. dbs r(mean) r(p50): summarize mpg, detail
Warning:  Because the command invoked does not set e(sample),
          dbs has no way to determine which observations are
          used incalculating the statistics and so assumes
          that all observations are used. Check for missing
          values with care.

Bootstrap replications (100 / 20)
----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5
..........

Bootstrap results                                           Number of obs = 74
                                                                    Reps1 = 100
                                                                    Reps2 = 20
command:  summarize mpg, detail
    _bs_1: r(mean)
    _bs_2: r(p50)

---------------------------------------------------------------------------------
          | Observed Coef.   Boot. Std. Err.   Bias   SFrancia   [95% Conf. Interval]
----------+----------------------------------------------------------------------
   _bs_1  |  21.2973      0.6301      -0.075       0.963     20.1315     22.8198
   _bs_2  |  20.0000      0.9891       0.095       0.561     16.9322     22.4864
---------------------------------------------------------------------------------
```

Bootstrap regression coefficients
---------------------------------

``` stata
. dbs _b[weight] _b[_cons]: regress mpg weight
Bootstrap replications (100 / 20)
----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5
..........

Bootstrap results                                           Number of obs = 74
                                                                    Reps1 = 100
                                                                    Reps2 = 20
command:  regress mpg weight
    _bs_1: _b[weight]
    _bs_2: _b[_cons]

---------------------------------------------------------------------------------
          | Observed Coef.   Boot. Std. Err.   Bias   SFrancia   [95% Conf. Interval]
----------+----------------------------------------------------------------------
   _bs_1  |  -0.0060      0.0006      -0.000       0.003     -0.0077     -0.0048
   _bs_2  |  39.4403      1.9402       0.023       0.001     35.2007     44.9857
---------------------------------------------------------------------------------
```

Multithreading with parallel
----------------------------

``` stata
. net install parallel, from(https://raw.github.com/gvegayon/parallel/stable/) replace
. mata mata mlib index
. dbs r(mean), reps1(5000) reps2(100) parallel(4): summarize mpg, meanonly
Warning:  Because the command invoked does not set e(sample),
          dbs has no way to determine which observations are
          used incalculating the statistics and so assumes
          that all observations are used. Check for missing
          values with care.

Since multiple instances work in parallel, no progress visualization is available.



Bootstrap results                                           Number of obs = 74
                                                                    Reps1 = 5000
                                                                    Reps2 = 100
command:  summarize mpg,  meanonly
    _bs_1: r(mean)

---------------------------------------------------------------------------------
          | Observed Coef.   Boot. Std. Err.   Bias   SFrancia   [95% Conf. Interval]
----------+----------------------------------------------------------------------
   _bs_1  |  21.2973      0.6727      -0.003       0.000     19.9914     22.7805
---------------------------------------------------------------------------------

```




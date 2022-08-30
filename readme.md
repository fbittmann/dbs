dbs: Stata command for computing double bootstrap confidence intervals
======================================================================
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

Multithreading with *parallel*
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


Using analytical standard errors
----------------------------
``` stata
. regress mpg weigh

      Source |       SS           df       MS      Number of obs   =        74
-------------+----------------------------------   F(1, 72)        =    134.62
       Model |   1591.9902         1   1591.9902   Prob > F        =    0.0000
    Residual |  851.469256        72  11.8259619   R-squared       =    0.6515
-------------+----------------------------------   Adj R-squared   =    0.6467
       Total |  2443.45946        73  33.4720474   Root MSE        =    3.4389

------------------------------------------------------------------------------
         mpg |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
      weight |  -.0060087   .0005179   -11.60   0.000    -.0070411   -.0049763
       _cons |   39.44028   1.614003    24.44   0.000     36.22283    42.65774
------------------------------------------------------------------------------

. matrix list r(table)

r(table)[9,2]
            weight       _cons
     b  -.00600869   39.440284
    se   .00051788   1.6140031
     t   -11.60251   24.436312
pvalue   3.798e-18   1.385e-36
    ll  -.00704106   36.222827
    ul  -.00497632    42.65774
    df          72          72
  crit   1.9934636   1.9934636
 eform           0           0

. dbs _b[weight] _b[_cons], reps(5000) dots(0) seed(123) analytic(r(table)[2,1] r(table)[2,2]): ///
>         regress mpg weigh


Bootstrap results                                           Number of obs = 74
                                                                     Reps = 5000
                                                             Reps (inner) = 0
command:          regress mpg weigh
analytic standard error(s) provided (shown in brackets)
    _bs_1: _b[weight] [r(table)[2,1]]
    _bs_2: _b[_cons] [r(table)[2,2]]

---------------------------------------------------------------------------------
          |   Observed   Bootstrap               Shapiro-
          |     Coef.    Std. Err.      Bias     Francia    [95% Conf. Interval]
----------+----------------------------------------------------------------------
   _bs_1  |  -0.0060      0.0006      -0.000       0.000     -0.0075     -0.0048
   _bs_2  |  39.4403      1.9915      -0.008       0.000     34.8924     44.9830
---------------------------------------------------------------------------------



Citation
============
Thanks for citing this software as follows:

> Bittmann, Felix (2020): dbs: Stata module to compute double bootstrap confidence intervals. Available from: https://github.com/fbittmann/dbs





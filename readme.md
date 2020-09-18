dbs: Stata module for computing double bootstrap confidence intervals
=====================================================================
Double bootstrap confidence intervals promise **more precise** results with a better nominal coverage for many applications. The package is **lightweight**, easy to use
and very similar to the regular standard Stata bootstrap command. **Multithreading** allows the computation with multiple instances even without Stata-MP for massive
speed gain.

Installation
============

``` stata
. net install parallel, from(https://raw.github.com/fbittmann/dbs) replace
```


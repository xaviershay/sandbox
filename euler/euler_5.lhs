> import Test.HUnit

Problem 5
---------

 > 2520 is the smallest number that can be divided by each of the numbers from
 1 to 10 without any remainder.

 > What is the smallest positive number that is evenly divisible by all of the
 numbers from 1 to 20?

Kind of cheating by using the built-in `lcm` primitive, but we have already
written a prime factoring algorithm (the basis of the `lcm` algorithm in
problem three.

> eulerFive n = foldr lcm n [1..n-1]
> testsFive =
>   [ "#5 given"   ~: 2520      ~=? eulerFive 10
>   , "#5 problem" ~: 232792560 ~=? eulerFive 20
>   ]

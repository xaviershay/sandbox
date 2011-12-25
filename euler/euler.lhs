Project Euler
=============

  > Project Euler is a series of challenging mathematical/computer programming
  problems that will require more than just mathematical insights to solve.
  Although mathematics will help you arrive at elegant and efficient methods,
  the use of a computer and programming skills will be required to solve most
  problems. -- http://projecteuler.net

This is my attempt at them.

Both sample input and expected answers (after they have been solved) will be
expressed as HUnit tests at the bottom of the file.

> import Test.HUnit

List functions will be used extensively.

> import List

Problem 1
---------

  > If we list all the natural numbers below 10 that are multiples of 3 or 5,
  we get 3, 5, 6 and 9. The sum of these multiples is 23.

  > Find the sum of all the multiples of 3 or 5 below 1000.

> eulerOne max = sum . nub $ (multiplesOf 3) ++ (multiplesOf 5)
>   where  multiplesOf x = [x,x*2..max-1]
> testsOne =
>   [ "#1 given"   ~: 23 ~=? eulerOne 10
>   , "#1 problem" ~: 233168 ~=? eulerOne 1000
>   ]


Epilogue
--------

Run all given test cases as the main function of this file.

> main = runTestTT $ TestList ( testsOne )

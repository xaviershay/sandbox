> import Test.HUnit

Problem 7
---------

 > By listing the first six prime numbers: 2, 3, 5, 7, 11, and 13, we can see
 that the 6th prime is 13.

 > What is the 10 001st prime number?

Having read the [Haskell wiki][haskell-wiki-primes] page on prime generation a
few times, I cheated and just nabbed an algorithm with a good trade-off between
readability and efficiency ("Optimal trial divison").

[haskell-wiki-primes]: http://www.haskell.org/haskellwiki/Prime_numbers

> coprime factors n = foldr (\p r -> p*p > n || (rem n p /= 0 && r))
>                           True factors
> primes = 2 : 3 : filter (coprime $ tail primes) [5,7..]
> isPrime = coprime primes

> eulerSeven x = head $ drop (x - 1) primes

> testsSeven =
>   [ "#7 given"   ~: 13     ~=? eulerSeven 6
>   , "#7 problem" ~: 104743 ~=? eulerSeven 10001
>   ]

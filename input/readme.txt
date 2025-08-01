LINEAR
======

github.com/PL-ML/code2inv
benchmarks > C_instances > c

Initially the suite has 133 benchmarks.
* 37 differ only on postcondition => combined
* 38 are duplicates               => removed
*  9 are invalid                  => removed
This leaves 49 benchmarks.

====

001 [x, y] 0≤y<100000

       x == 1 + (y*y - y)/2
    ≡ 2x == 2 + (y^2 - y)

002 [x, y] 0≤y<1000

       x == 1 + (y*y - y)/2
    ≡ 2x == 2 + (y^2 - y)

003 [x, y, z] 0≤x≤4

       x == 0 ∨ z >= y
















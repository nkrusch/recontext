### Some baseline assumptions about inputs

* A variable holds one value at a time
* Integer domain (or a subset)
* null values -- unknown

I use "trace" as a generic term for some tabular data.
Could be generated from a program execution, but could also come from other sources.

### Intuitions

* The inference techniques may fail easily & maybe cannot say much (why/what makes them fail).
* More entries in traces; increasing "variables", or noise in traces will likely break the inference.
* Can we uncover the limitations/boundary of the current existing techniques?

### About other tools

* Daikon observes concrete program states that capture the values of variables at designated locations in the program when a program is run on a given input. 
  By sampling large numbers of inputs, Daikon can determine relationships that may hold among variables across those samples. 
  Confirming that those relationships constitute a true invariant has been a focus of follow-on work to Daikon. 

* Several invariant generation approaches, e.g., 
  [NumInv](https://github.com/dynaroars/numinv), 
  [G-CLN](https://www.cs.columbia.edu/~rgu/publications/pldi20-yao.pdf) 
  use a hybrid approach that dynamically infers candidate invariants and then attempts to verify that they hold for all inputs.


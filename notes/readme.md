# Questions

1. [How does DIG work?](dig.md)

2. What is the impact on the inference if we...
   * increase the degree, i.e., number of variables
   * add more/give less traces, i.e., change number of rows
   * restrict value domain (Z, nat, binary)

3. What are some other ways to infer invariants from numerical data
   * This is a lit review question (may have nothing to do with FM or PL)
   * Ultimately we want to do some comparison


# Notes

### Some baseline assumptions about inputs

* A variable holds one value at a time
* Integer domain (or a subset)
* null values -- unknown

I use "trace" as a generic term for numerical tabular data.
A trace could be generated from a program execution (but it could also come from other sources).

### Intuitions

* The inference techniques may fail easily & maybe cannot say much (why/what makes them fail).
* More entries in traces; increasing "variables", or noise in traces will likely break the inference.
* Can we uncover the limitations/boundary of the current existing techniques?

### About other invariant inference techniques

* Daikon observes concrete program states that capture the values of variables at designated locations in the program when a program is run on a given input. 
  By sampling large numbers of inputs, Daikon can determine relationships that may hold among variables across those samples. 
  Confirming that those relationships constitute a true invariant has been a focus of follow-on work to Daikon. 

* Several invariant generation approaches, e.g., 
  [NumInv](https://github.com/dynaroars/numinv), 
  [G-CLN](https://www.cs.columbia.edu/~rgu/publications/pldi20-yao.pdf) 
  use a hybrid approach that dynamically infers candidate invariants and then attempts to verify that they hold for all inputs.


# Vocabulary & Terms

* _CEGIR - Counterexample guided invariant refinement_    
  : iterates the inference and verification processes until reaching a stable result.

* _numerical invariants_      
  : capture numerical relations among program variables; can be conjunctive, disjunctive, etc.


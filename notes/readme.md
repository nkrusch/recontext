# Questions

1. [How does DIG work?](dig.md)

2. What is the impact on the inference if we...
   * Increase the degree, i.e., number of variables
   * Adding more/giving fewer traces, i.e., change the number of rows
   * Restrict value domain (Z, nat, binary)

3. What are some other ways to infer invariants from numerical data
   * This is a lit review question (may have nothing to do with FM or PL)
   * Ultimately we want to do some comparison


# Notes

### Some baseline assumptions about inputs

* A variable holds one value at a time
* Integer domain (or a subset)
* relationships between variables (vs. individual variables)
* null values -- unknown

I use "trace" as a generic term for numerical tabular data.
A trace could be generated from a program execution (but it could also come from other sources).

### Intuitions

* I suspect an inference technique will fail "easily" if we only provide traces as input
  - We may be unable to say much about the input => what can we say?
  - Why/what makes the inference fail?
  
* Increasing the difficulty of inference (e.g., higher variable count, more traces, or "noisy" trace) will likely break inference.
* Can we uncover/describe the limitations/boundary of the state-of-the-art techniques?

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


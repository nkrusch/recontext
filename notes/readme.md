# Questions

1. [How does DIG work?](dig.md)

2. What is the impact on the inference if we...
    * Increase the degree, i.e., number of variables [A: exponential]
    * Adding more/giving fewer traces, i.e., change the number of rows [A: should be adaptable]
    * Restrict the domain of values (Z, nat, binary) [A: ???]

3. What are some other ways to infer invariants from numerical data
    * This is a lit review question (may have nothing to do with FM or PL)
    * Ultimately we want to do some comparison

4. What does a case study look like/how is it structured?
    * Look at previous works at same venue for inspiration

# Baseline assumptions

* We are interested in [_numerical (relational?) invariants_](vocabulary.md)
* We want to infer invariants about variables: ideally relationships _between_ variables
* A "variable" holds one value at a time
* Assume values are in integer domain (or its subset)
* Treatment of null values is unknown

"Trace" is as a generic term for inputs -- can be viewed as numerical tabular data ("data frames").   
A trace could be generated from a program execution, but it could also come from other sources.    
An "invariant" may correspond to a "constraint" in some other literature.  

# Intuitions

* Inference will fail "easily" if we only provide traces as input
  - We may be unable to say much about the input (what can we say?)
  - Why? What makes the inference fail?
  
* Increasing the difficulty of inference (e.g., higher variable count, more
  traces, or "noisy" trace) will likely break inference.
  - Can we uncover the limitations/boundary of the state-of-the-art techniques?

* For polynomial equalities: 
  - in DIG, the polynomial degree and variable count exponentially increase the solution space/solver time
  - Can we preprocess a trace, or fix some terms by deduction, to make this more scalable? [cf. @bouajjani2022]
  - Some related strategies: prune the search space, use semantics to check feasibility, 
    model space of feasible programs; use types to prune infeasible programs. [@wang2022]
  
* Using diverse input samples (maximally different) is helpful to guide the inference 
  - How to locate such diverse inputs in traces?

* Assumptions about DIG without symbolic states:
  - Instrumentation should not occur
  - CEGIR-based inference should not iterate
  - [LIKELY FALSE] Inequality invariants should not be inferrable
  - Symbolic exec. impacts invariant quality; should NOT affect expressivity
  



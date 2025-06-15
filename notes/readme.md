# Baseline assumptions

* We are interested in numerical invariants
* A variable holds one value at a time
* Assume integer domain or its subset (but real domain may be achievable) 
* Hope to infer invariants about individual variables and ideally relationships _between_ variables
* The inference is automatic (no manual problem-specific annotations/beyond what is possible through CLI options)
* Treatment of null values is unknown

I use "trace" as a generic term for inputs that that can be viewed as numerical tabular data ("data frames").   
A trace could be generated from a program execution, but it could also come from other sources.    
An "invariant" may correspond to a "constraint" in some other domains.  

# Intuitions

* I suspect inference will fail "easily" if we only provide traces as input
  - We may be unable to say much about the input (what can we say?)
  - Why? What makes the inference fail?
  
* Increasing the difficulty of inference (e.g., higher variable count, more
  traces, or "noisy" trace) will likely break inference.
  - Can we uncover the limitations/boundary of the state-of-the-art techniques?

* For polynomial equalities: 
  - The polynomial degree and variable count exponentially increases the solution space/solver time
  - Can we preprocess a trace, or fix some terms by deduction, to make this more scalable?
  
* Using diverse input samples is helpful to guide the inference 
  - How to locate such diverse input (maximally different entries) in traces?

* Assumptions about Using DIG without symbolic states:
  - Instrumentation should not occur
  - CEGIR-based inference should not iterate
  - [LIKELY FALSE] Inequality invariants should not be inferrable
  - Symbolic execution impacts the quality of generated invariants;
    it should NOT affect the overall expressivity, and what equations may be generated 
  
# Questions

1. [How does DIG work?](dig.md)

2. What is the impact on the inference if we...
    * Increase the degree, i.e., number of variables [A: exponential]
    * Adding more/giving fewer traces, i.e., change the number of rows [A: should be adaptable]
    * Restrict the domain (Z, nat, binary) [A: ???]

3. What are some other ways to infer invariants from numerical data
    * This is a lit review question (may have nothing to do with FM or PL)
    * Ultimately we want to do some comparison

4. What does a case study look like/how is it structured?
    * Look at previous works at same venue for inspiration


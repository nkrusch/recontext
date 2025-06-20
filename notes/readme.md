# Active questions

1. [How does DIG work?](dig.md)

2. (lit review) [What are some other ways to infer invariants from numerical data?](related.md)
    * [(De Moura and Bjørner, 2011)](https://doi.org/10.1145/1995376.1995394) is a nice intro connecting various domains
    * Discussion of the [PL/FM techniques](techniques.md)
    * Ultimately we want to do some comparison between the techniques

3. For different techniques, what is the impact on the inference if we...
    * Increase the degree, i.e., number of variables 
    * Adding more/giving fewer traces, i.e., change the number of rows 
    * Restrict the domain of values (Z, nat, binary)

4. Experiments: What are we testing and on what?
    * TODO: start thinking about the right experiment design
    * see: [this](https://www.sigplan.org/Resources/EmpiricalEvaluation/) and
      [this](https://evaluate.inf.usi.ch/sites/default/files/EvaluateCollaboratoryTR1.pdf)

5. What does a case study look like/how is it structured?
    * Look at previous works at same venue for inspiration:
      [1](https://arxiv.org/pdf/2412.07235)

6. What are the challenges and lessons learned from transferring research 
   ideas to new settings (think of these questions in advance)?

# Baseline assumptions

We are interested in [_numerical (relational?) invariants_](vocabulary.md)

_Variable_ is a symbolic abstraction (for variable $x$, we have $x \mapsto int$) 
* A variable holds one value at one point in time
* Values are in the integer domain (or its subset) 
* Values (at different times) are consistent (noise-free)
* Treatment of null values is unknown [maybe remove?]

_Trace_ is as a generic term for a record of variable values
* A trace could be generated from a program execution, but it could also come from other sources.
* in general: numerical tabular data ("data frames") can be viewed as a trace
* Traces, and the values they contain, are always over finite domains. 
  
We want to infer invariants about variables and ideally relationships _between_ variables
* Invariant holds for _each instance_ of a trace (not _across_ many instances)
* An "invariant" is an [(arithmetic) constraint](./vocabulary.md) in some other literature.

# Intuitions

* Suspect inference will fail easily if we only provide traces as input
  - We may be unable to say much about the input (what can we say?)
  - Why? What makes the inference fail?
  
* Increasing the difficulty of inference (e.g., higher variable count, more
  traces, or noisy trace) will likely break inference.
  - Can we uncover the limitations/boundary of techniques?

* Invariant polynomial degree and variable count increases the solution space/solver time
  - Can we preprocess a trace, or fix some terms by deduction, to make this more scalable? [cf. @bouajjani2022]
  - Some related strategies: pruning the search space, using semantics to check feasibility, 
    modeling the space of feasible programs; using types to prune infeasible outputs [@wang2022]
  
* Using diverse input samples (maximally different) is helpful to guide the inference 
  - How to locate such diverse inputs in traces?


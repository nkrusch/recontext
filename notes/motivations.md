# Motivations

THOUGHTS

* An invariant is an assertion that always holds at certain program location [@nguyen2014].
* Invariants are critical for program verification and fault-detection.
* In verification, invariants can be used to show a program meets its specification.
* More broadly, invariants support numerous software development tasks, like testing, debugging, optimization, and code maintenance [@rosenblum1995, @alagarsamy2024, @zhang2015, @ernst2000].

> Constraint-satisfaction problems arise in diverse application areas, including software and hardware verification, type inference, static program analysis, test-case generation, scheduling, planning, and graph problems, and share a common trait—a core component using logical formulas for describing states and transformations between them. [@demoura2011]

Unfortunately, invariant are implicit in programs and innovation is needed to discover them.
* Invariant inference is one of the hardest problems in verification [@feldman2019, @yu2023, @dillig2013].
* Since the 1970s, and the seminal work of [@karr1976], invariant inference is a major research area in program analysis [@nguyen2014].
* Many advanced techniques have been developed, including dynamic invariant inference.

In _dynamic invariant inference_, a program is first executed to obtain traces.
* A _trace_ if a plaintext record that captures execution-time values of variables at a particular program location.
* Based on the traces, an analysis then aims to discover numerical relations that hold in every program execution, i.e., invariants.

Numerical data is ubiquitous [develop this argument, cf. https://arxiv.org/pdf/2211.09286].
* _Tabular numerical data is essentially comparable, in format and representation, to a program trace._
* Thus, we can obtain trace-like records from various (non-program) sources.

## HYPOTHESIS

Taking as a baseline the state-of-the-art techniques developed for numerical invariant inference (in programs),
we investigate whether the same techniques generalize to analysis of numerical data (from non-program sources).

* Such capability would enable many new applications:    
  e.g., in data synthesis, needed for data protection and privacy; anomaly detection, machine learning, etc.
* Dynamic program analysis has many pre-requisites (full program, tracing execution), it can only be used in some cases     
  &rarr; the new use case would extend the utility of dynamic techniques.
* More broadly: strengthen and reveal the significance of programming languages-based of invariant inference.

## EXPECTED OUTCOME

(A) We will discover new capabilities embedded in the existing invariant inference techniques.

-or-

(B) We will improve understanding of their limitations and how to improve     
    (and understand better the role of programs in driving the inference).


## Maybe useful arguments

- The problem is undecidable in general; all practical techniques must
  search for invariants heuristically in a potentially-infinite space
  of candidates [@wang2022]

- State-of-the-art invariant synthesis tools were designed primarily
  for a single program (e.g., symbolic exec, abstract interpretation)
  => cannot be easily adapted to generate relational invariants. [@wang2022]

- Invariants based on sampled data, may produce unnecessarily complicated
  invariants (program semantics helps). [@wang2022, @nguyen2022b]

- Neural network based techniques focus on encoding program dependencies;
  often ineffective in synthesizing relational predicates. [@wang2022]

- Ideal solution does not constrain the search space (e.g., the 
  number of variables or the values) and does not fix the invariant 
  shape e.g., by bounding the number and kind of logical connectives.

- Invariant can be considered a constraint, but not vice versa; e.g., 
  precondition is a constraint, but not an invariant. Constraints define 
  limitations on the system, invariants ensure that some conditions
  remain always true (cf. <https://www.csplib.org> for examples)
  
- (invariant/constraint) inference can be seen as an inverse of a constraint 
  satisfaction problem (CSP) [@paramonov2017]. In CSP, the goal is to 
  find an instantiation of variables that satisfies given constraints. 

- Identifying [constraints] and encoding them into a mathematical model 
  requires domain knowledge and modelling expertise [@kumar2022].

- Constraint learning approaches aim to overcome this issue by learning
  constraints from past solutions. Automating the modeling step makes 
  constraint solving techniques more accessible and makes the modeling 
  process faster and cheaper. [@kumar2022]


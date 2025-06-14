# How DIG Works

* DIG is a dynamic analysis framework for inferring expressive numerical
  invariants [@nguyen2022].

* DIG can successfully discover polynomial and array invariants in 
  standard benchmark suites [@nguyen2014].


### Analysis steps

1. INPUT
   - C, Java, Java bytecode, or trace file [@dig] 
   - "concrete state" is an alias of trace
   - traces are values from numerical (reals/integer) or array variables at any program point [@nguyen2014]

2. (optional) INSTRUMENTATION                     
   - Uses symbolic execution to compute symbolic states.
   - Symbolic states are used to obtain concrete states.

3. INFERENCE of equality and inequality invariants.

   A) **Equation invariants (CEGIR-based)** [@nguyen2022c]      
      - SymInfer formulates verification conditions from symbolic states, 
        to confirm or refute an invariant, solves those using an SMT solver, 
        and produces counterexamples to refine the inference process [@nguyen2022]. 
      - Giving traces as input means symbolic states are not used [@nguyen2022c]     
      - Using traces only can generate _spurious invariants_, i.e., correct in traces,
        but not in all executions [@nguyen2022c].
      - Convergence rate depends on the form of examples [@feldman2019].

             [*] Traces -----> Inference                    [*] start
                  ↑               ↓     
                  ↑               ↓     
                  ↑            Equations   
                  ↑               ↓     
                  ↑               ↓     
             Counterexample <---- Z3 Solver <---- Symbolic states
   
   B) **Inequality invariants (SMT-based)** [@nguyen2022b]      
      Computed directly from symbolic states. 
      - Enumerate octagonal terms (x-y, x+y, etc.) and min/max-plus 
        terms, such as min(x, y, z). 
      - For each term t, use an SMT solver to compute the smallest 
        upperbound k for t, from symbolic states.

4. POSTPROCESSING
   - simplification, removing redundancy 

5. OUTPUT: Invariants

## About Invariant Inference

DIG uses concepts and tools from mathematical fields (linear algebra,
geometry, formal methods, etc.) to improve dynamic analysis [@nguyen2014].

* DIG uses _parameterized templates_ [@nguyen2014]
  - Computes the unknown coefficients in the templates directly from trace.
  - Resulting invariants are precise over the input traces.

* Different techniques are used to generate invariants, depending on the
  invariant kind (polynomial, inequality, etc.) [@nguyen2014]
  - Numerical trace data is treated as points in Euclidean space, DIG computes
    geometric shapes enclosing the points
  - Represents equality and inequality constraints among multiple variables as
    hyperplanes and polyhedra.
  - When additional inputs are available, new inequalities can be deduced from
    equality relations.
  - Polynomial relations can be viewed as geometric shapes => use linear algebra
    and geometry algorithms to reason about these invariants
       
*  (multidimensional) _array variables_ and functions that can be viewed as arrays [@nguyen2014]:
  - Invariants may represent flat (non-nested) or nested array relations 
  - Linear equations in flat arrays: 
    + 1. Find equalities among array elements 
    + 2. Identify the relations among array indices from the obtained equalities
  - Nested array relations are inferred by performing reachability analysis and by
    SMT solver
  - Automatic theorem proving is used to reason about large arrays more
    efficiently

### Example

The trace values of the two variables v1, v2 are points in the (v1, v2)-plane.
First DIG determines if these points lie on a line, represented by a linear
equation of the form c0 + c1v1 + c2v2 = 0.

If such a line does not exist, DIG builds a bounded convex polygon from these
points. The edges of the polygon are represented by linear inequalities of the
form c0 + c1v1 + c2v2 >= 0.

This technique generalizes to equations and inequalities among multiple
variables by constructing hyperplanes and polyhedra in a high-dimensional space.

To generate nonlinear constraints, DIG uses terms to represent nonlinear
polynomials over program variables, for example, t1 = v1, t2 = v1v2. This allows
DIG to generate equations such as t1 + t2 = 1. This represents a line over t1,t2
and a hyperbola over v1, v2.

## About DIG vs. SymInfer

* SymInfer takes input is a program in C, Java, or Java bytecode (but NOT
  traces) [@nguyen2022b]
* DIG supports nonlinear equalities and inequalities, of arbitrary degree, over
  numerical variables [@nguyen2014]

* Without symbolic states (these are assumptions):
  - Instrumentation should not occur 
  - CEGIR-based inference should not iterate
  - Inequality invariants should not be inferrable ==> THIS IS LIKELY FALSE

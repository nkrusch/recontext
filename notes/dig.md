# How DIG Works

DIG is a dynamic analysis framework for inferring expressive numerical invariants [@nguyen2022].

DIG supports nonlinear equalities and inequalities, of arbitrary degree, over numerical variables [@nguyen2014]

DIG takes as input the set $V$ of variables, that are in scope at location $L$, the associated traces $X$, and a maximum degree $d$. 
It returns a set of possible polynomial relations among the variables in $V$ whose degree is at most $d$ [@nguyen2014].

DIG can successfully discover polynomial and array invariants in standard benchmark suites (of programs) [@nguyen2014].

## Analysis steps

**DIG Workflow**

     Traces --→ INV GENERATOR --→ Post Process --→ Candidate Invariants

1. **INPUT**
   - C, Java, Java bytecode, or trace file ("concrete states") [@dig]
   - traces are values from numerical (reals/integer) or array variables at any program point [@nguyen2014]

2. (optional) **INSTRUMENTATION**                     
   - Uses symbolic execution to compute symbolic states.
   - Symbolic states are used to obtain concrete states.

3. **INFERENCE** of equality and inequality invariants.

   A) **Equation invariants (CEGIR-based)** [@nguyen2022c]      
      - SymInfer formulates verification conditions from symbolic states, 
        to confirm or refute an invariant, solves those using an SMT solver, 
        and produces counterexamples to refine the inference process [@nguyen2022]. 
      - Giving traces as input means symbolic states are not used [@nguyen2022c]     
      - Using traces only can generate _spurious invariants_, i.e., correct in traces,
        but not in all executions [@nguyen2022c].
      - Convergence rate depends on the form of examples [@feldman2019].

             [*] Traces -----→ Inference                    [*] start
                  ↑               ↓     
                  ↑               ↓     
                  ↑            Equations   
                  ↑               ↓     
                  ↑               ↓     
             Counterexample ←-- Z3 Solver ←-- Symbolic states
   
   B) **Inequality invariants (SMT-based)** [@nguyen2022b] - computed directly from symbolic states. 
      - Enumerate octagonal terms (x-y, x+y, etc.) and min/max-plus 
        terms, such as min(x, y, z). 
      - For each term t, use an SMT solver to compute the smallest 
        upperbound k for t, from symbolic states.

4. **POSTPROCESSING** (simplification + removing redundancy) [@nguyen2014]
   - pruning and filtering to remove redundant and spurious invariants
   - pruning removes invariants that are logical implications from other invariants, 
     e.g. keep $x=y$ and discard $x^2=y^2$.
   - Traces not used in inference are used to check the resulting invariants
   - Using symbolic execution helps in this step; to procude higher quality invariants [@nguyen2022]

5. **OUTPUT** Invariants

## About Invariant Inference

The generator creates relations that are polynomial, disjunctive, and/or flat and nested arrays.

DIG uses concepts and tools from mathematical fields (linear algebra, geometry, formal methods, etc.) to improve dynamic analysis [@nguyen2014].

DIG uses **_parameterized templates_** [@nguyen2014]
- Computes the unknown coefficients in the templates directly from trace.
- Resulting invariants are precise over the input traces.

Inference is based on a **subset of traces** for inference [@nguyen2014]
Since an invariant holds for any set of traces, it is likely that we
can find that same invariant using a smaller subset of the available traces.

**Different techniques** are used to generate invariants, depending on the
invariant kind (polynomial, inequality, etc.) [@nguyen2014]
Trace data is treated as points in Euclidean space and DIG computes
geometric shapes enclosing the points.

**Polynomial equality relations**
- Viewed as unbounded geometric shapes (lines, planes, etc.)
  + use algorithms from linear algebra and geometry to generate invariants
- From the shapes, obtain equality invariants of the form $c_1t_1 + ··· + c_nt_n = 0$     
  where $c_i$ are real-valued and $t_i$ are _terms_ (cf. @nguyen2014 pg. 5-6).
- The polynomial degree and number of variables rapidly increase the solution space
- See @nguyen2014 pg. 7 for algorithm and details

**Inequality relations**
- Represents equality and inequality constraints among multiple variables as
  hyperplanes and polyhedra.
- When additional inputs are available, new inequalities can be deduced from
  previously inferred equality relations.

**Array variables** and functions that can be viewed as arrays [@nguyen2014]
- Invariants may represent flat (non-nested) or nested array relations 
- Linear equations in flat arrays: find equalities among array elements, then
  identify the relations among array indices from the obtained equalities
- Nested array relations are inferred by performing reachability analysis and by
  SMT solver
- Automatic theorem proving is used to reason about large arrays more
  efficiently

**User can modify the parameters** for better performance or to specify additional information to aid the invariant generation process [@nguyen2014].

## Inference Example [@nguyen2014, p.4]

The trace values of the two variables $v_1$, $v_2$ are points in the ($v_1$, $v_2$)-plane. 
First DIG determines if these points lie on a line, represented by a linear equation of the form $c_0 + c_1v_1 + c_2v_2 = 0$.

If such a line does not exist, DIG builds a bounded convex polygon from these points. 
The edges of the polygon are represented by linear inequalities of the form $c_0 + c_1v_1 + c_2v_2 \geq 0$.

This technique generalizes to equations and inequalities among multiple variables by constructing hyperplanes and polyhedra in a high-dimensional space.

To generate nonlinear constraints, DIG uses terms to represent nonlinear polynomials over program variables, for example, $t_1 = v_1$, $t_2 = v_1v_2$. 
This allows DIG to generate equations such as $t_1 + t_2 = 1$. 
This represents a line over $t_1$, $t_2$ and a hyperbola over $v_1$, $v_2$.


# How DIG Works

DIG is a dynamic analysis framework for inferring expressive numerical
invariants [@nguyen2022].

### Analysis steps

1. INPUT
   - C, Java, Java bytecode, or trace file [@dig] 
   - "concrete state" is an alias of trace

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

   
## About DIG vs. SymInfer

* SymInfer takes input is a program in C, Java, or Java bytecode (but NOT
  traces) [@nguyen2022b]
* DIG supports nonlinear equalities and inequalities, of arbitrary degree, over
  numerical variables [@nguyen2014]

* Without symbolic states (these are assumptions):
  - Instrumentation should not occur 
  - CEGIR-based inference should not iterate
  - Inequality invariants should not be inferrable

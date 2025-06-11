# How DIG Works

DIG is a dynamic analysis framework for inferring expressive numerical invariants [@1].

### Analysis steps

1. INPUT
   - C, Java, Java bytecode, or trace file [@3] 
   - "concrete state" is an alias of trace

2. (optional) INSTRUMENTATION                     
   - Uses symbolic execution to compute symbolic states; then symbolic states are used to obtain concrete states.

3. INFERENCE of equality and inequality invariants.

   A) **Equation invariants (CEGIR-based)** [@2]      
      + SymInfer formulates verification conditions from symbolic states, 
        to confirm or refute an invariant, solves those using an SMT solver, 
        and produces counterexamples to refine the inference process [@1]. 
      + Giving traces as input means symbolic states are not used [@2]     
      + Can result in spurious invariants (correct in traces, but not overall)

             [*] Traces -----> Inference                    [*] start
                  ↑               ↓     
                  ↑               ↓     
                  ↑            Equations   
                  ↑               ↓     
                  ↑               ↓     
             Counterexample <---- Z3 Solver <---- Symbolic states
   
   B) **Inequality invariants (SMT-based)** [@4]      
      Computed directly from symbolic states. 
      + Enumerate octagonal terms (x-y, x+y, etc.) and min/max-plus 
        terms, such as min(x, y, z). 
      + For each term t, use an SMT solver to compute the smallest 
        upperbound k for t, from symbolic states.

4. POSTPROCESSING
   - simplification, removing redundancy 

5. OUTPUT: Invariants

   
## DIG vs. SymInfer

* SymInfer takes input is a program in C, Java, or Java bytecode, marked with target locations.    
  It returns invariants found at those locations [@4]
* The Instrumentation step may be specific to SymInfer?
* Without symbolic states:
  - CEGIR inference should not iterate?
  - Inequality invariants may not be inferrable?


-------------
## References

* [1]: "Using Symbolic States to Infer Numerical Invariants": https://roars.dev/pubs/nguyen2021using.pdf
* [2]: "SymInfer - ICSE'22 Demo": https://www.youtube.com/watch?v=VEuhJw1RBUE
* [3]: DIG source code: https://github.com/dynaroars/dig
* [4]: "SymInfer: Inferring Numerical Invariants using Symbolic States": https://roars.dev/pubs/nguyen2022syminfer.pdf

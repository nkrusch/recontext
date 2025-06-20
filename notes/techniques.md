# Invariant inference techniques

Invariants can be identified from programs using static or dynamic 
analysis [@nguyen2014].

Static analysis discovers invariants by inspecting program code 
directly, and thus often has the advantage of providing sound results 
that are valid for any program input. The requirement that invariants 
be sound leads to expensive computations arising from the difficulty 
of analyzing complex program structures.

Dynamic analysis infers invariants from traces gathered from program 
executions over a sample of test cases. The accuracy of the inferred 
invariant thus depends on the quality and completeness of the test 
cases. However, dynamic analysis is generally efficient and scales well 
to complex programs because it focuses on traces, rather than program 
structures.

- Static techniques: abstract interpretation and the constraint-based 
  approach are the most widespread approaches [@furia2010], 
  e.g., [@karr1976, @dillig2013]

- Dynamic, template-based inference: given a predefined collection of
  invariant templates likely to occur in programs, the detector filters 
  out invalid templates based on observed program traces and returns 
  the remainders as candidate invariants e.g., [@alur2013, @colon2003, 
  @jeannet2014, @sankaranarayanan2004, @srivastava2009, @ernst2007, 
  @srivastava2012]

- Hybrid approach: dynamically infer candidate invariants, then attempt 
  to verify statically that they hold for all inputs
  e.g., [@zhang2014, @padhi2016, @garg2016, @nguyen2017, @yao2020]


## Technical subcategories

- Data-driven techniques use sampled data to generate invariants, 
  e.g., ICE-DT, LoopInvGen, Guess-and-Check

- Neural network based techniques use graph neural networks to encode 
  the program dependencies, e.g., Cln2Inv, G-CLN

- Symbolic execution, 
  e.g., NumInv, [@nguyen2022b]

- Abstract interpretation, 
  e.g., [@rodriguezc2004, @rodriguezc2007] 

- Compositional recurrence analysis 
  e.g., [@kincaid2017, @kincaid2017b, @farzan2015]

- Constrained Horn clause (CHC) solvers for generating loop invariants
  e.g., Eldarica, ImplCheck, [@zhu2018]
  
- Syntax-guided: To improve tractability, syntax-guided techniques 
  allow imposing structural (syntactic) constraints on the set of 
  possible solutions. The structural constraints are imposed by 
  restricting the solution to functions defined by a given context-free 
  grammar. e.g., [@alur2013]

- Generate-and-test [@valiant1984] (or guess-and-check): based on some 
  heuristic, propose a candidate and check, until convergence.


## Tools & Implementations

The tools with ✔️ can be executed; the ones with 💀 should not even be attempted.

| Name and Notes           | Ref           | Inference   | Status | Notes            |
|:-------------------------|:--------------|:------------|:------:|:-----------------|
| [AutoSpec][AUTOSPEC]     | [@wen2024]    | static      |   💀   | LLM 🤮           |
| [DIG][DIG]               | [@nguyen2014] | hybrid      |   ✔️   |                  |
| [Daikon][DAIKON]         | [@ernst2007]  | dynamic     |   ✔️   |                  |
| [Eldarica][ELDERICA][^1] |               |             |        | model checker    |
| [G-CLN][G-CLN]           | [@yao2020]    |             |        | machine learning |
| [ImplCheck][IMPLC][^1]   | [@riley2022]  |             |        | inside Seahorn   |
| [LIPuS][LIPUS]           | [@yu2023]     |             |   💀   |                  |
| [LoopInvGen][LOOPINV]    | [@padhi2016]  | data-driven |   💀   |                  |
| [NumInv][NUMINV]         | [@nguyen2017] | hybrid      |   💀   | deprecated       |
| [cln2inv][CLN2]          | [@ryan2020]   |             |        | machine learning |
| [code2inv][CODE2]        | [@si2018]     | static      |   ✔️   |                  |
| [cvc5][CVC5][^1]         |               |             |   ✔️   | SMT solver       |

[NUMINV]: https://github.com/dynaroars/numinv
[G-CLN]: https://github.com/jyao15/G-CLN
[CLN2]: https://github.com/gryan11/cln2inv.git
[CODE2]: https://github.com/PL-ML/code2inv.git
[CVC5]: https://github.com/cvc5/cvc5
[ELDERICA]: https://github.com/uuverifiers/eldarica
[LIPUS]: https://github.com/Santiago-Yu/LIPuS
[IMPLC]: https://github.com/grigoryfedyukovich/aeval.git
[AUTOSPEC]: https://sites.google.com/view/autospecification
[DAIKON]: https://plse.cs.washington.edu/daikon
[DIG]: https://github.com/dynaroars/dig
[LOOPINV]: https://github.com/SaswatPadhi/LoopInvGen

[^1]: Not a standalone tool; invariants inference is an internal step of the parent tool.

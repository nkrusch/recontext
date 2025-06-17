## Invariant inference techniques

Invariants can be identified from programs using static or dynamic analysis [@nguyen2014].

Static analysis discovers invariants by inspecting program code directly, and
thus often has the advantage of providing sound results that are valid for any
program input. The requirement that invariants be sound leads to expensive
computations arising from the difficulty of analyzing complex program
structures.

Dynamic analysis infers invariants from traces gathered from program executions
over a sample of test cases. The accuracy of the inferred invariant thus depends
on the quality and completeness of the test cases. However, dynamic analysis is
generally efficient and scales well to complex programs because it focuses on
traces, rather than program structures.

- Static techniques: abstract interpretation and the constraint-based approach
  are the most widespread approaches [@furia2010], e.g., [@karr1976, @dillig2013]

- Dynamic, template-based inference: given a predefined collection of
  invariant templates likely to occur in programs, the detector filters out
  invalid templates based on observed program traces and returns the remainders
  as candidate invariants
  e.g., [@alur2013, @colon2003, @jeannet2014, @sankaranarayanan2004,
  @srivastava2009, @ernst2007, @srivastava2012]

- Hybrid approach: dynamically infer candidate invariants, then attempt to
  verify statically that they hold for all inputs
  e.g., [@zhang2014, @padhi2016, @garg2016, @nguyen2017, @yao2020]

More specialized techniques

- Data-driven techniques use sampled data to generate invariants, 
  e.g., ICE-DT, LoopInvGen, Guess-and-Check

- Neural network based techniques use graph neural networks to encode 
  the program dependencies, e.g., Cln2Inv, G-CLN

- Symbolic execution, 
  e.g., NumInv, DIG

- Abstract interpretation, 
  e.g., [@rodriguezc2004, @rodriguezc2007] 

- Compositional recurrence analysis 
  e.g., [@kincaid2017, @kincaid2017b, @farzan2015]

- Constrained Horn clause (CHC) solvers for generating loop invariants
  e.g., Eldarica, ImplCheck, [@zhu2018]
  
- syntax-guided [@alur2013]: To improve tractability, syntax-guided techniques 
  allow imposing structural (syntactic) constraints on the set of possible 
  solutions. The structural constraints are imposed by restricting the 
  solution to functions defined by a given context-free grammar.


## Tools & Implementations

| Name and Notes           | Ref           | Inference   | Status | Notes            |
|:-------------------------|:--------------|:------------|:------:|:-----------------|
| [AutoSpec][AUTOSPEC]     | [@wen2024]    | static      |   💀   | LLM 🤮           |
| [DIG][DIG]               | [@nguyen2014] | hybrid      |   ✔️   |                  |
| [Daikon][DAIKON]         | [@ernst2007]  | dynamic     |   ✔️   |                  |
| [Eldarica][ELDERICA][^1] |               |             |        | model checker    |
| [G-CLN][G-CLN]           | [@yao2020]    |             |        | machine learning |
| [ImplCheck][IMPLC][^1]   | [@riley2022]  |             |        | in Seahorn       |
| [LIPuS][LIPUS]           | [@yu2023]     |             |   💀   |                  |
| [LoopInvGen][LOOPINV]    |               | data-driven |   💀   |                  |
| [NumInv][NUMINV]         | [@nguyen2017] | hybrid      |   💀   | deprecated       |
| [cln2inv][CLN2]          | [@ryan2020]   |             |        | machine learning |
| [code2inv][CODE2]        | [@si2018]     | static      |   ✔️   |                  |
| [cvc5][CVC5][^1]         |               |             |        | smt solver       |


## Tool-specific notes

* Daikon [@ernst2007] observes concrete program states that capture the values
  of variables at designated locations in the program when a program is run on a
  given input. By sampling large numbers of inputs, Daikon can determine
  relationships that may hold among variables across those samples. Confirming
  that those relationships constitute a true invariant has been a focus of
  follow-on work to Daikon. [@nguyen2022]


## Notations

- Let X be a set of variables. 
  Linear formulas over X are boolean combinations of linear constraints of the form 
  $\Sigma^n_{i=1} a_i x_i \leq b$ where the $x_i$'s are variables in X, the $a_i$'s are integer constants, and
  $b \in \mathbb{Z} \cup \{ + \infty \}$.
  We use linear formulas to reason symbolically about programs with integer variables. 
  Assume we have a program with a set of variables $V$ and let \(n = |V|\). 
  A state of the program is a vector of integers in $\mathbb{Z}^n$.

- Nice DLS grammar in [@wang2022] p. 4 (Fig. 4)



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

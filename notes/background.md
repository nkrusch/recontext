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

- Dynamic, template-based invariant inference: given a predefined collection of
  invariant templates likely to occur in programs, the detector filters out
  invalid templates based on observed program traces and returns the remainders
  as candidate invariants
  e.g., [@alur2013, @colon2003, @jeannet2014, @sankaranarayanan2004,
  @srivastava2009, @ernst2007, @srivastava2012]

- Hybrid approach: dynamically infer candidate invariants, then attempt to
  verify statically that they hold for all inputs
  e.g., [@zhang2014, @padhi2016, @garg2016, @nguyen2017, @yao2020]

## Inference Tools & Implementations

| Name and Notes                            | Ref           | Inference | Status | Notes                           |
|:------------------------------------------|:--------------|:----------|:------:|:--------------------------------|
| [AutoSpec][AUTOSPEC]                      | [@wen2024]    | static    |   💀   | broken, LLM                     |
| [Daikon][DAIKON]                          | [@ernst2007]  | dynamic   |   ✔️   | works                           |
| [G-CLN][G-CLN]                            | [@yao2020]    |           |        | machine learning                |
| [ImplCheck][IMPLC][^1] [[Zenodo]][IMPLCZ] | [@riley2022]  |           |        | CHC within Seahorn              |
| [LIPuS][LIPUS] [[Zenodo]][LIPUSZ]         | [@yu2023]     |           |   💀   | broken                          |
| [NumInv][NUMINV]                          | [@nguyen2017] | hybrid    |   💀   | deprecated                      |
| [cln2inv][CLN2]                           | [@ryan2020]   |           |        | machine learning                |
| [code2inv][CODE2]                         | [@si2018]     | static    |   ✔️   | linear only; weird input format |
| [cvc5][CVC5][^1]                          |               |           |        | smt solver                      |
| [eldarica][ELDERICA][^1]                  |               |           |        | model checker                   |
| [DIG][DIG]                                | [@nguyen2014] | hybrid    |   ✔️   | works                           |

[NUMINV]: https://github.com/dynaroars/numinv
[G-CLN]: https://github.com/jyao15/G-CLN
[CLN2]: https://github.com/gryan11/cln2inv.git
[CODE2]: https://github.com/PL-ML/code2inv.git
[CVC5]: https://github.com/cvc5/cvc5
[ELDERICA]: https://github.com/uuverifiers/eldarica
[LIPUS]: https://github.com/Santiago-Yu/LIPuS
[LIPUSZ]: https://zenodo.org/records/7909725
[IMPLC]: https://github.com/grigoryfedyukovich/aeval.git
[IMPLCZ]: https://zenodo.org/records/7047061
[AUTOSPEC]: https://sites.google.com/view/autospecification
[DAIKON]: https://plse.cs.washington.edu/daikon
[DIG]: https://github.com/dynaroars/dig

[^1]: Not a standalone tool; invariants inference is an internal step of the parent tool.

## Tool-specific notes

* Daikon [@ernst2007] observes concrete program states that capture the values
  of variables at designated locations in the program when a program is run on a
  given input. By sampling large numbers of inputs, Daikon can determine
  relationships that may hold among variables across those samples. Confirming
  that those relationships constitute a true invariant has been a focus of
  follow-on work to Daikon. [@nguyen2022]

## Notations

Let X be a set of variables. 
Linear formulas over X are boolean combinations of linear constraints of the form \( \Sigma^n_{i=1} a_i x_i \leq b \) where the $x_i$'s are variables in X, the $a_i$'s are integer constants, and \( b \in \mathbb{Z} \cup \{ + \infty \} \).
We use linear formulas to reason symbolically about programs with integer variables. 
Assume we have a program with a set of variables $V$ and let \(n = |V|\). 
A state of the program is a vector of integers in \(\mathbb{Z}^n\).


# Questions

1. [How does DIG work?](dig.md)

2. What is the impact on the inference if we...
   * Increase the degree, i.e., number of variables
   * Adding more/giving fewer traces, i.e., change the number of rows
   * Restrict value domain (Z, nat, binary)

3. What are some other ways to infer invariants from numerical data
   * This is a lit review question (may have nothing to do with FM or PL)
   * Ultimately we want to do some comparison

# Notes

Baseline assumptions about inputs

* We are interested in numerical invariants
* A variable holds one value at a time
* Integer domain (or a subset)
* relationships between variables (vs. individual variables)
* null values -- unknown

I use "trace" as a generic term for inputs that that can be viewed as numerical tabular data.
A trace could be generated from a program execution, but it could also come from other sources.

Intuitions

* I suspect an inference technique will fail "easily" if we only provide traces as input
  - We may be unable to say much about the input => what can we say?
  - Why/what makes the inference fail?
  
* Increasing the difficulty of inference (e.g., higher variable count, more
  traces, or "noisy" trace) will likely break inference.
* Can we uncover/describe the limitations/boundary of the state-of-the-art
  techniques?

# Invariant inference techniques

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

**Examples**

- Static techniques: abstract interpretation and the constraint-based approach
  are the most widespread approaches [@furia2010]
  e.g., [@karr1976]

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

| Name and Notes                            | Ref           | Inference | Notes                              |
|:------------------------------------------|:--------------|:----------|:-----------------------------------|
| [AutoSpec][AUTOSPEC]                      | [@wen2024]    | static    | 💀 broken, LLM                     |
| [Daikon][DAIKON]                          | [@ernst2007]  | dynamic   | ✔️ works                           |
| [G-CLN][G-CLN]                            | [@yao2020]    |           | machine learning                   |
| [ImplCheck][IMPLC][^1] [[Zenodo]][IMPLCZ] | [@riley2022]  |           | CHC within Seahorn                 |
| [LIPuS][LIPUS] [[Zenodo]][LIPUSZ]         | [@yu2023]     |           | 💀 broken                          |
| [NumInv][NUMINV] ("DIG2")                 | [@nguyen2017] | hybrid    | 💀 deprecated                      |
| [cln2inv][CLN2]                           | [@ryan2020]   |           | machine learning                   |
| [code2inv][CODE2]                         | [@si2018]     | static    | ✔️ linear only; weird input format |
| [cvc5][CVC5][^1]                          |               |           | smt solver                         |
| [eldarica][ELDERICA][^1]                  |               |           | model checker                      |
| [DIG][DIG]                                | [@nguyen2014] | hybrid    | ✔️ works                           |

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

## Notes about tools

* Daikon [@ernst2007] observes concrete program states that capture the values
  of variables at designated locations in the program when a program is run on a
  given input. By sampling large numbers of inputs, Daikon can determine
  relationships that may hold among variables across those samples. Confirming
  that those relationships constitute a true invariant has been a focus of
  follow-on work to Daikon. 



[^1]: Not a standalone tool; invariants inference is an internal step of the parent tool.
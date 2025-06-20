# Related Works

Note: we are only interested in approaches with an implementation, since it would not be possible to do comparisons otherwise.

### TaCLe

<https://github.com/ML-KULeuven/tacle> [@paramonov2017]

Investigates a "Tabular Constraint Learning Problem" over rows and 
columns of tabular (numeric/string) data.   

* Aims to find [logical constraints](https://en.wikipedia.org/wiki/Constraint_programming#Constraint_satisfaction_problem)
  over contiguous "blocks" of values of same type.     
  => VERY SENSITIVE to value ordering (since this determines blocks) 
  and runtime depends heavily on input size. 

* Uses a hard-coded set of templates        
  => The templates are rigid, e.g., to represent a - b = 0, would need 
  a full column of 0s. Learning more expressive constraints, requires
  generating prohibitively large combinations of templates and makes 
  inference time-consuming.
 
* Returns all constraints that are valid for the provided input     
  => much redundancy!  

* TaCle is an example of _constraint learning_ (also [@kumar2022])     
  a learner obtains constraints by inspecting examples.

### Daikon

<https://plse.cs.washington.edu/daikon/> [@ernst2007] 

Observes concrete program states that capture the values of variables at
designated locations in the program when a program is run on a given 
input. By sampling large numbers of inputs, Daikon can determine 
relationships that may hold among variables across those samples. 
Confirming that those relationships constitute a true invariant has 
been a focus of follow-on work to Daikon. [@nguyen2022]





### Literature

The first algorithm for learning constraints was given by Valiant [@valiant1984]. 
Given a set of feasible examples, the algorithm learns Boolean formulas consistent with the given examples. 
It enumerates all possible formulas upto a pre-defined complexity and keeps only those which are satisfied by all feasible examples.
This is essentially a generate-and-test approach, where the algorithm generates all possible constraints and then tests whether they hold on the given dataset.


# Related Works

Note: we are only interested in approaches with an implementation, since it would not be possible to do comparisons otherwise.


### [TaCLe](https://github.com/ML-KULeuven/tacle) [@paramonov2017]

Investigates a "Tabular Constraint Learning Problem" over rows and columns of tabular (numeric/string) data.   

* Aims to find [logical constraints](https://en.wikipedia.org/wiki/Constraint_programming#Constraint_satisfaction_problem) over contiguous "blocks" of values of same type.     
  => VERY SENSITIVE to value ordering (since this determines blocks) and runtime depends heavily on input size. 

* Uses a hard-coded set of templates        
  => The templates are rigid, e.g., to represent a - b = 0, would need a full column of 0s
 
* Returns all constraints (from templates) that are valid for the provided input     
  => much redundancy!  


### [Daikon](https://plse.cs.washington.edu/daikon/) [@ernst2007] 

Observes concrete program states that capture the values of variables at designated locations in the program when a program is run on a given input. By sampling large numbers of inputs, Daikon can determine relationships that may hold among variables across those samples. Confirming that those relationships constitute a true invariant has been a focus of follow-on work to Daikon. [@nguyen2022]



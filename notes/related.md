# Related Works

### [TaCLe](https://github.com/ML-KULeuven/tacle) [@paramonov2017]

Investigates a "Tabular Constraint Learning Problem" over rows and columns of tabular (numeric/string) data.   

* Aims to find [logical constraints](https://en.wikipedia.org/wiki/Constraint_programming#Constraint_satisfaction_problem) over contiguous "blocks" of values of same type.     
  => VERY SENSITIVE to value ordering (since this determines blocks) and runtime depends heavily on input size. 

* Uses a hard-coded set of templates        
  => The templates are rigid, e.g., to represent a - b = 0, would need a full column of 0s
 
* Returns all constraints (from templates) that are valid for the provided input     
  => much redundancy!  
  




# Related Works

* [@paramonov2017] [TaCLe](https://github.com/ML-KULeuven/tacle)
  - Tabular Constraint Learning Problem, over rows+columns of tabular (numeric/string) data.   
  - Aims to find [logical constraints](https://en.wikipedia.org/wiki/Constraint_programming#Constraint_satisfaction_problem) over contiguous "blocks" of values of same type.    
    - Sensitive to ordering of values, since this determines blocks. 
  - Uses a hard-coded set of templates    
    - The templates are rigid, e.g., to represent a - b = 0 must have a full column of 0s
  - Returns all constraints (from templates) that are valid for the provided input.  
  




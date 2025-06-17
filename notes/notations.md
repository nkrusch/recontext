# Notations

Let X be a set of variables.
Linear formulas over X are boolean combinations of linear constraints of the form
$\Sigma^n_{i=1} a_i x_i \leq b$ where the $x_i$'s are variables in X, the $a_i$'s are integer constants, and
$b \in \mathbb{Z} \cup \{ + \infty \}$.
We use linear formulas to reason symbolically about programs with integer variables.
Assume we have a program with a set of variables $V$ and let \(n = |V|\).
A state of the program is a vector of integers in $\mathbb{Z}^n$.

Nice DLS grammars in [@wang2022] p. 4 (Fig. 4) and in [@alur2013]

Given $n$ variables and $m$ records of variable values, a trace is an $n \times m$ matrix.
A matrix element is a "cell". 
A cell holds a value with a numerical type, whose type is integer or float.
When a cell is empty, its type is $\epsilon$, which is a subtype of all other types.

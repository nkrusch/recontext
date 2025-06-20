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

We use capitals for variables (e.g. X, Y and S), and lower case for values (e.g. v and w). 
We write D(X) for the domain of a variable X.

# Maybe useful?

* By introducing the slack variable $\displaystyle \mathbf {s} \geq \mathbf {0}$, the inequality
  $\displaystyle \mathbf {A} \mathbf {x} \leq \mathbf {b}$ can be converted to the equation
  $\displaystyle \mathbf {A} \mathbf {x} +\mathbf {s} =\mathbf {b}$.

* [X] proposes a set of constraints taken from the global constraints catalog that are consistent with the given examples.  


Some baseline assumptions about inputs

* A variable holds one value at a time
* Integer domain (or a subset)
* null values -- unknown

I use "trace" as a generic term for some tabular data.
Could be generated from a program execution, but could also come from other sources.

Intuitions
* The inference techniques may fail easily & maybe cannot say much (why/what makes them fail).
* More entries in traces; increasing "variables", or noise in traces will likely break the inference.
* Can we uncover the limitations/boundary of the current existing techniques?
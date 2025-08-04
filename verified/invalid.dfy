/*-----------------------------------------------------
  INVALID EXAMPLES IN THE LINEAR BENCHMARK SUITE
  The invalid claims (asserts)  are commented out.
  A counterexample proves the claim does not hold.
-----------------------------------------------------*/

method Linear26(n: int)
{
  assume {:axiom} n == 0;
  var x := n;
  while x > 1 {
    x := x - 1;
  }
  // invalid claim:
  // if x != 1 { assert n < 0; }
  assert x != 1 && !(n < 0);
}

method Linear27(n: int)
{
  assume {:axiom} n == 0;
  var x := n;
  while x > 1 {
    x := x - 1;
  }
  // invalid claim:
  // if n >= 0 { assert x == 1; }
  assert n >= 0 && x != 1;
}

method Linear31(n: int)
{
  assume {:axiom} n == 0;
  var x := n;
  while x > 1 {
    x := x - 1;
  }
  // invalid claim:
  // if x != 1 { assert(n < 0); }
  assert x != 1 && !(n < 0);
}

method Linear32(n: int)
{
  assume {:axiom} n == 0;
  var x := n;
  while x > 1 {
    x := x - 1;
  }
  // invalid claim:
  // if n >= 0 { assert x == 1; }
  assert n >= 0 && x != 1;
}

method Linear61(n: int)
  requires n > 0
  decreases * {
  assume {:axiom} n == 1;
  var c := 0;
  while *
    decreases * {
    if * {
      if c != n {
        c := c + 1; }
    } else {
      if c == n {
        c := 1;
      }
    }
  }
  // invalid claim:
  // if c == n { assert n <= -1; }
  if c == n { assert !(n <= -1); }
}

method Linear62(n: int)
  requires n > 0
  decreases * {
  assume {:axiom} n == 1;
  var c := 0;
  while *
    decreases * {
    if * {
      if c != n {
        c := c + 1; }
    } else {
      if c == n {
        c := 1;
      }
    }
  }
  // invalid claim:
  // if n > -1 { assert c != n; }
  assert n > -1 && (c == 0 || c == n);
}

method Linear72(y: int)
  requires y >= 127
  decreases * {
  assume {:axiom} y == 128;
  var c, z := 0, 36 * y;
  while *
    invariant 0 <= c <= 36
    invariant c == 0 ==> !(z < 4608)
    decreases * {
    if c < 36 {
      z := z + 1;
      c := c + 1;
    }
  }
  // case: loop did not execute
  assume {:axiom} c == 0;

  // invalid claim:
  // if c < 36 { assert z < 4608; }
  assert c < 36 && !(z < 4608);
}

method Linear75(y: int)
  requires y >= 127
  decreases * {
  assume {:axiom} y == 128;
  var c, z := 0, 36 * y;
  while *
    invariant 0 <= c <= 36
    invariant c == 0 ==> !(z < 4608)
    decreases * {
    if c < 36 {
      z := z + 1;
      c := c + 1;
    }
  }
  // case: loop did not execute
  assume {:axiom} c == 0;

  // invalid claim:
  // if c < 36 { assert(z < 4608); }
  assert c < 36 && !(z < 4608);
}

method Linear106(a: int, j: int, m0: int) {
  assume {:axiom} a == 0;
  assume {:axiom} m0 == 1;
  var k, m := 0, m0;
  assert a <= m;
  while (k < 1) {
    if m < a {
      m := a;
    }
    k := k + 1;
  }
  // invalid claim:
  // assert a >= m;
  assert !(a >= m);
}
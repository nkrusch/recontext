/*-----------------------------------------------------
VERIFIED LINEAR BENCHMARK SUITE

We prove the linear benchmarks, to confirm the 
invariants needed to prove functional correctness.
-----------------------------------------------------*/

predicate Nat(x: int) { x >= 0 }

function Min(a: int, b: int): int
{
  if a < b then a else b
}

function Max(a: int, b: int): int
{
  if a > b then a else b
}

function Pow(base: nat, exp: nat): nat
  requires  base > 0 ensures 1 <= Pow(base, exp)
{
  if exp == 0 then 1 else base * Pow(base, exp-1)
}

method Linear1_2(n: nat)
  requires n in [1000, 100000]
{
  var x, y := 1, 0;
  while y < n
    invariant x == 1 + (y * y - y)/2
  {
    x := x + y;
    y := y + 1;
  }
}

method Linear3_4_5(a: int, b: int, n: int)
{
  var x, y, z := 0, a, b;
  while x < n
    invariant x == 0 || y <= z
  {
    x := x + 1;
    if z <= y {
      y := z;
    }
  }
}

method Linear7_8(a: nat, b: nat)
  requires  a < 11 && b < 11
  decreases *
{
  var x, y := a, b;
  ghost var n := 0;
  while *
    invariant x == a + n * 10
    invariant y == b + n * 10
    decreases *
  {
    x := x + 10;
    y := y + 10;
    n := n + 1;
  }
}

method Linear9_10(a: nat, b: nat)
  requires a < 3 && b < 3
  decreases *
{
  var x, y := a, b;
  ghost var n := 0;
  while *
    invariant x == a + n * 2
    invariant y == b + n * 2
    decreases *
  {
    x := x + 2;
    y := y + 2;
    n := n + 1;
  }
}

method Linear15_16_17_18(n: nat)
{
  var x, m := 0, 0;
  while x < n
    invariant m <= x <= n
  {
    if * {
      m := x;
    }
    x := x + 1;
  }
}

method Linear23()
{
  var i, j := 1, 20;
  ghost var n := 0;
  while j  >= i
    invariant j == 20 - n && i == 1 + 2 * n
  {
    i := i + 2;
    j := j - 1;
    n := n + 1;
  }
}

method Linear24()
{
  var i, j := 1, 10;
  ghost var n := 0;
  while j  >= i
    invariant j == 10 - n && i == 1 + 2 * n
  {
    i := i + 2;
    j := j - 1;
    n := n + 1;
  }
}

method Linear25_30(n: nat)
  requires n in [100, 10000]
{
  var x := n;
  while x > 0
    invariant 0 <= x <= n
  {
    x := x - 1;
  }
}

method Linear28_29(n : int)
{
  var x := n;
  while x > 0
    invariant (n < 0 && n == x) || 0 <= x <= n
  {
    x := x - 1;
  }
}

method Linear35_36_37()
  decreases *
{
  var c := 0;
  while *
    invariant 0 <= c <= 40
    decreases * {
    if * {
      if c != 40 {
        c := c + 1;
      }
    } else if (c == 40) {
      c := 1;
    }
  }
}

method Linear38_39(n: int)
  requires n > 0
  decreases *
{
  var c := 0;
  while *
    invariant 0 <= c <= n
    decreases *
  {
    if c == n {
      c := 1;
    } else {
      c := c + 1;
    }
  }
}

method Linear40_41_42_43_44_56_57(n: int)
  requires n > 0
  decreases *
{
  var c := 0;
  while *
    invariant c == 0
    decreases *
  {
    if * {
      if c > n {
        c := c + 1;
      }
    } else {
      if c == n {
        c := 1;
      }}
  }
}

method Linear45_46_47_48_49(n: int)
  requires n > 0
  decreases *
{
  var c := 0;
  while *
    invariant 0 <= c <= n
    decreases * {
    if * {
      if c != n {
        c := c + 1;
      }
    } else {
      if c == n {
        c := 1;
      }}
  }
}

method Linear50_51_52()
  decreases *
{
  var c := 0;
  while *
    invariant 0 <= c <= 4
    decreases *
  {
    if * {
      if c != 4 {
        c := c + 1;
      }
    } else {
      if c == 4 {
        c := 1;
      }}
  }
}

method Linear63_64(a: int)
{
  var x, y := 1, a;
  while x <= 10
    invariant x == 1 || y == 11 - x
  {
    y := 10 - x;
    x := x + 1;
  }
}

method Linear65_66(a: int)
{
  var x, y := 1, a;
  while x <= 100
    invariant 1 <= x <= 101
    invariant y in [a, 101 - x]
    invariant x == 1 || y == 101 - x
  {
    y := 100 - x;
    x := x + 1;
  }
}

method Linear67_68_70(n: int, a: int)
{
  var x, y := 1, a;
  while x <= n
    invariant x == 1 || y == n + 1 - x
  {
    y := n - x;
    x := x + 1;
  }
}

method Linear71_73(y: int)
  requires y >= 127
  decreases *
{
  var c, z := 0, 36 * y;
  assert z >= 0;
  while *
    invariant z == 36 * y + c
    decreases *
  {
    if c < 36 {
      z := z + 1;
      c := c + 1;
    }
  }
}

method Linear77_78_79(x: nat, y: nat)
  requires x >= y
  decreases *
{
  var i := 0;
  while *
    invariant i <= y <= x
    decreases *
  {
    if i < y {
      i := i + 1;
    }
  }
}

method Linear83(a: nat)
  requires a > 0
{
  var y: nat, x := a, -5000;
  while x < 0
    invariant x == (y * y - y)/2 - (a * a - a)/2 - 5000
    decreases -x
  {
    x := x + y;
    y := y + 1;
  }
}

method Linear84(a: nat)
  requires a > 0
{
  var x, y: nat :=  -50, a;
  while x < 0
    invariant x == (y * y - y)/2 - (a * a - a)/2 - 50
    decreases -x
  {
    x := x + y;
    y := y + 1;
  }
}

method Linear85(a: int)
  requires a > 0
{
  var x, y: nat := -15000, a;
  while x < 0
    invariant x == (y * y - y)/2 - (a * a - a)/2 - 15000
    decreases -x {
    x := x + y;
    y := y + 1;
  }
}

method Linear87_88(a: int, b: int)
  requires a == b || a + 1 == b
  decreases *
{
  var x, y := a, b;
  var lock := if (a == b) then 1 else 0;
  while (x != y)
    invariant lock == 1 <==> x == y
    invariant lock == 0 <==> x == y - 1
    decreases * {
    if * {
      lock := 1;
      x := y;
    } else {
      lock := 0;
      x := y;
      y := y + 1;
    }
  }
}

method Linear91()
  decreases *
{
  var x, y := 0, 0;
  while *
    invariant y == 0
    decreases * {
    y := y + x;
  }
}

method Linear93(n: nat)
{
  var i, x, y := 0, 0, 0;
  while i < n
    invariant x + y == 3 * i
    invariant i <= x <= i * 2
    invariant i <= y <= i * 2
  {
    i := i + 1;
    if * {
      x := x + 1;
      y := y + 2;
    } else {
      x := x + 2;
      y := y + 1;
    }
  }
}

method Linear94(n: nat)
{
  var i, j := 0, 0;
  while i <= n
    invariant 0 <= i <= n + 1
    invariant 2 * j == i * i + i
  {
    i := i + 1;
    j := j + i;
  }
}

method Linear95_96(x: int)
{
  var i, j, y := 0, 0, 1;
  while i <= x
    invariant j == i
  {
    i := i + 1;
    j := j + y;
  }
}

method Linear97_98(x: int)
{
  var i, j, y : int := 0, 0, 2;
  while i <= x
    invariant j == i * 2
  {
    i := i + 1;
    j := j + y;
  }
}

method Linear99_100(n: nat)
{
  var x, y := n, 0;
  while x > 0
    invariant 0 <= x <= n
    invariant y == n - x
  {
    y := y + 1;
    x := x - 1;
  }
}

method Linear101_102(n: int)
{
  var x := 0;
  while x < n
    invariant n < 0 || 0 <= x <= n
  {
    x := x + 1;
  }
}

method Linear103()
{
  var x := 0;
  while x < 100 {
    x := x + 1;
  }
}

method Linear107(a: int, b: int)
{ 
  var k, m := 0, b;
  while (k < 1)
    invariant m <= Max(a,b)
    invariant k in [0, 1]
  {
    if m < a {
      m := a;
    }
    k := k + 1;
  }
}

method Linear108(a: int, b: int, c: int)
  requires a <= b && c > 0
{
  var k, m := 0, b;
  while k < c
    invariant 0 <= k <= c
    invariant m == b
  {
    if m < a {
      m := a;
    }
    k := k + 1;
  }
}

method Linear109(a: int, b: int, c: int)
{
  var k, m := 0, b;
  while k < c
    invariant (k == 0 && m == b) || (1 <= k <= c && m == Max(a, b))
  {
    if m < a {
      m := a;
    }
    k := k + 1;
  }
}

method Linear110_111_118_119(n: int)
  requires n >= 1
{
  var sn, i := 0, 1;
  while i <= n
    invariant 0 <= sn < i <= n + 1
    invariant sn == i - 1
  {
    i := i + 1;
    sn := sn + 1;
  }
}

method Linear114_115()
  decreases *
{
  var sn, x := 0, 0;
  while *
    invariant sn == x
    decreases *
  {
    x := x + 1;
    sn := sn + 1;
  }
}

method Linear120_121()
{
  var sn, i := 0, 1;
  while i <= 8
    invariant 0 <= i <= 9
    invariant sn + 1 == i
  {
    i := i + 1;
    sn := sn + 1;
  }
}

method Linear124_125(i: nat, j: int)
{
  var x, y := i, j;
  while x != 0
    invariant 0 <= x <= i
    invariant y == j - i + x
  {
    x := x - 1;
    y := y - 1;
  }
}

method Linear128(y: int)
{
  var x := 1;
  ghost var n := 0;
  while x < y
    invariant x == Pow(2, n)
  {
    x := x + x;
    n := n + 1;
  }
}

method Linear130_131(a: int, b: int)
  decreases *
{
  var d1, d2, d3 := 1, 1, 1;
  var x1, x2, x3 := 1, a, b;
  while x1 > 0
    invariant x1 in [0, 1]
    invariant x2 == a - 1 + x1
    invariant x3 == b - 1 + x1
    decreases *
  {
    if x2 > 0 {
      if x3 > 0 {
        x1 := x1 - d1;
        x2 := x2 - d2;
        x3 := x3 - d3;
      }
    }
  }
}

method Linear132(c: int)
  requires 49 <= c <= 56
  decreases *
{
  var i, j, t := 0, 48 - c, c - 48;
  ghost var n := 0;
  while *
    invariant 0 < t < 9
    invariant t == c - 48
    invariant i == j + t
    invariant j == i - t
    // invariant n > 0 ==> j == Pow(2, n) * 2 * t - 2 * t
    decreases * {
    if c > 48 {
      if c < 57 {
        j := i + i;
        t := c - 48;
        i := j + t;
        n := n + 1;
      }
    }
  }
}

method Linear133(n: nat)
{
  var x := 0;
  while x < n
    invariant 0 <= x <= n
  {
    x := x + 1;
  }
}
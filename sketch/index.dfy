module VMod {

  type pos = x : nat | x > 0 witness 1

  // data dimensionality
  const degree : pos

  // types
  type bit = i : nat | i in {0, 1} witness 1
  type idx = x : nat | x < degree witness 0
  type Pred = seq<real> -> bool

  type mutableT = (seq<idx>, Pred)
  type immutableS = seq<idx>
  type mutableS = seq<mutableT>
  type matrow = r : seq<real> | |r| == degree witness seq(degree, _ => 0.0)
  type matrix = m : seq<matrow> | forall i : nat :: i < |m| ==> |m[i]| == degree witness []

  function IdxValues(row: matrow, colI: seq<idx>) : seq<real>
    ensures var res := IdxValues(row, colI); |res| == |colI| && forall i : nat :: i < |colI| ==> res[i] == row[colI[i]]
  {
    if |colI| == 0 then [] else [row[colI[0]]] + IdxValues(row, colI[1..])
  }

  predicate MutableHold(matrix: matrix, cond : mutableS)
  {
    forall row : nat :: 0 <= row < |matrix| ==> MutableHoldAtRow(matrix[row], cond)
  }

  predicate MutableHoldAtRow(row: matrow, cond: mutableS)
  {
    if |cond| == 0 then true
    else
      var fst, rest := cond[0], cond[1..];
      var values, pred := IdxValues(row, fst.0), fst.1;
      pred(values) && MutableHoldAtRow(row, rest)
  }

  predicate ImmutableHold(original: matrix, mutated: matrix, colI: immutableS)
    requires |original| == |mutated|
  {
    forall row : nat :: row < |original| ==> SeqEqual(IdxValues(original[row], colI), IdxValues(mutated[row], colI))
  }

  predicate Correct(original: matrix, mutated: matrix, cond: mutableS, colI : immutableS)
    requires |original| == |mutated|
  {
    ImmutableHold(original, mutated, colI) && MutableHold(mutated, cond)
  }

  lemma ImmSameEq()
  ensures forall m : matrix, i :immutableS :: ImmutableHold(m, m, i) {} 

  method Dependencies(m: mutableS) returns (res: seq<seq<idx>>)
    decreases *
    // ensures |res| == |m|
  {
    var sets := Map(m, (x: mutableT) => ToSet(x.0));
    var merged := true;
    var scc := [];
    while merged decreases *
    {
      merged := false;
      while |sets| > 0 decreases *
      {
        var fst, rest := sets[0], sets[1..];
        sets := [];
        for i := 0 to |rest| {
          var other := rest[i];
          if other !! fst {
            sets := sets + [other];
          } else {
            merged := true;
            fst := fst + other; // union
          }
        }
        scc := scc + [fst];
      }
    }
    res := [];
    for i := 0 to |m| {
      var idx := ToSet(m[i].0);
      for j := 0 to |scc| {
        if (scc[j] !! idx) == false {
          idx := idx + scc[j];
        }
      }
      var ss := SetToSeq(idx);
      res := res + [ss];
    }
  }

  class Verify {
    const mut : mutableS
    const imm : immutableS
    const deps : seq<seq<idx>>

    constructor (mut: mutableS, imm: immutableS)
      // ensures |deps| == |mut| 
      decreases *
    {
      var deps := Dependencies(mut);
      this.mut := mut;
      this.imm := imm;
      this.deps := deps;
    }

    function Apply(o: matrix, m: matrix, mask: seq<seq<bool>>) : matrix
    {
      o       
      //  if 0 <= i < r && 0 <= j < c then (
      //  if vmap[i, j] then m[i, j] else o[i, j]
      //  ) else 0.0);
    }

    method EnsureC(o: matrix, m: matrix) returns (final: matrix)
      requires MutableHold(o, mut)
      requires |deps| == |mut|
      requires |m| == |o|
      // ensures |final| == |o|
      // ensures Correct(final, o, mut, imm)
    {

      var irow := [];
      for i := 0 to degree  { irow := irow + [i in imm]; }
      var vmap := seq(|o|, _ => irow[..]);
      assert |irow| == degree;
      assert |vmap| == |m|;
      assert forall i : nat :: i < |vmap| ==> |vmap[i]| == degree;
      var m' := Apply(o, m, vmap);
      // assert ImmutableHold(o, m', imm);

      vmap := seq(|o|, _ => seq(degree, _ => true));
      // for k := 0 to |mut|
      // {
      //   var src, P, dp := mut[k].0, mut[k].1, deps[k];
      //   for rr := 0 to r {
      //     var values := IdxValues(m', rr, src);
      //     if !P(values) {
      //       for i := 0 to |dp| {
      //         vmap[rr, dp[i]] := false;
      //       }
      //     }
      //   }
      // }

      final := [];
      // final := new real[r, c]
      // ((i, j) reads vmap, o, m' =>
      //  if 0 <= i < r && 0 <= j < c then
      //  var b := if vmap[i, j] then 1.0 else 0.0;
      //  m'[i, j] * b + o[i, j] * (1.0 - b)
      //  else 0.0);
    }
  }



  // function ArrayToSet<T>(a: array<T>): set<T>
  //   reads a
  // {
  //   SliceToSet(a, 0, a.Length)
  // }

  // function SliceToSet<T>(a: array<T>, i: nat, j: nat): set<T>
  //   reads a
  //   requires 0 <= i <= j <= a.Length
  // {
  //   set k | i <= k < j :: a[k]
  // }

  // method SetToArray<T>(s: set<T>) returns (a: array<T>)
  //   ensures |s| == a.Length
  //   ensures s == ArrayToSet(a)
  // {
  //   if |s| == 0 {
  //     return new T[0];
  //   }
  //   var x :| x in s;
  //   a := new T[|s|](_ => x);
  //   var i := 0;
  //   var t := s;
  //   while i < |s|
  //     invariant 0 <= i <= a.Length
  //     invariant |s| == |t| + i
  //     invariant s == t + SliceToSet(a, 0, i)
  //   {
  //     label L:
  //     var y :| y in t;
  //     a[i] := y;
  //     assert forall j | 0 <= j < i :: old@L(a[j]) == a[j];
  //     t := t - {y};
  //     i := i + 1;
  //   }
  // }

  // method Concat1<T>(a: array<T>, x: T) returns (c: array<T>)
  //   ensures c[..] == a[..] + [x]
  // {
  //   var one := new T[][x];
  //   c := Concat(a, one, x);
  // }

  // method Concat<T>(a: array<T>, b: array<T>, default:T) returns (c: array<T>)
  //   ensures c[..] == a[..] + b[..]
  // {
  //   c := new T[a.Length + b.Length]
  //   (i reads a, b =>
  //    if 0 <= i < a.Length
  //    then a[i]
  //    else if 0 <= i - a.Length < b.Length
  //    then b[i - a.Length]
  //    else default);
  // }

  predicate SeqEqual<T(==)>(a: seq<T>, b: seq<T>)
  {
    |a| == |b| && forall i : nat :: 0 <= i < |a| ==> a[i] == b[i]
  }

  function ToSet<T>(xs: seq<T>): set<T>
  {
    set x: T | x in xs
  }

  method SetToSeq<A>(s: set<A>) returns (se: seq<A>)
    ensures var q := se; forall i :: 0 <= i < |q| ==> q[i] in s
  {
    se := [];
    var temp := s;
    while temp != {}
      invariant forall x :: x in s ==> x in temp || x in se
      invariant forall x :: x in se ==> x in s
    {
      var x :| x in temp;
      se := se + [x];
      temp := temp - {x};
    }
  }

  function Map<A, B>(s: seq<A>, f: A -> B): seq<B>
  {
    if |s| == 0 then []
    else [f(s[0])] + Map(s[1..], f)
  }
}
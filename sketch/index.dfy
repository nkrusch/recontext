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
  type maskr = r : seq<bool> | |r| == degree witness seq(degree, _ => false)
  type mask = m : seq<maskr> | forall i : nat :: i < |m| ==> |m[i]| == degree witness []


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

  class Verify {
    const mut : mutableS
    const imm : immutableS
    const irow : maskr
    const deps : seq<seq<idx>>

    constructor (mut: mutableS, imm: immutableS)
      // ensures |deps| == |mut|
      decreases *
    {
      var deps := Dependencies(mut);
      this.mut := mut;
      this.imm := imm;
      this.deps := deps;

      var tmp := new bool[degree](_ => true);
      for i := 0 to degree { tmp[i] := i in imm; }
      this.irow := tmp[..];
    }

    static method Dependencies(m: mutableS) returns (res: seq<seq<idx>>)
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

    function ApplyIdx(j:idx, ri: nat, o: matrix, m: matrix, mask: mask) : real 
    requires |m| == |o| == |mask| && ri < |o|
    {
      if mask[ri][j] then m[ri][j] else o[ri][j]
    }

    function Apply(o: matrix, m: matrix, mask: mask) : matrix
      requires |o| == |m| == |mask|
      requires forall i : nat :: i < |mask| ==> |mask[i]| == degree
      // ensures var m' := Apply(o, m, mask); |m'| == |o|
    {
      o
    }

    method EnsureC(o: matrix, m: matrix) returns (final: matrix)
      requires MutableHold(o, mut)
      requires |deps| == |mut|
      requires |m| == |o|
      ensures |final| == |o|
      // ensures Correct(final, o, mut, imm)
    {
      var vmap : mask := seq(|o|, _ => irow[..]);
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

      final := Apply(o, m', vmap);
    }
  }

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

  /* Proofs */
  lemma ImmutableOfSameTauto()
    ensures forall m : matrix, i :immutableS :: ImmutableHold(m, m, i)
  {}

}
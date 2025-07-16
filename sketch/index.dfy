module VMod {

  type pos = x : nat | x > 0 witness 1

  // data dimensionality
  const degree : pos

  // types
  type idx = x : nat | x < degree witness 0
  type Pred = seq<real> -> bool

  type mutableT = (seq<idx>, Pred)
  type mutableS = seq<mutableT>
  type immutableS = seq<idx>
  type matrow = r : seq<real> | |r| == degree witness seq(degree, _ => 0.0)
  type maskr = r : seq<bool> | |r| == degree witness seq(degree, _ => false)
  type matrix = seq<matrow>
  type mask = seq<maskr>

  predicate IsCorrect(original: matrix, mutated: matrix, cond: mutableS, imm : immutableS)
    requires |original| == |mutated| {
    ImmutableHold(original, mutated, imm) && MutableHold(mutated, cond)
  }

  predicate MutableHold(matrix: matrix, cond : mutableS) {
    forall row : nat :: 0 <= row < |matrix| ==> MutableHoldAtRow(matrix[row], cond)
  }

  predicate MutableHoldAtRow(row: matrow, cond: mutableS) {
    if |cond| == 0 then true
    else
      var fst, rest := cond[0], cond[1..];
      var values, pred := IdxValues(row, fst.0), fst.1;
      pred(values) && MutableHoldAtRow(row, rest)
  }

  predicate ImmutableHold(original: matrix, mutated: matrix, imm: immutableS)
    requires |original| == |mutated| {
    forall ri : nat :: ri < |original| ==> ImmutableHoldAtRow(original[ri], mutated[ri], imm)
  }

  predicate ImmutableHoldAtRow(o: matrow, m: matrow, ci: immutableS) {
    SeqEqual(IdxValues(o, ci), IdxValues(m, ci))
  }

  predicate SeqEqual<T(==)>(a: seq<T>, b: seq<T>) {
    |a| == |b| && forall i : nat :: 0 <= i < |a| ==> a[i] == b[i]
  }

  method ControlledMutation(o: matrix, m: matrix, mut: mutableS, imm: immutableS) returns (corr: matrix)
    requires |o| == |m| && MutableHold(o, mut)
    ensures  |o| == |corr| // && Correct(final, o, mut, imm)
  {
    var tmp := new bool[degree](_ => true);
    for i := 0 to degree { tmp[i] := i in imm; }
    var irow := tmp[..];

    var vmap : mask := seq(|o|, _ => irow[..]);
    var m' := Apply(o, m, vmap);
    // assert ImmutableHold(o, m', imm);
    vmap := MutMask(m', mut);
    corr := Apply(o, m', vmap);
    //assert IsCorrect(corr, o, mut, imm);
  }

  function MutMask (m: matrix, cond: mutableS) : mask
    ensures var m' := MutMask(m, cond); |m'| == |m|
  {
    if |m| == 0 then []
    else
      var corr := MutableHoldAtRow(m[0], cond);
      [seq(degree, _ => corr)] + MutMask(m[1..], cond)
  }

  function Apply(original: matrix, modified: matrix, mask: mask) : matrix
    requires |original| == |modified| == |mask|
    ensures var m := Apply(original, modified, mask); |m| == |original|
    ensures var m := Apply(original, modified, mask);
            forall r : nat :: r < |original| ==> forall i : idx :: if mask[r][i] then m[r][i] == modified[r][i] else m[r][i] == original[r][i]
  {
    if |original| == 0 then []
    else var o, m, k := original[0], modified[0], mask[0];
         [MapRow(o, m, k)] + Apply(original[1..], modified[1..], mask[1..])
  }

  function MapRow(o: seq<real>, m: seq<real>, k: seq<bool>) : seq<real>
    requires |o| == |m| == |k|
    ensures var r := MapRow(o, m, k);
            |r| == |o| &&
            forall i : nat :: i < |r| ==> if k[i] then r[i] == m[i] else r[i] == o[i]
  {
    if |o| == 0 then []
    else
      var fst := if k[0] then m[0] else o[0];
      [fst] + MapRow(o[1..], m[1..], k[1..])
  }

  function IdxValues(row: matrow, colI: seq<idx>) : seq<real>
    ensures var res := IdxValues(row, colI);
            |res| == |colI| &&
            forall i : nat :: i < |colI| ==> res[i] == row[colI[i]]
  {
    if |colI| == 0 then [] else [row[colI[0]]] + IdxValues(row, colI[1..])
  }
}

// method Dependencies(m: mutableS) returns (res: seq<seq<idx>>)
//   decreases *
//   // ensures |res| == |m|
// {
//   var sets := Map(m, (x: mutableT) => ToSet(x.0));
//   var merged := true;
//   var scc := [];
//   while merged decreases *
//   {
//     merged := false;
//     while |sets| > 0 decreases *
//     {
//       var fst, rest := sets[0], sets[1..];
//       sets := [];
//       for i := 0 to |rest| {
//         var other := rest[i];
//         if other !! fst {
//           sets := sets + [other];
//         } else {
//           merged := true;
//           fst := fst + other;
//         }
//       }
//       scc := scc + [fst];
//     }
//   }
//   res := [];
//   for i := 0 to |m| {
//     var idx := ToSet(m[i].0);
//     for j := 0 to |scc| {
//       if (scc[j] !! idx) == false {
//         idx := idx + scc[j];
//       }
//     }
//     var ss := SetToSeq(idx);
//     res := res + [ss];
//   }
// }

  // function Map<A, B>(s: seq<A>, f: A -> B): seq<B>
  //   ensures var r := Map(s, f); |r| == |s|
  //   ensures var r := Map(s, f); forall i : nat :: i < |r| ==> r[i] == f(s[i])
  // {
  //   if |s| == 0 then [] else [f(s[0])] + Map(s[1..], f)
  // }

  // function ToSet<T>(xs: seq<T>): set<T>
  // {
  //   set x: T | x in xs
  // }

  // method SetToSeq<A>(s: set<A>) returns (se: seq<A>)
  //   ensures forall i :: 0 <= i < |se| ==> se[i] in s
  //   ensures forall x :: x in s ==> exists i : nat :: i < |se| && se[i] == x
  // {
  //   se := [];
  //   var temp := s;
  //   while temp != {}
  //     invariant forall x :: x in s ==> x in temp || x in se
  //     invariant forall x :: x in se ==> x in s
  //   {
  //     var x :| x in temp;
  //     se := se + [x];
  //     temp := temp - {x};
  //   }
  // }
module DomainSpec {
  // data dimensionality
  const degree : nat := 5

  // numerical domain
  type domain = real
  const Default := 0.0
}

module MutationModule {

  import DS = DomainSpec
  const degree := DS.degree
  type domain = DS.domain

  // types
  type idx = x : nat | x < degree witness 0
  type Pred = seq<domain> -> bool

  type mutableT = (seq<idx>, Pred)
  type mutableS = seq<mutableT>
  type immutableS = seq<idx>
  type matrow = r : seq<domain> | |r| == degree witness seq(degree, _ => DS.Default)
  type maskr = r : seq<bool> | |r| == degree witness seq(degree, _ => false)
  type mask1 = r : maskr | forall i : idx :: r[i] == r[0] witness seq(degree, _ => false)
  type matrix = seq<matrow>
  type mask = seq<maskr>

  /*********************************/
  /* Correctness under constraints */
  /*********************************/

  predicate IsCorrect(original: matrix, mutated: matrix, cond: mutableS, imm : immutableS)
    requires |original| == |mutated|
  {
    forall ri : nat :: ri < |original| ==> CorrectVector(original[ri], mutated[ri], cond, imm)
  }

  predicate MutableHold(matrix: matrix, cond : mutableS)
  {
    forall ri : nat :: ri < |matrix| ==> MutableVecCorrect(matrix[ri], cond)
  }

  predicate CorrectVector(o: matrow, m: matrow, cond: mutableS, imm : immutableS)
  {
    ImmutableVecCorrect(o, m, imm) && MutableVecCorrect(m, cond)
  }

  predicate ImmutableVecCorrect(o: matrow, m: matrow, ci: immutableS)
  {
    IdxValues(o, ci) == IdxValues(m, ci)
  }

  predicate MutableVecCorrect(row: matrow, cond: mutableS)
    ensures
      var b := MutableVecCorrect(row, cond);
      (b ==> forall i : nat :: i < |cond| ==> EvalPred(row, cond[i])) &&
      (!b ==> exists i : nat :: i < |cond| && EvalPred(row, cond[i]) == false)
  {
    if |cond| == 0 then true
    else
      var fst, rest := cond[0], cond[1..];
      if !EvalPred(row, fst) then false
      else MutableVecCorrect(row, rest)
  }

  predicate EvalPred(row: matrow, cond: mutableT) {
    var indices, pred := cond.0, cond.1;
    var values := IdxValues(row, indices);
    pred(values)
  }

  lemma  EquivCorrectness(r1: matrow, r2: matrow, cond: mutableS)
    requires MutableVecCorrect(r1, cond)
    ensures r1 == r2 ==> MutableVecCorrect(r2, cond)
  { }

  /***********************************/
  /* Correctness preserving mutation */
  /***********************************/

  method VectMutation(o: matrow, m: matrow, mut: mutableS, imm: immutableS) returns (final: matrow)
    requires MutableVecCorrect(o, mut)
    ensures CorrectVector(o, final, mut, imm)
  {
    var m' := EnsureImmVector(o, m, imm);
    final := EnsureMutVector(o, m', mut);
  }

  method EnsureImmVector(o: matrow, m: matrow, imm: immutableS) returns (m': matrow)
    ensures ImmutableVecCorrect(o, m', imm)
    ensures forall i : idx :: m'[i] == if !(i in imm) then m[i] else o[i]
  {
    var irow := IRow(imm);
    m' := MapVec(o, m, irow);
  }

  method EnsureMutVector(o: matrow, m: matrow, cond: mutableS) returns (m': matrow)
    requires MutableVecCorrect(o, cond)
    ensures MutableVecCorrect(m, cond) ==> m == m'
    ensures MutableVecCorrect(m', cond)
    ensures forall imm: immutableS :: ImmutableVecCorrect(o, m, imm) ==> ImmutableVecCorrect(o, m', imm)
  {
    var corr := MutableVecCorrect(m, cond);
    var mask : mask1 := seq(degree, _ => corr);
    m' := MapVec(o, m, mask);
    assert MutableVecCorrect(m', cond) by {
      if corr {
        assert MutableVecCorrect(m, cond);
        EquivCorrectness(m, m', cond);
      } else {
        EquivCorrectness(o, m', cond);
      }
    }
  }

  function MapVec(o: seq<domain>, m: seq<domain>, k: seq<bool>) : seq<domain>
    requires |o| == |m| == |k|
    ensures
      var v := MapVec(o, m, k);
      |v| == |o| &&
      (forall i : nat :: i < |v| ==> v[i] == if k[i] then m[i] else o[i])
  {
    if |o| == 0 then []
    else
      var fst := if k[0] then m[0] else o[0];
      [fst] + MapVec(o[1..], m[1..], k[1..])
  }

  function IdxValues(row: matrow, indices: seq<idx>) : seq<domain>
    ensures
      var res := IdxValues(row, indices);
      |res| == |indices| &&
      forall i : nat :: i < |indices| ==> res[i] == row[indices[i]]
  {
    if |indices| == 0 then [] else [row[indices[0]]] + IdxValues(row, indices[1..])
  }

  method IRow(imm: immutableS) returns (irow : maskr)
    ensures |irow| == degree
    ensures forall i : idx :: irow[i] == !(i in imm)
  {
    var tmp := new bool[degree];
    for i := 0 to degree
      invariant forall j : idx :: j < i ==> tmp[j] == !(j in imm)
    {
      tmp[i] := !(i in imm);
    }
    irow := tmp[..];
  }

  /***********************************/
  /* Mutation in 2D */
  /***********************************/

  method ControlledMutation(
    o: matrix, m: matrix, mut: mutableS, imm: immutableS
  ) returns (final: matrix)
    requires |o| == |m|
    requires MutableHold(o, mut)
    ensures |o| == |final|
    ensures IsCorrect(o, final, mut, imm)
  {
    final := [];
    for i := 0 to |o|
      invariant |final| == i
      invariant forall j:nat :: 0 <= j < i ==> CorrectVector(o[j], final[j], mut, imm)
    {
      var nxt := VectMutation(o[i], m[i], mut, imm);
      assert CorrectVector(o[i], nxt, mut, imm);
      final := final + [nxt];
    }
  }
}

module Tests {
  import V = MutationModule
  type domain = V.domain

  function P(s:seq<domain>) : bool {
    if |s| == 2 then s[0] <= s[1] else false }

  // constraints (invariants)
  const imm := [0, 3, 4]
  const mut := [([1, 3], P)]

  // matrices
  const original : V.matrix := [
    [-2.0, 0.0, 0.0, 2.0, 3.0],
    [82.0, 1.0, 7.0, 4.0, 6.0]
  ]
  // modified
  const mutation : V.matrix := [
    [-2.0, 3.0, 1.0, 2.0, 3.0],
    [ 6.0, 4.0, 3.0, 4.0, 7.0]
  ]
  // immutable (only)
  const expectedIR : V.matrix := [
    [-2.0, 3.0, 1.0, 2.0, 3.0],
    [82.0, 4.0, 3.0, 4.0, 6.0]
  ]
  // correct mutation
  const final : V.matrix := [
    [-2.0, 0.0, 0.0, 2.0, 3.0],
    [82.0, 4.0, 3.0, 4.0, 6.0]
  ]

  method Basics(){
    var irow := V.IRow(imm);
    assert irow == [false, true, true, false, false];

    assert V.IdxValues(original[0], [0, 1, 3]) ==
           [original[0][0], original[0][1], original[0][3]];
    assert V.IdxValues(original[1], [2, 4]) ==
           [original[1][2], original[1][4]];

    assert V.MutableHold(original, mut);
    assert V.IsCorrect(original, original, mut, imm);
    assert (V.MutableHold(mutation, mut) == false) by {
      assert V.MutableVecCorrect(mutation[0], mut) == false;
    }
  }

  method ImmutableTransfrom()
  {
    var IR0 := V.EnsureImmVector(original[0], mutation[0], imm);
    var IR1 := V.EnsureImmVector(original[1], mutation[1], imm);

    assert IR0 == expectedIR[0];
    assert IR1 == expectedIR[1];

    assert V.ImmutableVecCorrect(original[0], IR0, imm);
    assert V.ImmutableVecCorrect(original[1], IR1, imm);

    assert V.EvalPred(IR0, mut[0]) == false;
    assert V.EvalPred(IR1, mut[0]) == true;
  }

  // method Main() {

  //   var irow := V.IRow(imm);
  //   var imask :=  seq(2, _ => irow);
  //   var IR := V.Apply(original, mutation, imask);
  //   assert V.MutableHoldAtRow(IR[1], mut);

  //   var mmask := V.MutationMask(IR, mut);
  //   assert mmask[0] == [false, false, false, false, false];
  //   assert mmask[1] == [true, true, true, true, true];
  //   assert mmask == [mmask[0], mmask[1]];

  //   var final := V.ControlledMutation(original, mutation, mut, imm);
  //   var final' := V.Apply(original, IR, mmask);
  //   assert final'[0] == [-2, 0, 0, 2, 3];
  //   assert final'[1] == [82, 4, 3, 4, 6];
  //   assert final' == [final'[0], final'[1]];
  //   assert V.SeqEqual(final'[0], [-2, 0, 0, 2, 3]);
  //   assert V.ImmutableHold(original, final', imm);
  //   assert V.IsCorrect(original, final', mut, imm);
  // }
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
//
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
//
// lemma RowWiseCorrectness(o: matrix, m: matrix)
//   requires |o| == |m|
//   ensures forall cond: mutableS, imm : immutableS ::
//   IsCorrect(o, m, cond, imm) <==> forall ri : nat ::
//   ri < |m| ==> RowCorrect(o[ri], m[ri], cond, imm)  { }
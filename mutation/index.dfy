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

  function VectMutation(o: matrow, m: matrow, mut: mutableS, imm: immutableS) : matrow
    requires MutableVecCorrect(o, mut)
    ensures
      var final := VectMutation(o,m,mut,imm);
      CorrectVector(o, final, mut, imm)
  {
    var m' := EnsureImmVector(o, m, imm);
    EnsureMutVector(o, m', mut)
  }

  function EnsureImmVector(o: matrow, m: matrow, imm: immutableS) : matrow
    ensures
      var m' := EnsureImmVector(o, m, imm);
      ImmutableVecCorrect(o, m', imm) &&
      forall i : idx :: m'[i] == if !(i in imm) then m[i] else o[i]
  {
    MapVec(o, m, IRow(imm))
  }

  function EnsureMutVector(o: matrow, m: matrow, cond: mutableS) : matrow
    requires MutableVecCorrect(o, cond)
    ensures
      var m' := EnsureMutVector(o, m, cond);
      (MutableVecCorrect(m, cond) ==> m == m') &&
      MutableVecCorrect(m', cond) &&
      forall imm: immutableS :: ImmutableVecCorrect(o, m, imm) ==> ImmutableVecCorrect(o, m', imm)
  {
    var corr := MutableVecCorrect(m, cond);
    var mask : mask1 := seq(degree, _ => corr);
    var m' := MapVec(o, m, mask);
    assert MutableVecCorrect(m', cond) by {
      if corr {
        assert MutableVecCorrect(m, cond);
        EquivCorrectness(m, m', cond);
      } else {
        EquivCorrectness(o, m', cond);
      }
    }
    m'
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

  function IRow(imm: immutableS) : maskr
    ensures |IRow(imm)| == degree
    ensures var r := IRow(imm); forall i : idx :: r[i] == !(i in imm)
  {
    IRowN(0, degree, imm)
  }

  function IRowN(lo: nat, hi:nat, imm: immutableS) : seq<bool>
    decreases hi - lo
    requires lo <= hi
    ensures |IRowN(lo, hi, imm)| == hi - lo
  {
    if hi-lo == 0 then []
    else [!(lo in imm)] + IRowN(lo+1, hi, imm)
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
      invariant IsCorrect(o[..i], final, mut, imm) 
    { 
      var nxt := VectMutation(o[i], m[i], mut, imm);
      assert CorrectVector(o[i], nxt, mut, imm);
      final := final + [nxt];
      assert final[i] == nxt;
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
  const expected : V.matrix := [
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

  method Main() {
    var final := V.ControlledMutation(original, mutation, mut, imm);
    assert V.IsCorrect(original, final, mut, imm);
  }
}



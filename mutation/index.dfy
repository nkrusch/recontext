module MutationModule {

  /** specs of numerical data */
  import DS = DomainSpec
  /** data dimensionality */
  const degree := DS.degree
  /** data value type */
  type D = DS.domain

  /** sequence initializer */
  function init<T>(id: T): seq<T> { seq(degree, _ => id) }

  /** constraint types */
  type idx = x: nat | x < degree witness 0
  type pred = seq<D> -> bool
  type immutables = seq<idx>
  type mutableT = (seq<idx>, pred)
  type mutables = seq<mutableT>

  /** vector (data row) types */
  type vec = r: seq<D> | |r| == degree witness init(DS.Default)
  type mask = r: seq<bool> | |r| == degree witness init(false)
  type mask1 = r: mask | forall i: idx :: r[i] == r[0] witness init(false)

  /** 2D types */
  type matrix = seq<vec>
  type masks = seq<mask>

  //===============================
  // Correctness under constraints
  //===============================

  /** Mutation correctness: A mutation (of original) is permissible if it satisfies, 
      row-wise, all predicates and preserves immutable values. */
  predicate IsCorrect(original: matrix, mutated: matrix, cond: mutables, imm: immutables)
    requires |original| == |mutated|
  {
    forall ri: nat ::
      ri < |original|  ==>
        CorrectVector(original[ri], mutated[ri], cond, imm)
  }

  /** A vector (row of data) is correct is it satisfied all constraints. */
  predicate CorrectVector(o: vec, m: vec, cond: mutables, imm: immutables)
  {
    ImmutableVecCorrect(o, m, imm) && MutableVecCorrect(m, cond)
  }

  /** Immutability constaint holds when values are unchanged. */
  predicate ImmutableVecCorrect(o: vec, m: vec, imm: immutables)
  {
    IdxValues(o, imm) == IdxValues(m, imm)
  }

  /** For a vector, all predicates must be true. */
  predicate MutableVecCorrect(row: vec, cond: mutables)
    ensures
      MutableVecCorrect(row, cond) ==>
        forall i: nat :: i < |cond| ==> EvalPred(row, cond[i])
  {
    if |cond| == 0 then true
    else
      var fst, rest := cond[0], cond[1..];
      if !EvalPred(row, fst) then false
      else MutableVecCorrect(row, rest)
  }

  /** A predicate holds if it evaluates to true. */
  predicate EvalPred(row: vec, cond: mutableT) {
    var indices, P := cond.0, cond.1;
    var values := IdxValues(row, indices);
    P(values)
  }

  /** For a matrix, predicates hold for all vectors */
  predicate MutableHold(matrix: matrix, cond: mutables)
  {
    forall ri : nat :: ri < |matrix| ==> MutableVecCorrect(matrix[ri], cond)
  }

  lemma  EquivCorrectness(r1: vec, r2: vec, cond: mutables)
    requires MutableVecCorrect(r1, cond)
    ensures r1 == r2 ==> MutableVecCorrect(r2, cond)
  { }

  //=================================
  // Correctness preserving mutation 
  //=================================

  function VectMutation(o: vec, m: vec, mut: mutables, imm: immutables): vec
    requires MutableVecCorrect(o, mut)
    ensures
      var final := VectMutation(o,m,mut,imm);
      CorrectVector(o, final, mut, imm)
  {
    var m' := EnsureImmVector(o, m, imm);
    EnsureMutVector(o, m', mut)
  }

  function EnsureImmVector(o: vec, m: vec, imm: immutables): vec
    ensures
      var m' := EnsureImmVector(o, m, imm);
      ImmutableVecCorrect(o, m', imm) &&
      forall i: idx :: m'[i] == if !(i in imm) then m[i] else o[i]
  {
    MapVec(o, m, IRow(imm))
  }

  function EnsureMutVector(o: vec, m: vec, cond: mutables): vec
    requires MutableVecCorrect(o, cond)
    ensures
      var m' := EnsureMutVector(o, m, cond);
      (MutableVecCorrect(m, cond) ==> m == m') &&
      MutableVecCorrect(m', cond) &&
      forall imm: immutables :: ImmutableVecCorrect(o, m, imm) ==> ImmutableVecCorrect(o, m', imm)
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

  function MapVec(o: seq<D>, m: seq<D>, k: seq<bool>): seq<D>
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

  function IdxValues(row: vec, indices: seq<idx>): seq<D>
    ensures
      var res := IdxValues(row, indices);
      |res| == |indices| &&
      forall i: nat :: i < |indices| ==> res[i] == row[indices[i]]
  {
    if |indices| == 0 then [] else [row[indices[0]]] + IdxValues(row, indices[1..])
  }

  function IRow(imm: immutables): mask
    ensures |IRow(imm)| == degree
    ensures var r := IRow(imm); forall i : idx :: r[i] == !(i in imm)
  {
    IRowN(0, degree, imm)
  }

  function IRowN(lo: nat, hi:nat, imm: immutables): seq<bool>
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
    o: matrix, m: matrix, mut: mutables, imm: immutables
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

module DomainSpec {
  // dimensionality of numerical data
  const degree: nat := 5

  // type of numerica data
  type domain = real
  const Default:= 0.0
}

module Tests {
  import V = MutationModule
  type domain = V.D

  function P(s:seq<domain>): bool {
    if |s| == 2 then s[0] <= s[1] else false }

  // constraints (invariants)
  const imm := [0, 3, 4]
  const mut := [([1, 3], P)]

  // matrices
  const original: V.matrix := [
    [-2.0, 0.0, 0.0, 2.0, 3.0],
    [82.0, 1.0, 7.0, 4.0, 6.0]
  ]
  // modified
  const mutation: V.matrix := [
    [-2.0, 3.0, 1.0, 2.0, 3.0],
    [ 6.0, 4.0, 3.0, 4.0, 7.0]
  ]
  // immutable (only)
  const expectedIR: V.matrix := [
    [-2.0, 3.0, 1.0, 2.0, 3.0],
    [82.0, 4.0, 3.0, 4.0, 6.0]
  ]
  // correct mutation
  const expected: V.matrix := [
    [-2.0, 0.0, 0.0, 2.0, 3.0],
    [82.0, 4.0, 3.0, 4.0, 6.0]
  ]

  method Basics(){
    var irow:= V.IRow(imm);
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



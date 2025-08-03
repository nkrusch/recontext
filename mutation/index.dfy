module MutationModule {

  // specs of numerical data
  import DS = DomainSpec
  /** data dimensionality */
  const degree := DS.degree
  /** type of data values */
  type D = DS.domain

  // sequence initializer
  function init<T>(id: T): seq<T> { seq(degree, _ => id) }

  // constraint types
  type idx = x: nat | x < degree witness 0
  type pred = seq<D> -> bool
  type immutables = seq<idx>
  type mutableT = (seq<idx>, pred)
  type mutables = seq<mutableT>

  // vector (data row) types
  type vec = r: seq<D> | |r| == degree witness init(DS.Default)
  type mask = r: seq<bool> | |r| == degree witness init(false)
  type mask1 = r: mask | forall i: idx :: r[i] == r[0] witness init(false)

  // 2D types
  type matrix = seq<vec>
  type masks = seq<mask>

  //===============================
  // Correctness under constraints
  //===============================

  /** Mutation correctness: A matrix mutation (of original) is permissible 
      if it satisfies all predicates and preserves immutable values. */
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

  /** Predicates hold for all vectors */
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

  /** Controlled mutation of a data vector that preserves constraints. */
  function VectMutation(o: vec, m: vec, cond: mutables, imm: immutables): vec
    requires MutableVecCorrect(o, cond)
    ensures CorrectVector(o, m, cond, imm) ==> m == VectMutation(o, m, cond, imm)
    ensures var m' := VectMutation(o, m, cond, imm); CorrectVector(o, m', cond, imm)
    ensures var ir :=  EnsureImmVector(o, m, imm);
            VectMutation(o, m, cond, imm) == if MutableVecCorrect(ir, cond) then ir else o
  {
    var ir := EnsureImmVector(o, m, imm);
    EnsureMutVector(o, ir, cond)
  }

  function EnsureImmVector(o: vec, m: vec, imm: immutables): vec
    ensures var m' := EnsureImmVector(o, m, imm);
            (forall i: idx :: m'[i] == if i in imm then o[i] else m[i]) &&
            ImmutableVecCorrect(o, m', imm)  &&
            (ImmutableVecCorrect(o, m, imm) ==> m == m')
  {
    MapVec(o, m, IRow(imm))
  }

  function MapVec(o: seq<D>, m: seq<D>, k: seq<bool>): seq<D>
    requires |o| == |m| == |k|
    ensures |o| == |MapVec(o, m, k)|
    ensures var v := MapVec(o, m, k);
            forall i: nat :: i < |v| ==> v[i] == if k[i] then m[i] else o[i]
  {
    if |o| == 0 then []
    else
      var fst := if k[0] then m[0] else o[0];
      [fst] + MapVec(o[1..], m[1..], k[1..])
  }

  function EnsureMutVector(o: vec, m: vec, cond: mutables): vec
    requires MutableVecCorrect(o, cond)
    ensures MutableVecCorrect(EnsureMutVector(o, m, cond), cond)
    ensures EnsureMutVector(o, m, cond) == if MutableVecCorrect(m, cond) then m else o
    ensures var m' := EnsureMutVector(o, m, cond);
            forall imm: immutables :: ImmutableVecCorrect(o, m, imm) ==> ImmutableVecCorrect(o, m', imm)
  {
    var corr := MutableVecCorrect(m, cond);
    var mask : mask1 := seq(degree, _ => corr);
    var m' := MapVec(o, m, mask);
    EquivCorrectness(if corr then m else o, m', cond);
    m'
  }

  function IdxValues(row: vec, indices: seq<idx>): seq<D>
    ensures |indices| == |IdxValues(row, indices)|
    ensures var r := IdxValues(row, indices);
            forall i: nat :: i < |indices| ==> r[i] == row[indices[i]]
  {
    if |indices| == 0 then []
    else [row[indices[0]]] + IdxValues(row, indices[1..])
  }

  function IRow(imm: immutables): mask
    ensures |IRow(imm)| == degree
    ensures var r := IRow(imm);
            forall i: idx :: r[i] == !(i in imm)
  {
    var f := i => !(i in imm);
    IdxMap(0, degree, f)
  }

  function IdxMap(lo: nat, hi:nat, f: nat-> bool): seq<bool>
    decreases hi - lo
    requires lo <= hi
    ensures |IdxMap(lo, hi, f)| == hi - lo
    ensures var r := IdxMap(lo, hi, f);
            forall i: nat :: i < |r| ==> r[i] == f(i + lo)
  {
    if hi - lo == 0 then []
    else [f(lo)] + IdxMap(lo + 1, hi, f)
  }

  lemma MutationFact1(o: vec, m: vec, cond: mutables, imm: immutables)
    requires MutableVecCorrect(o, cond)
    ensures var ir := EnsureImmVector(o, m, imm);
            MutableVecCorrect(ir, cond) ==> ir == VectMutation(o, m, cond, imm)
  {}

  //================
  // Mutation in 2D
  //================

  function ControlledMutation(
    o: matrix, m: matrix, mut: mutables, imm: immutables) : matrix
    requires |o| == |m|
    requires MutableHold(o, mut)
    ensures |o| == |ControlledMutation(o, m, mut, imm)|
    ensures
      var m' := ControlledMutation(o, m, mut, imm);
      IsCorrect(o, m', mut, imm) &&
      (forall i : nat :: i < |o| ==> m'[i] == VectMutation(o[i], m[i], mut, imm))
  {
    if |o| == 0 then []
    else [VectMutation(o[0], m[0], mut, imm)] + ControlledMutation(o[1..], m[1..], mut, imm)
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

  predicate P(s: seq<domain>) {
    |s| > 1 && s[0] <= s[1]
  }

  // constraints (invariants)
  const imm := [0, 3, 4]
  const cond := [([1, 3], P)]

  const RealSample := (
    [[-2.3, 1.8, 5.0, 4.1, 7.2], [82.2, 1.3, 7.6, 4.8, 6.3]],
    [[-2.5, 3.2, 5.5, 4.3, 6.8], [14.4, 5.1, 6.9, 4.8, 6.1]],
    [[-2.3, 3.2, 5.5, 4.1, 7.2], [82.2, 5.1, 6.9, 4.8, 6.3]],
    [[-2.3, 3.2, 5.5, 4.1, 7.2], [82.2, 1.3, 7.6, 4.8, 6.3]])

  const IntSample := (
    [[-2, 1, 4, 7, -3], [11, 2, -7, 5, 3]],
    [[-3, 2, 5, 8, -4], [10, 6, -5, 4, 2]],
    [[-2, 2, 5, 7, -3], [11, 6, -5, 5, 3]],
    [[-2, 2, 5, 7, -3], [11, 2, -7, 5, 3]])

  const source := RealSample
  const original := source.0
  const mutation := source.1
  const IR := source.2
  const expected := source.3

  method Basics()
  {
    assert V.MutableHold(original, cond);

    assert (V.MutableHold(mutation, cond) == false) by {
      assert V.MutableVecCorrect(mutation[1], cond) == false;
    }
  }

  method ImmutableTransfrom()
  {
    var IR0 := V.EnsureImmVector(original[0], mutation[0], imm);
    var IR1 := V.EnsureImmVector(original[1], mutation[1], imm);
    assert IR0 == IR[0] && IR1 == IR[1];

    assert V.ImmutableVecCorrect(original[0], IR0, imm);
    assert V.ImmutableVecCorrect(original[1], IR1, imm);

    assert V.EvalPred(IR0, cond[0]) == true;
    assert V.EvalPred(IR1, cond[0]) == false;
  }

  method Main() {
    var o, m := original, mutation;

    var final := V.ControlledMutation(o, m, cond, imm);
    assert V.IsCorrect(o, final, cond, imm);

    var ir0 := V.EnsureImmVector(o[0], m[0], imm);
    assert V.MutableVecCorrect(ir0, cond);
    assert final[0]
        == V.VectMutation(o[0], m[0], cond, imm)
        == V.EnsureMutVector(o[0], ir0, cond)
        == expected[0] == ir0;

    var ir1 := V.EnsureImmVector(o[1], m[1], imm);
    assert V.MutableVecCorrect(ir1, cond) == false;
    assert final[1]
        == V.VectMutation(o[1], m[1], cond, imm)
        == V.EnsureMutVector(o[1], ir1, cond)
        == expected[1] == o[1];
  }
}



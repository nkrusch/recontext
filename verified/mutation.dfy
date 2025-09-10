module MutationModule {

  // specs of numerical data
  import DS = DomainSpec
  /** data dimensionality */
  const degree := DS.degree
  /** type of data values */
  type D = DS.domain

  // sequence initializer
  function init<T>(id: T): seq<T> { seq(degree, _ => id) }

  // invariant types
  type idx = x: nat | x < degree witness 0
  type values = seq<D>
  type pred = values -> bool
  type immutableT = idx
  type mutableT = (seq<idx>, pred)
  type immutables = seq<immutableT>
  type mutables = seq<mutableT>

  // vector types
  type vec = r: values | |r| == degree witness init(DS.Default)
  type mask = r: seq<bool> | |r| == degree witness init(false)
  type mask1 = r: mask | forall i: idx :: r[i] == r[0] witness init(false)

  // 2D types
  type trace = seq<vec>
  type masks = seq<mask>

  //===============================
  // Correctness with invariants
  //===============================

  /** Trace mutation is permissible if it satisfies all invariants. */
  predicate IsCorrect(original: trace, mutated: trace, cond: mutables, imm: immutables)
    requires |original| == |mutated|
  {
    forall ri: nat ::
      ri < |original|  ==>
        CorrectVector(original[ri], mutated[ri], cond, imm)
  }

  /** A vector is correct is it satisfied all invariants. */
  predicate CorrectVector(o: vec, m: vec, cond: mutables, imm: immutables)
  {
    ImmutableVecCorrect(o, m, imm) && MutableVecCorrect(m, cond)
  }

  /** Immutability invariant holds when values are unchanged. */
  predicate ImmutableVecCorrect(o: vec, m: vec, imm: immutables)
  {
    IdxValues(o, imm) == IdxValues(m, imm)
  }

  /** Mutation requries all predicates are true. */
  predicate MutableVecCorrect(row: vec, cond: mutables)
    ensures MutableVecCorrect(row, cond) ==>
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
  predicate MutableHold(matrix: trace, cond: mutables)
  {
    forall ri : nat :: ri < |matrix| ==> MutableVecCorrect(matrix[ri], cond)
  }

  lemma  EquivCorrectness(r1: vec, r2: vec, cond: mutables)
    requires MutableVecCorrect(r1, cond)
    ensures r1 == r2 ==> MutableVecCorrect(r2, cond)
  { }

  //===================================
  // Invariant preserving mutation (1D)
  //===================================

  /** 
    * Controlled mutation of a vector that preserves invariants 
    * (using naive reset strategy).
    */
  function VectMutation(o: vec, m: vec, cond: mutables, imm: immutables): vec
    requires MutableVecCorrect(o, cond)
    ensures var m' := VectMutation(o, m, cond, imm);
            CorrectVector(o, m', cond, imm) // correctness
            && (CorrectVector(o, m, cond, imm) ==> m == m') // progress
    ensures var ir :=  EnsureImmVector(o, m, imm);
            VectMutation(o, m, cond, imm) ==
            if MutableVecCorrect(ir, cond) then ir else o
  {
    var ir := EnsureImmVector(o, m, imm);
    EnsureMutVector(o, ir, cond)
  }

  function EnsureImmVector(o: vec, m: vec, imm: immutables): vec
    ensures ImmutableVecCorrect(o, EnsureImmVector(o, m, imm), imm)
    ensures ImmutableVecCorrect(o, m, imm) ==> m == EnsureImmVector(o, m, imm)
    ensures forall i :: i in imm ==> EnsureImmVector(o, m, imm)[i] == o[i]
    ensures forall i: idx :: i !in imm ==> EnsureImmVector(o, m, imm)[i]==m[i]
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
    ensures !MutableVecCorrect(m, cond) ==> EnsureMutVector(o, m, cond) == o
    ensures EnsureMutVector(o, m, cond) ==
            if MutableVecCorrect(m, cond) then m else o
    ensures var m' := EnsureMutVector(o, m, cond);
            forall imm: immutables ::
              ImmutableVecCorrect(o, m, imm) ==>
                ImmutableVecCorrect(o, m', imm)
  {
    var corr := MutableVecCorrect(m, cond);
    var mask : mask1 := seq(degree, _ => corr);
    var m' := MapVec(o, m, mask);
    EquivCorrectness(if corr then m else o, m', cond);
    m'
  }

  lemma MutationFailResets(o: vec, m: vec, cond: mutables)
    requires MutableVecCorrect(o, cond)
    requires !MutableVecCorrect(m, cond) 
    ensures EnsureMutVector(o, m, cond) == o {}


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

  //================
  // Mutation in 2D
  //================

  function ControlledMutation(
    o: trace, m: trace, mut: mutables, imm: immutables) : trace
    requires |o| == |m|
    requires MutableHold(o, mut)
    ensures |o| == |ControlledMutation(o, m, mut, imm)|
    ensures
      var m' := ControlledMutation(o, m, mut, imm);
      IsCorrect(o, m', mut, imm) &&
      (forall i : nat :: i < |o| ==> m'[i] == VectMutation(o[i], m[i], mut, imm))
  {
    if |o| == 0 then []
    else [VectMutation(o[0], m[0], mut, imm)] +
         ControlledMutation(o[1..], m[1..], mut, imm)
  }

}

// To configure value type and dimensionality
//
module DomainSpec {
  // dimensionality of numerical data
  const degree: nat := 5

  // type of numerica data
  type domain = int
  const Default:= 0
}

module Tests {

  import V = MutationModule
  type domain = V.D

  // for some reason |s| > 1 is easier than |s| == 2
  predicate P(s: seq<domain>)
  {
    |s| > 1 && s[0] <= s[1]
  }

  // Invariants
  const imm := [0, 3, 4]
  const mut := [([1, 3], P)]
  const I := mut[0]

  const RealSample := (
    [[-2.3, 1.8, 5.0, 4.1, 7.2], [82.2, 1.3, 7.6, 4.8, 6.3]],
    [[-2.5, 3.2, 5.5, 4.3, 6.8], [14.4, 5.1, 6.9, 4.8, 6.1]],
    [[-2.3, 3.2, 5.5, 4.1, 7.2], [82.2, 5.1, 6.9, 4.8, 6.3]],
    [[-2.3, 3.2, 5.5, 4.1, 7.2], [82.2, 1.3, 7.6, 4.8, 6.3]])

  const IntSample := (
    [[-2, 1, 4, 7, -3], [11, 2, -7, 5, 3]], // [X] initial
    [[-3, 2, 5, 8, -4], [10, 6, -5, 4, 2]], // [Y] mutation
    [[-2, 2, 5, 7, -3], [11, 6, -5, 5, 3]], // mid-[T]ransform
    [[-2, 2, 5, 7, -3], [11, 2, -7, 5, 3]]) // [E]xpected (final)

  const source := IntSample
  const X := source.0 // [X] initial
  const Y := source.1 // [Y] mutation
  const T := source.2 // mid-[T]ransform
  const E := source.3 // [E]xpected (final)

  method CheckPremises()
    ensures V.MutableHold(X, mut)
    ensures !V.MutableHold(Y, mut)
  {
    // initial input is satisfactory
    assert V.MutableHold(X, mut);

    // the mutation does not preserve all invariants
    assert (V.MutableHold(Y, mut) == false) by {
      assert !V.MutableVecCorrect(Y[1], mut);
    }

    // expect a mix of initial and mutated values
    assert E[0] == T[0] && E[1] == X[1];
  }

  method EnsureImmRestoresImmutableIndices()
    ensures
      forall i : nat ::
        i < |X| ==>
          var vi := V.EnsureImmVector(X[i], Y[i], imm);
          V.ImmutableVecCorrect(X[i], vi, imm)
  {
    var T0 := V.EnsureImmVector(X[0], Y[0], imm);
    assert V.ImmutableVecCorrect(X[0], T0, imm);

    var T1 := V.EnsureImmVector(X[1], Y[1], imm);
    assert V.ImmutableVecCorrect(X[1], T1, imm);
  }

  method MutableTransfrom()
    ensures V.MutableVecCorrect(V.EnsureImmVector(X[0], Y[0], imm), mut)
    ensures !V.MutableVecCorrect(V.EnsureImmVector(X[1], Y[1], imm), mut)
  {
    // Mutation predicates hold for T0
    assert V.EvalPred(X[0], I);
    var T0 := V.EnsureImmVector(X[0], Y[0], imm);
    assert V.EvalPred(T0, I);
    assert V.MutableVecCorrect(T0, mut);
    assert  E[0] == V.EnsureMutVector(X[0], T0, mut) == T0;

    // Mutation predicates fails => reset to X
    assert V.EvalPred(X[1], I);
    var T1 := V.EnsureImmVector(X[1], Y[1], imm);
    assert V.EvalPred(T1, I) == false by {
      assert T1[1] == Y[1][1];
      assert T1[3] == X[1][3];
      assert !(T1[1] <= T1[3]);
    }
    assert V.MutableVecCorrect(T1, mut) == false;
    assert E[1] == V.EnsureMutVector(X[1], T1, mut) == X[1];
  }

  method Main() {
    var Y' := V.ControlledMutation(X, Y, mut, imm);
    assert V.IsCorrect(X, Y', mut, imm);
  }
}

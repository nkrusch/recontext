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

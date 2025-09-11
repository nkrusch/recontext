include "mutation.dfy"

// Test data mutations
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
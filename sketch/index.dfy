module DomainSpec {
  // data dimensionality
  const degree : nat := 5

  // numerical domain
  type domain = int
  const Default := 0
}

module MyMod {

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
  type matrix = seq<matrow>
  type mask = seq<maskr>

  predicate IsCorrect(original: matrix, mutated: matrix, cond: mutableS, imm : immutableS)
    requires |original| == |mutated|
  {
    ImmutableHold(original, mutated, imm) && MutableHold(mutated, cond)
  }

  predicate RowCorrect(o: matrow, m: matrow, cond: mutableS, imm : immutableS)
  {
    ImmutableHoldAtRow(o, m, imm) && MutableHoldAtRow(m, cond)
  }

  predicate MutableHold(matrix: matrix, cond : mutableS)
  {
    forall row : nat :: row < |matrix| ==> MutableHoldAtRow(matrix[row], cond)
  }

  predicate MutableHoldAtRow(row: matrow, cond: mutableS)
  {
    if |cond| == 0 then true
    else
      var fst, rest := cond[0], cond[1..];
      var values, pred := IdxValues(row, fst.0), fst.1;
      pred(values) && MutableHoldAtRow(row, rest)
  }

  predicate ImmutableHold(original: matrix, mutated: matrix, imm: immutableS)
    requires |original| == |mutated|
  {
    forall ri : nat :: ri < |original| ==> ImmutableHoldAtRow(original[ri], mutated[ri], imm)
  }

  predicate ImmutableHoldAtRow(o: matrow, m: matrow, ci: immutableS)
  {
    SeqEqual(IdxValues(o, ci), IdxValues(m, ci))
  }

  predicate SeqEqual<T(==)>(a: seq<T>, b: seq<T>) {
    |a| == |b| && forall i : nat :: i < |a| ==> a[i] == b[i]
  }

  method ControlledMutation(o: matrix, m: matrix, mut: mutableS, imm: immutableS) returns (final: matrix)
    requires |o| == |m|
    requires MutableHold(o, mut)
    ensures |o| == |final|
    ensures ImmutableHold(o, final, imm)
    // ensures IsCorrect(o, final, mut, imm)
  {
    var irow := IRow(imm);
    var imap' := seq(|o|, _ => irow);
    var m' := Apply(o, m, imap');
    assert ImmutableHold(o, m', imm);
    var mmap := MutationMask(m', mut);
    final := Apply(o, m', mmap);
    // assert IsCorrect(o, final, mut, imm);
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

  function MutationMask(m: matrix, cond: mutableS) : mask
    ensures var m' := MutationMask(m, cond); |m'| == |m|
    ensures var m' := MutationMask(m, cond); forall ri:nat, j:idx :: ri <|m| ==>  m'[ri][0] == m'[ri][j]
    ensures var m' := MutationMask(m, cond); forall ri : nat :: ri < |m| ==> m'[ri][0] == MutableHoldAtRow(m[ri], cond)
  {
    if |m| == 0 then []
    else [MutationMaskRow(m[0], cond)] + MutationMask(m[1..], cond)
  }
  function MutationMaskRow(r : matrow, cond: mutableS) : maskr
    ensures var r' := MutationMaskRow(r, cond);
            var b := MutableHoldAtRow(r, cond);
            forall i : idx :: r'[i] == b
  {
    var corr := MutableHoldAtRow(r, cond);
    seq(degree, _ => corr)
  }

  function Apply(original: matrix, modified: matrix, mask: mask) : matrix
    requires |original| == |modified| == |mask|
    ensures var m := Apply(original, modified, mask); |m| == |original|
    ensures var m := Apply(original, modified, mask);
            forall r : nat :: r < |original| ==> forall i : idx ::
                                  if mask[r][i] then m[r][i] == modified[r][i] else m[r][i] == original[r][i]
  {
    if |original| == 0 then []
    else
      var o, m, k := original[0], modified[0], mask[0];
      [MapRow(o, m, k)] + Apply(original[1..], modified[1..], mask[1..])
  }

  function MapRow(o: seq<domain>, m: seq<domain>, k: seq<bool>) : seq<domain>
    requires |o| == |m| == |k|
    ensures var r := MapRow(o, m, k); |r| == |o|
    ensures var r := MapRow(o, m, k); forall i : nat :: i < |r| ==> if k[i] then r[i] == m[i] else r[i] == o[i]
  {
    if |o| == 0 then []
    else
      var fst := if k[0] then m[0] else o[0];
      [fst] + MapRow(o[1..], m[1..], k[1..])
  }

  function IdxValues(row: matrow, ii: seq<idx>) : seq<domain>
    ensures var res := IdxValues(row, ii); |res| == |ii|
    ensures var res := IdxValues(row, ii); forall i : nat :: i < |ii| ==> res[i] == row[ii[i]]
  {
    if |ii| == 0 then [] else [row[ii[0]]] + IdxValues(row, ii[1..])
  }

  lemma RowWiseCorrectness(o: matrix, m: matrix)
    requires |o| == |m|
    ensures forall cond: mutableS, imm : immutableS ::
              IsCorrect(o, m, cond, imm) <==> forall ri : nat :: ri < |m| ==> RowCorrect(o[ri], m[ri], cond, imm)  { }

}

module Tests {
  import V = MyMod
  type domain = V.domain

  function P(s:seq<domain>) : bool { if |s| == 2 then s[0] <= s[1] else false }

  // invariants
  const imm := [0, 3, 4]
  const mut := [([1, 3], P)]

  // matrices
  const original : V.matrix := [
    [-2, 0, 0, 2, 3],
    [82, 1, 7, 4, 6]
  ]
  const mutation : V.matrix := [
    [-2, 3, 1, 2, 3],
    [ 6, 4, 3, 4, 7]
  ]

  method Basics(){
    var irow := V.IRow(imm);
    var imask :=  seq(2, _ => irow);
    assert irow == [false, true, true, false, false];
    assert imask == [irow, irow];

    assert V.IdxValues(mutation[0], [0, 1, 3]) == [-2, 3, 2];
    assert V.IdxValues(mutation[1], [2, 4]) == [3, 7];

    assert V.MutableHold(original, mut);
    assert V.IsCorrect(original, original, mut, imm);
    assert (V.MutableHold(mutation, mut) == false) by {
      assert V.MutableHoldAtRow(mutation[0], mut) == false;
    }
  }

  method IRCheck()
  {
    var irow := V.IRow(imm);
    var imask :=  seq(2, _ => irow);
    var IR := V.Apply(original, mutation, imask);
    var values, pred := V.IdxValues(IR[1], mut[0].0), mut[0].1;

    assert IR[0] == [-2, 3, 1, 2, 3];
    assert IR[1] == [82, 4, 3, 4, 6];
    assert IR == [IR[0], IR[1]];
    assert values == [4, 4] && pred(values);

    assert V.ImmutableHold(original, IR, imm);
    assert V.MutableHoldAtRow(IR[1], mut);
    assert (V.MutableHold(IR, mut) == false) by {
      assert V.MutableHoldAtRow(IR[0], mut) == false;
    }
  }

  method Main() {

    var irow := V.IRow(imm);
    var imask :=  seq(2, _ => irow);
    var IR := V.Apply(original, mutation, imask);
    assert V.MutableHoldAtRow(IR[1], mut);

    var mmask := V.MutationMask(IR, mut);
    assert mmask[0] == [false, false, false, false, false];
    assert mmask[1] == [true, true, true, true, true];
    assert mmask == [mmask[0], mmask[1]];

    var final := V.ControlledMutation(original, mutation, mut, imm);
    var final' := V.Apply(original, IR, mmask);
    assert final'[0] == [-2, 0, 0, 2, 3];
    assert final'[1] == [82, 4, 3, 4, 6];
    assert final' == [final'[0], final'[1]];
    assert V.SeqEqual(final'[0], [-2, 0, 0, 2, 3]);
    assert V.ImmutableHold(original, final', imm);
    assert V.IsCorrect(original, final', mut, imm);
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
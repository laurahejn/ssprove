(* Global utility *)
(* Partly stolen from MetaCoq *)

From Coq Require Import Utf8 Lia.
Set Warnings "-notation-overridden".
From mathcomp Require Import ssreflect eqtype ssrbool ssrnat.
Set Warnings "notation-overridden".
From extructures Require Import ord.
From Equations Require Import Equations.

Set Bullet Behavior "Strict Subproofs".
Set Default Goal Selector "!".
Set Primitive Projections.

(* Simple products *)

(* Notation "x × y" := (prod x y) (at level 80, right associativity). *)


(* Dependent sums *)

(* Use \sum to input ∑ in Company Coq (it is not a sigma Σ). *)
Notation "'∑' x .. y , p" := (sigT (fun x => .. (sigT (fun y => p%type)) ..))
  (at level 200, x binder, right associativity,
   format "'[' '∑'  '/  ' x  ..  y ,  '/  ' p ']'")
  : type_scope.

Notation "( x ; y )" := (@existT _ _ x y).
Notation "( x ; y ; z )" := (x ; ( y ; z)).
Notation "( x ; y ; z ; t )" := (x ; ( y ; (z ; t))).
Notation "( x ; y ; z ; t ; u )" := (x ; ( y ; (z ; (t ; u)))).
Notation "( x ; y ; z ; t ; u ; v )" := (x ; ( y ; (z ; (t ; (u ; v))))).
Notation "x .π1" := (@projT1 _ _ x) (at level 3, format "x '.π1'").
Notation "x .π2" := (@projT2 _ _ x) (at level 3, format "x '.π2'").


(* Handy rewrite on sig *)

Lemma sig_rewrite_aux :
  ∀ {T A} {P : A → Prop} {x y} (p : T → A) (h : P (p x)) (e : x = y),
    P (p y).
Proof.
  intros T A P x y p h e. subst. auto.
Defined.

Lemma sig_rewrite :
  ∀ {T A} {P : A → Prop} {x y} (p : T → A) (h : P (p x)) (e : x = y),
    exist _ (p x) h = exist _ (p y) (sig_rewrite_aux p h e).
Proof.
  intros T A P x y p h e. subst. reflexivity.
Qed.

Ltac sig_rewrite e :=
  lazymatch type of e with
  | ?x = _ =>
    match goal with
    | |- context [ exist ?P ?p ?h ] =>
      lazymatch p with
      | context [ x ] =>
        lazymatch eval pattern x in p with
        | (fun x => @?q x) ?y =>
          erewrite (sig_rewrite q _ e)
        end
      end
    end
  end.

(** Tactic sig rewrite

  Usage: you have e : x = y as an hypothesis and you want to rewrite e inside
  a term of the form exist _ u v, specifically inside the term u.
  sig rewrite e will replace x by y in u and update v accordingly.

*)
Tactic Notation "sig" "rewrite" hyp(e) :=
  sig_rewrite e.


(** Tactic falso

  Usage: you have an hyothesis containing a use of [False_rect] at top-level.
  This tactic will take it to close the goal.

*)
Ltac falso :=
  lazymatch goal with
  | h : context [ False_rect _ ?x ] |- _ => exact (False_rect _ x)
  end.


(** mathcomp: derive EqDec for any ordType *)
Instance ordType_EqDec {A : ordType} : EqDec A.
Proof.
  intros x y. destruct (x == y) eqn:e.
  - move: e => /eqP. auto.
  - move: e => /eqP. auto.
Defined.

(** Notion of positive natural number

  Usage: Simply write [mkpos n] to turn [n] into a positive natural number.
  The positivity proof should be inferred by the [lia] tactic.
*)
Class Positive (n : nat) :=
  is_positive : 0 < n.

Ltac nat_reify :=
  repeat match goal with
  | h : is_true (_ < _) |- _ => move: h => /ltP h
  | h : is_true (_ <= _) |- _ => move: h => /leqP h
  | h : is_true (_ == _) |- _ => move: h => /eqP h
  end.

Hint Extern 1 (Positive ?n) =>
  reflexivity : typeclass_instances.

Hint Extern 2 (Positive ?n) =>
  unfold Positive ; apply/ltP ; lia : typeclass_instances.

Hint Extern 4 (Positive ?n) =>
  unfold Positive ; apply/ltP ; nat_reify ; lia : typeclass_instances.

Instance PositiveExp2 n : Positive (2^n)%N.
Proof.
  unfold Positive. apply/ltP. induction n.
  - auto.
  - rewrite expnS. rewrite mulSnr. rewrite mulSnr.
    change (0 * ?n) with 0.
    set (m := 2^n) in *. clearbody m. cbn.
    rewrite -addnE. rewrite -plusE.
    lia.
Qed.

Record positive := mkpos {
  pos : nat ;
  cond_pos : Positive pos
}.
Arguments mkpos _ {_}.

Definition positive_to_nat (p : positive) : nat :=
  p.(pos).

Coercion positive_to_nat : positive >-> nat.

Definition positive_eq : rel positive :=
  λ u v, u.(pos) == v.(pos).

Lemma positive_eqP : Equality.axiom positive_eq.
Proof.
  intros [n hn] [m hm]. unfold positive_eq. simpl.
  destruct (n == m) eqn:e.
  - move: e => /eqP e. subst. left. f_equal.
    apply eq_irrelevance.
  - move: e => /eqP e. right.
    intro h. apply e. inversion h. reflexivity.
Qed.

Canonical positive_eqMixin := EqMixin positive_eqP.
  Canonical positive_eqType :=
    Eval hnf in EqType positive positive_eqMixin.

(** Tactic to unfold all positives (NEEDED?) *)
Ltac unfold_positives :=
  repeat match goal with
  | p : positive |- _ =>
    let n := fresh "p" in
    let h := fresh "h" in
    destruct p as [n h] ;
    repeat change (pos {| pos := n ; cond_pos := h |}) with n in * ;
    repeat change (positive_to_nat {| pos := n ; cond_pos := h |}) with n in *
  end.

Instance PositiveEqDec n : EqDec (Positive n).
Proof.
  intros x y.
  left. apply eq_irrelevance.
Qed.

Derive NoConfusion NoConfusionHom EqDec for positive.

(* Utility for defining functions with Equations *)
Definition inspect {A : Type} (x : A) : { y : A | y = x } :=
  exist _ x Logic.eq_refl.

(** Hints notation

  When dealing with typeclasses, sometimes automation will fail.
  The purpose of this is to be able to help the automation by providing
  hints without having to write the whole term.

  [hints h1 ; .. ; hn ] will try to solve the goal by having h1 to hn in the
  context. This can be useful to provide lemmata that are not usually picked
  up by the instance mechanism.
  This could also be used in combination with Programs or Equations'
  automation.

  [hints] is also provided for completeness, but is merely long for _.

*)

(* Hints notation *)
Notation "[ 'hints' ]" :=
  (_)
  (at level 0, only parsing)
  : package_scope.

Notation "[ 'hints' x1 ]" :=
  (let hint := x1 in _)
  (at level 0, only parsing)
  : package_scope.

Notation "[ 'hints' x ; .. ; z ]" :=
  (let hint := x in .. (let hint := z in _) ..)
  (at level 0, only parsing)
  : package_scope.
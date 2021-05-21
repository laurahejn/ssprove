(*
  This file showcases the use of packages.
 *)


From Coq Require Import Utf8.
Set Warnings "-ambiguous-paths,-notation-overridden,-notation-incompatible-format".
From mathcomp Require Import ssrnat ssreflect ssrfun ssrbool ssrnum eqtype choice seq.
Set Warnings "ambiguous-paths,notation-overridden,notation-incompatible-format".
From extructures Require Import ord fset fmap.
From Crypt Require Import RulesStateProb Package Prelude.
Import PackageNotation.

From Equations Require Import Equations.
Require Equations.Prop.DepElim.


Set Bullet Behavior "Strict Subproofs".
Set Default Goal Selector "!".
Set Primitive Projections.

#[local] Open Scope package_scope.

Definition I0 : Interface :=
  [interface val #[3] : 'nat → 'nat].

Definition I1 : Interface :=
  [interface
    val #[0] : 'bool → 'bool ;
    val #[1] : 'nat → 'unit ;
    val #[2] : 'unit → 'bool
  ].

Definition I2 : Interface :=
  [interface
    val #[4] : 'bool × 'bool → 'bool
  ].

Definition pempty : package fset0 [interface] [interface] :=
  [package].

Definition p0 : package fset0 [interface] I0 :=
  [package
    def #[3] (x : 'nat) : 'nat {
      ret x
    }
  ].

Definition p1 : package fset0 [interface] I1 :=
  [package
    def #[0] (z : 'bool) : 'bool {
      ret z
    } ;
    def #[1] (y : 'nat) : 'unit {
      ret Datatypes.tt
    } ;
    def #[2] (u : 'unit) : 'bool {
      ret false
    }
  ].

Definition foo (x : bool) : code fset0 [interface] bool_choiceType :=
  {code let u := x in ret u}.

Definition bar (b : bool) : code fset0 [interface] nat_choiceType :=
  {code if b then ret 0 else ret 1}.

Definition p2 : package fset0 [interface] I2 :=
  [package
    def #[4] (x : 'bool × 'bool) : 'bool {
      let '(u,v) := x in ret v
    }
  ].

Definition test₁ :
  package
    [fset (chNat; 0)]
    [interface val #[0] : 'nat → 'nat]
    [interface
      val #[1] : 'nat → 'nat ;
      val #[2] : 'unit → 'unit
    ]
  :=
  [package
    def #[1] (x : 'nat) : 'nat {
      getr ('nat; 0) (λ n : nat,
        opr (0, ('nat, 'nat)) n (λ m,
          putr ('nat; 0) m (ret m)
        )
      )
    } ;
    def #[2] (_ : 'unit) : 'unit {
      putr ('nat; 0) 0 (ret Datatypes.tt)
    }
  ].

Definition sig := {sig #[0] : 'nat → 'nat }.

#[program] Definition test₂ :
  package
    [fset ('nat; 0)]
    [interface val #[0] : 'nat → 'nat ]
    [interface
      val #[1] : 'nat → 'nat ;
      val #[2] : 'unit → 'option ('fin 2) ;
      val #[3] : {map 'nat → 'nat} → 'option 'nat
    ]
  :=
  [package
    def #[1] (x : 'nat) : 'nat {
      n ← get ('nat ; 0) ;;
      m ← op sig ⋅ n ;;
      n ← get ('nat ; 0) ;;
      m ← op sig ⋅ n ;;
      put ('nat ; 0) := m ;;
      ret m
    } ;
    def #[2] (_ : 'unit) : 'option ('fin 2) {
      put ('nat ; 0) := 0 ;;
      ret (Some (gfin 1))
    } ;
    def #[3] (m : {map 'nat → 'nat}) : 'option 'nat {
      ret (getm m 0)
    }
  ].

(* Testing the #import notation *)
Definition test₃ :
  package
    fset0
    [interface
      val #[0] : 'nat → 'bool ;
      val #[1] : 'bool → 'unit
    ]
    [interface
      val #[2] : 'nat → 'nat ;
      val #[3] : 'bool × 'bool → 'bool
    ]
  :=
  [package
    def #[2] (n : 'nat) : 'nat {
      #import {sig #[0] : 'nat → 'bool } as f ;;
      #import {sig #[1] : 'bool → 'unit } as g ;;
      b ← f n ;;
      if b then
        g false ;;
        ret 0
      else ret n
    } ;
    def #[3] ('(b₀,b₁) : 'bool × 'bool) : 'bool {
      ret b₀
    }
  ].

(** Information is redundant between the export interface and the package
    definition, so it can safely be skipped.
*)
Definition test₄ : package fset0 [interface] _ :=
  [package
    def #[ 0 ] (n : 'nat) : 'nat {
      ret (n + n)%N
    } ;
    def #[ 1 ] (b : 'bool) : 'nat {
      if b then ret 0 else ret 13
    }
  ].

Section MoreTests.

  (** As we are in a section, we can safely kill the obligation tactic.
      It will restored after we leave the section.
  *)
  Obligation Tactic := idtac.
  Set Equations Transparent.

  Definition ℓ : Location := ('nat ; 0).

  Equations? foo : code fset0 [interface] 'nat :=
    foo := {code
      n ← get ℓ ;;
      ret n
    }.
  Proof.
    ssprove_valid.
  Abort.

End MoreTests.

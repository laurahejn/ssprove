From mathcomp Require Import all_ssreflect all_algebra.

From Jasmin Require Import
  arch_params_proof
  compiler
  compiler_proof.

From Jasmin Require Import
  arch_decl
  arch_extra
  arch_sem
  asm_gen_proof.

From Jasmin Require Import sem.

From JasminSSProve Require Import jasmin_translate.
From Crypt Require Import Prelude Package.

Import PackageNotation.
Import JasminNotation.
Import Utf8.

Local Open Scope positive.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section __.

Context
  {syscall_state : Type} {sc_sem : syscall.syscall_sem syscall_state} {gf : glob_decls}
  `{asm_e : asm_extra} {call_conv : calling_convention} {asm_scsem : asm_syscall_sem}
  {fresh_vars lowering_options : Type}
  (aparams : architecture_params fresh_vars lowering_options)
  (haparams : h_architecture_params aparams)
  (cparams : compiler_params fresh_vars lowering_options).

Hypothesis print_uprogP : forall s p, cparams.(print_uprog) s p = p.
Hypothesis print_sprogP : forall s p, cparams.(print_sprog) s p = p.
Hypothesis print_linearP : forall s p, cparams.(print_linear) s p = p.

Context `(asm_correct : ∀ o, sem_correct (tin (get_instr_desc (Oasm o))) (sopn_sem (Oasm o))).

Theorem equiv_to_asm subroutine p xp entries scs vm m fn scs' m' va vr xm m_id s_id s_st st :
  compile_prog_to_asm aparams cparams entries subroutine p = ok xp
  -> fn \in entries
  -> sem.sem_call p scs m fn va scs' m' vr
  -> handled_program p
  -> mem_agreement m (asm_mem xm) (asm_rip xm) (asm_globs xp)
  -> enough_stack_space xp fn (top_stack m) (asm_mem xm)
  -> ⊢ ⦃ rel_estate (sem.Estate scs m vm) m_id s_id s_st st ⦄
      get_translated_fun p fn s_id~1 [seq totce (translate_value v) | v <- va]
      ⇓ [seq totce (translate_value v) | v <- vr]
      ⦃ rel_estate (sem.Estate scs' m' vm) m_id s_id~0 s_st st ⦄
  /\ exists xd : asm_fundef,
  get_fundef (asm_funcs xp) fn = Some xd
  /\ forall args',
    asm_scs xm = scs
    -> asm_reg xm ad_rsp = top_stack m
    -> get_typed_reg_values xm (asm_fd_arg xd) = ok args'
    -> List.Forall2 value_uincl va args'
    -> exists xm' res',
    get_typed_reg_values xm' (asm_fd_res xd) = ok res'
    /\ List.Forall2 value_uincl vr res'.
Proof.
  intros cmp fn_in sc hp mem ss.
  split.
  unshelve eapply translate_prog_correct; try eauto.
  unshelve epose proof compile_prog_to_asmP haparams _ _ _ cmp fn_in sc mem ss as [xd [get_fd _ cmp_correct]]; eauto.
  exists xd. split; eauto.
  intros args'.
  specialize (cmp_correct args').
  intros asm_scs asm_reg reg_args' args'_va.
  specialize (cmp_correct asm_scs asm_reg reg_args' args'_va) as [xm' [res' []]].
  exists xm', res'; eauto.
Qed.

End __.

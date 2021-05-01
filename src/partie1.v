Require Import Omega.
Require Import Lia.
Require Import ssreflect.
Require Import ssrfun.
Require Import Coq.ssr.ssrbool.

Notation "a :: b" := (cons a b).
Notation "[]" := (nil).


(* Question 1 *)

Inductive DeBruijn :=
    | Var : nat -> DeBruijn
    | Lambda : DeBruijn -> DeBruijn
    | Application : DeBruijn -> DeBruijn -> DeBruijn
    | Protect : DeBruijn -> DeBruijn.

Check Application (Lambda (Var 0)) (Lambda (Var 0)).

Fixpoint deprotect (t: DeBruijn) :=
    match t with
    | Var n => Var n
    | Lambda tp => Lambda (deprotect tp)
    | Application tp1 tp2 => Application (deprotect tp1) (deprotect tp2)
    | Protect tp => deprotect tp
    end
.

(* Basically "detects" if a terms contains a protected subterm *)
Fixpoint protected (t: DeBruijn) : Prop :=
    match t with
    | Var n => False
    | Lambda tp => protected tp
    | Application tp1 tp2 => (protected tp1) \/ (protected tp2)
    | Protect tp => True
    end
.

Fixpoint contains_geq_n (t: DeBruijn) (n: nat) : Prop :=
    match t with 
    | Var n0 => n0 >= n
    | Lambda t => contains_geq_n t (n + 1)
    | Application tp1 tp2 => (contains_geq_n tp1 n) \/ (contains_geq_n tp2 n)
    | Protect tp => contains_geq_n tp n
    end
.

Fixpoint protected_n (t: DeBruijn) (n: nat) : Prop :=
    match t with
    | Var n0 => False
    | Lambda tp => protected_n tp n
    | Application tp1 tp2 => (protected_n tp1 n) \/ (protected_n tp2 n)
    | Protect tp => contains_geq_n tp n
    end
.

(* This is a safe term, without any protected subterm *)
Notation "S( t )" := (~(protected t)).

Notation "S[ n ]( t )" := (~(protected_n t n)).

(* De Morgan *)
Lemma destruct_false_or : forall (P: Prop), forall (Q: Prop),
    ~(P \/ Q) <-> ~P /\ ~Q.
Proof.
    intuition.
Qed.

Lemma deprotect_correction : forall (t: DeBruijn),
    S(deprotect t).
Proof.
    intro t.
    induction t.
    simpl. auto.
    simpl. exact IHt.
    simpl. apply <- destruct_false_or. split. exact IHt1. exact IHt2. 
    simpl. exact IHt.
Qed. 

Lemma lambda_equal : forall (t: DeBruijn), forall (u: DeBruijn),
    Lambda t = Lambda u -> t = u.
Proof.
    intros t u.
    case. trivial.
Qed.

Theorem safe_deprotect : forall (t: DeBruijn),
    S(t) -> deprotect(t) = t.
Proof.
    induction t.
    simpl. reflexivity.
    simpl. assert (deprotect t =  t -> Lambda (deprotect t) = Lambda t).
    intro H. rewrite H. reflexivity. intro H0. apply H. apply IHt. exact H0.
    simpl. intro H. apply destruct_false_or in H. destruct H.
    assert (deprotect t1 = t1). apply IHt1. exact H.
    assert (deprotect t2 = t2). apply IHt2. exact H0.
    rewrite H1. rewrite H2. reflexivity.
    simpl. contradiction.
Qed.

Lemma deprotect_involutive : forall (t: DeBruijn),
    deprotect (deprotect t) = deprotect t.
Proof.
    move => t.
    assert (S(deprotect t)). apply deprotect_correction.
    apply (safe_deprotect (deprotect t) H).
Qed.

(* Question 2 *)

Fixpoint max_var_smaller_n_depth (t: DeBruijn) (n: nat) (depth: nat) : Prop :=
    match t with
    | Var v => v < n + depth
    | Lambda tp => max_var_smaller_n_depth tp n (depth + 1)
    | Application tp0 tp1 => (max_var_smaller_n_depth tp0 n depth) /\ (max_var_smaller_n_depth tp1 n depth)
    | Protect tp => max_var_smaller_n_depth tp n depth
    end.

Definition max_var_smaller_n (t: DeBruijn) (n: nat) : Prop := 
    max_var_smaller_n_depth t n 0.

Lemma heredite_0: forall (t: DeBruijn), forall (n: nat), forall (d: nat),
    (max_var_smaller_n_depth t n d) -> (max_var_smaller_n_depth t (n+1) d).
Proof.
    move => t.
    induction t.
    simpl. lia.
    simpl. intros n d.
    apply IHt.
    intros n d.
    simpl.
    case. intro H1. intro H2.
    split.
    apply IHt1. apply H1.
    apply IHt2. apply H2.
    simpl. intros n d H.
    apply IHt. exact H.
Qed.
    
Notation "C[ n ]( t )" := (max_var_smaller_n t n).

Lemma C_deprotect_aux : forall (t: DeBruijn), forall (n: nat), forall (d: nat),
    max_var_smaller_n_depth t n d = max_var_smaller_n_depth (deprotect t) n d.
Proof.
    move => t n.
    induction t.
    move => d.
    simpl. reflexivity.
    move => d.
    simpl. rewrite (IHt (d + 1)). reflexivity.
    move => d.
    simpl. rewrite IHt1. rewrite IHt2. reflexivity.
    simpl. exact IHt.
Qed. 

Lemma C_deprotect : forall (t: DeBruijn), forall (n: nat),
    C[n](t) -> C[n](deprotect t).
Proof.
    move => t n Cn.
    unfold max_var_smaller_n.
    unfold max_var_smaller_n in Cn.
    rewrite <- (C_deprotect_aux t n 0). exact Cn.
Qed.

Lemma inutile_0 : forall (n: nat),
    n + 0 = n.
Proof.
    intro n.
    lia.
Qed.

Lemma inutile_1 : forall (n: nat),
    S n = n + 1.
Proof.
    intro n.
    lia.
Qed.

Lemma inutile_2 : forall (n: nat), forall (m: nat), forall (p: nat),
    n + m + p = n + (m + p).
Proof.
    intros n m p.
    lia.
Qed.

Lemma heredite_1 : forall (t: DeBruijn), forall (n: nat),
    C[n](t) -> C[n + 1](t).
Proof.
    intros t n H.
    apply heredite_0. exact H.
Qed.

Lemma heredite_2 : forall (t: DeBruijn), forall (n: nat), forall (m: nat),
    C[n](t) -> C[n + m](t).
Proof.
    intros t n m H.
    induction m.
    simpl. rewrite -> inutile_0. exact H.
    rewrite inutile_1. rewrite <- inutile_2.
    apply heredite_1 with (t := t) (n := n + m). exact IHm.
Qed. 

Lemma heredite_3 : forall (t: DeBruijn), forall (n: nat), forall (m: nat),
    n <= m -> C[n](t) -> C[m](t).
Proof.
    intros t n m H H0.
    assert (n + (m - n) = m). lia.
    rewrite <- H1.
    apply heredite_2.
    exact H0.
Qed.

Definition closed (T: DeBruijn) :=
    C[0](T).

Notation "C( t )" := (closed t).

Theorem closed_universal : forall (t: DeBruijn),
    C(t) -> forall (n: nat), C[n](t).
Proof.
    intros t H n.
    induction n.
    exact H.
    assert (n+1 = S n).
    lia.
    rewrite <- H0.
    apply heredite_1 with (t := t) (n := n).
    exact IHn.
Qed.


(* Question 3 *)
(* TODO change this to a unique depth-shift. *)
Fixpoint correct_free_variable_depth (t: DeBruijn) (depth: nat) :=
    match t with
    | Var n => if depth <=? n then Var (n + 1) else Var n
    | Lambda tp => Lambda (correct_free_variable_depth tp (depth + 1))
    | Application tp0 tp1 => Application (correct_free_variable_depth tp0 depth) (correct_free_variable_depth tp1 depth)
    | Protect tp => Protect (correct_free_variable_depth tp depth)
    end
.

Definition correct_free_variable (t: DeBruijn) :=
    correct_free_variable_depth t 0
.

Fixpoint substitution (t: DeBruijn) (index: nat) (u: DeBruijn) : DeBruijn :=
    match t with
    | Var n => if n =? index then (Protect u) else (Var n)
    | Lambda tp => Lambda (substitution tp (index + 1) (correct_free_variable u))
    | Application tp0 tp1 => Application (substitution tp0 index u) (substitution tp1 index u)
    | Protect tp => Protect tp
    end
.

Notation "t [ y <- u ]" := (deprotect (substitution t y u)) (at level 0).

Lemma aux_0 : forall (n: nat), forall (n0: nat),
    C[n](Var n0) -> n > n0.
Proof.
    intros n n0 H.
    induction n.
    unfold max_var_smaller_n in H.
    unfold max_var_smaller_n_depth in H.
    simpl in H. exact H.
    unfold max_var_smaller_n in H.
    unfold max_var_smaller_n_depth in H.
    unfold max_var_smaller_n in IHn.
    unfold max_var_smaller_n_depth in IHn.
    simpl in H. lia.
Qed.


(* Thanks a lot to Samuel Vivien! *)
Lemma aux_0_0 : forall (n: nat), forall (n0: nat),
    n > n0 -> (Nat.eqb n0 n) = false.
Proof.
    intros n n0 H.
    destruct (PeanoNat.Nat.eqb_neq n0 n).
    apply H1.
    lia.
Qed.

Lemma aux_0_1 : forall (n: nat), forall (n0: nat), forall (u: DeBruijn),
    C[n](Var n0) -> (if n0 =? n then u else Var n0) = Var n0.
Proof.
    intros n n0 u H.
    rewrite aux_0_0. apply aux_0. exact H.
    reflexivity.
Qed.

Lemma aux_1_0 : forall (t: DeBruijn), forall (u: DeBruijn),
    u = t -> Lambda u = Lambda t.
Proof.
    intros t u H.
    rewrite H. reflexivity.
Qed.

Lemma aux_1_1 : forall (t1: DeBruijn), forall (t2: DeBruijn), forall (u1: DeBruijn), forall (u2: DeBruijn),
    t1 = u1 -> t2 = u2 -> Application t1 t2 = Application u1 u2.
Proof.
    intros t1 t2 u1 u2 H H0.
    rewrite H. rewrite H0. reflexivity.
Qed.

Lemma aux_2_0 : forall (t: DeBruijn), forall (n: nat), forall (d: nat),
    max_var_smaller_n_depth t n (d + 1) <-> max_var_smaller_n_depth t (n + 1) d.
Proof.
    move => t n d.
    split.
    revert d.
    induction t.
    simpl.
    lia.
    simpl.
    move => d.
    apply IHt with (d := d + 1).
    simpl. case. case.
    simpl. split.
    apply IHt1 with (d := 0). simpl. exact a.
    apply IHt2 with (d := 0). simpl. exact b.
    split.
    destruct H.
    apply IHt1 with (d := S n0). exact H.
    destruct H.
    apply IHt2 with (d := S n0). exact H0.
    simpl. exact IHt.
    revert d.
    induction t.
    move => d.
    simpl. lia.
    move => d.
    simpl. exact (IHt (d + 1)).
    move => d.
    simpl. move => H.
    destruct H.
    split.
    exact (IHt1 d H).
    exact (IHt2 d H0).
    move => d.
    simpl. exact (IHt d).
Qed.

Lemma aux_2_1 : forall (t: DeBruijn), forall (n: nat), forall (d: nat),
    max_var_smaller_n_depth (Lambda t) n d <-> max_var_smaller_n_depth t (n + 1) d.
Proof.
    split.
    intros H.
    induction t.
    simpl. simpl in H.
    lia.
    simpl in H.
    simpl. apply -> aux_2_0. exact H.
    simpl. split.
    destruct H.
    apply aux_2_0. exact H.
    destruct H.
    apply aux_2_0. exact H0.
    simpl. apply IHt. simpl in H. simpl. exact H.
    move => H.
    induction t.
    simpl. unfold max_var_smaller_n_depth in H.
    lia.
    simpl. simpl in H. apply <- (aux_2_0 t n (d + 1)). exact H.
    simpl. destruct H.
    split.
    exact (IHt1 H).
    exact (IHt2 H0).
    simpl. simpl in H. simpl in IHt.
    exact (IHt H).
Qed.

Lemma aux_2_2 : forall (t: DeBruijn), forall (n: nat),
    C[n](Lambda t) -> C[n + 1](t).
Proof.
    intros t n H.
    simpl. apply aux_2_1. exact H.
Qed.

Lemma aux_3 : forall (t1: DeBruijn), forall (t2: DeBruijn), forall (n: nat),
    C[n](Application t1 t2) -> C[n](t1) /\ C[n](t2).
Proof.
    intros t1 t2 n H. 
    split. 
    unfold max_var_smaller_n. 
    unfold max_var_smaller_n in H.
    unfold max_var_smaller_n_depth in H.
    destruct H.
    fold max_var_smaller_n_depth in H.
    exact H.
    unfold max_var_smaller_n. 
    unfold max_var_smaller_n in H.
    unfold max_var_smaller_n_depth in H.
    destruct H.
    fold max_var_smaller_n_depth in H.
    exact H0.
Qed.

Lemma protect_aux_0 : forall (t: DeBruijn), forall (u: DeBruijn),
    t = u -> deprotect t = deprotect u.
Proof.
    intros t u H.
    rewrite H. reflexivity.
Qed.

Theorem substitution_aux : forall (t: DeBruijn), forall (n: nat), 
    C[n](t) -> forall (u: DeBruijn), t[n <- u] = deprotect t.
Proof.
    intro t. 
    induction t.
    simpl. intros n0 H u. 
    assert (forall (n: nat), deprotect (Var n) = Var n).
    simpl. reflexivity. rewrite <- H0. apply protect_aux_0.
    apply aux_0_1. exact H.
    simpl. intros n H u. apply aux_1_0. 
    apply IHt with (n := n + 1). apply aux_2_2 with (t := t) (n := n). exact H.
    intros n H u.
    simpl. apply aux_3 in H. 
    destruct H.
    rewrite IHt1. exact H.
    rewrite IHt2. exact H0.
    reflexivity.
    intros n H u. simpl. reflexivity.
Qed.

Theorem substitution_thm_general : forall (t: DeBruijn),
    closed t -> forall (u: DeBruijn), forall (n: nat), t[n <- u] = deprotect t.
Proof.
    intros t H u n.
    apply substitution_aux.
    apply closed_universal.
    trivial.
Qed.

Theorem substitution_thm : forall (t: DeBruijn),
    C(t) -> S(t) -> forall (u: DeBruijn), forall (n: nat), t[n <- u] = t.
Proof.
    intros t C S.
    assert (deprotect t = t).
    apply safe_deprotect. exact S.
    pattern (t) at 2. rewrite <- H.
    apply substitution_thm_general.
    exact C.
Qed.


Theorem raw_substitution_aux : forall (t: DeBruijn), forall (n: nat), 
    C[n](t) -> forall (u: DeBruijn), substitution t n u = t.
Proof.
    intro t. 
    induction t.
    simpl. intros n0 H u. 
    simpl. apply aux_0_1. exact H.

    move => n H u. simpl. apply aux_1_0. simpl.
    assert (C[n + 1](t)). apply aux_2_2. exact H. 
    apply (IHt (n + 1) H0 (correct_free_variable u)).
    move => n H u. simpl. apply aux_3 in H.
    destruct H.
    rewrite (IHt1 n H u).
    rewrite (IHt2 n H0 u).
    reflexivity.
    move => n C u.
    simpl. reflexivity.
Qed.

Theorem raw_substitution_thm_general : forall (t: DeBruijn),
    closed t -> forall (u: DeBruijn), forall (n: nat), substitution t n u = t.
Proof.
    intros t H u n.
    apply raw_substitution_aux.
    apply closed_universal.
    trivial.
Qed.

Lemma partial_safeness_passes : forall (t: DeBruijn), forall (n: nat),
    S[n](t) <-> S[n](Lambda t)
.
Proof.
    induction t.
    move => n0.
    simpl. intuition.
    move => n.
    apply (IHt n).
    move => n.
    simpl. intuition.
    intuition.
Qed.

Lemma contains_geq_n_heredite_1 : forall (t: DeBruijn), forall (n: nat),
    ~ (contains_geq_n t n) -> ~ (contains_geq_n t (n + 1))
.
Proof.
    induction t.
    move => n0.
    simpl. lia.
    move => n.
    simpl. exact (IHt (n + 1)).
    simpl.
    move => n H.
    apply destruct_false_or.
    apply destruct_false_or in H. destruct H.
    split. apply (IHt1 n H).
    apply (IHt2 n H0).
    simpl. trivial.
Qed.

Lemma partial_safeness_heredite_1 : forall (t: DeBruijn), forall (n: nat),
    S[n](t) -> S[n + 1](t)
.
Proof.
    induction t.
    move => n0.
    simpl. intuition.
    move => n.
    simpl. apply (IHt n).
    move => n.
    simpl. intro.
    apply destruct_false_or. apply destruct_false_or in H.
    destruct H.
    split. exact (IHt1 n H).
    exact (IHt2 n H0).
    move => n.
    simpl. exact (contains_geq_n_heredite_1 t n).
Qed.

Lemma partial_safeness_application : forall (tp1: DeBruijn), forall (tp2: DeBruijn),
    forall (n: nat),
    S[n](Application tp1 tp2) -> (S[n](tp1)) /\ (S[n](tp2))
.
Proof.
    move => tp1 tp2 n H.
    simpl in H. apply destruct_false_or in H.
    destruct H.
    split.
    exact H. exact H0.
Qed.

Lemma not_contains_geq_n_Cn : forall (t: DeBruijn), forall (n: nat),
    ~ (contains_geq_n t n) -> C[n](t)
.
Proof.
    induction t.
    move => n0.
    simpl. unfold max_var_smaller_n. simpl. lia.
    move => n.
    simpl. move => H. unfold max_var_smaller_n. simpl. unfold max_var_smaller_n in IHt.
    assert (max_var_smaller_n_depth t (n + 1) 0).
    apply (IHt (n + 1) H).
    apply <- (aux_2_0 t n 0). exact H0.
    simpl. move => n H.
    apply destruct_false_or in H.
    unfold max_var_smaller_n.
    destruct H.
    split.
    exact (IHt1 n H).
    exact (IHt2 n H0).
    move => n.
    simpl.
    unfold max_var_smaller_n. simpl. exact (IHt n).
Qed.

Lemma not_contains_geq_n_Cn_reversed : forall (t: DeBruijn), forall (n: nat),
    C[n](t) -> ~ (contains_geq_n t n)
.
Proof.
    induction t.
    move => n0 H.
    simpl.
    assert (n0 > n). apply aux_0. exact H.
    lia.
    move => n H.
    simpl.
    assert (C[n + 1](t)). apply aux_2_1. exact H.
    exact (IHt (n + 1) H0).
    move => n C.
    destruct C.
    apply destruct_false_or.
    split. 1-2:fold contains_geq_n.
    exact (IHt1 n H).
    exact (IHt2 n H0).
    simpl.
    trivial.
Qed.

Lemma not_contains_Cn : forall (t: DeBruijn), forall (n: nat),
    C[n](t) <-> ~ (contains_geq_n t n)
.
Proof.
    move => t n.
    split.
    move => C.
    apply not_contains_geq_n_Cn_reversed. exact C.
    move => S.
    apply not_contains_geq_n_Cn. exact S.
Qed.

Lemma partial_safety_protect_C : forall (t: DeBruijn), (forall (n: nat),
    S[n](Protect t) <-> C[n](t))
.
Proof.
    split.
    move => Sn.
    induction t.
    unfold max_var_smaller_n. simpl. 
    unfold protected_n in Sn.
    unfold contains_geq_n in Sn. lia.
    simpl in Sn.
    assert (~(contains_geq_n (Lambda t) n)).
    simpl. exact Sn.
    apply not_contains_geq_n_Cn. exact H.
    simpl. simpl in Sn. apply destruct_false_or in Sn. destruct Sn.
    split.
    apply (IHt1 H).
    apply (IHt2 H0).
    unfold max_var_smaller_n. simpl. simpl in IHt.
    simpl in Sn. exact (IHt Sn). 
    
    move => C.
    unfold protected_n.
    apply not_contains_Cn. exact C. 
Qed.

Lemma stupid_0 : forall (n: nat), forall (n0: nat),
    (n =? n0) = true <-> n = n0.
Proof.
    intros n n0.
    admit.
Admitted.

Lemma partial__protect_identity_aux : forall (t: DeBruijn), forall (n: nat), forall (u: DeBruijn),
    C[n](t) -> (deprotect t)[n <- u] = deprotect t
.
Proof.
    induction t.
    revert n.
    simpl.
    move => n n0 u Cn0.
    case_eq (n =? n0).
    move => H.
    assert (n < n0). apply aux_0.
    exact Cn0.
    assert (n = n0). apply stupid_0. exact H.
    assert (~(n = n0)). lia. contradiction.
    move => H. simpl. reflexivity.
    move => n u Cn.
    simpl. apply aux_1_0.
    apply (IHt (n + 1) (correct_free_variable u)).
    apply aux_2_1. exact Cn.
    move => n u Cn.
    destruct Cn.
    simpl. apply aux_1_1.
    exact (IHt1 n u H).
    exact (IHt2 n u H0).
    simpl. assumption.
Qed.
    
Theorem partial_protect_identity : forall (t: DeBruijn),
    forall (n: nat), forall (u: DeBruijn),
    S[n](t) -> t[n <- u] = (deprotect t)[n <- u]
.
Proof.
    induction t.
    move => n0 u Sn0.
    simpl. reflexivity.
    move => n u Sn.
    simpl. assert (S[n](t)). apply partial_safeness_passes. exact Sn.
    apply aux_1_0. rewrite (IHt (n + 1) (correct_free_variable u)).
    exact (partial_safeness_heredite_1 t n H).
    reflexivity.
    move => n u.
    move => Sn.
    simpl. assert (S[n](t1) /\ S[n](t2)). apply partial_safeness_application. exact Sn.
    apply aux_1_1. 
    destruct H.
    exact (IHt1 n u H).
    destruct H.
    exact (IHt2 n u H0).
    move => n u Sn.
    simpl. assert (C[n](t)). apply partial_safety_protect_C.
    exact Sn.
    assert (deprotect t = (deprotect t) [n <- u] <-> (deprotect t)[n <- u] = (deprotect t)).
    intuition. apply H0. apply partial__protect_identity_aux.
    exact H.
Qed.   

(* Question 4 *)

Fixpoint substitution_multiple_aux (t: DeBruijn) (offset: nat) (u: list DeBruijn) : DeBruijn :=
    match u with
    | [] => t
    | hd :: tl => 
    substitution (substitution_multiple_aux t (offset + 1) tl) (offset) hd
    end
.

Definition substitution_multiple (t: DeBruijn) (base: nat) (u: list DeBruijn) :=
    substitution_multiple_aux t base u.

Notation "t [ n <-- l ]" := (deprotect (substitution_multiple t n l)) (at level 0).

Theorem substitution_multiple_nil : forall (t: DeBruijn), forall (n: nat),
    S(t) -> t[n <-- []] = t.
Proof.
    intros t n H.
    unfold substitution_multiple.
    unfold substitution_multiple_aux.
    apply safe_deprotect. exact H.
Qed.

Lemma substitution_multiple_one_step : forall (t: DeBruijn), forall (n: nat), 
    forall (u: DeBruijn), forall (terms: list DeBruijn),
    S(t) -> substitution_multiple t n (u :: terms) = 
        substitution (substitution_multiple t (n + 1) terms) n u.
Proof.
    intros t n u terms H .
    induction terms.
    unfold substitution_multiple.
    unfold substitution_multiple_aux.
    reflexivity.
    unfold substitution_multiple.
    unfold substitution_multiple_aux. simpl.
    assert (n + 1 + 1 = n + 2). lia. rewrite H0. reflexivity.
Qed.

Theorem substitution_multiple_C_0 : forall (t: DeBruijn), forall (n: nat),
    C[n](t) -> S(t) -> forall (u: list DeBruijn), forall (m: nat),
    m >= n -> substitution_multiple t m u = t.
Proof.
    move => t n C S.
    induction u.
    unfold substitution_multiple.
    move => m cmp.
    unfold substitution_multiple_aux. reflexivity.

    move => m cmp.
    rewrite (substitution_multiple_one_step t m a u S).

    assert (m + 1 >= n). lia.
    rewrite (IHu (m + 1) H).

    apply raw_substitution_aux. apply (heredite_3 t n m). lia. exact C.
Qed.

Theorem substitution_multiple_C_thm : forall (t: DeBruijn), forall (n: nat),
    C[n](t) -> S(t) -> forall (u: list DeBruijn), t[n <-- u] = t.
Proof.
    move => t n C S u.
    assert (n >= n). lia.
    rewrite (substitution_multiple_C_0 t n C S u n H). 
    apply safe_deprotect. exact S.
Qed.

Fixpoint C_multiple (u: list DeBruijn) (n: nat) : Prop :=
    match u with
    | [] => True
    | hd :: tl => (C[n](hd)) /\ (C_multiple tl n)
    end
.

Notation "Cm[ n ]( u )" := (C_multiple (List.tl u) n).

Lemma sub_preserves_equality : forall (t: DeBruijn), forall (u: DeBruijn), 
    forall (n: nat), forall (v: DeBruijn),
    t = u -> t[n <- v] = u[n <- v].
Proof.
    move => t u n v E.
    rewrite E.
    reflexivity.
Qed.




Lemma substitute_equal : forall (t: DeBruijn), forall (n: nat),
    S(t) -> t[n <- Var n] = t.
Proof.
    move => t.
    induction t.
    move => n0.
    move => S.
    simpl.
    case_eq (n =? n0).
    move => egalite.
    apply stupid_0 in egalite.
    rewrite <- egalite. simpl. reflexivity.
    intro H. simpl. reflexivity.  

    move => n S. assert (correct_free_variable (Var n) = Var (n + 1)).
    unfold correct_free_variable. simpl. reflexivity. simpl. rewrite H.
    rewrite (IHt (n + 1)). exact S. reflexivity.
    move => n S.
    simpl. rewrite IHt1. 
    simpl in S. apply destruct_false_or in S.
    destruct S. exact H.
    simpl. rewrite IHt2.
    simpl in S. apply destruct_false_or in S.
    destruct S. exact H0. reflexivity.
    move => n. unfold protected.
    contradiction.
Qed.

Lemma cm_add : forall (u: list DeBruijn), forall (n: nat), forall (a: DeBruijn),
    Cm[n](a::u) -> C_multiple u n.
Proof.
    move => u n a Cm.
    unfold C_multiple in Cm.
    unfold C_multiple.
    trivial.
Qed.

Lemma cm_completion : forall(u : list DeBruijn), forall(a: DeBruijn), forall (n: nat),
    Cm[n](u) -> C[n](List.hd (Var 0) u) -> Cm[n](a :: u).
Proof.
    move => u a n Cm C.
    induction u.
    trivial.
    simpl.
    split.
    simpl in C. exact C.
    apply (cm_add u n a0).
    exact Cm.
Qed.

Lemma list_prop_completion : forall (t: list DeBruijn), forall (a: DeBruijn),
    forall (f: DeBruijn -> Prop),
    (List.Forall f t) -> f a -> (List.Forall f (a :: t)).
Proof.
    move => t a f.
    intuition.
Qed.

Lemma cm_conversion : forall (u: list DeBruijn), forall(n: nat),
    C_multiple u n -> Cm[n](u).
Proof.
    move => u n.
    induction u.
    simpl. trivial.
    simpl. intuition.
Qed.

Lemma cm_truc : forall (u: list DeBruijn), forall (a: DeBruijn), forall (b: DeBruijn),
    forall (n: nat),
    Cm[n](a :: b :: u) -> C[n](b).
Proof.
    intros u a b n H.
    unfold C_multiple in H. simpl in H.
    destruct H.
    exact H.
Qed.

Lemma cm_truc_2 : forall (u: list DeBruijn), forall (a: DeBruijn), forall (b: DeBruijn),
    forall (n: nat),
    Cm[n](a :: b :: u) -> Cm[n](u).
Proof.
    intros u a  b n H.
    unfold C_multiple in H. simpl in H.
    destruct H. apply (cm_conversion u n).
    fold C_multiple in H0.
    exact H0.
Qed.

Lemma cm_truc_3 : forall (u: list DeBruijn), forall (a: DeBruijn), forall (n: nat),
    Cm[n](a :: u) -> Cm[n](u).
Proof.
    induction u.
    simpl. intuition.
    move => a0 n.
    simpl. intuition.
Qed.

Lemma cm_truc_4 : forall(u : DeBruijn), forall (a: DeBruijn), forall (terms: list DeBruijn),
    forall (n: nat),
    Cm[n](u :: a :: terms) -> Cm[n](u :: terms).
Proof.
    intros u a terms n H.
    assert (C_multiple (a :: terms) n). intuition.
    assert (Cm[n](a :: terms)). apply cm_conversion. exact H0.
    assert (C_multiple terms n). intuition.
    intuition.
Qed.

Lemma cm_meaning : forall (u: list DeBruijn), forall (n: nat),
    Cm[n](u) -> List.Forall (fun x => C[n](x)) (List.tl u).
Proof.
    move => u n Cm.
    induction u. simpl.
    intuition.
    
    simpl.
    induction u. intuition. 
    apply (list_prop_completion u a0 (max_var_smaller_n^~ n)).
    assert (Cm[n](u)). apply (cm_truc_2 u a a0 n). exact Cm.
    assert C[n](a0). apply (cm_truc u a a0 n). exact Cm.
    assert (Cm[n](a0::u)). apply (cm_truc_3 (a0::u) a n). exact Cm.
    apply IHu. exact H1. apply (cm_truc u a a0). exact Cm.
Qed.

Lemma heredite_var : forall (n: nat), forall (n0: nat),
    C[n](Var n0) -> C[n + 1](Var (n0 + 1)).
Proof.
    move => n n0.
    unfold max_var_smaller_n.
    simpl. lia.
Qed.

Lemma stupid_1 : forall(n0: nat),
    (0 <=? n0) = false -> False.
Proof.
    simpl. intuition.
Qed.

Lemma heredite_correct_variable_aux : forall (t: DeBruijn), forall (n: nat),
    forall (d: nat), forall (dp: nat),
    max_var_smaller_n_depth t n d -> 
        max_var_smaller_n_depth (correct_free_variable_depth t dp) (n + 1) d.
Proof.
    induction t.
    simpl.
    move => n0 d dp.
    move => cond.
    simpl.
    case_eq (dp <=? n).
    move => Cond.
    simpl. lia.
    move => Cond.
    simpl. lia.

    move => n d dp.
    unfold max_var_smaller_n. simpl.
    unfold max_var_smaller_n in IHt. simpl in IHt.
    unfold correct_free_variable in IHt.
    exact (IHt n (d + 1) (dp + 1)).

    move => n d dp.
    unfold max_var_smaller_n. simpl.
    split. 
    apply (IHt1 n d dp).
    destruct H.
    exact H.

    apply (IHt2 n d dp).
    destruct H.
    exact H0.

    move => n d dp.
    unfold max_var_smaller_n. simpl.
    exact (IHt n d dp).
Qed.

Lemma heredite_correct_variable : forall (t: DeBruijn), forall (n: nat),
    C[n](t) -> C[n + 1](correct_free_variable t).
Proof.
    move => t n Cn.
    apply heredite_correct_variable_aux.
    exact Cn.
Qed.


Lemma substitution_multiple_commut : forall (t: DeBruijn), forall (n: nat), forall (u1: DeBruijn), 
    forall (u2 : DeBruijn),
    S(t) -> C[n](u2) -> t[n <-- u1 :: u2 :: []] = t[n+1 <- u2][n <- u1].
Proof.
    simpl.
    induction t.
    revert n.
    simpl.
    move => n0 n u1 u2 S C2.
    case_eq (n0 =? n + 1).
    move => egalite.
    apply stupid_0 in egalite.
    simpl. assert (S(deprotect u2)). apply deprotect_correction.
    assert (C[n](deprotect u2)). apply (C_deprotect u2 n). exact C2.
    assert ((deprotect u2)[n <- u1] = deprotect (deprotect u2)).
    apply (substitution_aux (deprotect u2) n H0 u1).
    rewrite -> deprotect_involutive in H1.
    intuition.
    simpl. intro H. reflexivity.
    move => n u1 u2 S C. assert (S(t)). intuition.
    assert (C[n + 1](u2)). apply (heredite_1 u2 n C). simpl.
    apply aux_1_0. (* assert (n + 1 + 1 = n + 2). lia. rewrite H1. *) 
    assert (C[n + 1](correct_free_variable u2)). apply (heredite_correct_variable u2 n C).
    rewrite (IHt (n + 1) (correct_free_variable u1) (correct_free_variable u2) H H1). reflexivity.
    move => n u1 u2 S C2.
    simpl. apply aux_1_1.
    assert (S(t1)). unfold protected in S. intuition.
    apply (IHt1 n u1 u2 H C2).
    assert (S(t2)). unfold protected in S. intuition.
    apply (IHt2 n u1 u2 H C2).
    move => n u1 u2 S C2.
    simpl. contradiction S. simpl. trivial.
Qed.

Lemma substitution_multiple_commut_weak : forall (t: DeBruijn), forall (n: nat), forall (u1: DeBruijn), 
    forall (u2 : DeBruijn), forall (terms: list DeBruijn),
    S[n](t) -> C[n](u2) -> Cm[n](terms) ->
    t[n <-- u1 :: u2 :: []] = 
    t[n+1 <- u2][n <- u1].
Proof.
    simpl.
    induction t.
    revert n.
    move => n n0 u1 u2 terms S C Cm.
    case_eq (n =? n0).
    move => H.
    assert (n = n0). apply stupid_0. exact H.
    apply sub_preserves_equality.
Admitted.

(*
H1: (Var n0) [n <-- u :: a :: []] = ((Var n0) [n + 1 <-- a :: []]) [n <- u]
H2: (Var n0) [n <-- u :: terms] = ((Var n0) [n + 1 <-- terms]) [n <- u]
1/4
(Var n0) [n <-- u :: a :: terms] = ((Var n0) [n + 1 <-- a :: terms]) [n <- u]
*)

Lemma heredite_substitution_mutiple : forall (t: DeBruijn), forall (u: DeBruijn), forall (a: DeBruijn),
    forall (terms: list DeBruijn), forall (n: nat),
    S(t) -> Cm[n](u :: a :: terms) -> Cm[n](u :: terms) ->
    (forall (t0: DeBruijn), S(t0) -> C[n](a) -> t0[n <-- u :: a :: []] = (t0[n + 1 <-- a :: []])[n <- u]) ->
    t[n <-- u :: terms] = (t[n + 1 <-- terms])[n <- u] ->
    t[n <-- u :: a :: terms] = (t[n + 1 <-- a :: terms])[n <- u].
Proof.
    move => t u a terms n0 S Cm1 Cm2 H1 H2.
    simpl. 
    simpl in H2. apply sub_preserves_equality.
    
    unfold substitution_multiple in H2.
    simpl in H1.
    (* En fait... On n'a pas la safety du terme :( bah ouais, c'est une substitution_multiple,
    donc clairement il a potentiellement plein d'endroits protégés.
    Mais mais mais... La propriété S(t) pour substitution_multiple_commut est un
    tout petit peu trop forte: (substitution_multiple t (n + 1) terms) marcherait,
    pour peu que C[n](terms)... Pénible à faire! *)
    admit.
Admitted.

Lemma protected_protected_n : forall (t: DeBruijn),
    S(t) -> forall (n: nat), S[n](t)
.
Proof.
    induction t.
    move => S n0.
    unfold protected_n.
    intuition.
    simpl.
    assumption.
    simpl.
    move => H. apply destruct_false_or in H. destruct H.
    move => n.
    apply destruct_false_or. split.
    exact (IHt1 H n).
    exact (IHt2 H0 n).
    simpl. intuition.
Qed.

Lemma Sn_heredite_substitution : forall (t: DeBruijn), forall (a: DeBruijn), forall (n: nat),
    S[n](t) -> C[n](a) -> (forall (m: nat), S[n](substitution t m a))
.
Proof.
    induction t.
    move => a n0 Sn0 Cn0 m.
    simpl. case_eq (n =? m).
    move => H. apply stupid_0 in H.
    simpl.
    apply partial_safety_protect_C. exact Cn0.
    move => H. exact Sn0.
    move => a n Sn Cn m.
    simpl. (*exact (IHt (correct_free_variable a) n Sn Cn (m + 1)).*)
    admit.
    move => a n Sn Cn m.
    simpl.
    apply destruct_false_or.
    simpl in Sn. apply destruct_false_or in Sn.
    destruct Sn.
    split.
    exact (IHt1 a n H Cn m).
    exact (IHt2 a n H0 Cn m).
    move => a n Sn Cn m.
    simpl. simpl in Sn. exact Sn.
Admitted.
(*
induction t.
    move => a n0 Sn0 Cn0 m.
    simpl. case_eq (n =? m).
    move => H. apply stupid_0 in H.
    simpl.
    induction a.
    simpl. assert (n0 > n1). apply aux_0. exact Cn0. lia.
    
*)

Lemma petit_lemme_final : forall (t: DeBruijn),  forall (terms: list DeBruijn),
    S(t) -> (forall (n: nat), C_multiple terms n -> 
    (forall (m: nat), S[n](substitution_multiple t m terms)))
.
Proof.
    induction terms.
    move => S n H m. apply (protected_protected_n t S n).
    simpl. move => S n H m.
    destruct H. apply (Sn_heredite_substitution 
        (substitution_multiple t (m + 1) terms) a 
    ). exact (IHterms S n H0 (m + 1)). exact H.
Qed.


Theorem substitution_multiple_C_2 : forall (t: DeBruijn), forall (n: nat), forall (u: DeBruijn),
    forall (terms: list DeBruijn),
    S(t) -> Cm[n](u :: terms) -> t[n <-- u :: terms] = 
        (t[n+1 <--terms])[n <- u].
Proof.
    induction terms.
    revert n.
    move => n S Cm.
    simpl. rewrite (safe_deprotect t S). reflexivity.

    
    assert (forall (t0: DeBruijn), S(t0) -> C[n](a) -> t0[n <-- u :: a :: []] = (t0[n + 1 <-- a :: []])[n <- u]).
    intros t0 H H0. apply substitution_multiple_commut. exact H. exact H0.
    move => S Cm.
    assert (Cm[n](u :: terms)). apply (cm_truc_4 u a terms n Cm).
    apply partial_protect_identity.
    assert (C_multiple (a :: terms) n). apply (cm_add (a:: terms) n u Cm). 
    apply (petit_lemme_final t (a::terms) S n H1).
Qed.

(*
partial_protect_identity : forall (t: DeBruijn),
    forall (n: nat), forall (u: DeBruijn),
    S[n](t) -> t[n <- u] = (deprotect t)[n <- u]
*)
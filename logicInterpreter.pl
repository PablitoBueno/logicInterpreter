% ================================================================
% PROPOSITIONAL LOGIC META-INTERPRETER (FIXED)
% + Logical simplifier (fully functional)
% ================================================================

% -----------------------------------------------------------------
% Extract variables
% -----------------------------------------------------------------
variables(Atom, [Atom]) :- atom(Atom), !.
variables(neg(F), Vars) :- variables(F, Vars).
variables(and(F1, F2), Vars) :-
    variables(F1, V1), variables(F2, V2), append(V1, V2, Vars).
variables(or(F1, F2), Vars) :-
    variables(F1, V1), variables(F2, V2), append(V1, V2, Vars).
variables(impl(F1, F2), Vars) :-
    variables(F1, V1), variables(F2, V2), append(V1, V2, Vars).
variables(iff(F1, F2), Vars) :-
    variables(F1, V1), variables(F2, V2), append(V1, V2, Vars).

unique_vars(F, Unique) :-
    variables(F, Vars),
    sort(Vars, Unique).

% -----------------------------------------------------------------
% Generate all truth assignments (using findall for robustness)
% -----------------------------------------------------------------
generate_rows(Vars, Rows) :-
    findall(Row, assignment(Vars, Row), Rows).

assignment([], []).
assignment([V|Vs], [[V,Val]|Rest]) :-
    member(Val, [true, false]),
    assignment(Vs, Rest).

% -----------------------------------------------------------------
% Evaluate formula under an environment
% -----------------------------------------------------------------
evaluate(Atom, Env, Val) :-
    member([Atom, Val], Env), !.

evaluate(neg(F), Env, true) :- evaluate(F, Env, false).
evaluate(neg(F), Env, false) :- evaluate(F, Env, true).

evaluate(and(F1, F2), Env, true) :-
    evaluate(F1, Env, true), evaluate(F2, Env, true).
evaluate(and(F1, F2), Env, false) :-
    ( evaluate(F1, Env, false) ; evaluate(F2, Env, false) ).

evaluate(or(F1, F2), Env, true) :-
    ( evaluate(F1, Env, true) ; evaluate(F2, Env, true) ).
evaluate(or(F1, F2), Env, false) :-
    evaluate(F1, Env, false), evaluate(F2, Env, false).

evaluate(impl(F1, F2), Env, true) :-
    ( evaluate(F1, Env, false) ; evaluate(F2, Env, true) ).
evaluate(impl(F1, F2), Env, false) :-
    evaluate(F1, Env, true), evaluate(F2, Env, false).

evaluate(iff(F1, F2), Env, true) :-
    evaluate(F1, Env, V1), evaluate(F2, Env, V2), V1 == V2.
evaluate(iff(F1, F2), Env, false) :-
    evaluate(F1, Env, V1), evaluate(F2, Env, V2), V1 \= V2.

% -----------------------------------------------------------------
% Build truth table
% -----------------------------------------------------------------
truth_table(Formula, Table) :-
    unique_vars(Formula, Vars),
    generate_rows(Vars, Rows),
    maplist(build_row(Formula), Rows, Table).

build_row(Formula, Env, RowWithResult) :-
    evaluate(Formula, Env, Result),
    append(Env, [[result, Result]], RowWithResult).

% -----------------------------------------------------------------
% Classify
% -----------------------------------------------------------------
classify(Formula, Class, Table) :-
    truth_table(Formula, Table),
    maplist(extract_result, Table, Results),
    ( all_true(Results) -> Class = tautology
    ; all_false(Results) -> Class = contradiction
    ; Class = contingency
    ).

extract_result(Row, Val) :- member([result, Val], Row).

all_true([]).
all_true([true|Rest]) :- all_true(Rest).

all_false([]).
all_false([false|Rest]) :- all_false(Rest).

% -----------------------------------------------------------------
% Pretty printer (full table)
% -----------------------------------------------------------------
print_table(Formula) :-
    truth_table(Formula, Table),
    unique_vars(Formula, Vars),
    format('~nTruth Table for:~n~p~n~n', [Formula]),
    maplist(print_var, Vars),
    format(' | Result~n'),
    forall(member(Row, Table), (
        maplist(print_val(Vars), Row),
        nl
    )).

print_var(V) :- format('~w\t', [V]).
print_val(Vars, [Var, Val]) :-
    member(Var, Vars), !,
    format('~w\t', [Val]).
print_val(_, [result, Val]) :-
    format('~w', [Val]).

% ================================================================
% LOGICAL SIMPLIFIER (CORRIGIDO – BOTTOM-UP)
% ================================================================

% simplify/2: simplifica completamente uma fórmula
simplify(true, true).
simplify(false, false).
simplify(Atom, Atom) :-
    atom(Atom),
    Atom \= true,
    Atom \= false.

simplify(neg(F), S) :-
    simplify(F, SF),
    simplify_neg(SF, S).

simplify(and(F1, F2), S) :-
    simplify(F1, S1),
    simplify(F2, S2),
    simplify_and(S1, S2, S).

simplify(or(F1, F2), S) :-
    simplify(F1, S1),
    simplify(F2, S2),
    simplify_or(S1, S2, S).

simplify(impl(F1, F2), S) :-
    simplify(or(neg(F1), F2), S).

simplify(iff(F1, F2), S) :-
    simplify(and(impl(F1, F2), impl(F2, F1)), S).

% --- Regras para negação após simplificar o argumento ---
simplify_neg(true, false).
simplify_neg(false, true).
simplify_neg(neg(X), X).                         % dupla negação
simplify_neg(and(A, B), S) :-                    % De Morgan
    simplify(or(neg(A), neg(B)), S).
simplify_neg(or(A, B), S) :-                     % De Morgan
    simplify(and(neg(A), neg(B)), S).
simplify_neg(X, neg(X)).                         % caso geral (átomo, etc.)

% --- Regras para conjunção após simplificar os argumentos ---
simplify_and(true, F, Result) :-
    !,
    simplify_and_true(F, Result).
simplify_and(F, true, Result) :-
    !,
    simplify_and_true(F, Result).
simplify_and(false, _, false) :- !.
simplify_and(_, false, false) :- !.
simplify_and(F, F, F) :- !.
simplify_and(F1, F2, and(F1, F2)).

simplify_and_true(true, true).
simplify_and_true(false, false).
simplify_and_true(F, F) :-
    F \= true,
    F \= false.

% --- Regras para disjunção após simplificar os argumentos ---
simplify_or(false, F, Result) :-
    !,
    simplify_or_false(F, Result).
simplify_or(F, false, Result) :-
    !,
    simplify_or_false(F, Result).
simplify_or(true, _, true) :- !.
simplify_or(_, true, true) :- !.
simplify_or(F, F, F) :- !.
simplify_or(F1, F2, or(F1, F2)).

simplify_or_false(true, true).
simplify_or_false(false, false).
simplify_or_false(F, F) :-
    F \= true,
    F \= false.

% -----------------------------------------------------------------
% Predicados auxiliares que já existiam (permanecem funcionais)
% -----------------------------------------------------------------
simplify_and_print(F) :-
    simplify(F, S),
    format('Original:   ~p~n', [F]),
    format('Simplified: ~p~n', [S]).

equivalent(F1, F2) :-
    unique_vars(and(F1, F2), Vars),
    generate_rows(Vars, Rows),
    forall(
        member(Env, Rows),
        (
            evaluate(F1, Env, V1),
            evaluate(F2, Env, V2),
            V1 == V2
        )
    ).

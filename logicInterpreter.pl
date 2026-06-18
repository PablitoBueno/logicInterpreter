% ================================================================
% PROPOSITIONAL LOGIC META-INTERPRETER (FIXED)
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
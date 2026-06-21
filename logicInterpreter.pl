% ================================================================
% PROPOSITIONAL LOGIC META-INTERPRETER (SIMPLIFIED)
% ================================================================

% ---- SYNTAX VALIDATION ----

valid(Formula) :- is_valid(Formula).

is_valid(true) :- !.
is_valid(false) :- !.
is_valid(Atom) :- atom(Atom), Atom \= true, Atom \= false, !.
is_valid(neg(F)) :- is_valid(F), !.
is_valid(and(F1,F2)) :- is_valid(F1), is_valid(F2), !.
is_valid(or(F1,F2))  :- is_valid(F1), is_valid(F2), !.
is_valid(impl(F1,F2)):- is_valid(F1), is_valid(F2), !.
is_valid(iff(F1,F2)) :- is_valid(F1), is_valid(F2), !.

detail(F) :-
    format('~n~p~n', [F]),
    ( is_valid(F) -> format('  Valid~n') ; format('  Invalid~n'), fail ),
    op_count(F, N), depth(F, D), vars(F, V),
    format('  Ops: ~w, Depth: ~w, Vars: ~p~n', [N,D,V]).

op_count(Atom,0) :- atom(Atom), !.
op_count(neg(F),N) :- op_count(F,N1), N is N1+1.
op_count(and(F1,F2),N) :- op_count(F1,N1), op_count(F2,N2), N is N1+N2+1.
op_count(or(F1,F2),N)  :- op_count(F1,N1), op_count(F2,N2), N is N1+N2+1.
op_count(impl(F1,F2),N):- op_count(F1,N1), op_count(F2,N2), N is N1+N2+1.
op_count(iff(F1,F2),N) :- op_count(F1,N1), op_count(F2,N2), N is N1+N2+1.

depth(Atom,1) :- atom(Atom), !.
depth(neg(F),D) :- depth(F,D1), D is D1+1.
depth(and(F1,F2),D) :- depth(F1,D1), depth(F2,D2), D is max(D1,D2)+1.
depth(or(F1,F2),D)  :- depth(F1,D1), depth(F2,D2), D is max(D1,D2)+1.
depth(impl(F1,F2),D):- depth(F1,D1), depth(F2,D2), D is max(D1,D2)+1.
depth(iff(F1,F2),D) :- depth(F1,D1), depth(F2,D2), D is max(D1,D2)+1.

% ---- VARIABLES ----

vars(F, V) :- variables(F, V1), sort(V1, V).

variables(Atom,[Atom]) :- atom(Atom), !.
variables(neg(F),V) :- variables(F,V).
variables(and(F1,F2),V) :- variables(F1,V1), variables(F2,V2), append(V1,V2,V).
variables(or(F1,F2),V)  :- variables(F1,V1), variables(F2,V2), append(V1,V2,V).
variables(impl(F1,F2),V):- variables(F1,V1), variables(F2,V2), append(V1,V2,V).
variables(iff(F1,F2),V) :- variables(F1,V1), variables(F2,V2), append(V1,V2,V).

% ---- TRUTH TABLE ----

rows(Vars, Rows) :- findall(R, assignment(Vars,R), Rows).
assignment([],[]).
assignment([V|Vs],[[V,Val]|Rest]) :- member(Val,[true,false]), assignment(Vs,Rest).

evaluate(Atom, Env, Val) :- member([Atom,Val], Env), !.
evaluate(neg(F), Env, true) :- evaluate(F,Env,false).
evaluate(neg(F), Env, false) :- evaluate(F,Env,true).
evaluate(and(F1,F2), Env, true) :- evaluate(F1,Env,true), evaluate(F2,Env,true).
evaluate(and(F1,F2), Env, false) :- (evaluate(F1,Env,false); evaluate(F2,Env,false)).
evaluate(or(F1,F2), Env, true) :- (evaluate(F1,Env,true); evaluate(F2,Env,true)).
evaluate(or(F1,F2), Env, false) :- evaluate(F1,Env,false), evaluate(F2,Env,false).
evaluate(impl(F1,F2), Env, true) :- (evaluate(F1,Env,false); evaluate(F2,Env,true)).
evaluate(impl(F1,F2), Env, false) :- evaluate(F1,Env,true), evaluate(F2,Env,false).
evaluate(iff(F1,F2), Env, true) :- evaluate(F1,Env,V1), evaluate(F2,Env,V2), V1==V2.
evaluate(iff(F1,F2), Env, false) :- evaluate(F1,Env,V1), evaluate(F2,Env,V2), V1\=V2.

table(F, Table) :-
    vars(F, Vars),
    rows(Vars, Rows),
    maplist(build_row(F), Rows, Table).

build_row(F, Env, Row) :-
    evaluate(F, Env, Result),
    append(Env, [[result,Result]], Row).

show(F) :-
    table(F, Table),
    vars(F, Vars),
    format('~n~p~n', [F]),
    maplist(format('~w\t'), Vars), format('Result~n'),
    forall(member(Row, Table),
           (maplist(print_val(Vars), Row), nl)).

print_val(Vars, [Var,Val]) :-
    member(Var, Vars), !, format('~w\t', [Val]).
print_val(_, [result,Val]) :- format('~w', [Val]).

% ---- CLASSIFICATION ----

classify(F, Class, Table) :-
    table(F, Table),
    maplist(extract_result, Table, Results),
    ( all_true(Results) -> Class = tautology
    ; all_false(Results) -> Class = contradiction
    ; Class = contingency ).

extract_result(Row, Val) :- member([result,Val], Row).
all_true([]).
all_true([true|T]) :- all_true(T).
all_false([]).
all_false([false|T]) :- all_false(T).

% ---- SIMPLIFICATION ----

simp(true, true).
simp(false, false).
simp(Atom, Atom) :- atom(Atom), Atom \= true, Atom \= false.
simp(neg(F), S) :- simp(F, SF), simp_neg(SF, S).
simp(and(F1,F2), S) :- simp(F1,S1), simp(F2,S2), simp_and(S1,S2,S).
simp(or(F1,F2), S)  :- simp(F1,S1), simp(F2,S2), simp_or(S1,S2,S).
simp(impl(F1,F2), S) :- simp(or(neg(F1), F2), S).
simp(iff(F1,F2), S) :- simp(and(impl(F1,F2), impl(F2,F1)), S).

simp_neg(true, false).
simp_neg(false, true).
simp_neg(neg(X), X).
simp_neg(and(A,B), S) :- simp(or(neg(A), neg(B)), S).
simp_neg(or(A,B), S)  :- simp(and(neg(A), neg(B)), S).
simp_neg(X, neg(X)).

simp_and(true, F, R) :- !, simp_and_true(F, R).
simp_and(F, true, R) :- !, simp_and_true(F, R).
simp_and(false, _, false) :- !.
simp_and(_, false, false) :- !.
simp_and(F, F, F) :- !.
simp_and(F1, F2, and(F1,F2)).

simp_and_true(true, true).
simp_and_true(false, false).
simp_and_true(F, F) :- F \= true, F \= false.

simp_or(false, F, R) :- !, simp_or_false(F, R).
simp_or(F, false, R) :- !, simp_or_false(F, R).
simp_or(true, _, true) :- !.
simp_or(_, true, true) :- !.
simp_or(F, F, F) :- !.
simp_or(F1, F2, or(F1,F2)).

simp_or_false(true, true).
simp_or_false(false, false).
simp_or_false(F, F) :- F \= true, F \= false.

simp_print(F) :- simp(F,S), format('~p  ->  ~p~n', [F,S]).

equiv(F1,F2) :-
    vars(and(F1,F2), Vars),
    rows(Vars, Rows),
    forall(member(Env, Rows),
           (evaluate(F1,Env,V1), evaluate(F2,Env,V2), V1==V2)).

% ---- DEMO / TESTS (SIMPLIFIED OUTPUT) ----

demo :-
    format('~n=== DEMO ===~n'),
    F1 = and(p,q),
    detail(F1), show(F1),
    F2 = and(neg(neg(p)), true),
    detail(F2), simp_print(F2),
    F3 = and(p),
    ( is_valid(F3) -> format('~p valid~n',[F3]) ; format('~p invalid~n',[F3]) ),
    F4a = and(p,true), F4b = p,
    ( equiv(F4a,F4b) -> format('~p ≡ ~p~n',[F4a,F4b]) ; format('~p not ≡ ~p~n',[F4a,F4b]) ),
    F5 = or(and(p,q), neg(r)),
    detail(F5).

tests :-
    format('~n=== TESTS ===~n'),
    format('Valid: '),
    forall(member(F,[p,and(p,q),or(neg(p),q),impl(p,q),iff(p,q),neg(neg(p))]),
           ( (is_valid(F) -> format('✓') ; format('✗')) )), nl,
    format('Invalid: '),
    forall(member(F,[and(p),or(p,q,r),badop(p,q),123]),
           ( (\+ is_valid(F) -> format('✓') ; format('✗')) )), nl,
    format('Ops/Depth: ~w ~w~n', [and(p,q), or(neg(p),q)]),
    format('Simplify: '),
    forall(member(F,[and(p,true), or(p,false), neg(neg(p)), and(or(p,q),neg(or(p,q)))]),
           ( simp(F,S), format('~p->~p ', [F,S]) )), nl,
    format('Equiv: '),
    forall(member((F1,F2,Exp),[(p,p,true),(p,q,false),(and(p,true),p,true),(or(p,false),p,true),(neg(neg(p)),p,true)]),
           ( (equiv(F1,F2) -> R=true ; R=false),
             (R=Exp -> format('✓') ; format('✗')) )), nl,
    format('Classify: '),
    forall(member((F,Exp),[(or(p,neg(p)),tautology),(and(p,neg(p)),contradiction),(and(p,q),contingency)]),
           ( classify(F,C,_), (C=Exp -> format('✓') ; format('✗')) )), nl.

help :-
    format('~nCommands: demo, tests, is_valid(F), detail(F), show(F), simp(F,S), classify(F,C,T), equiv(F1,F2)~n').

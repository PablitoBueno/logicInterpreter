# Propositional Logic Meta-Interpreter

## Overview

This project implements a Prolog meta-interpreter for Propositional Logic capable of:

- Extracting propositional variables from formulas
- Generating all possible truth assignments
- Evaluating logical formulas
- Building complete truth tables
- Classifying formulas as:
  - Tautology
  - Contradiction
  - Contingency

## Supported Operators

| Operator | Meaning |
|----------|----------|
| `neg(F)` | Negation |
| `and(F1,F2)` | Conjunction |
| `or(F1,F2)` | Disjunction |
| `impl(F1,F2)` | Implication |
| `iff(F1,F2)` | Biconditional |

## Examples

```prolog
?- classify(or(p,neg(p)), Class, Table).
Class = tautology.
```

```prolog
?- classify(and(p,neg(p)), Class, Table).
Class = contradiction.
```

```prolog
?- classify(impl(p,q), Class, Table).
Class = contingency.
```

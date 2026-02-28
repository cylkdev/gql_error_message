# Accept Absinthe-normalized plain maps in CommonError.translate/3

---
Status: accepted
Date: 2026-02-28
Deciders: []
Consulted: []
Informed: []
---

## Context and Problem Statement

When a nested field resolver returns `{:error, %ErrorMessage{}}`, Absinthe 1.9+ normalizes the struct into a plain map (`%{message: "...", extensions: %{}}`) during nested field error handling. The `GQLErrorMessage.Absinthe.Middleware` on the top-level query field then iterates `resolution.errors` and passes each error through `GQLErrorMessage.translate/3`. The default translator, `GQLErrorMessage.CommonError`, had no clause matching a plain map, so the catch-all clause raised a `RuntimeError`. The question is: should `CommonError.translate/3` recognize these Absinthe-normalized plain maps and reconstruct the appropriate error structs?

## Decision Drivers

- The library must not crash when Absinthe 1.9+ normalizes error structs into plain maps during nested field resolution.
- The fix must be minimal and upstream (in the translator) rather than requiring every consumer to add workaround code in their middleware or resolvers.
- The plain-map shapes are deterministic: Absinthe produces `%{message: msg, extensions: ext}` for server errors and `%{message: msg, field: field}` for client errors.
- The existing struct-matching clauses must remain unaffected because Elixir pattern matching on structs is more specific than plain maps.

## Considered Options

1. Add `translate/3` clauses in `CommonError` for plain maps with a `:message` key.
2. Filter out already-normalized maps in the middleware before calling `translate/3`.
3. Require consumers to handle this in their custom translator modules.

## Decision Outcome

Chosen option: "Add translate/3 clauses in CommonError for plain maps with a :message key", because it fixes the crash at the root (the translator) without requiring changes in middleware or consumer code, and the new clauses are guarded tightly so they only match maps that look like already-translated errors.

### Consequences

Good, because the library no longer crashes when Absinthe 1.9+ normalizes error structs into plain maps during nested field resolution.

Good, because consumers with custom translators can adopt the same pattern by delegating plain-map cases to `CommonError.translate/3`.

Bad, because the translator now accepts a broader input surface. A plain map that happens to have a `:message` key will be silently accepted instead of raising. The tight guards (`is_binary(message)`, `is_map(extensions)`, `is_list(field)`) reduce this risk.

## Validation

Run the regression tests that cover the three new plain-map shapes:

    mix test test/gql_error_message/common_error_test.exs --trace

Expect three passing tests in the `"translate/3 with Absinthe-normalized plain maps"` describe block:

- `translates a ServerError-shaped map to a ServerError`
- `translates a ClientError-shaped map to a ClientError`
- `translates a bare message map to a ServerError`

## Pros and Cons of the Options

### Add translate/3 clauses in CommonError for plain maps

Add three guarded clauses before the catch-all in `CommonError.translate/3`: one for `%{message, extensions}` (ServerError), one for `%{message, field}` (ClientError), and one for `%{message}` (bare fallback to ServerError).

Good, because it is a minimal, upstream fix — three function clauses and three tests.
Good, because existing struct-matching clauses are unaffected by Elixir's pattern matching specificity.
Bad, because it widens the accepted input surface slightly.

### Filter in middleware

Check each error in the middleware and skip `translate/3` for maps that already have a `:message` key. Pass them through as-is to `place_errors`.

Good, because the translator remains strict about what it accepts.
Bad, because it moves error-type knowledge into the middleware, duplicating the "what is a translated error?" concern. Custom middleware implementations would need the same logic.

### Require consumer workaround

Document the issue and ask consumers to handle plain maps in their custom translator or middleware.

Good, because the library stays unchanged.
Bad, because every consumer using Absinthe 1.9+ with nested error-returning resolvers must independently discover and fix the same crash.

## More Information

The three new clauses are ordered from most specific to least specific: `%{message, extensions}` then `%{message, field}` then `%{message}`. This ensures a map with both `:message` and `:extensions` is always treated as a ServerError, even if it also contains a `:field` key.

Revisit this decision if Absinthe changes how it normalizes nested field errors, or if the broader input surface causes false positives in production.

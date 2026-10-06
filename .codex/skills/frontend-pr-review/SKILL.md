---
name: frontend-pr-review
description: Review a frontend change against the touched diff, project conventions, reusable component architecture, Figma, and production-quality checks. Use for React, Next.js, TypeScript, CSS, Tailwind, and frontend PR reviews.
---

# Frontend PR Review

Perform a read-only, defect-first review of the frontend work in scope. Review
the work the contributor touched, not unrelated pre-existing code. Inspect
nearby callers, shared components, types, tokens, tests, and configuration only
when they are needed to understand the touched change or prove a finding.

Do not edit files, commit, push, post GitHub comments, or resolve review
threads during this skill. Report findings in the current chat. End by asking:
“Would you like me to fix these findings?” Only implement, commit, or push when
the user separately authorizes that action.

## Review priorities

Use this order when findings compete:

1. Component architecture, reuse, and DRY structure.
2. Correctness, security, and tests.
3. Performance and rendering cost.
4. SEO and metadata.
5. Responsive behavior and layout integrity.
6. Accuracy against the supplied Figma/design reference.
7. Accessibility and keyboard/screen-reader behavior.
8. Clean, readable, organized code.

The priority order does not excuse a serious security, correctness, or
accessibility defect. Severity is based on user impact, not on this ordering.

## Scope boundary

1. Resolve the actual review base and head, then inspect the merge-base diff.
2. List every touched file and categorize it as component, page, style, data,
   metadata/SEO, test, dependency, or configuration.
3. Attribute findings only to the candidate diff. A pre-existing issue may be
   mentioned separately, but do not present it as a required PR fix.
4. Read the owning `AGENTS.md`, architecture/design rules, testing guide,
   quality guide, and any project-specific frontend instructions before
   judging the code.
5. Search for existing components, hooks, utilities, design tokens, constants,
   and sibling implementations before suggesting a new abstraction.

## Component architecture and code organization

Always inspect this area first.

- Prefer an existing component or utility when it already expresses the same
  behavior or visual pattern.
- Extract a repeated visual/semantic block into a named component when it is
  used in multiple places, is likely to be reused, or makes a large component
  difficult to read. Do not demand abstractions for a genuinely one-off block.
- Flag large components that mix page composition, repeated content markup,
  interaction state, data transformation, and styling without clear boundaries.
- Check that atoms, molecules, compounds, pages, hooks, constants, and types
  follow the repository’s established responsibility boundaries.
- Keep static content, tokens, and reusable style constants outside components;
  keep state, refs, handlers, and derived values with their owner.
- Check server/client boundaries. A component should be client-side only when
  it needs state, effects, browser APIs, context, or event handlers.
- Check props for a useful, typed contract. Flag duplicated prop shapes,
  boolean-prop combinations that hide several modes, and casts that conceal
  missing cases.
- Search for duplicated JSX, duplicated class groups, repeated data mappings,
  repeated route strings, direct color values where project tokens exist, and
  parallel implementations that should share one component.
- Prefer readable named helpers or small components over deeply nested
  conditionals and repeated branches.

## Figma and visual accuracy

Matching the supplied Figma design is a required acceptance criterion, not a
nice-to-have. When a Figma URL or node is supplied:

1. Load the Figma design-to-code instructions before requesting design context.
2. Inspect the exact referenced node and its relevant desktop/mobile variants.
3. Compare layout geometry, max-widths, spacing, typography, colors/tokens,
   image treatment, content, interaction states, and responsive behavior.
4. Compare the running implementation at the relevant viewport sizes when the
   app can be run. Use screenshots or browser inspection rather than relying
   only on source classes.
5. Report the smallest concrete mismatch and the expected design behavior.

If the Figma reference itself appears inconsistent or incorrect, distinguish a
design problem from a code problem. State what is inconsistent and recommend
confirming the intended design; do not force the developer to guess between
two conflicting references.

## Quality lenses

Apply these lenses to the touched change:

- Boundary fit: does the code live in the right component/module and reuse the
  project’s existing patterns?
- Simplicity: can the same behavior be expressed with fewer branches or a
  clearer component boundary without losing behavior?
- Test confidence: are new transformations, states, routes, and interactions
  covered by focused tests or appropriate browser checks?
- Security: are external inputs, links, forms, client-visible errors, and
  server/client boundaries handled safely?
- Scalability: does rendering, image loading, mapping, or repeated work grow
  unnecessarily with content size or viewport changes?
- Maintainability: can a frontend engineer add the next variant without
  copying fragile markup or changing unrelated files?
- Automation: can a repeatable problem be prevented by a test, lint rule,
  shared token, type, or project documentation?

## Frontend checks

Discover the project’s required checks rather than inventing replacements. Run
the full configured quality gate when possible, including the project’s format,
lint, type-check, unit tests, production build, and dependency audit. Also run
focused tests for touched logic and browser/visual checks for changed journeys.

For visual work, inspect desktop and mobile, narrow overflow, keyboard focus,
loading/empty/error states where relevant, and the exact Figma reference. For
Next.js work, check metadata, canonical URLs, sitemap/robots behavior, image
alt text and sizing hints, heading structure, and link semantics.

Do not weaken, skip, disable, or rewrite a failing check to obtain a pass. Do
not run database generate/migrate/push/studio/drop commands without explicit
permission. Report checks as passed, failed, or not run, including why.

## Findings standard

Only report findings that are concrete, introduced by the touched change,
meaningful, and actionable for the contributor. Do not report personal style
preferences, speculative future problems, or unrelated pre-existing issues.

Order findings by severity:

- **P0:** critical security, data-loss, or universal release failure.
- **P1:** major user-facing correctness, accessibility, security, or build/CI
  failure that should block the change.
- **P2:** ordinary correctness, architecture, performance, SEO, responsive,
  accessibility, or maintainability defect that should be fixed.
- **P3:** lower-impact but worthwhile cleanup or confidence gap.

Use this format for every finding:

```text
[P2] Short imperative title — path/to/file.tsx:42

Problem: What the touched code does and the concrete scenario where it fails.
Why it matters: The user, maintainer, performance, SEO, or accessibility impact.
Fix: The smallest clear correction, naming an existing component/pattern when one exists.
Verify: The focused test, viewport, browser state, or command that proves the fix.
```

Explain findings so a junior frontend engineer can fix them without guessing.
Give one recommended direction, not a list of vague alternatives. If a value
requires product, content, or design approval, label it as “Approval needed”
instead of asking the engineer to invent business requirements.

After findings, include:

- a short overall assessment;
- checks and their actual results;
- residual uncertainties or approval-needed items;
- good patterns worth preserving;
- optional automation follow-ups.

Finish with: “Would you like me to fix these findings?”

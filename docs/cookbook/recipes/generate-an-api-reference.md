---
title: "Recipe: Generate an API Reference"
description: "Generate an OpenAPI 3.1 spec and interactive docs from your codebase"
category: "cookbook"
level: "intermediate"
time_estimate: "5 minutes"
related:
  - ../../commands.md
  - ../../generate.md
---

# Recipe: Generate an API Reference

**Time:** 5 minutes
**Level:** Intermediate
**Prerequisites:** A codebase with REST/HTTP endpoints (routes, controllers, or handler files)

## Problem

I have an API with no OpenAPI spec, no SDK docs, and no interactive reference — and I don't want
to hand-write 3.1-spec YAML.

## Solution

1. **Run the API documentation command**

   ```
   /folio:docs:api
   ```

   Or route through the generator dispatcher:

   ```
   /folio:docs:generate api
   ```

   Why: both paths reach the same generator; `docs:api` is the direct entry, `docs:generate api`
   is the router form — use whichever you remember.

2. **Let it analyze your project first.** Invoked with no arguments, the command inspects your
   route/controller files and proposes an API documentation approach before generating anything —
   review the plan before it writes files.

3. **Review the generated OpenAPI 3.1 spec** and any Swagger UI scaffolding it produced.

## Explanation

`docs:api` is backed by the `api-documenter` agent, which specializes in OpenAPI 3.1 specs, SDK
generation, and developer-portal-style output. It reads your actual route/handler code rather
than asking you to describe the API by hand, so the spec stays traceable to real endpoints.

## Related recipes

- [Check Documentation Health Before a PR](check-docs-health-before-a-pr.md) — validate the new
  spec's links before committing
- [Find the Right Docs Command](find-the-right-docs-command.md)

## What's Next

- [Commands Reference](../../commands.md)
- [Skills & Agents](../../skills-agents.md) — see `api-documenter`

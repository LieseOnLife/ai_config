---
description: Go logging — take the logger from the context and bind it once per function.
globs: ["**/*.go"]
---
# Go logging

- When a function has a `context.Context`, get the logger from it (dd-source: `log.FromContext(ctx)`), not a global/default logger (`log.DefaultLogger()`, package-level `log.Errorf`).
- Bind it once at the top of the function (`logger := log.FromContext(ctx)`) and reuse that local for every log call in the function.
- Log errors as a structured field (dd-source: `logger.Error("msg", log.ErrorField(err))`), not formatted into the message with `%v`.
- Apply this to code you write or touch; don't rewrite untouched pre-existing log calls without being asked.

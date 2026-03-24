#!/bin/bash
# PreToolUse hook: Override OTEL protocol for terraform commands
# Terraform only accepts 'grpc' or 'http/protobuf', not 'http/json'

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

if [ "$tool_name" != "Bash" ]; then
  exit 0
fi

command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Check if the command invokes terraform
if echo "$command" | grep -qE '(^|&&|\|\||;|[[:space:]])terraform[[:space:]]'; then
  # Prefix terraform invocations with the protocol override
  modified=$(echo "$command" | sed -E 's/(^|(&& *|; *|\|\| *))terraform /\1OTEL_EXPORTER_OTLP_PROTOCOL=http\/protobuf terraform /g')
  echo '{"decision":"replace","tool_input":{"command":"'"$(echo "$modified" | sed 's/"/\\"/g')"'"}}'
else
  exit 0
fi

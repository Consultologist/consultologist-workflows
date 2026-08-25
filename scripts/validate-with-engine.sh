#!/usr/bin/env bash
# Run the ENGINE's validator over one or more package directories (#185).
#
# Usage:
#   ./scripts/validate-with-engine.sh <engine-checkout> <package-dir> [<package-dir>...]
#
# <engine-checkout> is a checkout of Consultologist-Blazor WITH SUBMODULES.
# Example:
#   ./scripts/validate-with-engine.sh engine packages/general
#
# WHY THIS EXISTS. CI here validates structure — manifest parses, CalVer shape,
# every referenced file present — and nothing else. It never reads specVersion,
# never traverses nodes, results or when. So a condition naming an undeclared
# enum value, a deliverable whose node is not an aggregator, or a prompt that
# fails strict rendering all pass and publish cleanly. The failure then lands at
# pin resolve, where the app reports "Workflow package registry is unavailable"
# — pointing at infrastructure when the cause is content. Versions are
# immutable, so the remedy is a new version number rather than a fix.
#
# WorkflowPackageValidator.Validate is the same method the registry runs on
# every account publish. This is not a second opinion; it is the same one, moved
# earlier — and since #449 CI checks the engine out at the commit the deployed
# app reports (GET /api/Public/Engine), so it is the same build too. main is
# the fallback only when that endpoint cannot say, and the run says which.
#
# Errors fail the run. Warnings are annotated and do NOT fail, which is exactly
# what the app's publish does — the editor lists them and publishes anyway. A
# package must not be publishable through one door and refused by the other.
set -uo pipefail

if [[ $# -lt 2 ]]; then
	grep '^#' "$0" | sed 's/^# \{0,1\}//' | head -8
	exit 1
fi

ENGINE="$1"
shift

SCRIPT="$ENGINE/scripts/validate-workflow-package.cs"

if [[ ! -f "$SCRIPT" ]]; then
	echo "error: $SCRIPT not found — is <engine-checkout> a Consultologist-Blazor checkout?" >&2
	exit 2
fi

# The validator matches every declared package schema against the output-contract
# catalog, and an absent catalog fails every package that declares one. The CLI
# reads it from the agents submodule, so a checkout without submodules produces a
# confusing wall of schema errors instead of this sentence.
if [[ ! -f "$ENGINE/external/consultologist-agents/agents/output-contracts.json" ]]; then
	echo "error: the agents submodule is missing from $ENGINE — check out with submodules: true." >&2
	exit 2
fi

STATUS=0

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

for PACKAGE in "$@"; do
	echo "--- $PACKAGE"

	# Plain files rather than $(...) with a process substitution for stderr.
	# Command substitution waits for every writer to the pipe to close, and the
	# processes dotnet leaves behind inherit that descriptor — VBCSCompiler, the
	# Roslyn compiler server, holds it for its ten-minute idle keepalive. The
	# first CI run cost exactly that per package: the validator answered in
	# seconds and the shell then sat for ten minutes, three times over, with
	# tee and sed still listed as orphans when the job was killed. It never
	# showed up locally, where the compiler server was already warm.
	#
	# -v q is load-bearing: without it MSBuild writes build warnings to STDOUT,
	# and the warning transform reads stdout. With it, stdout carries only the
	# validator's own lines.
	dotnet run -v q --file "$SCRIPT" -- "$PACKAGE" > "$WORK/out" 2> "$WORK/err"
	CODE=$?

	cat "$WORK/out"
	cat "$WORK/err" >&2

	# Anchored at line start so MSBuild's "warning CS8602:" — which is preceded
	# by a file path — cannot be mistaken for the validator's own "warning: ".
	sed -n 's/^warning: /::warning::/p' "$WORK/out"
	sed -n 's/^error: /::error::/p' "$WORK/err"

	if [[ $CODE -ne 0 ]]; then
		echo "::error::$PACKAGE failed engine validation (exit $CODE)"
		STATUS=1
	fi
done

# One failing package must not hide the others, so the exit is accumulated
# rather than taken on the first failure.
exit $STATUS

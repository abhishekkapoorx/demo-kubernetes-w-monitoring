# Project handoff: Alert-triggered, read-only incident investigation agent

## Context
I'm a final-year CS student (AI specialization) building this as a college project with a 1-month MVP deadline. It is also the seed of a possible startup, so the design should not paint us into a corner. For now, the goal is a solid, demoable technical project.

## Problem
When a production service goes down, slows down, or becomes unreachable, a DevOps/SRE engineer manually jumps between tools (Grafana, logs, kubectl, GitHub, ArgoCD, Slack) to work out what changed and why. The slow part is correlating scattered signals into a hypothesis, usually at 3am. Research from Reddit/SRE communities and vendor reports shows:
- Engineers accept AI with read-only access, but reject autonomous write access to production.
- Main pains: alert noise, context scattered across tools and people's heads, and AI tools that confidently give wrong root causes.
- Accuracy is the hard part. Public benchmarks show agents recover the exact root cause only roughly 20-30% of the time on hard incidents. There is no trusted independent benchmark.
- Existing tools: HolmesGPT (CNCF, open source, agentic investigation), K8sGPT (CNCF, Kubernetes analyzers plus LLM explanations), and commercial AI SRE products (Datadog Bits AI, incident.io, Resolve, Traversal, Cleric).

## What we're building (MVP)
An alert fires -> webhook -> the system gathers evidence from the cluster (read-only) -> an LLM proposes ranked hypotheses, each citing evidence -> a verifier drops unsupported claims -> a briefing is posted to Slack. A replay/eval harness scores accuracy on injected failure scenarios.

## Long-term vision (not for MVP, but don't block it)
- Backtesting harness that replays a team's past incidents to prove whether an agent can be trusted. This is the likely differentiator.
- Alert-noise analysis that proposes alert-tuning changes.
- Incident memory and runbook capture.
- Self-hosted / bring-your-own-model deployment for data-sensitive teams.
- Later: human-approved remediation. Never autonomous writes.

## Design principles
1. Deterministic evidence gathering first, LLM reasoning second.
2. Every claim must cite evidence IDs. Unsupported claims are dropped.
3. Confidence is computed from rules, not the model's self-report.
4. Strictly read-only tools: no write verbs exist in the tool layer.
5. If the LLM fails or exceeds budget, still post the deterministic context pack.
6. Hard cap on tool calls and cost per investigation; redact secrets before LLM calls.

## Architecture (high level)
Alert sources -> Ingest API (normalize, fingerprint-dedup) -> job queue -> Investigation worker [context pack -> LLM hypothesis loop -> verifier] using read-only connectors (Kubernetes API first) -> Postgres store (alerts, investigations, evidence, hypotheses, feedback, audit log) -> Slack briefing. Separate replay/eval runner.

Stack: Python, FastAPI, Postgres, LiteLLM (swappable models), Slack incoming webhook, Docker Compose, a `kind` cluster with a small demo app.
Core abstraction: Evidence { id, source, query, fetched_at, summary, raw_ref, truncated }.
Existing code: I may already have a server plus a Python Textual CLI with browser device-code auth from an earlier related attempt. Ask me before assuming or rewriting it.

## 4-week plan
- Week 1: repo, Docker Compose, kind cluster plus demo app, 4-5 failure-injection scenarios with known root causes (CrashLoopBackOff from bad config, OOMKilled, ImagePullBackOff, service selector mismatch, optional latency), Alertmanager webhook endpoint, alert normalization and dedup, DB tables.
- Week 2: Evidence/Tool interface, Kubernetes collectors (pod status/events/logs, rollout history, service/endpoints), context pack, plain Slack post with no LLM.
- Week 3: LLM hypothesis loop, evidence-citing hypotheses, verifier, rule-based confidence, fallback, redaction, final briefing format.
- Week 4: replay/eval runner (top-1/top-3 hit rate, grounded-claim rate, time, cost; ~3 runs per scenario), baseline comparison (raw kubectl output in a chat model, or HolmesGPT), docs, architecture diagram, demo video, report.
Cut order if behind: Prometheus metrics, pgvector memory, Slack feedback buttons, CLI/web view, multi-model support. Never cut: evidence citation, the verifier, the replay eval.

## Current implementation
- The repository is now `kubernetes-incident-investigation-lab` and includes a small Python demo stack with Docker build/deploy scripts, Prometheus metrics, OpenTelemetry traces, Grafana dashboards, and Tempo.
- Online Boutique is tracked at `demo-apps/microservices-demo` as a submodule. Its local checkout still has separate unpushed edits.
- `scenarios/` contains eight reversible Online Boutique failure scenarios, sanitized baselines, Alertmanager fixtures, ground truth, an interactive runner, and a full smoke test. Set `NAMESPACE` to the deployed namespace; the current local cluster uses `default`.
- Root usage instructions are in `README.md`. Before relying on benchmark timings, run `snapshot` against a healthy cluster and then `verify_all.sh`.


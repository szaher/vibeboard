# Vibe Gaming App — Prompt Pack (ChatGPT + Claude, Modular)

A ready‑to‑run set of prompts that generates a complete engineering spec and execution plan for a **mobile online gaming platform (Dominoes, Chess, …)** with a **Go backend** and **Kubernetes/Helm** deployment. Designed for **ChatGPT** to create plans & documents and **Claude** to write/code.

---

## How to Use (Modular Run)
1. **Copy the Variables block** below and edit values as needed. Keep the keys the same.
2. In **ChatGPT** (planner/docs), run **Module 0** once to establish context; then run any of the **Docs Modules (1–12)** independently to generate that file.
3. After docs are ready, switch to **Claude** and run the **Coding Kickoff** + **Implementation Modules**.
4. Each module outputs a **single file** and must **start with a filename header** and end with a **self‑check list**.

---

## 🔧 Variables (Copy, Edit, Reuse)
```yaml
APP_NAME: "Vibe Arcade"
ORG_NAME: "Acme Games"
DESCRIPTION: "Mobile online entertainment platform to play casual turn-based board games with friends or matchmaking. Initial games: Dominoes & Chess."
GAMES:
  - Dominoes
  - Chess
MOBILE_STACK: "Flutter (Dart)"
STATE_MGMT: "Riverpod"
BACKEND_STACK: "Go (Gin or Fiber)"
DB: "PostgreSQL"
CACHE_QUEUE: "Redis"
REALTIME: "WebSockets (JSON)"
BROKER: "NATS (event bus)"
AUTHN_AUTHZ: "JWT w/ refresh, optional OIDC (Google/Apple)"
DEPLOY: "Kubernetes (Helm charts), container images via GH Actions + Docker"
OBSERVABILITY: "OpenTelemetry traces, Prometheus metrics, Grafana dashboards, Loki logs"
CLOUD: "Any (EKS/GKE/AKS or self-managed)"
REGION: "multi‑region ready, start single region"
COMPLIANCE: "GDPR-capable: data deletion, export, consent"
NONFUNCTIONAL: "P95 < 200ms API, 99.9% availability, scalability to 50k concurrent players"
PAYMENTS: "Out of scope v1 (cosmetics later)"
MONETIZATION: "Ads or cosmetics in v2; v1 free with accounts"
```

> Include this YAML at the **top** of every module prompt you run so models have consistent context.

---

## Output Contract (All Modules Must Obey)
- **Begin** with a top line: `FILENAME: <name>.md`
- Use **Markdown only**. No HTML.
- Include **Mermaid diagrams** where helpful (`flowchart`, `sequence`, `erDiagram`, `gantt`).
- Put **assumptions** in a section and proceed—do not block on questions.
- End with a **Self‑Check** list (acceptance criteria) and **Next Actions**.

---

## Module 0 — Project Context (ChatGPT)
**Prompt:**
```
Use the Variables block. Establish a concise, durable **Project Context** for subsequent modules.
Produce a single file:
FILENAME: context.md
Content must include: mission, scope boundaries, games list, stack choices, nonfunctionals, compliance, and explicit assumptions.
Add a short glossary.
End with: Self‑Check and Next Actions.
```

---

## Module 1 — Product Requirements (PRD) (ChatGPT)
**Prompt:**
```
Use the Variables block and context.md. Generate the **Product Requirements Document**.
FILENAME: PRD.md
Include:
1) Vision & goals
2) Personas & top JTBD
3) User stories (priority tags: P0/P1/P2)
4) Use cases & flows (signup, lobby, matchmaking, invite, in‑game, reconnection, chat)
5) Success metrics & guardrails (KPI & UX)
6) Release scope (MVP, v1.1, v2)
7) Out‑of‑scope & constraints
8) Assumptions & risks
9) Open questions
Use Mermaid `flowchart` for key flows.
End with Self‑Check and Next Actions.
```

---

## Module 2 — Architecture (C4 + Realtime) (ChatGPT)
**Prompt:**
```
Use the Variables block and PRD.md to define architecture.
FILENAME: architecture.md
Include:
- C4 Level 1–3 (system, containers, components)
- Services: api‑gateway, auth, users, lobby/matchmaking, game‑engine (plugin per game), realtime (WebSocket hub), leaderboard, telemetry
- Data stores: PostgreSQL (ERD), Redis (sessions, queues)
- Eventing: NATS subjects, event schemas
- Protocols: REST for CRUD, WebSockets for realtime, (optional) gRPC internal
- Sequence diagrams: matchmaking, join game, turn submission, reconnection
- Scaling & resilience (HPA, idempotency, retries, backoff)
- Config & secrets (12‑factor, K8s secrets)
- Observability (metrics, traces, logs)
- Deployment overview (Helm/k8s)
Include Mermaid `sequenceDiagram`, `flowchart`, and `erDiagram`.
End with Self‑Check and Next Actions.
```

---

## Module 3 — API Spec (REST + WS) (ChatGPT)
**Prompt:**
```
Use Variables + architecture.md. Produce the API specification.
FILENAME: api.md
Sections:
- REST endpoints (OpenAPI-like tables): auth, users, lobby, matchmaking, games, moves, chat, leaderboard
- Request/response schemas (JSON), pagination, errors
- WebSocket channels & message envelopes (subscribe, heartbeat, game events)
- Rate limits & idempotency keys
- Versioning & deprecation policy
End with Self‑Check and Next Actions.
```

---

## Module 4 — Database Design & Migrations (ChatGPT)
**Prompt:**
```
Use Variables + architecture.md. Produce DB design.
FILENAME: db.md
Include:
- ERD (Mermaid `erDiagram`)
- Table definitions with columns, types, PK/FK, indexes
- Sample SQL migrations (PostgreSQL) for MVP tables
- Data lifecycle & retention (GDPR delete/export)
- Example queries for leaderboard and matchmaking
End with Self‑Check and Next Actions.
```

---

## Module 5 — UI/UX Spec (Flutter) (ChatGPT)
**Prompt:**
```
Use Variables + PRD.md. Produce UI/UX spec for Flutter.
FILENAME: ui-ux.md
Include:
- IA & navigation map
- Key screens: onboarding, home/lobby, create/join match, matchmaking, game boards (Dominoes, Chess), chat, profile, settings
- Widget tree per screen; responsive & accessibility notes
- Design tokens (typography, spacing, color roles); dark mode
- State management (Riverpod) patterns
- Offline & reconnection UX
- Example Flutter widget snippets for critical components
- Analytics events mapping
End with Self‑Check and Next Actions.
```

---

## Module 6 — Agents (Roles & Protocols) (ChatGPT)
**Prompt:**
```
Use Variables. Define AI agent roles used in this project.
FILENAME: agents.md
Include roles:
- Planner (ChatGPT): owns docs/modules, tickets, acceptance criteria
- Go Backend Coder (Claude)
- Flutter App Coder (Claude)
- Infra/Helm Engineer (Claude)
- QA/Test Engineer (Claude)
For each: objectives, inputs, outputs, guardrails, handoff contracts, and DoD (definition of done).
Define a shared **artifact contract** (file tree, naming, code style, commit message convention) and a **handoff protocol** from ChatGPT → Claude.
End with Self‑Check and Next Actions.
```

---

## Module 7 — Claude Coding Guide (Claude) (ChatGPT generates)
**Prompt:**
```
Use Variables + agents.md. Produce a model‑specific guide for Claude (code writing).
FILENAME: claude.md
Include:
- Expected inputs (links to PRD, architecture, api, db, ui-ux)
- Repo bootstrap plan & file tree (Go + Flutter mono‑repo or workspace)
- Coding conventions (Go, Dart), lint/format tools
- Stub generation strategy; incremental delivery; test‑first guidance
- How to implement WebSocket hub; plugin interface for games; Dominoes & Chess engines
- Error handling, logging, metrics
- Performance guardrails & profiling tips
- Chunking strategy for long files
- Output contract: one subsystem per run; include README and Makefile updates; keep changeset under token budget
End with Self‑Check and Next Actions.
```

---

## Module 8 — Security (Threat Model + Controls) (ChatGPT)
**Prompt:**
```
Use Variables + architecture.md. Produce the security plan.
FILENAME: security.md
Include:
- Threat model (STRIDE) for API, WebSockets, auth, matchmaking, in‑game events
- Controls: authn (JWT/OIDC), authz (RBAC/ABAC), input validation, rate limiting, CSRF (if web), replay protection, TLS, secrets mgmt, pinning
- Anti‑cheat considerations (move validation, server‑authoritative rules, detection heuristics)
- Data privacy & GDPR workflows (export/delete), data minimization
- Secure coding checklist (Go/Dart)
- Incident response playbook
End with Self‑Check and Next Actions.
```

---

## Module 9 — Testing Strategy (Unit → E2E) (ChatGPT)
**Prompt:**
```
Use Variables + architecture.md + api.md.
FILENAME: testing.md
Include:
- Test pyramid: Go unit tests, Flutter widget tests, integration tests, contract tests, E2E (mobile + backend), load testing (k6), chaos testing
- Test data management & seeding
- Coverage goals & quality gates
- Example test cases (Dominoes move validation, Chess move legality, reconnect flow)
- CI pipeline stages & caching
End with Self‑Check and Next Actions.
```

---

## Module 10 — Infra & Helm on Kubernetes (ChatGPT)
**Prompt:**
```
Use Variables + architecture.md.
FILENAME: infra.md
Include:
- Containerization strategy, base images, multi‑stage builds (Go, Flutter)
- Helm chart structure: charts/<service>, values.yaml samples, common library chart
- K8s objects: Deployment, Service, Ingress, HPA, PDB, NetworkPolicy, ConfigMap, Secret
- Environments: dev/staging/prod with overlays
- Observability setup (Prometheus, Grafana, Loki, OTel Collector)
- CD pipeline outline (GitHub Actions), artifact versioning, rollback plan
- Example Helm templates for one service, and shared values schema
End with Self‑Check and Next Actions.
```

---

## Module 11 — Contributing & Standards (ChatGPT)
**Prompt:**
```
Use Variables.
FILENAME: contributing.md
Include:
- Branching & PR policy, commit convention
- Code style (go fmt, golangci‑lint, Dart fmt, analyzer)
- Docs style, ADRs (architecture decision records)
- Conventional labels & review checklist
End with Self‑Check and Next Actions.
```

---

## Module 12 — Roadmap & Backlog (ChatGPT)
**Prompt:**
```
Use Variables + PRD.md.
FILENAME: roadmap.md
Include:
- Milestones (MVP → v1.1 → v2) with scope
- Gantt (Mermaid) and dependency map
- Work breakdown into epics → stories → tasks
- Risks with mitigations
End with Self‑Check and Next Actions.
```

---

# 🧰 Claude — Coding Kickoff & Implementation Modules

## Kickoff — Bootstrap Repo (Claude)
**Prompt:**
```
Using context.md, architecture.md, api.md, db.md, ui-ux.md, and claude.md, generate an initial repo skeleton.
Goals:
- Mono‑repo layout: /backend (Go), /app (Flutter), /deploy (helm), /docs
- Implement minimal runnable scaffolds: health checks, version endpoints, WebSocket echo, Riverpod app shell
- Add Makefile(s), dockerfiles, basic Helm chart stubs
- Add CI yaml with build/test/lint
Output:
- A tree view and the content for all created files, chunked across responses if needed.
- Include commands to run locally and expected output.
```

## Implementation — Backend Game Plugin Interface (Claude)
**Prompt:**
```
Implement Go interfaces for game engines (Dominoes, Chess) and a registry pattern.
Provide: package structure, interfaces, concrete Dominoes & Chess validators, unit tests, and wiring into WebSocket hub.
```

## Implementation — Matchmaking & Lobby (Claude)
**Prompt:**
```
Implement REST + WS for lobby and matchmaking per api.md. Include Redis usage for queues, idempotency, and integration tests.
```

## Implementation — Flutter UI (Claude)
**Prompt:**
```
Implement Flutter screens (onboarding, lobby, game boards) with Riverpod. Provide widget tests and offline/reconnect handling.
```

## Implementation — Helm Charts (Claude)
**Prompt:**
```
Create production‑grade Helm charts for services with values.yaml examples, HPA, PDB, Ingress, and basic NetworkPolicies.
```

---

## Optional Utilities
**Ticketization (ChatGPT):**
```
From PRD.md and roadmap.md, generate a backlog as GitHub Issues (markdown) with labels, estimates, and acceptance criteria. One section per epic.
FILENAME: backlog.md
```

**ADR Template (ChatGPT):**
```
Create an Architecture Decision Record template and sample ADRs for DB choice, WebSockets vs. gRPC, and event bus.
FILENAME: adr.md
```

---

## Quality Gates (apply to every module)
- Starts with `FILENAME:`
- Assumptions listed; no open questions block progress
- Mermaid diagrams render
- Clear acceptance criteria
- Next Actions with who/which agent owns them

---

## Tips
- If output is long, split logically; keep each file self‑contained.
- Prefer code snippets over prose when instructive.
- Always link back to prior files to keep cohesion.


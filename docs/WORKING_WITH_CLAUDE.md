# Working with Claude — the 10-step flow

How to take **one piece of work** (a bug, a feature, a question) from "something is wrong"
to "fixed, tested, live, committed and documented" with Claude Code. It works for any
project and any stack.

Every step has a **gate**: don't move on until it's met. Each step also has a prompt you can
copy. The *italic* lessons come from real incidents — they're why the step exists.

---

## Big work: phases → steps → this flow

Anything bigger than a single fix is split up before any code is written:

1. **Phases.** Each phase delivers something usable on its own, with a clear **exit gate**
   (e.g. *Phase 1: works for 50 users → Phase 2: works for 500 → Phase 3: works for 5,000*).
   Don't start the next phase until the current gate is met.
2. **Steps.** Each phase is broken into numbered steps (*Step 1, Step 2, …*), each small
   enough to finish and verify on its own.
3. **The 10-step flow below** is run for **every step**.
4. **Track it in a plan file** in the repo: each step with checkboxes, its status, and a
   **sign-off line** (*who / date / notes*) when done. Mark steps done only when their gate
   is met, and log every change in a dated change log.

> **Prompt:** "Before any code, break this into phases with exit gates, and each phase into
> numbered steps. Put it in a plan file with checkboxes and sign-off lines."

*Lesson: a project split into numbered steps with sign-offs stayed clear for weeks; the
single-device test that hid a ~50-device limit shows why later phases need their own gates.*

---

## The two rules that apply to every step

### 1. Production must never be harmed
At no step — investigating, building, testing or deploying — may production be damaged,
slowed down, or have its data changed by accident.

- **Investigate with read-only actions only:** reads, `SELECT`s, log reads. No writes, no
  restarts, no config changes "just to check".
- **Test on test data / staging / a test account,** never on real customers' data. If the
  only way to test is in production, say so up front and agree on it first.
- **No destructive commands without a backup and a stated rollback:** deletes, overwrites,
  `reset --hard`, dropping tables, mass updates.
- **Respect the system's protections:** don't hammer APIs, don't trip rate limits or account
  lockouts, don't fire real alerts or messages at real users while testing.
- **Mind load:** a loop, a poll or a migration that is harmless on one record can take
  production down on thousands. Ask "what does this do at full scale?"
- **Every production change can be undone:** a backup or previous version, plus the exact
  rollback steps, written down **before** you change anything.

*Lesson: repeated failed `sudo` attempts locked the admin account out of a live server for 15
minutes. Nothing was broken, but it could have been during an incident.*

### 2. Every piece of work ships with test cases
No fix or feature is done without tests that prove it:
- a test that **fails before** the fix and **passes after** it (the bug can't silently
  return);
- tests for the **edge cases** found in Step 4;
- the **full existing suite** still passing.

If something truly can't be tested automatically (e.g. physical hardware), write down the
**manual test steps** and their expected results instead.

---

## Step 1 — Define the ask with the 5W (+H)

One task per conversation thread. Answer the **5W + H** before anything else:

| | Question | Example |
|---|---|---|
| **What** | What's wrong, or what's wanted? | Battery shows 100% while the device is offline |
| **Why** | Why does it matter? | Users trust a stale number during an outage |
| **Where** | Which screen / endpoint / module / environment? | Home card + details screen, production |
| **When** | When does it happen, and by when is it needed? | After the device drops offline; before rollout |
| **Who** | Who is affected, and who owns or signs off? | All customers; owner signs off |
| **How** | How will we know it's done? | The real state shows, tested on the real device |

> **Prompt:** "Here's the 5W+H: what …, why …, where …, when …, who …, done = …"

If something is unclear, ask Claude to fill the gaps:

> **Prompt:** "Give me the 5W+H for this problem from what you can find, and mark what you're
> unsure of."

**Gate:** all six answered, and Claude can repeat the task back without guessing.

*Lesson: "make it three rows instead of two", without naming the screen, cost a round trip.*

---

## Step 2 — Investigate, read-only

Claude finds the **root cause with evidence**: logs, database, server state, code, configs,
vendor docs. **Nothing is changed.**

> **Prompt:** "Read only — no code, no writes. Find why X happens. Show me the evidence (log
> lines, rows, code lines) and the reason."

**Gate:** a cause backed by evidence, not "probably". If it's a guess, keep investigating.

*Lesson: a confident guess ("the device only supports this for one alarm type") turned out
wrong; reading the firmware and permissions found the real cause.*

---

## Step 3 — Plan, still no code

Claude proposes the fix: options with a **recommendation**, the **files** that change, the
**risks to production**, the **tests** that will prove it, and the **rollback**.

> **Prompt:** "No code yet. Give me the plan: options, your recommendation, which files
> change, what could break in production, which tests you'll write, and how we undo it."

**Gate:** you approve the plan (or pick an option).

---

## Step 4 — "What am I missing?"

Before building, ask Claude to sweep for what you didn't mention.

> **Prompt:** "Before you build: what am I missing? Check other places that show or use the
> same thing, offline/error states, full-scale load, security, other teammates' recent work,
> and anything this could break in production."

**Gate:** the scope is agreed, with each extra item either included or written down for later.

*Lessons: one wrong value was displayed in five places, not one. A test on a single device
hid a limit that would have broken at ~50 devices.*

---

## Step 5 — Pre-flight (repo + environment)

Make sure you're building on the real current state, and that production is protected.

> **Prompt:** "Pre-flight: pull, confirm the working tree is clean, commit anything pending,
> confirm production matches the repo for the files we'll touch, and make a backup of
> anything we'll change."

**Gate:** clean tree on the latest main branch, production = repo for the files in scope,
backup in place.

*Lesson: a pull wiped two days of uncommitted fixes from a laptop; only the copy on the
server saved them.*

---

## Step 6 — Build, with test cases

Small changes in the style of the surrounding code, **plus the test cases**.

> **Prompt:** "Proceed with the plan. Keep changes minimal, and write the test cases: one
> that fails without the fix, and one for each edge case we agreed."

**Gate:** only the planned files changed (`git diff --stat` matches the plan), and the new
tests exist.

---

## Step 7 — Verify locally

> **Prompt:** "Run the linter/analyzer and the full test suite. Show me the results, and
> confirm the new tests fail without the fix."

**Gate:** clean analysis, **all** tests pass (old and new). Any failure is fixed or explained,
never skipped.

---

## Step 8 — Deploy (only committed code, production-safe)

1. **Commit and push first.** Never deploy uncommitted work.
2. **Backup / previous version** ready, with the rollback steps written down.
3. **Database migrations before** the code that uses them; backward-compatible where possible.
4. Deploy with the project's **standard deploy process**, which should validate before it
   changes anything.
5. Prefer **low-traffic times** for risky changes.
6. **Tell the team** what went live, so nobody overwrites it.

> **Prompt:** "Commit and push, then deploy with our standard process. Migrations first,
> backup ready. Show me the output and the rollback steps."

**Gate:** the deploy completes without errors, and production health (logs, error rate, jobs)
is normal right after.

*Lesson: two people deployed from different copies and silently overwrote each other's
changes on the live server.*

---

## Step 9 — Verify live, in the real environment

The real system is the judge, not the claim.

> **Prompt:** "It's deployed. I'll do <the real action>. Watch the logs and tell me what
> happened end to end."

**Gate:** you saw it work for real **and** the logs agree, with no side effects on other
users. If the fix is a **workaround**, label it temporary and record the real fix as a
follow-up.

---

## Step 10 — Close out

> **Prompt:** "Close out: show me git log to prove it's pushed, update the docs and the
> changelog, and list every loose end we left."

**Gate:** the commit is on main, nothing is uncommitted, the docs are updated and the loose
ends are written down.

*Lesson: "I made the commit, I hope it worked" — it hadn't. Check, don't hope.*

---

## Ground rules

| Rule | Why |
|---|---|
| **Production is never harmed** — read-only investigation, test data, backups, rollback ready | A fix that breaks production isn't a fix |
| **Big work goes phase by phase, step by step** — each with a gate and a sign-off | Keeps scope clear; nothing gets marked done before it is |
| **Start every task with the 5W + H** | Vague asks cost round trips |
| **Every change ships with test cases** — failing-before / passing-after, plus edge cases | Bugs that aren't tested come back |
| **"Read-only" means nothing changes** — no writes, restarts or deploys | Investigation must be safe |
| **Root cause over workaround** | Workarounds become cleanup debt |
| **The real system is the judge** | Claims can be wrong; real results aren't |
| **Commit right after each verified fix** | Uncommitted work gets wiped |
| **Deploy only committed main, and announce it** | Prevents silent overwrites |
| **Test breadth, not just depth** — think at full scale | One working instance ≠ thousands |
| **Respect protections:** rate limits, lockouts, real users' alerts | Testing must not trip them |
| **Secrets stay in secret storage; never paste them in chat** | Rotate any that were shared |
| **Keep a running TODO of loose ends** | Many threads mean forgotten half-done work |

---

## One-screen checklist

0. ☐ Big work? Split into **phases** (exit gates) → **numbered steps**, tracked in a plan file
   with sign-offs
1. ☐ Ask defined with the **5W + H** (what / why / where / when / who / how-done)
2. ☐ Root cause found, read-only, with evidence — production untouched
3. ☐ Plan approved (options, files, production risks, tests, rollback)
4. ☐ "What am I missing?" — scope agreed
5. ☐ Pre-flight: pulled, clean, production = repo, backup made
6. ☐ Built **with test cases** (fails before / passes after, edge cases)
7. ☐ Analyzer + **all** tests pass
8. ☐ Committed + pushed → migrations → standard deploy → team told; rollback ready
9. ☐ Seen working for real, logs agree, no side effects
10. ☐ Push confirmed in git log, docs updated, loose ends listed

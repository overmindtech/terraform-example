# AGM Talk Preparation Notes

Comprehensive notes, references, incident analysis, and theoretical framework for the investor AGM presentation.

**Speaker:** Dylan Ratcliffe, Founder & CEO, Overmind
**Context:** AGM for investor audience

---

## Table of Contents

1. [The Loom Incident — Full Technical Summary](#1-the-loom-incident--full-technical-summary)
2. [Theoretical Framework — Why This Keeps Happening](#2-theoretical-framework--why-this-keeps-happening)
3. [Risk Management Theatre — The Wrong Response](#3-risk-management-theatre--the-wrong-response)
4. [The Overmind Thesis — Pre-Mortems Not Post-Mortems](#4-the-overmind-thesis--pre-mortems-not-post-mortems)
5. [Key Quotes & Data Points](#5-key-quotes--data-points)
6. [Previous Talk Structures](#6-previous-talk-structures)
7. [Full Reference List](#7-full-reference-list)

---

## 1. The Loom Incident — Full Technical Summary

**Source:** Loom blog post (March 8, 2023, updated March 10, 2023). Technical detail from Vinay Hiremath, Co-founder & CTO. Dylan spoke directly to the CTO of Loom and confirmed they did not know about the implication of the change.

**About Loom:** Video recording and screen sharing platform. Recently acquired by Atlassian for ~$1B.

### What Happened

At 11:03 AM PST on March 7, 2023, a Loom employee opened the website and found themselves logged into a completely different user's account. As more employees checked, they discovered it was affecting everyone on the platform — users were being logged in as other users and could see all of their content.

### The Cause — Step by Step

1. **The change:** An apparently innocuous Terraform change to Loom's CloudFront (CDN) configuration. The change moved from a whitelist of headers to caching all headers.
2. **The rollout:** Applied to dev environment ~February 24th. Progressed through dev → test → staging over **10 days** with no anomalous behaviour. Then deployed to production on March 7th.
3. **The mechanism:**
   - Loom uses **rolling cookie-based sessions** — every time the app sees a session cookie, it extends the expiry and returns a `Set-Cookie` response header
   - The CDN config change started **forwarding session cookie headers to JS and CSS static asset endpoints** served by the application behind CloudFront
   - When the app received these requests, it deserialized the session cookie, bumped it, and returned a `Set-Cookie` header in the response
   - CloudFront **cached these responses (including the `Set-Cookie` header) for 1 second**
   - Any user requesting the same static asset within that 1-second window received **another user's session token**
4. **Why it wasn't caught:** The bug required two different users to hit the same endpoint within 1 second of each other. This almost never happens in dev/test/staging environments.

### The CloudFront Complexity Problem

This wasn't a simple misconfiguration — CloudFront is genuinely complex:
- **Cache policies** can be shared across many **distributions**
- A single distribution can have many cache policies
- A distribution can sit in front of something simple (S3 bucket) or complex (load balancer → multiple target groups → multiple applications)
- Changing a single header policy can therefore affect many distributions, and a single distribution can affect caching for many applications
- The impact of changing a header policy "could be nothing, or it could be huge — you have to do the research to find out every time"
- This is obvious when you can see the dependency graph, but "trust me when I tell you it's not obvious in the AWS GUI"

### Timeline (All Times PST, March 7, 2023)

| Time | Event | Notes |
|------|-------|-------|
| ~Feb 24 | Terraform change applied to dev | Innocuous-looking CDN config update |
| 10 days | Change progresses through dev → test → staging | No issues detected |
| 10:21 AM | Change reaches production | |
| 11:03 AM | Incident declared | **42 min undetected.** Staff noticed wrong-account logins. Not caught by monitoring. |
| 11:10 AM | Initial mitigation — CDN config reverted | 7 min response time after alert |
| 11:21 AM | Additional user reports show escalating issues | |
| 11:30 AM | **App fully disabled** | Management decision: pull the plug rather than risk more exposure. **27 min from alert to full shutdown.** |
| 2:45 PM | Service restored | DB/codebase rolled back to pre-10:15 AM snapshot. All caches fully cleared. |

**Incident window:** 1 hour 9 minutes (10:21 – 11:30 AM)
**Downtime window:** 3 hours 15 minutes (11:30 AM – 2:45 PM)
**Impact:** 0.18% of total workspaces potentially affected (may contain false positives)

### Loom's Response

From their blog: *"Will be looking into enhancing our monitoring and alerting to help us catch abnormal session usage across accounts and services."*

**Analysis of their response:**
- **Positive:** They did NOT fall prey to risk management theatre. They didn't add manual steps to the deployment process that don't actually reduce risk.
- **Limitation:** Better monitoring will help them respond faster, but won't prevent the issue. The problem didn't exist until it reached production-level traffic. Unless non-production environments see production-like traffic (users hitting the same endpoint within a second of each other), monitoring alone won't prevent recurrence.
- **The real fix:** The experience itself. This is now burned into their collective memory — it's no longer an unknown unknown. But the *next* big outage will come from a different unknown unknown, which this control won't prevent.

---

## 1b. Technical Replication — What The Terraform Change Actually Was

See `replication-before.tf`, `replication-after.tf`, and `replication-shared.tf` for full Terraform configs.

### The Architecture

```
Users → CloudFront Distribution → ALB → App Servers
                |
                ├── /api/*     → no caching, all cookies forwarded (safe)
                ├── /static/*  → cached for 1 second (THIS IS WHERE THE BUG IS)
                └── default    → no caching
```

The app servers use **rolling cookie-based sessions**: every request that includes a session cookie gets a response with `Set-Cookie` extending the session expiry. This is normal and fine — unless the CDN caches that `Set-Cookie` header.

### The Deprecated Config (SAFE)

In the old Terraform, CloudFront cache behaviors used the `forwarded_values` block:

```hcl
ordered_cache_behavior {
  path_pattern = "/static/*"

  forwarded_values {
    query_string = false
    cookies {
      forward = "none"   # <-- THE KEY SAFETY SETTING
    }
  }

  default_ttl = 1   # 1 second cache
}
```

**The critical thing about `forward = "none"`** is that it's a single atomic setting that does THREE things simultaneously:

1. **Strips `Cookie` headers** from requests forwarded to the origin
2. **Strips `Set-Cookie` headers** from responses returned to viewers
3. **Excludes cookies** from the cache key

From the [AWS docs](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Cookies.html):
> "Don't forward cookies to your origin – CloudFront doesn't cache your objects based on cookie sent by the viewer. In addition, **CloudFront removes cookies before forwarding requests to your origin, and removes `Set-Cookie` headers from responses before returning responses to your viewers.**"

### The New Config (DANGEROUS)

The migration moved to the new `cache_policy_id` + `origin_request_policy_id` model. In this model, the three things that `forward = "none"` did are **split across two separate resources**:

```hcl
# Cache Policy: controls what's in the cache key
resource "aws_cloudfront_cache_policy" "static_assets" {
  default_ttl = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"   # No cookies in cache key — looks safe!
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# Origin Request Policy: controls what's forwarded to the origin
# "We passed on more headers" — this is where the danger is
resource "aws_cloudfront_origin_request_policy" "forward_all" {
  cookies_config {
    cookie_behavior = "all"      # Forwards ALL cookies to origin
  }
  headers_config {
    header_behavior = "allViewer" # Forwards ALL viewer headers
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}

# Applied to the static assets cache behavior
ordered_cache_behavior {
  path_pattern             = "/static/*"
  cache_policy_id          = aws_cloudfront_cache_policy.static_assets.id
  origin_request_policy_id = aws_cloudfront_origin_request_policy.forward_all.id  # DANGER
}
```

They may also have used the AWS managed `AllViewer` origin request policy (ID: `216adef6-5c7f-47e4-b989-5492eafa07d3`) or `AllViewerExceptHostHeader` (ID: `b689b0a8-53d0-40ab-baf2-68738e2966ac`) — both forward all cookies.

### Why This Is Dangerous — The Exact Mechanism

The engineer likely thought: "`cookies_config.cookie_behavior = "none"` in the cache policy is equivalent to `forward = "none"`". **It is not.**

The cache policy only controls the cache key. The origin request policy independently controls what gets forwarded to the origin. When combined:

1. **Origin request policy forwards ALL cookies to the origin** (including session cookies)
2. **The app server sees the session cookie**, processes the rolling session, bumps the expiry, and returns a `Set-Cookie` header in the response
3. **CloudFront considers cookies "configured"** because they're being forwarded (via the origin request policy), so it **caches the `Set-Cookie` header** with the response
4. **The cache policy has `cookie_behavior = "none"`**, so all users share the SAME cached response — cookies are not part of the cache key
5. **User B requests the same JS file within 1 second** → gets User A's session cookie from the cached response → **is now logged in as User A**

From the [AWS docs](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Cookies.html):
> "If the origin response includes `Set-Cookie` headers, CloudFront returns them to the viewer with the requested object. **CloudFront also caches the `Set-Cookie` headers with the object returned from the origin, and sends those `Set-Cookie` headers to viewers on all cache hits.**"

### The Migration Trap Visualised

```
OLD MODEL (forwarded_values):
┌────────────────────────────────────────┐
│ cookies { forward = "none" }           │
│                                        │
│   ✅ Don't forward cookies to origin   │
│   ✅ Strip Set-Cookie from responses   │
│   ✅ Don't use cookies in cache key    │
│                                        │
│   ALL THREE in ONE setting             │
└────────────────────────────────────────┘

NEW MODEL (cache policy + origin request policy):
┌─────────────────────────────────┐  ┌──────────────────────────────────┐
│ CACHE POLICY                    │  │ ORIGIN REQUEST POLICY            │
│                                 │  │                                  │
│ cookies_config {                │  │ cookies_config {                 │
│   cookie_behavior = "none"     │  │   cookie_behavior = "all"       │
│ }                               │  │ }                                │
│                                 │  │                                  │
│ ✅ Don't use cookies in cache   │  │ ❌ DO forward cookies to origin  │
│    key                          │  │                                  │
│ ❌ Does NOT control whether     │  │ ❌ Because cookies are forwarded,│
│    cookies are forwarded        │  │    CloudFront CACHES Set-Cookie  │
│ ❌ Does NOT control whether     │  │    headers and serves them to    │
│    Set-Cookie is stripped       │  │    ALL subsequent viewers        │
└─────────────────────────────────┘  └──────────────────────────────────┘

RESULT: Cookies forwarded to origin + Set-Cookie cached + shared cache
        = session hijacking
```

### Why It Wasn't Caught

1. **The Terraform plan looked fine** — migrating from `forwarded_values` to `cache_policy_id` + `origin_request_policy_id` is a documented, recommended migration
2. **It was reviewed by other infrastructure engineers** who likely focused on "are the values the same?" without understanding the subtle behavioural difference
3. **10 days in non-production** — the bug requires two users to hit the same endpoint within 1 second. Dev/test/staging environments don't have that level of concurrent traffic
4. **No code changes** to authentication or session handling — the bug is entirely in the CDN configuration
5. **The AWS docs don't make this trap obvious** — you have to cross-reference the cache policy docs, origin request policy docs, and cookie caching docs to understand the interaction

### Bonus: Known AWS Bug

In November 2023, someone [reported on AWS re:Post](https://repost.aws/questions/QUnvXr4pJ_TWWcVRmexD6MiA/cloudfront-cache-policy-incorrect-set-cookie-behaviour) that CloudFront was caching `Set-Cookie` headers even when NO cookies were configured in the cache policy (contrary to documented behaviour). AWS's response was to open a support ticket. This suggests the `Set-Cookie` stripping behaviour in the new policy model may have been unreliable even beyond the specific trap described above.

### Deploying & Testing the Replication

This module is self-contained and deployable. It creates:
- A **Lambda function** that simulates Loom's rolling session behaviour (if it sees a session cookie, it extends the expiry and returns `Set-Cookie`)
- A **CloudFront distribution** with the dangerous cache policy + origin request policy combination

**Prerequisites:** AWS credentials configured, Terraform installed.

```bash
cd modules/agm-talk
terraform init
terraform apply
```

Once deployed, run the test script:

```bash
./test.sh
```

The test script:
1. Hits the Lambda directly (baseline — each user gets their own cookie)
2. Hits CloudFront as "User A" with `session=ALICE_SECRET`
3. Immediately hits CloudFront as "User B" with `session=BOB_SECRET`
4. Checks whether User B received User A's session cookie

You can also test manually:

```bash
CF_URL=$(terraform output -raw cloudfront_url)

# User A
curl -v -H "Cookie: session=ALICE_SECRET" "${CF_URL}/app.js"

# Within 1 second, User B
curl -v -H "Cookie: session=BOB_SECRET" "${CF_URL}/app.js"
```

If the leak is working, User B's response will contain `set-cookie: session=ALICE_SECRET`.

**Clean up:**
```bash
terraform destroy
```

---

## 2. Theoretical Framework — Why This Keeps Happening

### Woods' Theorem

> "As the complexity of a system increases, the accuracy of any single agent's own model of that system decreases rapidly."
> — David Woods

**Source:** Referenced extensively in the STELLA Report (SNAFUcatchers Workshop, 2017). See: [snafucatchers.github.io](https://snafucatchers.github.io/)

### The STELLA Report — Key Findings

**What it is:** Report from the SNAFUcatchers Workshop on Coping With Complexity, Brooklyn NY, March 14-16, 2017. Consortium of Etsy, IBM, IEX, and Ohio State University. ~20 participants reviewed and discussed real postmortems.

**Citation:** Woods DD. *STELLA: Report from the SNAFUcatchers Workshop on Coping With Complexity.* Columbus, OH: The Ohio State University, 2017.

#### Common Features of All Anomalies Studied

Every outage examined shared these characteristics:
1. **Each arose from unanticipated, unappreciated interactions between system components** — not from a single failure
2. **There was no "root cause"** — anomalies arose from multiple latent factors that combined to generate a vulnerability
3. **The vulnerabilities were present for weeks or months** before they played a part in an anomaly
4. **The activators were minor events** — near-nominal operating conditions or only slightly off-normal situations
5. **Both external and internal software** was involved (vendor + in-house code, configs, automation)

#### Fundamental Surprise vs Situational Surprise

All the outages studied caused **fundamental surprise** (Lanir, 1983):
1. Situational surprise is compatible with previous beliefs; **fundamental surprise refutes basic beliefs**
2. Situational surprise can be anticipated; **fundamental surprise cannot be anticipated**
3. Situational surprise can be averted by tuning warnings; **fundamental surprise challenges models that produced success in the past**
4. Learning from situational surprise closes quickly; **learning from fundamental surprise requires model revision**

**Key insight for the talk:** Outages will always happen at the edge of your mental model — with the things you don't know you don't know. If you knew about it, you wouldn't have got yourself into that situation in the first place.

#### The Above-the-Line / Below-the-Line Framework

The STELLA report introduces a framework where:
- **Below the line:** Technical artifacts (code, infrastructure, databases, etc.) — never directly seen or touched, only accessed via representations
- **Above the line:** People doing cognitive work — observing, inferring, anticipating, diagnosing, correcting
- **The line of representation:** Screens, terminals, dashboards — everything people use to understand what's happening below the line

**Critical consequence:** What is below the line is *inferred from people's mental models*. These models are "sure to be incomplete, buggy, and quickly become stale." When a system surprises us, it is most often because our mental models are flawed.

#### Dark Debt

**Definition:** Vulnerability that is not recognized or recognizable until an anomaly reveals it. Named by analogy with dark matter — it has detectable effects but cannot be seen directly.

**Contrast with Technical Debt:**

| | Technical Debt | Dark Debt |
|---|---|---|
| Visibility | Appreciated before creation, visible in code | Not recognizable until anomaly reveals it |
| Fix | Can be eliminated by refactoring | Cannot be fixed proactively — invisible until triggered |
| Impact | Makes development less efficient | Generates anomalies and outages |
| Origin | Deliberate shortcut for speed | Product of complexity, unforeseen interactions |

**Dark debt events cited in STELLA:** Knight Capital (Aug 2012), AWS (Oct 2012), NYSE (Jul 2015), Facebook (Sep 2015), GitHub (Jan 2016), Southwest Airlines (Jul 2016), Delta (Aug 2016), and others.

**Key quote:** "Critics of the notion of dark debt will argue that it is preventable by design, code review, thorough testing, etc. But these and many other preventative methods have already been used to create those systems where dark debt has created outages."

#### Strange Loops

When some part of a system that provides a function also depends on the function it provides. All three STELLA cases were complicated by strange loop dependencies. This maps to the Loom case: the monitoring and testing infrastructure relies on the same CDN/infrastructure that caused the outage.

#### Postmortems — The Write-Only Memory Problem

- Postmortem libraries are often "write-only memory" — large collections of inert knowledge
- Learning is truncated at organisational boundaries
- Publicly available reports are "pale and stale" compared to the real issues
- One participant: *"Collectively, our skill isn't in having a good model of how the system works, our skill is in being able to update our model efficiently and appropriately."*
- There is the related *"how-did-this-ever-work?!"* experience — where you fix something but can't construct a mental model that would have ever allowed the system to work correctly before

### The Unknown Unknowns Argument

**Dylan's framing from previous talks:**
- Outages always happen at the edge of your mental model, in the unknown unknowns
- If you only knew that you didn't know something (a known unknown), you wouldn't do a big deployment — you'd research it first and move it into known knowns
- The trigger of any major outage is, by definition, something nobody anticipated
- Therefore: controls designed after an incident are unlikely to prevent the *next* incident, because the next one will come from a different unknown unknown

---

## 3. Risk Management Theatre — The Wrong Response

### What It Is

The typical management response to outages: "We followed all the processes and something still went wrong → add more process." This creates a vicious feedback cycle.

### The Feedback Loop (DORA / State of DevOps 2017 data)

Compared to high-performing companies, low-performing companies engaged in risk management theatre have:

| Metric | Impact |
|--------|--------|
| **Lead time** | 440x longer |
| **Deployment frequency** | Much lower (each change must be 46x bigger to keep pace) |
| **Change failure rate** | 5x more likely to fail |
| **Recovery time** | 96x longer when things go wrong |

**The cycle:**
1. Outage occurs → more process added → increased lead time
2. Longer lead times → lower deployment frequency
3. Lower frequency → each change must be bigger
4. Bigger changes + less practice → higher failure rate
5. All of the above → when things go wrong, they go wrong bigger → more process added
6. **Repeat**

**Source:** State of DevOps Report, 2017 (when it focused specifically on this effect). Numbers may be slightly dated but the pattern definitively still occurs.

**Key line:** "This basically amounts to getting so many fingerprints on the gun that when it does finally go off, they can't pin it on any one person."

### Loom Avoided This Trap

Loom's response was focused on monitoring and alerting, not adding manual approval gates or process. They didn't add manual steps to the deployment process that don't actually help reduce risk. Credit to them.

---

## 4. The Overmind Thesis — Pre-Mortems Not Post-Mortems

### The Core Argument

1. **You can't rely on engineers maintaining perfect mental models** — Woods' Theorem tells us this is impossible at scale
2. **Post-incident controls are retrospective** — they address the last incident, not the next one
3. **Monitoring catches issues sooner but doesn't prevent them** — the issue has to exist before it can be detected
4. **Pre-mortems / blast radius analysis is the gap** — understanding the potential impact of a change *before* deploying it

### Why Platforms Are the Key

From previous talks:
- Modern platforms know about the application code
- They know about the infrastructure required to run it
- They might host docs, gather metrics, traces, and logs
- **Everything you need for a post-mortem is likely in one place** — probably for the first time
- **If you have enough information to do a post-mortem, you have enough information to build a mental model *before* the change and prevent the issue**
- The thing you don't have is **time** — manually gathering all that data can only be justified when something has gone wrong, not before every single change

### What Overmind Does (For Reference)

- Ingests a Terraform plan and identifies what's changing
- Looks up those items in AWS & Kubernetes in real-time
- Finds dependencies: things that depend on them, and things that depend on *those* things, etc.
- Calculates the **blast radius** — everything that might be affected by the change
- Analyses the blast radius and distils it into **human-readable risks** accounting for:
  - The change being made
  - The current state of target resources in AWS
  - All dependencies and their current state
- In the Loom case (replicated config): Overmind identified the distributions the header policy would affect, showing the full blast radius including metadata from AWS

### The Key Reframe

Don't try to force engineers to maintain a model of the entire system (impossible per Woods' Theorem). Instead: **allow users to build mental models on-the-fly for each change they make** by making dependencies and blast radius visible automatically.

---

## 5. Key Quotes & Data Points

### From the Loom Incident
- **0.18%** of total workspaces potentially impacted
- **42 minutes** undetected before internal staff noticed
- **7 minutes** from alert to initial mitigation
- **27 minutes** from alert to full app shutdown
- **10 days** the change sat in non-production environments without issue
- **1 second** cache window that caused the session leak
- Loom acquired by Atlassian for **~$1 billion**

### From the STELLA Report / Woods
- *"As the complexity of a system increases, the accuracy of any single agent's own model of that system decreases rapidly."* — Woods' Theorem
- *"Each anomaly arose from unanticipated, unappreciated interactions between system components."*
- *"There was no root cause. Instead, the anomalies arose from multiple latent factors that combined to generate a vulnerability."*
- *"The vulnerabilities themselves were present for weeks or months before they played a part."*
- *"The activators were minor events, near-nominal operating conditions, or only slightly off-normal situations."*
- On postmortems: *"Collectively, our skill isn't in having a good model of how the system works, our skill is in being able to update our model efficiently and appropriately."*
- Dark debt: *"Not recognized or recognizable until the anomaly revealed it."*
- Postmortem libraries as *"write-only memory"*
- *"What is below the line is inferred from people's mental models of The System"* — and those models are "sure to be incomplete, buggy, and quickly become stale"

### From DORA / Risk Management Theatre
- **440x** longer lead time for low-performing companies
- **46x** bigger changes required
- **5x** more likely to fail
- **96x** longer recovery time
- Source: State of DevOps Report, 2017

### Dylan's Lines (From Previous Talks)
- *"Getting so many fingerprints on the gun that when it does finally go off, they can't pin it on any one person"*
- *"The beacons were lit"* (re: Loom's incident response)
- *"If you have enough information to do a post-mortem, you have enough information to build a mental model before you make the change"*
- *"The thing you don't have is time"*
- *"I want you to think about how you can allow your users to build new mental models on-the-fly for each change they make, rather than relying on them maintaining a model of the entire app, which we know won't be accurate"*

---

## 6. Previous Talk Structures

### Ignite Talk (Short Format ~5 min)
**File:** `Loom outage ignite script.txt`
**Structure:** Who am I → Who is Loom → The outage story → How it happened (Terraform change, CDN caching) → Why not caught in testing → CloudFront complexity → Loom's response → Overmind's approach → CTA (design partners)

### Webinar (Target: 30 min, currently ~15 min)
**File:** `Webinar script.txt`
**Structure:** Who am I → Loom intro → Outage story → Technical cause → CloudFront complexity demo → Woods' Theorem + STELLA findings → Fundamental surprise / unknown unknowns → Risk management theatre (DORA stats) → Loom's actual response (credit: avoided theatre) → Relevance to audience (platform builders) → Platform thesis → CTA
**Note from file:** "This is coming out to like 15min, where it needs to be 30min. Need to somehow double the length of it"

### Fat Outline (Planning Doc)
**File:** `Fat Outline.txt`
**Includes ROAM analysis:**
- **Readers:** AWS users (won't necessarily be deeply technical)
- **Objective:** Understand that even small changes can cause huge problems if you don't understand implications
- **Action:** Offer to become a design partner
- **Impression:** Expert who can help with their problems

---

## 7. Full Reference List

### Primary Sources — The Loom Incident
- Loom blog post, March 8, 2023 (updated March 10, 2023). Technical incident report by Vinay Hiremath, Co-founder & CTO.
- Hussein Nasser video explanation: https://www.youtube.com/watch?v=iPXLk5Fk1-U
- Overmind blog post: [Loom's nightmare AWS outage and how it might have been prevented](https://overmind.tech/blog/looms-nightmare-aws-outage) (Dylan Ratcliffe, September 17, 2025)

### STELLA Report & Resilience Engineering
- Woods DD. *STELLA: Report from the SNAFUcatchers Workshop on Coping With Complexity.* Columbus, OH: The Ohio State University, 2017. https://snafucatchers.github.io/
- Cook RI (1998). *How Complex Systems Fail.* Chicago: CTL.
- Allspaw J. (2015). *Trade-Offs Under Pressure: Heuristics And Observations Of Teams Resolving Internet Service Outages.* Masters Thesis, Lund University.
- Woods DD, Dekker SWA, Cook RI, Johannesen L, Sarter N. (2010). *Behind Human Error, 2nd Edition.* Ashgate Press.
- Woods DD & Hollnagel E. (2006). *Joint Cognitive Systems: Patterns in Cognitive Systems Engineering.* CRC/Taylor & Francis.
- Lanir Z. (1983). *Fundamental Surprises.* Decision Research.
- Hofstadter DR. (2007). *I am a strange loop.* BasicBooks. (Strange loops concept)
- Cunningham W. (1992). *The WyCash Portfolio Management System.* OOPSLA'92. (Origin of "technical debt" metaphor)
- Fowler M. (2003). *Technical Debt.* martinfowler.com. (Refactoring definition)
- Conway ME. (1968). *How do committees invent?* Datamation 14(5):28-31. (Conway's Law)

### DORA / DevOps Performance
- State of DevOps Report, 2017. (Risk management theatre statistics: 440x lead time, 46x change size, 5x failure rate, 96x recovery time)

### Dark Debt Events Referenced in STELLA
- Knight Capital, August 2012
- AWS, October 2012
- Medstar, April 2015
- NYSE, July 2015
- UAL, July 2015
- Facebook, September 2015
- GitHub, January 2016
- Southwest Airlines, July 2016
- Delta, August 2016
- SSP Pure broking, August 2016

---

*Notes compiled for AGM talk preparation. Module created as a container in the terraform-example repo.*

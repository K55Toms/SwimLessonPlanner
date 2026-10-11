# SwimLessonPlanner

A web application that helps qualified swimming teachers build lesson plans quickly. The plans are aligned with the stages of the **Swim England Learn to Swim Programme** (Stages 1–7).

> **Disclaimer:** SwimLessonPlanner is an independent project. Swim England does not affiliate with, endorse or license it. "Swim England" and "Learn to Swim" belong to their respective owners. The app does not reproduce official scheme material. Teachers enter or paraphrase outcomes in their own words, and plans are *aligned with* the scheme rather than taken from it.

## Who it is for

Qualified swimming teachers planning group lessons. Every plan, including one generated with AI assistance, is a draft. The qualified teacher delivering the lesson stays responsible for checking that it is safe and suitable for their pool, their group and their pool's operating procedures.

## Core features

### 1. Outcome-led planning
- Choose a **stage (1–7)** and the **outcomes** you want to target.
- Get **suggested activities** for each section of the lesson, drawn from:
  - the shared library of plans already built and used by teachers, and
  - AI-generated suggestions (Claude API), saved back into the library.
- Accept, swap or edit any suggestion before you save the plan.

### 2. Standard lesson plan structure
Every plan has the same sections:

| Section | Purpose |
|---|---|
| **Pre-water-entry safety question & talking point** | *Always required.* A safety question to ask the swimmers and a short talking point before anyone enters the water. |
| Stage | Learn to Swim stage (1–7) |
| Outcomes targeted | The outcomes this lesson works towards |
| Warm-up | Entry and warm-up activity |
| Main set | Core teaching activities for the targeted outcomes |
| Contrasting activity | A different skill, for variety and engagement |
| Game | A fun activity that reinforces skills |
| Cool-down | A calm finish and exit |
| Equipment | Kit needed for the session |
| Teaching points | Key coaching cues |
| Differentiation | How to adapt the plan for weaker and stronger swimmers |
| Safety notes | Session-specific hazards and controls |

A plan can't be saved without the pre-water-entry safety question and talking point.

### 3. Lesson delivery log
- Mark a plan as **used**, with the date and the group or class.
- Optionally add **notes on how the lesson went** (what worked, what to change).
- When a teacher chooses to submit them, these notes feed back into the shared library, which improves later suggestions and rankings.

*Out of scope:* tracking individual swimmers' achievements. That stays in the pool's existing tracking software, so the app stores no data about swimmers.

### 4. Term blocks
- Group delivered and planned lessons into a **term block** (for example, a 10-week Stage 3 term).
- Use the delivery log and notes to plan the next lessons in the block.

### 5. Output
- **Mobile-friendly view** for use on a phone or tablet at the poolside.
- **PDF export** for printing.

## Tech stack

| Layer | Choice |
|---|---|
| Front end and API | [Next.js](https://nextjs.org/) |
| Database | Oracle Cloud Infrastructure (OCI) **Autonomous Database (ADB)** |
| AI suggestions | Anthropic Claude API |
| PDF generation | TBD |
| Authentication | TBD |
| Hosting | TBD (OCI is the likely option) |

## Data model (draft)

- **teachers**: account and profile
- **outcomes**: stage-linked outcome descriptions, written in the app's own words
- **activities**: reusable activity library, tagged by stage, outcome and lesson section
- **lesson_plans**: a plan with its stage, targeted outcomes, sections, safety question and talking point
- **lesson_deliveries**: when a plan was used, by whom, and optional notes and whether they were shared
- **term_blocks**: an ordered set of plans and deliveries for a group across a term

## Roadmap

1. Project scaffold (Next.js, ADB connection)
2. Data model and outcome entry for Stages 1–7
3. Plan builder with the required sections and safety gate
4. AI activity suggestions and a shared plan library
5. Mobile view and PDF export
6. Delivery log and notes
7. Term blocks

## Status

Early design. Nothing is built yet.

## Licence

To be decided. See the discussion in the project issues.

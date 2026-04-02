# An Open Letter to Garmin's Product Team
## On the UX Debt Across the Connect IQ Platform and a Concrete Way Forward

**By José Alonso Solís Lemus**  
Senior Software Architect | Garmin Forerunner 970 User  
March 2026

---

I am writing this as someone who switched to Garmin from Apple Watch deliberately. 
The hardware case was clear: battery life, sensor depth, training algorithms, and
the richness of the data backend are genuinely without peer. 
The developments of some key features in Garmin are the products of serious, sustained, 
engineering investment: the Firstbeat Analytics, the training load model, VO2 max estimation, 
Body Battery, show the commitment to hardware and software coexisting and complementing each other. 
This holds across the Forerunner, Fenix, Epix, Venu, and Instinct lines. 

The platform problem I am describing is not specific to a product line but
wherever the Connect IQ SDK is the development surface.

In a few words, the user-facing layer is very frustrating to encounter.

This letter is not a complaint. It is a structured critique from a software professional, with
a concrete proposal attached. I am publishing it openly because I believe it reflects a
systemic problem that deserves public framing, not a support ticket.

---

## I. The Problem Is Architectural, Not Cosmetic

The instinct when reading UX criticism is to think about colours, fonts, and icon sizes. 
That is not what I am describing. The issue I see with the platform is structural: the
information architecture does not seem to have a coherent model, and the UI layer reflects that.
Let me summarise a few points based on my experience, my wife's, and the community response
I have been able to find. 

> Please note: I am taking educated guesses, the problems and symptoms are all there, 
> I'm just trying to provide an explanation to support my proposal.

**There is no information hierarchy.** Weather is accessible from a Glance, from the Controls
menu, from a Connect IQ widget, from within activity forecasting, and as a complication on
certain watch faces. These are not the same data, not styled consistently, and not
cross-referenced. 
It does not look like "multiple entry points to the same feature," but as the same 
concept implemented independently in four different places because there is no canonical data
contract at the platform level. The user pays for this with confusion and the developer pays for
it with duplication.

**The navigation model has no spatial coherence.** The Forerunner 970 manual describes at
least six distinct gestures from the watch face — swipe up, swipe down, button press, button
hold, double press, and palm cover — each revealing a different layer of the OS. There is no
persistent orientation cue. No "you are here." Users cannot build a mental model of the system
because the system does not have one to offer. 
I do not think this is about having too many features, it looks to me that 
features have been added over time without a unifying architecture to absorb them.

**The round screen is treated as a viewport, not a canvas.** The Forerunner 970 has a 1.4-inch
AMOLED display with a 454×454 pixel circular panel. Menus, lists, and data screens render as
vertically-scrolling rectangular rows that clip at the edges. The corners of the screen are
structurally unused. This is not a rendering limitation as the Connect IQ SDK exposes arc and
polygon primitives. 
It seems like a design culture that never made the form factor a first-class constraint. 
Every list that clips at the bezel is a small, visible signal to the user that
the software was not designed for the hardware they are holding.

**Configurability has become a substitute for design.** Garmin's answer to the complexity
problem has historically been to expose more customisation: reorder your Glances, build your
own Controls menu, configure your data screens. But whilst this is a reasonable power-feature,
it reads to me as a design failure when it is the primary mitigation for defaults that do not serve
anyone. Configurability used this way creates what I call configuration debt: users spend
hours constructing workarounds for the OS, then resist every firmware update because their
configuration breaks. 
Power users use their time going around the OS instead of exploiting its features and 
normal users who want simplicity will be deterred, not wanting to spend those hours. 

**The result is a platform that punishes its own users for caring.** 
The people most likely to buy a Forerunner 970 are also the people most likely to eventually 
exhaust their patience with a navigation model they cannot internalise.  
COROS has demonstrated, with a simpler but coherent UI, that this is not an inevitable trade-off 
between feature depth and usability. It is a choice.

<!-- There is no mention of the incomplete Garmin guidelines -->

---

## II. Root Causes

Three structural conditions produce the symptoms above. Fixing the symptoms without addressing
these will yield incremental improvement at best.

**No shared UI component system.** The Connect IQ SDK provides a 2D graphics context: draw
calls, no abstractions. Every developer, including Garmin's own teams, must re-implement menus,
dialogs, progress indicators, and list primitives from scratch. There is no standard menu
widget, no standard dialog, no standard progress bar. The result is what the developer
community has described explicitly on the Connect IQ forums: each app reinvents the same
primitives, inconsistently, under memory pressure. This is an infrastructure gap, 
not a problem in the quality of the developers. 

**No form-factor design language.** Apple Watch has a design system. Android Wear has a design
system. Garmin has a hardware lineup. There is no published specification for how interactive
elements should behave on a circular AMOLED or MIP screen, no radial layout grid, no guidance on
safe-area margins relative to the bezel. 
The inevitable result is a user experience feeling "fragmented and disjointed."
Garmin has in fact published design intent for Confirmations, Toasts, and Progress Bars in their Personality Library
but shipped no code to implement any of it. The gap between documented intent and usable infrastructure has never been closed.

**Feature accumulation without information architecture.** The Forerunner 970's UI, as
described by reviewers, is composed of chunks of the Fenix 8 UI merged with the Forerunner
965's interaction model. Features are ported between platforms; the underlying model is never
rearchitected to accommodate them. Each generation adds surface area, the navigational depth
grows. No generation has dared to simplify the model.

---

## III. The Proposal

I am proposing three specific changes, ordered by implementation cost and impact:

**Proposal 1: Define a circular design language (cost: design investment, zero engineering).**  
Publish a round-device design specification: radial layout grid, safe-area insets,
standard touch target sizes for circular screens, arc-based list behaviour, and AOD
constraints. This costs nothing to ship. It unblocks the entire Connect IQ developer ecosystem
and forces internal consistency across product teams. It is the highest-leverage intervention
on this list.

**Proposal 2: Introduce a shared Connect IQ component library (cost: medium engineering).**  
A standard set of Monkey C UI primitives: circular menus, arc-bounded lists, dialogs, progress
indicators, and toast notifications, designed for round screens with dual input support (touch
and buttons), with a shape-agnostic architecture that extends to square and semi-octagon devices.
This removes the "reinvent from scratch" burden from every developer across the entire Connect IQ
device family and creates the visual consistency that a design language specification alone cannot
enforce. 

To demonstrate feasibility, I am building an open-source prototype of exactly this:
*IQKit*, a Monkey C component library targeting round-screen Garmin devices in Phase 1, with
all other screen shapes as planned extensions. The specification is published separately and
linked at the end of this letter.

**Proposal 3: Establish a canonical data model for system-level concepts (cost: high engineering, high impact).**  
Things like Weather, heart rate, training status, Body Battery should each have one canonical
representation in the OS, accessible from any context: Glance, watch face complication,
activity data field, and Connect IQ app. The current state, where the same concept is
implemented in multiple disconnected places, is a platform architecture problem that leaks
directly into the user experience. This is the hardest change on this list and likely the
most valuable.

---

## IV. What I Am Asking For

Specifically:

1. A public commitment to a Garmin unified design language, starting with the circular design, 
   even a versioned draft published to the developer portal would change the trajectory of the 
   Connect IQ ecosystem.

2. An official response to the component library gap acknowledged in the Connect IQ developer
   forums. The community has identified this clearly. It deserves an official position.

3. A feedback channel for architectural proposals that is not a support ticket or a forum post.
   Garmin has a sophisticated developer ecosystem. It would benefit from a structured path for
   substantive UX proposals.

I am not asking Garmin to adopt *IQKit*. I am asking Garmin to acknowledge the gap it
addresses and consider what a first-party version of it would look like.

---

## V. Closing

Garmin makes hardware and algorithms that I am genuinely glad exist. The Forerunner 970 is
remarkable engineering. It deserves software that is worthy of it.

The gap between what Garmin's sensors can perceive and what the platform lets users access
cleanly is the most consequential product problem Garmin has. In my opinion, it is
entirely solvable by building the architectural foundation that makes defaults good enough 
that most users never need to open Settings at all.

I am publishing this letter alongside a user-facing companion piece and the *IQKit* library
specification. I welcome engagement from the Garmin product and developer relations teams.

---

**José Alonso Solís Lemus**  
GitHub: [IQKit](https://github.com/alonsoJASL/IQKit)
[*IQKit* specification](spec.md)
March 2026
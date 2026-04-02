# Garmin's UX Problem Is Not What You Think It Is
## A diagnosis, a comparison, and what you can actually do about it

**By José Alonso Solís Lemus**  
March 2026

---

I spent six years on the same Apple Watch (Series 6). 
Then I switched to a Garmin Forerunner 970 because the hardware case is overwhelming:
Battery life measured in weeks, excellent sensors, the potential of training algorithms 
backed by exercise science, GPS that locks in seconds outdoors.

Within a week of daily use, I had opened the settings menu thirty-four times. 
I know because I counted.

That number is not a sign that I am a curious power user exploring a new platform. It is a
symptom of a platform that has mistaken customisation for design. And there is a meaningful
difference between the two.

This is not a complaint that my Garmin doesn't have 'Smart Watch' features, 
I can understand the distinction. Instead, this is a view, from a software developer's 
point of view, that Garmin made bad software decisions and to propose a way they might be 
able to fix them. If they wanted to.


---

## The real problem is not that Garmin is complicated

Garmin is complicated, but that is not the problem. The problem is that it is complicated in
ways that do not pay off. You do not navigate the watch's menus and emerge with a
system tuned precisely to how your mind works. 
You navigate them and emerge with a system that is slightly less wrong than the defaults,
hopefully the next firmware update won't reset something, forcing you to start again.

This is what I call configuration debt. You invest hours building workarounds for an OS
that did not make good choices by default. Then you defend those workarounds against every
update, because the system has no stable model you can rely on. 

I don't think power users want an OS that lets them configure everything. 
In my experience, they want an OS whose defaults are correct, and whose configuration 
options exist to handle their genuine edge case or use case. 
Users (power or not) should never have to compensate for decisions the design team never made.

---

## Five things that are actually wrong (not just unfamiliar)

These are specific, structural failures, not the learning curve of a new platform.

**1. Six ways to navigate from the same screen.**  
From the watch face: swipe up for Glances, swipe down for notifications, button press for
activities, button hold for the main menu, double press for the flashlight, palm cover to dim.
None of these are labelled. None of them share a visual metaphor. 
There is no persistent cue that tells you where you are in the OS. 
This reads like a navigation model that was assembled over many years without a coherent map.

**2. The same information lives in multiple unconnected places.**  
Weather is available as a Glance, in the Controls menu, as a Connect IQ widget, and inside
activity weather forecasting. These are not the same data. They are not styled the same way.
They are not aware of each other. Ask the watch what the weather is, and the answer depends
entirely on which path you took to get there. This reflects a platform with no concept of a
canonical data source — where the same feature was built multiple times, by different teams,
at different points in time.

**3. Round hardware, rectangular soul.**  
The Forerunner 970 has a circular AMOLED screen. Every list, every menu, every data screen
is a rectangle (or trapezoid, heaven help me) scrolling behind a circular window. 
Content clips at the edges. 
The corners of the screen are unused. 
Know that this is not a technical constraint, the rendering API supports arcs and curves. 
It is a design culture that never asked what a list should look like on a round screen. 
The clipping is a constant reminder to the user that the software was not designed for 
the hardware in their hand. 

**4. There is no app model.**  
On a phone, you understand what an app is. It has a name, an icon, a purpose. You open it,
you use it, you close it. Garmin has Glances (passive, read-only), Activities (locked to
workout mode), and Connect IQ apps (third-party, inconsistent). 
A sports watch might not need the concept of 'apps', but what it does need is a persistent
foreground application model for everyday-use features. 
Outside of activities, there is no coherent mental model for "how do I quickly do the thing 
I want to do."

**5. The Connect IQ store reflects the platform's infrastructure problem, not just bad apps.**  
Third-party Garmin apps are inconsistent in quality, interaction, and visual language because
developers are given no shared components. Every developer, including Garmin's own teams,
must build menus, dialogs, and lists from scratch, in a constrained memory environment, using
a low-level drawing API. 
The inconsistency you might have seen in the store is a direct consequence of having no standard 
building blocks. Every app reinvents the same wheel, differently.

---

## COROS does not have this problem

This matters because the obvious defence of Garmin's UX is "sports watches are just like
this." They are not.

COROS, one Garmin's most serious competitor in the endurance segment, has a simpler watch UI.
Reviewers consistently describe it as "logical, quick to learn, and simple to use." 
Their companion app received a full redesign in July 2025 including crisper icons, faster navigation,
streamlined layout. They update it iteratively and publicly. Their customisation model is
intentional: you can rearrange your daily data, toolbox, and menus. 
It makes sense because athlete preferences genuinely vary.

Now, COROS has fewer features than Garmin. That is a real trade-off. But the existence of a simpler,
coherent UI at comparable hardware quality proves that the complexity of Garmin's platform is
a choice, not an inevitability.

Having come out of a long research to decide which sportswatch to get I can tell you this: 
Garmin's sensor data and training algorithms are meaningfully better. 
COROS's user-facing software is meaningfully more coherent. Neither company has solved the full problem.

---

## What you can do right now

The OS navigation model is not hackable. You cannot replace Garmin's menus or restructure
the Glance system. But you can reduce the friction in the areas you touch most.

**Trim your Glances list ruthlessly.** The default Glances list includes everything Garmin
thinks someone might want. Remove everything you have not used in two weeks. You cannot fix
the navigation depth, but you can reduce the number of stops along the way.

**Use the Controls menu as your command bar.** 
Hold the button from the watch face, in my case this is the LIGHT button, this is
the closest thing Garmin has to a fast-access layer. Customise it to contain only what you
trigger most that doesn't need a shortcut. Everything else belongs elsewhere.

<!-- **Bypass Garmin Connect for activity data.** Plug the watch via USB. Your activities live in
`/GARMIN/ACTIVITY/` as FIT files. You can upload these directly to Strava, sync to
TrainingPeaks, or process them yourself. Garmin Connect is not the only path to your data,
and for users frustrated with the app, this is a meaningful alternative. -->

**For the round-screen problem — there is a longer-term option.** 
A small open-source project called *IQKit* is in early development: 
a Monkey C component library specifically designed for Garmin's circular devices, but 
intended as a first approach to a unified design language. 
It provides curved list rendering, radial menus, and arc-based progress indicators. 
These are components designed for a round screen, not retrofitted onto one. 
It is not a watch face. It is infrastructure for anyone building on Connect IQ.
A reference watch face and a canonical data dashboard widget are part of the planned
deliverables. Details in the linked spec.

---

## What I think Garmin should do

A full architectural proposal is in the companion letter addressed to Garmin's product team.
The short version:

Garmin needs a universal design language, which starts with circular design. 
This would be a document with a specification for how interactive
elements behave on round screens. It needs a shared component library so that developers
stop reinventing primitives and start building features. And it needs to acknowledge that
"you can configure it" is not a substitute for "the defaults are good."

None of this requires abandoning what makes Garmin worth buying. The sensors are not the
problem. The algorithms are not the problem. The training models are not the problem.
The problem is that fifteen years of accumulated features have never been given a coherent
platform to stand on. That platform is buildable. It just has not been built.

---

## If you have a Garmin watch and you feel this too

The most useful thing you can do is say so specifically, structurally, and publicly.
Garmin product teams read DC Rainmaker's comment sections, the r/Garmin and r/running
communities, and the Connect IQ developer forums. Vague frustration is easy to dismiss.
Named, specific UX failures with proposed alternatives are not.

The five failure modes above are a starting point. Your own experience will have others.
Name them.

---

**José Alonso Solís Lemus**  
GitHub: [IQKit](https://github.com/alonsoJASL/IQKit)
[*IQKit* library specification](spec.md)
[Companion letter to Garmin](letter-garmin.md)
March 2026
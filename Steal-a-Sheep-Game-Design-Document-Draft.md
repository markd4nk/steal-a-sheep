# Steal a Sheep Game Design Document Draft

## Game vision

**Draft v0.3 • October 5, 2026 • Roblox MVP design**

Steal a Sheep is a climbing, sliding, collecting, and passive-income game set on a mountain leading to Olympus. Players train on a stair walker to climb steeper routes and carry heavier sheep with less slowdown. They steal a lamb from a god’s pasture, lift it overhead, and aim a downhill slide to escape or knock back players climbing up. At their plot, sheep earn coins and grow into larger adults. Coins fund better stair walkers, trails, and pen capacity. Each level offers three stages: reach its pasture, escape with Light sheep, then reliably bring heavier sheep home. Build this using as much of the existing Shear a Sheep UI, visual style, models, and working systems as possible.

**The player promise:** “I stole Zeus’s sheep, barely escaped, and now it is the biggest earner in my pen.”

This document is intended as a first implementation brief for the builder or coding agent. It covers the requested twelve-god prototype and the supporting systems needed to make the loop playable. All Steal a Sheep values and rules below are **proposed prototype settings**, not measurements from Steal an Egg.

### Concept and presentation

**Genre and audience:** a third-person collection simulator with climbing, sliding, and short competitive encounters. Design for players who enjoy building a valuable flock and improving their runs, with touch controls treated as a first-class input.

**Player role:** a mischievous mortal shepherd stealing divine lambs. The intended emotional sequence is temptation at a pasture, excitement during the downhill escape, relief at delivery, and pride in the flock.

**Distinctive promise:** train to climb steeper parts of Olympus, steal from a god, and aim a downhill slide past or into other climbers while carrying a sheep. The gods, sheep, and physical encounters should explain the fantasy without a long introduction.

**Presentation:** retain the existing sheep game’s chunky cartoon assets, UI style, readable silhouettes, and feedback. Olympus changes the world theme and content, not the established interface design. Team size and delivery dates remain unset until the actual reusable systems and movement prototype have been inspected.

### Existing work and constraints

- **User supplied:** the mountain map and player pens are already built.

- **User supplied:** sheep models can be reused from Shear a Sheep.

- **Required:** twelve primitive Olympus gods, sheep on every level, overhead carrying, aimed downhill sliding with knockback against uphill players, a stair walker that improves climbing ability, plot income, shop, and merging. Keep the Sheepdex a standard MVP collection screen.

- **Theft target:** gods in the MVP. Player interaction includes competing for wild sheep and hitting uphill players with a downhill slide. Stealing another player’s banked flock or carried sheep remains outside the MVP.

- **Reuse is the default:** inspect the existing Shear a Sheep UI, scripts, pens, models, and animations before creating replacements. The supplied documents describe candidates; the current implementation, dimensions, ownership permissions, and plot count have not yet been inspected.

### Design priorities

1. **The escape is the main action.** Climbing to a tempting sheep and sliding home with a god behind you should be enjoyable before the economy is expanded.

2. **Each level offers three steps of progress.** Reach its pasture, learn to escape with Light sheep, then train until heavier sheep are reliable targets. Show the next useful target in the existing UI.

3. **The plot shows progress.** A larger flock, growing sheep, and better equipment make upgrades readable.

4. **One system serves all twelve levels.** Share climbing, sliding, chase behavior, UI components, and animations. Change configuration and appearance between gods; bespoke boss encounters are later work.

5. **Immediate reward plus anticipation.** A delivered lamb earns immediately; adulthood reveals its final size and full earning power.

### MVP scope boundary

| Required for the complete MVP | After the core loop proves itself |
| --- | --- |
| Existing mountain and plots wired into gameplay | Additional maps and gods |
| Twelve themed god placeholders with shared pursuit behavior | Twelve unique attacks and combat |
| Twelve sheep families using reused models | Breeding and genetics |
| Climb, pickup, aimed slide, player knockback, chase, delivery, income, growth | Player plot raiding and base shields |
| Stair walker upgrades, trails, pen slots, inventory | Trading, gifting, auctions |
| Deterministic three-sheep merging and selling | Random fusion and complex mutations |
| Standard Sheepdex, tutorial, basic offline earnings, saving | Bespoke god collection tracks, quests, seasonal events |
| Reused sheep-game UI and visual style with necessary additions | Full UI redesign |
| Mobile, desktop, and controller interaction | Rebirth and premium progression |

**Completion target:** a player can start with nothing, collect and improve a flock, reach every god through earned progression, and rejoin with progress intact. A three-level slice is a development milestone; it does not replace the requested twelve-level MVP.

## Reference research

### Correct reference and confidence

The intended reference is **Steal An Egg by and Collect Rare Pets**, Roblox place **107778070777162**. Its official description confirms stealing eggs from pets and players, hatching, pet earnings, base and treadmill upgrades, treadmill Speed training, sizes, and mutations. [Official Roblox experience](https://www.roblox.com/games/107778070777162/Steal-An-Egg)

Research was conducted through public pages on October 5, 2026. This is a systems survey, not a live playtest or exhaustive audit of the current game. Similar titles and changing updates make exact numbers especially unreliable. The official description establishes the foundation; guides support the secondary systems with lower confidence.

### Reference systems translated into this game

| Reference finding and evidence | Steal a Sheep adaptation | Delivery |
| --- | --- | --- |
| Steal, hatch, earn, train, upgrade; officially described | Train on stair walker, climb steeper slopes, steal lamb, slide home, earn and grow | MVP |
| Stealing from other players; officially described | Shared sheep competition and slide knockback now; direct player theft later | Partial MVP |
| Sizes and mutations; officially described | Adult size reveal now; one cosmetic blessing layer later | Size in MVP |
| Guardians, pens, and trails reported in the overview | Gods pursue thieves; existing pens hold earners; trails improve training | MVP |
| Carry slowdown, Equip Best, Index rewards, offline earnings, and rare spawn announcements reported by guides | Weight tradeoff, automatic roster sorting, standard Sheepdex, capped offline credit, rare lamb alerts | MVP |
| Three-input fusion reported, but its exact outcome rules conflict | Explicit guaranteed merge with a preview | MVP |
| Sell shop and paid speed/pass products reported | Coin shop and sheep selling now; monetization separately balanced | Coin systems in MVP |
| Rebirth reported by some guides but not established by official description | No dependency on rebirth | Later |
| Rift bosses and event shops reported in later guides | Reserve for future Olympus events | Later |

The guardian, pen, and trail summary comes from [BloxInformer’s overview](https://bloxinformer.com/wikis/steal-an-egg/). Supporting activities, inventory convenience, carrying penalties, and event systems are guide-reported in [AllThingsHow’s progression guide](https://allthings.how/steal-an-egg-how-to-get-more-money-fast-in-roblox/). Selling and premium-store categories are reported by the [community shop guide](https://www.stealanegg-wiki.online/shop). None of their prices or formulas is adopted as a design requirement.

### Conflicts that affect the design

**Fusion:** one community guide describes free, immediate fusion and guaranteed improvement. A more recent page, updated October 4, documents a claimed three-Scorpion transaction with a fee, an egg output, and a smaller eventual pet. These sources disagree materially; the MVP should not inherit a supposed guarantee from a guide. Our guaranteed merge is an intentional design choice. [Earlier fusion description](https://steal-an-egg.robloxgameswiki.com/guide/fusion), [recent documented transaction](https://stealanegg.app/guides/pet-fusion/)

**Rebirth:** BloxInformer describes it, while a separate reference explicitly marks it unverified for this experience. Treat its presence and reset rules as unresolved until observed in the correct live game. [BloxInformer](https://bloxinformer.com/wikis/steal-an-egg/), [rebirth verification caveat](https://stealanegg.app/guides/rebirth/)

**Treadmills and trails:** the training loop is clear, but published unlock costs and multiplier explanations vary. For example, one guide describes a free starting treadmill while another lists a purchase requirement. The sheep game therefore defines its own unlock, training rate, and single-trail rule. [GAMES.GG treadmill guide](https://games.gg/roblox/guides/steal-an-egg-best-treadmills-ranked/), [AllThingsHow](https://allthings.how/steal-an-egg-how-to-get-more-money-fast-in-roblox/)

**Progression research:** the first four commonly reported Steal An Egg milestones are starter, 900, 10,000, and 40,000 Speed. That implies an approximately 11.1× jump from Lake to Desert, followed by 4× to Jungle. Carrying a larger egg can still prevent escape at a listed milestone. These are reported reference values, not verified guardian-speed constants. [Beebom biome guide](https://beebom.com/all-steal-an-egg-biomes/), [Eldorado progression guide](https://www.eldorado.gg/blog/steal-an-egg/steal-an-egg-biomes-and-speed-requirements/)

**Adopted direction:** use the reference’s escalating progression and within-level carrying tradeoff, with our own scale and timing. The three-stage structure below is our design interpretation, approved by the user; it is not a claim that the reference explicitly uses three unlocks. Its commercial success does not establish the optimum thresholds or training time for this mountain. Treat listed reference Speed as a planning milestone, not proof of a hard entry barrier; a documented Lake sign says “900 recommended.” [Gameplay evidence and qualification](https://pixeltwelve.com/articles/steal-an-egg-beginner-guide-pets-money-speed)

### What the reference contributes

The useful pattern is a connected set of decisions: improve income per animal, increase the number of earners, improve training, and attempt a more valuable target. Growth provides anticipation; duplicates feed an upgrade system; unusual sizes create memorable collection goals.

For this adaptation, the mountain replaces successive biomes, gods replace animal guardians, and visible lamb growth replaces hatching. Stair walkers replace treadmill training: increased Climb Power opens steeper ascent routes and reduces carrying slowdown relative to the stolen sheep’s source tier. Sliding becomes the return-trip action. The final adult size preserves surprise without hiding which sheep family was stolen.

### Remaining reference checks

Before pursuing closer feature parity, record a current live session covering the tutorial, treadmill panel, trail panel, pen upgrades, fusion preview and result, sell price, offline claim, and player stealing. This would resolve implementation fidelity questions, but it is not required to build the explicitly specified sheep prototype.

## Core gameplay

### Main loop

**Train on the stair walker → climb a steeper route → steal a lamb → aim and slide downhill → dodge or knock back uphill players → deliver → earn and grow → upgrade.**

The short loop is one successful escape. Within a level, players progress from reaching its pasture, to successful Light-sheep runs, to reliable heavier-sheep runs. The session loop is choosing between improving those runs and opening the next level. The longer collection loop is obtaining every god’s sheep, larger adults, and merged versions.

### A single theft

1. Walk up an accessible slope into an unlocked mountain level and approach a wild sheep.

2. Reuse the existing sheep inspection card. Lead with sheep name, earning potential, and carrying burden; show rarity and size detail in the existing detail view. Before adulthood, exact final size remains hidden.

3. Hold Interact for 0.5 seconds. The server reserves that sheep for the successful claimant and attaches its visual above the avatar’s head.

4. Display “[God] wants their sheep back!” and a home-direction arrow. Give a 1.5-second head start. Near the descent, the contextual instruction becomes “Slide home!”

5. Move onto a marked downhill route to enter a steerable slide automatically. The sheep stays overhead. The god pursues along that route; carrying burden reduces acceleration and slide speed, with less slowdown as Climb Power improves relative to that sheep’s source tier. Flat sections return to normal carrying movement. Aim toward an open lane or an uphill player; a valid hit knocks that player back and costs some slide momentum. Hitting another player does not secure the sheep or end the god chase.

6. Crossing the foothill safety line ends the chase. The player still carries the sheep to their own delivery pad.

7. Delivery grants permanent ownership once, fills an empty pen slot if available, starts growth if equipped, and begins income immediately.

8. Show the new flock income and a useful next action: another sheep, a pen slot, training, or the next level.

### Ownership and failure rules

| Situation | Exact MVP result |
| --- | --- |
| Two players claim the same wild sheep | First valid server claim wins; the other gets a clear unavailable message |
| Player already carries a sheep | Reject a second pickup |
| God catches the carrier | Return the wild sheep to its spawn; respawn player at the foothills; retain all previously banked progress |
| Death, reset, or disconnect before delivery | No ownership granted; sheep returns to its source |
| Player abandons the run | “Return sheep” sends it home; no free world-drop object |
| Carrying player crosses the safety line | God stops pursuit; cargo remains temporary until delivered |
| Wrong plot delivery | Reject and point to the owner’s plot |
| Pen is full, inventory has space | Deliver to storage; clearly show “Stored — not earning” |
| Inventory is full | Prevent pickup before a run and direct the player to merge or sell |
| Delivery and catch occur almost together | One authoritative event wins; never both award and respawn the same sheep |

A wild sheep grants no income before delivery. Carrying blocks fast travel, stair walker training, merging, and selling. A teleport or out-of-bounds recovery during a run cancels the theft, preventing free deliveries.

### Shared god behavior

Use one reusable state machine: **Idle → Alert → Chase → Catch or Disengage → Return**. Each god has a home position, patrol area, route navigation, speed, and catch distance. All twelve use this behavior in the primitive version.

There is one active god per level. Maintain a list of carriers who stole from that level; target the nearest eligible carrier, with a short target lock to prevent constant switching. When that carrier escapes or loses the sheep, choose the next. Ignore players carrying sheep from another level. This allows simple social distraction without requiring combat.

Pursuit continues along the descent route to the foothill safety line, across tier boundaries. Give gods a shared slope-following chase mode so a normal walking NPC is not automatically left behind by every slide. Tune pursuit against the slide controller, including braking and flat sections. A returning god is harmless until it has a valid target again. If navigation becomes stuck, reposition to a valid route node outside the player’s catch radius with a visible effect; never teleport directly onto a player.

Prototype tuning: catch within roughly 3 studs of valid path proximity, checked server-side with obstruction checks so gods cannot catch through walls. Tune range and head start on touch controls. Use knockback and a funny angry reaction instead of a health or combat system.

### Climbing and downhill sliding

Climb Power represents the ability to ascend increasingly steep marked routes. Each tier’s ascent has a configured slope grade and minimum Climb Power. Higher training unlocks higher grades and reduces the slowdown from carrying sheep. The same stat supports ascent access and escape readiness; it does not increase empty-handed speed without limit. Treat the twelve entry values as progression seeds, not literal angles. Measure the existing terrain before assigning the final grade-to-angle mapping; do not rebuild the mountain just to match invented degree values.

Use the existing roads and ramps. For the MVP, entering a marked descent while moving downhill automatically starts a slide, with or without a sheep. Aim the initial downhill heading with the camera/movement direction, then steer left or right with normal movement controls; pulling back brakes. Constrain direction to the downhill corridor so a slide cannot become an uphill dash. Stop on flat ground, when grounded speed falls below the slide threshold, or at the safe-zone runout. Mouse/keyboard, thumbstick, and touch movement must all support deliberate aiming without a required precision reticle. No sled, stamina bar, charge meter, trick system, or mandatory extra button is needed.

A short scenery collision slows the slide; it does not destroy a banked sheep or instantly fail the theft. Falling out of bounds or resetting while carrying uses the normal failed-run rule. Landing back on a valid descent resumes movement without a free boost. Jumping, side paths, and carried momentum must not bypass an uphill requirement. Use forgiving route edges and a gradual runout before the pens; crossing the safety line ends the chase and reduces the slide to a controlled stop, after which the player walks to their delivery pad. Keep the sheep and home direction visible on touch screens. Target first-tier round trips of 20–40 seconds and unlocked high-tier trips of roughly 60–100 seconds, then measure. Shorten dull connecting sections if needed; no outbound lift in the MVP, since climbing is now part of its identity.

### Aimed slide collisions

**User-confirmed mechanic:** a player sliding downhill can aim at and hit another player walking uphill, knocking that player back. This is light physical competition inside the escape loop. There is no combat health, weapon, kill reward, or transfer of sheep ownership.

**Eligible hit:** the attacker is actively sliding downhill on a marked mountain route above a minimum impact speed. The target is grounded and walking uphill or actively climbing that shared route. Both must be outside the foothill safe zone and neither can have tutorial or recovery protection. Idle players, other sliders, and players moving downhill are not targets in the first version. Normal walking contacts and ineligible contacts do not shove or physically block other players.

**Aiming and steering:** aim the entry heading before taking the descent, then make bounded steering corrections during the slide. Climbing players must be able to see or hear an approaching slider and sidestep. Keep shared routes wide enough to pass; inspect current bottlenecks and adjust only what prevents fair encounters. No new aim menu is required. If a direction cue is needed, reuse the existing world-arrow or targeting style.

**Proposed impact settings:** knock the uphill player roughly 6–8 studs back down the slope, keeping them on the walkable corridor; briefly interrupt climbing for about 0.5 seconds, then restore control. Displace along the slope rather than launching them vertically or off a cliff. Give the victim two seconds of protection from further slide hits, visibly indicated with reused character feedback. A single contact can trigger only one hit, and the attacker must separate before a future hit is eligible. Test and adjust these values for touch controls and network delay.

**Attacker tradeoff:** a successful hit reduces current slide speed by about 20%; the normal acceleration then resumes. Missing gives no bonus. The god continues chasing. Players can choose the safer clear line or spend momentum to knock someone back; there are no coin rewards, combo bonuses, or tasks for farming hits in the MVP.

**Recovery and protection:** keep the first tutorial theft and its descent protected from player hits until delivery or tutorial-run failure. All plot and foothill safe zones disable slide hits. Target protection persists through continuing contact and cannot be canceled by the attacker. Knockback does not remove money, training, unlocks, or sheep. If the target happens to carry a sheep, they retain it; a separate subsequent god catch still follows ordinary failure rules.

**Authority and verification:** the server validates slide state, direction, relative positions, route membership, speed threshold, obstruction, and target eligibility. Check movement between updates so a fast slide cannot skip a player, but never award a hit through terrain. Use a controlled movement response instead of unconstrained physics flinging. Repeated client requests, overlapping contacts, and simultaneous attackers must respect the same recovery window.

**Acceptance:** two players can repeatedly reproduce a hit, a miss, a sidestep, and a safe-zone no-hit. One slider cannot chain-stun a climber; two sliders cannot bypass recovery protection; neither hits nor misses grant ascent access or duplicate sheep. The same mechanic works while carrying and while empty-handed.

### First session

| Elapsed target | Player experience |
| --- | --- |
| First 5–10 seconds | Plot assigned; first lamb and god visible; one clear pickup objective |
| By 15–30 seconds | First sheep stolen and pursuit started |
| By 45–60 seconds | First slide completed; lamb delivered and earning |
| By 2–3 minutes | First adult reveal and stair walker purchase or upgrade |
| By 5–8 minutes | Steeper second route reached; understands why training matters |
| By 15 minutes | Several sheep, a pen decision, and progress toward a first merge |

These are proposed playtest targets, not measured outcomes. The tutorial provides a Light, ordinary Demeter lamb protected from spawn competition, with a forgiving chase and 30-second growth. After first delivery, grant a one-time 60-coin tutorial reward and 25 Climb Power. Show only the immediate objective and essential HUD at first. Introduce the stair walker after delivery, then Equip Best and merging when relevant. Keep shop offers out of the opening theft.

## Olympus progression

### Twelve levels

This is a proposed game order, not a ranking of mythological power. The roster uses Dionysus for the twelfth Olympian slot alongside the other listed gods. Zeus occupies the summit. Hades can be an underworld expansion.

Climb Power is one accumulated training score used for ascent access and carrying readiness. It is not literal walking speed or a number of degrees. The values below are proposed reach thresholds; Light and Heavy escape targets are derived separately. Actual slope angles must come from a map audit. Base income means an ordinary adult of standard size before merges.

| Tier | God and mountain area | Sheep family and primitive visual | Reach threshold | Base coins per second |
| --- | --- | --- | --- | --- |
| 1 | Demeter — foothill meadow | Meadow Sheep; wheat-colored wool | 0 | 2 |
| 2 | Dionysus — vineyard terraces | Grape Sheep; purple wool and leaf | 100 | 5 |
| 3 | Hermes — wind path | Wingfoot Sheep; tiny ankle wings | 800 | 13 |
| 4 | Aphrodite — rose garden | Rose Sheep; pink wool and flower | 3,200 | 31 |
| 5 | Hephaestus — forge ledge | Ember Sheep; charcoal wool and orange seams | 12,800 | 78 |
| 6 | Ares — redstone pass | War Sheep; red wool and small helmet | 51,200 | 195 |
| 7 | Artemis — moonlit grove | Moon Sheep; silver wool and crescent | 180,000 | 488 |
| 8 | Apollo — sun terrace | Sun Sheep; golden wool and sun disc | 720,000 | 1,221 |
| 9 | Athena — marble steps | Laurel Sheep; white wool and wreath | 2,900,000 | 3,052 |
| 10 | Poseidon — cloudwater falls | Tide Sheep; blue wool and foam crest | 9,000,000 | 7,629 |
| 11 | Hera — royal courtyard | Crown Sheep; ivory wool and purple crown | 27,000,000 | 19,073 |
| 12 | Zeus — Olympus summit | Thunder Sheep; white wool and lightning horns | 81,000,000 | 47,684 |

Base income seed formula: **round(2 × 2.5^(tier − 1))**. Keep the source formula and displayed table synchronized.

### Three stages within each level

The user-approved progression direction is **reach → escape with Light sheep → reliably bring heavier sheep home**. Reaching the pasture is a hard ascent unlock in this adaptation. The two escape targets are recommendations, not pickup restrictions or guaranteed wins. Players may attempt any burden in an accessible pasture; skill, head start, route choice, and other players still affect the result.

For tiers 2–12, use proposed Light readiness at **1.50× the reach threshold** and Heavy readiness at **2.25×**. Demeter is the introductory exception: reach at 0, Light readiness at 25, Heavy readiness at 60. Its protected first Light theft must remain winnable at zero training. These multipliers are new prototype choices, not extracted Steal An Egg formulas.

| God | Reach pasture | Light escape target | Heavy escape target |
| --- | --- | --- | --- |
| Demeter | 0 | 25 | 60 |
| Dionysus | 100 | 150 | 225 |
| Hermes | 800 | 1,200 | 1,800 |
| Aphrodite | 3,200 | 4,800 | 7,200 |
| Hephaestus | 12,800 | 19,200 | 28,800 |
| Ares | 51,200 | 76,800 | 115,200 |
| Artemis | 180,000 | 270,000 | 405,000 |
| Apollo | 720,000 | 1,080,000 | 1,620,000 |
| Athena | 2,900,000 | 4,350,000 | 6,525,000 |
| Poseidon | 9,000,000 | 13,500,000 | 20,250,000 |
| Hera | 27,000,000 | 40,500,000 | 60,750,000 |
| Zeus | 81,000,000 | 121,500,000 | 182,250,000 |

The proposed reach curve gives the second level a small initial target, then an 8× step into tier 3, mostly 3–4× steps through the mountain, and roughly 3× late steps. It borrows the broad scaling pattern without reproducing the reference’s numbers or its most extreme late jump. Light-to-Heavy mastery happens inside each tier before the next reach target. Mastery is optional: one successful delivery plus enough Climb Power can open the next ascent.

A larger displayed requirement does not by itself justify a longer wait. Upgrade training gains alongside requirements, then measure time to the next useful milestone. Keep the choice between improving Heavy runs here and pushing onward visible. Store reach thresholds once and derive the readiness targets so UI and gameplay cannot disagree.

Each god needs a readable silhouette, one signature accessory, a nameplate, an idle, a run, and a catch reaction. Reuse one rig and animation set wherever possible. The twelve identities should be recognizable even with simple blocks and flat materials.

Potential later attacks include Ares’s charge, Poseidon’s wave, and Zeus’s telegraphed lightning. They are not required for the MVP and should not delay the shared chase.

### Unlock rules

Each tier’s ascent requires the listed Climb Power and one successful delivery from the preceding tier. Tier 1 is always accessible. Increasing grades should correspond to visibly steeper ascent sections where the existing map supports them. Once unlocked, a route stays unlocked in this version. Insufficient training stops upward progress at a clearly marked boundary or gently slides the player back to its approach; it never traps them. Descent through a locked ascent grade remains possible, but jumping, side entry, or sliding momentum cannot grant access to its pasture.

Reuse the existing locked-upgrade and sheep-card styles. Before access, show “Train to climb this slope” with current and required Climb Power; explain a missing prior-tier delivery separately. After access, show the next relevant target: “Train for Light sheep” or “Train for Heavy sheep.” At Heavy readiness, show “Ready for heavier sheep” and the next ascent goal where available. These are readiness hints, not promises of success. Do not add a new screen or another progression stat.

### Spawn rules

Each level starts with four spawn markers, for a maximum of 48 wild sheep across twelve levels. A successful pickup reserves its marker until delivery or failure. Delivery starts a 15-second refill timer; failure restores that same sheep and its pre-rolled properties. Do not let repeated failed pickups reroll size.

Normal spawn distribution: 80% ordinary fleece, 18% rare fleece, 2% royal fleece. These multiply adult income by 1, 1.5, and 2.5 respectively. The family identifies the god; fleece rarity is a separate field.

Rolling a royal sheep produces a restrained server announcement only for players who have unlocked that tier. No forced global refresh wipes an active carry. The tutorial’s first lamb is provided separately and cannot be taken by another player.

Spawn probabilities are design seeds. Raise supply or add beginner protection if shared competition prevents new players from completing their first runs.

## Sheep and plot systems

### Family, rarity, age, size, and merge rank

Keep these five properties separate. A sheep’s family determines its god and base income. Fleece rarity changes its appearance and income multiplier. Age determines whether it is a lamb or adult. Adult size changes its displayed scale and earnings. Merge rank records an earned upgrade.

Reuse existing Shear a Sheep sheep appearances, shared rig, attachments, and animation controller wherever they exist and work. The supplied specifications describe Idle, Graze, Baa, Walk, Carried, and Startled animations plus Lava, Moon, Storm, Cloud, Dream, and Golden Fleece looks. These are candidates for Olympus families; the roster names are working labels, not instructions to commission twelve new models. Confirm actual implementation before counting anything as complete. Add a player slide pose and adjust overhead clearance only where needed.

### Growth and size reveal

A newly delivered, equipped lamb earns **50% of its family base income × fleece multiplier**, before any size bonus. It grows only while assigned to a pen slot. Growth pauses in storage and resumes when equipped. Growth progresses offline for equipped lambs.

Standard growth duration: **45 + 15 × (tier − 1) seconds**, or 45–210 seconds. The tutorial’s first lamb uses 30 seconds. Adult transformation is automatic, with a brief “Giant!” or “Large!” reveal and updated coins per second; there is no separate hatch button.

Roll and store adult size when the wild sheep is created. Rejoining, unequipping, and failed thefts must not reroll it. Its visible carrying class gives a useful clue:

| Burden class | Spawn chance | Carry multiplier at Reach / Light target / Heavy target | Adult outcome |
| --- | --- | --- | --- |
| Light | 70% | 0.84 / 0.92 / 0.97 | Standard 89%; Large 10%; Giant 1% |
| Stout | 25% | 0.72 / 0.84 / 0.95 | Standard 50%; Large 47%; Giant 3% |
| Heavy | 5% | 0.60 / 0.76 / 0.94 | Large 80%; Giant 20% |

These proposed conditional odds give **74.8% Standard, 22.75% Large, 2.45% Giant** overall. All carrying classes retain a size surprise; heavier lambs have better odds. Size income multipliers remain 1, 1.5, and 2.5, with proposed adult visual scales of 1, 1.35, and 1.7. Carry multipliers improve continuously between the three Climb Power targets using the movement rule below. They affect carrying on foot, target slide speed, and acceleration; braking authority stays constant. Burden is an intrinsic sheep property: training reduces its movement penalty without changing its adult-size roll or earnings.

Example: an ordinary Large Meadow adult earns **2 × 1 × 1.5 = 3 coins/second**; a royal Giant Meadow adult earns **2 × 2.5 × 2.5 = 12.5 coins/second**. Preserve fractional income internally.

Every size takes one earning slot. This keeps huge sheep desirable and avoids punishing lucky growth. Physical pen dimensions limit visual scale, not economic eligibility. If the existing pens cannot fit a 1.7-scale adult, reduce visual scales consistently while retaining size labels and income. Sheep should not physically block players.

### Pen capacity and inventory

Start with three earning slots and a maximum of twelve. Existing unused pen pads can be visibly locked and purchased; do not rebuild the plot solely to represent an upgrade.

Inventory holds 100 owned sheep, including equipped sheep. Reserve one inventory space on pickup, so an accepted delivery cannot fail because the inventory filled during the run. Storage earns nothing and pauses growth.

Offer **Equip Best**, manual equip and unequip, lock, inspect, and sort by income, family, size, or merge rank. Equip Best sorts by current income, preserves manually pinned slots, and uses a stable tie-breaker. Show the lamb’s future income range so players can deliberately raise one instead of always selecting current earners.

### Guaranteed merging

Call the station **Merge Shrine**. It is available after the third successful delivery. It consumes three unlocked adult sheep with the same family, fleece rarity, and merge rank. Different adult sizes are allowed.

- Output keeps the family and fleece rarity, takes the largest input size, and increases merge rank by one.

- Maximum rank is 2: ordinary rank 0, merged rank 1, and ascended rank 2.

- Income multiplier by rank is **1, 3, and 9**.

- No additional coin fee and no random failure in the prototype.

- Output is already adult. No egg or second growth timer is created.

- A short two-second animation ends in an explicit result card.

Adult income formula: **family base × fleece multiplier × size multiplier × 3^mergeRank**.

This guarantees that the output earns at least the combined adult income of the three eligible inputs: three copies share base, fleece, and rank, and the largest size is at least their average. Example: three ordinary Standard Meadow sheep each earning 2 merge into one earning 6. Two earning slots become available.

The preview must show all consumed sheep, the exact output, input total income, output income, and resulting equipped flock income. If any input was equipped, place the output into one vacated slot; the other slots remain empty until filled. If all inputs were stored, keep the output stored.

Locked sheep cannot be merged or sold. Validate ownership and eligibility at confirmation. Consume the three inputs and create the output as one saved transaction; repeated clicks or reconnects must not create duplicates.

### Selling and collection

The Sell Stall pays **15 seconds of the sheep’s current income**, before offline reductions. Show exact proceeds and the reduction in active flock income. Require a confirm step for each selection; never sell the last owned sheep. This provides a small cleanup reward without making quick selling outperform building a flock.

The **Sheepdex** is a standard MVP collection book. Reuse the existing Sheepdex window, card grid, silhouettes, selection details, progress display, and discovery-saving pattern wherever implemented. Replace its dataset with the twelve Olympus sheep families. An entry unlocks on first successful delivery and remains discovered after selling or merging. Show size in the sheep detail card; no separate god mastery trees, size-completion pages, quests, or new progression currency. Each first family delivery gives a one-time coin reward equal to 30 seconds of that family’s standard adult base income; the tutorial reward is separate. Use the existing reward notification. If the inherited UI has mutation tabs, hide unsupported tabs rather than importing the old mutation and rebirth systems.

## Economy and supporting systems

### Coins and Climb Power

Use two visible progression values: **Coins** for purchases and **Climb Power** for training progress. The stair walker raises Climb Power, enabling steeper ascents and reducing sheep-carrying slowdown. Reuse the sheep game’s existing currency and stat widgets with the necessary label and data-binding changes. Coins come from equipped sheep, limited first-discovery rewards, and selling, and buy stair walker tiers, pen slots, and trails. There is no stamina, food upkeep, or additional upgrade currency.

Online income is the sum of equipped sheep’s current rates and credits the wallet automatically. Show both coins and flock coins per second. A decorative trough can display the total, but income does not depend on repeatedly collecting from every sheep.

### Stair walkers

Each plot receives a functional starter stair walker for free. The player steps upward in place on a simple repeating staircase while training grants Climb Power and the flock keeps earning. Leaving stops training immediately. Upgrade tiers increase Climb Power gained per second. Reuse an existing training or upgrade panel; show current gain, next gain, cost, and the next useful reach or carrying-readiness target. The new machine appearance does not require a new UI design.

Proposed base rates for stair walker levels 0–11 are **2, 12, 40, 160, 640, 2,200, 9,000, 36,000, 100,000, 300,000, 900,000, 1,800,000 Climb Power/second**. These replace the prior rate seeds and are paired with the new reach curve. For a pacing check, machine level 0 covers the first climb; levels 1–10 cover the next reach interval in about one minute at base gain if already owned, without a trail. Equipment ownership is purchased, not automatically granted on entering a tier. Level 11 supports summit carrying mastery.

Upgrade from level L to L+1 costs **round(120 × 2.5^L) coins**, for L = 0–10. Levels are bought in order. A functional level does not require a new mesh; reuse the stair walker with material and accent changes.

| Early upgrade | Coin cost | New base training rate |
| --- | --- | --- |
| Level 0 to 1 | 120 | 12 Climb Power/second |
| Level 1 to 2 | 300 | 40 Climb Power/second |
| Level 2 to 3 | 750 | 160 Climb Power/second |
| Level 3 to 4 | 1,875 | 640 Climb Power/second |

Training gain equals **base stair walker rate × equipped trail multiplier × elapsed training seconds**. No gain while disconnected, carrying, or outside the training area. Avoid a required rhythm minigame or media feed; the MVP stair walker needs a clear animation and progress meter.

### Physical movement and chasing

Keep physical movement controllable while training creates a real escape advantage. Start with an empty-handed walking baseline around 18 studs/second and an unlocked-slope ascent pace tuned to route length. Empty-handed slide target speed varies with the configured descent segment, initially about 24–48 studs/second. Climb Power unlocks ascents and reduces carrying penalties; it does not multiply the empty-handed speed. These are prototype settings.

For a carried sheep, use its **source tier** to look up Reach, Light, and Heavy targets. Keep that source tier throughout the return, including lower mountain segments. Linearly interpolate its burden multiplier between the three values in the burden table: below Reach use the first value; from Reach to Light interpolate first to second; from Light to Heavy interpolate second to third; above Heavy cap at the third value. Apply that multiplier to the route segment’s unladen foot or slide target speed and acceleration. Use the player’s authoritative Climb Power; training is blocked while carrying. Never divide by the Reach threshold, since Demeter starts at zero.

Give each god a configured pursuit-speed profile along its entire return route. Initial seed: **0.88× that segment’s unladen player target speed**, with separate foot and slide segments. This yields Light-carrier targets of 0.84, 0.92, and 0.97 times unladen speed across the three stages, while Heavy carriers improve from 0.60 to 0.76 to 0.94. Tune each god’s profile, alert delay, and catch distance against measured travel time. These pursuit settings stay fixed for that god and segment: do not scale them with the current target’s Climb Power, burden, or slowed slide speed. Returning to an earlier god must feel easier after training.

At Reach, a clean Light escape may depend on the head start and a short route; merely reaching a pasture does not promise a successful theft. At the Light target, clean Light escapes should be repeatable. At the Heavy target, Heavy escapes should be repeatable with room for a minor steering error. Training never makes a collision or prolonged braking safe by guarantee. The tutorial overrides pursuit tuning only as needed to make its protected zero-training Light run forgiving. Calibrate every source tier over the complete route, including flat sections and tier transitions.

### Trails and pen upgrades

Trails are purchased through the hub shop. Equip only one at a time; multipliers do not stack. In this design they improve **training gain only**, which is an explicit adaptation and must be stated on the shop card.

| Trail | Cost in coins | Training multiplier |
| --- | --- | --- |
| Dust | 250 | 1.25 |
| Laurel | 2,500 | 1.5 |
| Sunlight | 25,000 | 2 |
| Storm | 250,000 | 3 |

All unlocked trails remain owned and can be equipped freely. Require the previous trail purchase to buy the next one. A new trail changes appearance immediately.

Pen slot n costs **round(300 × 2.5^(n − 4)) coins**, for slots 4–12. First costs: 300, 750, 1,875, and 4,688. Purchase sequentially. Upgrading adds an earning slot rather than increasing every sheep’s output.

Reuse the existing shop cards and upgrade feedback. Explain each purchase directly: “One more sheep can earn,” “Gain 40 Climb Power per second,” or “1.5× climbing training.” Describe Climb Power as “Climb steeper slopes and carry heavier sheep more easily.” Use the same stat widget and show one relevant next milestone rather than adding another currency or meter.

### Offline earnings

On exit, save the equipped roster and each lamb’s remaining growth time. On next join, integrate its juvenile and adult income over **at most two hours**, then credit **25%** of that amount once. Stored sheep earn nothing.

Growth itself may finish over the full elapsed offline time for sheep that were equipped. For earnings, apply the juvenile rate until maturity inside the credited two-hour window and the adult rate afterward. Use server time and a saved claim checkpoint; no client clock or repeated claim can create extra money. A small return summary shows coins earned and sheep that matured.

### Economy checks before release

All prices, rates, odds, and times in this draft are test data. They have not been validated against the existing mountain. Check upgrade affordability against real flock income. Requirements and training rates must be balanced together; the reference’s displayed scale does not establish how long our players should wait.

Targets: first purchase within three minutes; useful early purchases every two to four minutes; short stair walker visits rather than long mandatory waits; fresh sheep noticeably improve income. Measure time to reach a pasture, first Light delivery, and reliable Heavy deliveries separately. No player must finish Heavy readiness to attempt the next unlocked level. The first summit delivery after roughly 60–120 minutes remains only a prototype pacing target and must be retested with climbing and sliding. Reaching Zeus is a major milestone, not proof of sufficient long-term content; use ordinary flock improvement and Sheepdex completion before adding new systems.

A simple check: three ordinary Standard Meadow adults generate 6 coins/second, so a 120-coin stair walker upgrade takes 20 seconds of income once that flock exists. A three-to-one merge keeps those 6 coins/second and opens two slots. These checks establish local consistency, not the full progression duration.

Training arithmetic check without trails: starting at the tutorial’s 25 Climb Power, the free walker at 2/second reaches Dionysus at 100 in 37.5 seconds. With the first upgrade at 12/second, Dionysus Light readiness takes a further 50/12 ≈ 4.2 seconds and Heavy readiness a further 75/12 ≈ 6.3 seconds. The starter carrying stages are deliberately quick. From Dionysus’s 100 reach threshold to Hermes’s 800 is about 58 seconds at that rate. At Hermes, a level 2 walker gives 40/second: Reach to Light takes 10 seconds, then Light to Heavy takes 15 seconds. Each milestone should prompt another theft, not just another pause on the machine. Equipment, trails, and players’ choices change these times; test affordability so upgrades neither erase all three stages nor create long waits. These are training-only calculations; earning coins, travel, theft, and growth add session time.

### Interface and feedback

| Surface | Reuse first | Required adaptation |
| --- | --- | --- |
| Main HUD | Existing currency, income, stat, and navigation widgets | Bind Climb Power and next reach or carrying target |
| Sheep card and inventory | Existing sheep cards, previews, rarity treatments, selection and sorting | Add age, burden, earnings, and readiness hint only where missing |
| Pursuit feedback | Existing warning, notification, and directional prompt components | God name, home arrow, contextual “Slide home” hint |
| Plot panel | Existing pen capacity and upgrade controls | Match earning slots and growth state |
| Stair walker | Existing training or upgrade panel | Machine label, Climb Power gain, cost and next useful target |
| Shop and selling | Existing item cards, purchase buttons, confirmations and feedback | New item data and sheep sale values |
| Merge Shrine | Existing compatible three-item selection flow, if available | Exact input/output and income preview; mutation reels are not a merge flow |
| Sheepdex | Existing collection window, grid, silhouettes, details and progress | Twelve-family dataset; hide unsupported tabs |
| Offline summary and settings | Existing return reward, audio, and settings screens | Correct offline values; add missing accessibility options within the same style |

Keep the sheep game’s established fonts, colors, panel shapes, button hierarchy, icon treatment, rarity colors, spacing, sound cues, and open/close animations. Reuse functional components before making lookalikes. Preserve existing touch sizing and controller focus behavior, checking both after edits. Add only missing information and controls in that same style. Use camera/movement direction to aim and ordinary movement to steer and brake the automatic slide; reserve the context-sensitive Interact action for pickup and stations. Keep HUD and carried sheep clear of the route and touch controls.

Reuse existing sheep bleats, collection sounds, purchase feedback, and notification effects wherever suitable. Add only the missing god alert, slide sound, player slide pose, short impact and knockback feedback, and growth/merge feedback. Keep the chunky sheep-game visual style for primitive gods and equipment. There is no separate sprint meter, slide minigame, or redesigned Olympus menu theme.

### Monetization and retention

The internal MVP has no paid progression requirement. After pacing is validated, consider cosmetic trails, pen themes, and sheep accessories before time-saving products. Premium products need their own specification and purchase validation; none is required to finish this build.

The prototype’s return motivation is an improved flock, a new adult size, the next god, and completing the Sheepdex. Rebirth, daily streaks, limited-time bosses, mutation weather, player raids, and trading remain separate feature proposals.

## MVP build plan

### Asset and map audit

Before implementation, inspect the actual mountain place and source Shear a Sheep project. Inventory each UI screen and reusable component with its current location, behavior, dependencies, and status: reuse unchanged, adapt, or missing. Do the same for sheep rigs, carried animations, inventory, Sheepdex, save logic, shops, and rewards. Count existing plots and usable pads; measure ascent grades, descent lengths, transitions, and bottlenecks. Keep working code and style; do not recreate an existing screen because its labels or dataset differ.

Add named markers for player spawn, plot ownership, delivery pad, pen slots, stair walker, shop, merge station, zone entry, god home, sheep spawns, safe-zone boundary, and navigation nodes. Set the server’s player capacity to the number of usable plots after a load test.

### Build milestones

| Milestone | Work | Exit condition |
| --- | --- | --- |
| 1 — One complete climb and slide | One god, lamb, accessible ascent, pickup, overhead carry, aimed descent, player knockback, pursuit, loss and delivery | Touch and controller users can win and lose a run without duplication, repeated-hit trapping, or unreadable camera motion |
| 2 — Persistent plot | Reuse/adapt currency, roster, pen UI and saving; add growth and size reveal | Lamb earns, grows, and survives rejoin |
| 3 — Progression slice | First three gods, slope requirements, stair walker, reused shop and upgrade panels | Training enables a steeper route and improves Light-to-Heavy escapes against fixed gods; player reaches tier 3 through earned upgrades |
| 4 — Twelve-level mountain | Configure remaining gods, sheep, ascent grades and descent segments | All twelve tiers support fair pursuit, controlled slide transitions and safe runout |
| 5 — Supporting loop | Merge, selling, trails, standard reused Sheepdex, offline claim and tutorial | MVP systems work together within the existing sheep-game UI style |
| 6 — Release candidate | Multiplayer edge cases, device input, UI reuse audit, performance and economy playtests | Acceptance checks pass and no major progression blocker remains |

Persistence is introduced early so the final phase does not discover that ownership and merges require a redesign. Art polishing follows a working chase and readable placeholders.

### Content budget

- Twelve god variants built from one reusable rig and animation set.

- Twelve sheep families derived from existing sheep models.

- Three fleece rarity treatments and three adult scale settings.

- Existing sheep Carried animation where available, one compatible player carrying pose, and one player slide pose with reliable head clearance.

- One primitive stair walker with level treatments; reuse a compatible training system and upgrade panel.

- One shop interaction, one Sell Stall, and one Merge Shrine.

- Existing pens with capacity markers and delivery pads.

- One set of reusable warning, delivery, growth, and merge effects.

### Responsibilities of the game systems

| System | Owns |
| --- | --- |
| Player profile | Coins, Climb Power, upgrades, roster, discoveries, tutorial, timestamps |
| Plot manager | Plot assignment, earning slots, sheep display, delivery validation |
| Sheep spawner | Spawn pools, burden and rarity rolls, reservations, refills |
| Climbing and sliding | Slope eligibility, movement transitions, aiming, steering, braking, player hit validation, knockback immunity, runout and route validation |
| Carry and pursuit | Temporary cargo, burden modifiers, god targeting, slope pursuit, catch and escape |
| Progression | Climb requirements, stair walker training, shop purchases, pen capacity |
| Sheep lifecycle | Age, final size, current income, equipping and storage |
| Merge and sell | Eligibility, previews, confirmations, saved transactions |
| Economy | Online accrual, discovery rewards, offline settlement |
| Interface | Reuse/adapt existing screens and style; add missing prompts and feedback |

### Saved data requirements

Each owned sheep needs a unique ID, family, fleece rarity, adult size result, growth progress, merge rank, lock state, and equipped slot if any. Store hidden adult size server-side until reveal. A player profile stores coins, Climb Power, stair walker level, trail ownership and selection, pen capacity, tier unlocks and deliveries, Sheepdex discoveries and claimed rewards, tutorial stage, last settlement time, and data version.

Wild spawn claims and undelivered cargo are temporary server state. Persist ownership only when delivery commits. Never trust the client to specify reward amounts, adult size, movement eligibility, purchase prices, or which sheep it owns.

Serialize delivery, merge, sell, and purchase operations against the profile. Each operation must apply once, remain valid if retried, and preserve a consistent roster and wallet. Protect against concurrent sessions and recoverable save failures. If a profile cannot load, do not overwrite it with a new empty save or allow destructive inventory actions.

### Performance and multiplayer limits

Use server authority for ownership, rewards, gates, training, and catch decisions. Smooth visuals locally. Do not give every idle pen sheep expensive pathfinding; use small cosmetic movements around assigned pads and disable collisions with players.

Only actively chasing gods need frequent route updates. Test the full mountain, full plots, and concurrent carries at the configured server capacity. Before public release, verify that camera framing, model scale, and mobile performance remain usable when every pen contains adults.

No implementation or Studio changes were made as part of this document.

## Testing and open decisions

### Functional acceptance

- [ ] First-time player receives one plot, three slots, and a protected tutorial opportunity.

- [ ] Every mountain tier has a god, sheep spawns, a visible climb requirement, and a navigable descent. Undertrained players cannot bypass the ascent requirement through jumps, side paths, or slide momentum.

- [ ] Pickup places one sheep overhead. Burden affects carrying and sliding as displayed, with adequate camera clearance and consistent braking.

- [ ] Every god can pursue along slopes, catch, retarget, disengage, and return without catching through terrain. Sliding does not automatically eliminate the chase.

- [ ] Death, reset, disconnect, and simultaneous pickup cannot duplicate wild sheep.

- [ ] One delivery grants one owned sheep and one set of discovery rewards.

- [ ] A lamb earns immediately when equipped, grows, reveals its saved size, and updates income.

- [ ] Full pens store deliveries safely; full inventory blocks new pickup with an explanation.

- [ ] Stair walker training, upgrade costs, trail multipliers, reach thresholds, and derived Light/Heavy targets agree with their UI. Holding the sheep and route constant, more Climb Power reduces carrying slowdown until the configured cap; guardian speed stays unchanged.

- [ ] Equip Best, manual pinning, storage, and locks behave as described.

- [ ] Merge consumes exactly three eligible adults, preserves its guarantee, and saves once.

- [ ] Selling shows the income tradeoff and cannot remove the final sheep.

- [ ] Offline credit respects juvenile growth, the two-hour cap, and a single claim.

- [ ] Rejoining restores upgrades, flock, progression, Sheepdex, and tutorial state.

- [ ] Desktop, touch, and controller users can climb, steal, aim, steer, hit or evade a player, brake, stop at the safe-zone runout, and deliver using the specified controls. Existing UI style and components are reused wherever available.

- [ ] A fresh account can reach Zeus using earned progression without developer grants.

### Playtest questions and instrumentation

Record first pickup, slide start, safe-zone arrival, delivery, first income, first training session, and first new slope unlock as individual tutorial steps. Record Climb Power at pickup, stage readiness, source tier, burden, machine level, active trail, and theft success by tier and burden, loss causes, ascent/descent duration, slide hits and misses, recovery-chain attempts, tutorial interruptions, scenery collisions, training time, upgrades, income changes, reveals, merges, and exits. Split by device. Test changes against a stated problem rather than treating more time spent training as success.

**Three-stage playtest:** use the same sheep burden, source tier, pickup point, god profile, and route while testing at Reach, Light readiness, and Heavy readiness. Run at least ten solo attempts per burden and stage on touch and controller; log success, closest pursuit gap, and loss cause. Proposed acceptance targets are at least 8/10 clean Light deliveries at Light readiness and 8/10 Heavy deliveries at Heavy readiness, including a standardized minor steering correction. These are acceptance goals, not observed results or statistical proof. Then repeat with shared routes and slide collisions, reporting those results separately. At Reach, verify a tense attempt is possible without advertising a guaranteed escape. Revisit an earlier tier with later-tier training to confirm it feels easier. Tune route profiles and carrying curves before inventing another stat.

Proposed playtest targets: first theft within 15–30 seconds; first delivery within 45–60 seconds; at least 80% of first-time testers complete the opening loop within two minutes. Most should explain that stair walkers enable steeper climbs and easier heavier-sheep escapes and show how to steer/brake without coaching. Early required training visits should stay below roughly 90 seconds. These are test hypotheses, not promised retention benchmarks.

If ascents feel tedious, shorten connecting stretches or tune ascent pace while preserving the climb requirement. If slides feel automatic or impossible, adjust route shape, god pursuit, head start, burden, and braking before adding attacks. If players mainly wait on stair walkers, increase training gain or reduce grade requirements. If they miss upgrades, fix reused UI labels, prompts, and feedback before commissioning replacement screens.

### Decisions adopted for this draft

| Question | Decision | Status |
| --- | --- | --- |
| What is the distinctive movement? | Climb uphill and slide downhill carrying a sheep | User confirmed direction; controller tuning proposed |
| Can players hit each other? | Aimed downhill slides knock back uphill walkers; no damage or sheep transfer | User confirmed direction; impact tuning proposed |
| What replaces the treadmill? | Stair walker; Climb Power enables steeper routes and reduces carrying slowdown | User confirmed direction; stat name and numbers proposed |
| How should progression scale? | Reach, Light escape, Heavy escape within each tier; similar reference scaling with original values | User confirmed direction; thresholds and curves proposed |
| What UI should be used? | Reuse existing sheep-game UI, components and style wherever available | User requirement |
| How complex is the Sheepdex? | Standard MVP collection book using existing implementation where possible | User requirement |
| Who do players steal from? | Gods; shared wild-spawn competition | Working MVP recommendation |
| What replaces hatching? | Immediate lamb income, growth, adult-size reveal | Working MVP recommendation |
| Do giants use extra slots? | One slot regardless of size | Working MVP recommendation |
| How does merging work? | Guaranteed three-to-one, two ranks, exact preview | Working MVP recommendation |
| Do trails stack? | One equipped trail; training multiplier only | Working MVP recommendation |
| Does the MVP need rebirth? | No | Working MVP recommendation |
| Are gods unique bosses? | Shared slope pursuit, distinct looks | Working MVP recommendation |

The movement, slide knockback, stair walker, standard Sheepdex, UI reuse, and three-stage progression direction reflect the user’s latest instructions. Detailed controls, stat naming, prices, rates, probabilities, and timings are proposed implementation defaults to test. The Tizzy material informs early onboarding, clear feedback, and reuse; it does not establish demand or guarantee player counts.

### Decisions that need actual project evidence

1. **Map and plots:** actual slot count, terrain grades, safe descent transitions, and whether all twelve routes support climbing, sliding, and pursuit.

2. **Existing sheep-game assets and UI:** which rigs, animations, screens, components, inventory, Sheepdex, purchase, and saving systems are implemented and reusable. The supplied design specifications are references, not completion records.

3. **Multiplayer capacity:** number of usable plots and acceptable performance with full pens.

4. **Progression pace:** measured first-hour economy, new size odds, training time, and first-summit time using the actual ascent and slide routes.

5. **Further player theft:** slide knockback is included now. Intercepting ownership of unbanked cargo, stealing growing lambs, or raiding established flocks remains a separate expansion decision.

### Recommended first implementation brief

Inspect the existing sheep-game UI and systems first, then build one complete Demeter run on the existing mountain: climb to a lamb, pick it up overhead, trigger pursuit, aim and steer a downhill slide, validate knockback against an uphill test player, stop safely at the foothills, deliver, earn, grow, save, and rejoin. Reuse the existing HUD, sheep cards, pen controls, and feedback. Add stair walker training and the steeper Dionysus route next. Extend the shared systems through all twelve gods, then complete merging, shops, the standard Sheepdex, and the remaining acceptance checks.


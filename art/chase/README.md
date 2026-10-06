# Chase terror mock-up

A video mock-up of the steal and chase sound design (2026-10-06): the trailer's raw takes (`steal_chase2.mkv`,
`caught2.mkv` in `%USERPROFILE%\Videos\StealASheepTrailer\raw`) with a mix made here from Roblox's licensed sounds
and a red danger grade drawn per frame. The user OK'd it except the alarm; the game now plays these sounds
(`Config/Sounds`, the chase block) with the alarm from the alarm board. `soundboard.py` renders the alarm board (A-E)
and every other sound alone, numbered, as the game plays it.

| Script | Does |
| --- | --- |
| `search.py "words sfx" ...` | Searches the Creator Store's audio, keeping only Pro Sound Effects and APM (licensed) |
| `fetch.py name=id ...` | Downloads sounds to `<work>/snd/name.ogg` (no login: BRAIN GOTCHAS, Assets) |
| `analyze.py [name ...]` | Duration, loudness, where the sound is, pitch and a loudness strip, per file |
| `alarmfeat.py name[@start] ...` | An alarm's pulse rate, pitch and buzziness |
| `voicefeat.py name ...` | A voice's segments and pitch spread: one take of one voice has one segment (or evenly spaced laughs) at a steady pitch |
| `mockup.py [out.mp4]` | Mixes the sounds and grades the takes into the 19 s mock-up |
| `soundboard.py <board> out.mp4 dir` | A sound board (alarms, sounds, alarms2, goddess), and each sound in it as a WAV |

`<work>` is `%USERPROFILE%\Videos\StealASheepTrailer\work\chase` (`CHASE_WORK` overrides it). Fetch the sounds below
first. Picked from names, descriptions, measurements and spectrograms; the user has heard the mock-up's (2026-10-06),
not yet the alarm board's or the goddesses'.

| Name | Id | Creator Store name | Used for |
| --- | --- | --- | --- |
| alarmTag2 | 1835347409 | APM "Wild Intruder Alarm Tag 2" | The mock-up's alarm (the user: too much like heavy metal) |
| redAlert1 | 9118113271 | Red Alert Alarm Slow Constant Beeping 1 (SFX) | The game's alarm (board A, 1.15x); B-E: klaxonBuzzy 9118805558, elecAlarmD 1840227705 (from 1.9 s), dive 9119662416, neutralZone 9125709757 |
| consoleLow, elecF, elecAlarmE | 9125359572, 1840227739, 1840227737 | Alarm Beep Slow Console Lower Pitch Constant 1 (SFX); APM "Electronic Alarms (F)" and "(E)" | The second alarm board's F, G, H (between A and C); I is C at 0.75x, J is A and C together. KPM's lowercase "Electronic Alarms (d)" etc. are the same audio as APM's capitals |
| goblinRoar | 9114624345 | Goblin Growl 1 (SFX), "Human Generated Roar" | The god's roar (0.85x), snarls |
| yellE, yellB, yellD | 9125653266, 9125651083, 9125651408 | Male Scream Short Yelling Bursts (SFX) | The god's yells, pitched down (0.76-0.8x) |
| laugh4 | 9116239313 | Laugh Evil Male Various Versions 4 (SFX) | The catch's "HA HA HA" (0.8x) |
| fyell8, fyell10 | 9114399212, 9114399868 | Female Voices 2 Women Short Screams Yells (SFX) | The goddesses' yells (not in the video), at 0.77x since the user asked for them deeper |
| heart1 | 9043365727 | APM "HEARTBEAT 01 96BPM" (Epic Score, Horror Tools) | One lub-dub (0-0.62 s), retriggered faster as the god closes |
| boomy1 | 9125404769 | Boomy Footsteps Giant Thumpy Dinosaur (SFX) | The god's footfall (its first 0.32 s, 1.2x) |
| dragon23 | 9114166413 | Dragon Footsteps 23 (SFX) | Footfall foley over it in the mock-up only (too quiet at the source for a Sound's Volume) |
| rfl80, rflFull | 1845015064, 1845015012 | APM "Run For Your Life (80%)" (no drums) and full | Chase music: the drums fade in as the god closes; the two mixes line up to about 10 ms |
| whooshPunch, bodyImpact, boxing5 | 9120728815, 9113524237, 9113570506 | Whoosh Heavy Punches 1, Body Impact 2, Boxing Hits 5 (SFX) | The punch |
| thunder | 9126082854 | Synth Thunder Cracks Individual Explosion Booms (SFX) | Zeus's signature on the catch |
| whoosh, saved | 9120711172, 9048764475 | Whoosh Fast Swish By 7; APM "Magical Meetup - Hit2" (the game's Notice) | Flying off; reaching safety |
| birds, playtime | 9112749254, 1839857481 | The game's ambience and calm music | Before the steal |

Since the build (2026-10-06): the alarm is C (`elecAlarmD`), and every voice is one person in one take (the user heard
the layered roar and the many-laugh goddess file as more than one person). From the voice board every take but M1 is
in the game, said at random: god's roars M2-M4, goddess roars F1-F3, her yells FY1-FY2, laughs ML1-ML3 and FL1-FL3;
the god's "got away" 9125652955 and the goddess's 9114399696 (all goddess sounds about 0.77x). Not used any more: `goblinRoar` under the roar (it stays
the snarl), `fyell8`/`fyell10` (two women), `flaugh` (several laughs).

Other candidates measured: `Damage Zone Alarm 2` 9114024787 (a looping two-tone siren), `Alarm Bell On Carpet` 9113084849,
APM "Temple Bell Hits" 1840229203 and "Hollow Gong" 1845411462 (a temple-style alarm), APM "Terror Pursuit a"
1841476877 (orchestral strings) and "PANICKED PURSUIT B" 117859689044667, and the current "Evasion" 1840028287.

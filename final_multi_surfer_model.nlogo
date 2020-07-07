;;; This is my multiple surfer model which encourporates my environment model and patch wave model.
;;; This model simulates the temperature energy trade off experienced when surfing in cold water in Cape Town
;;; A surfer will continue surfing (staying in the ocean) until too cold or tired. After the surfer paddles to the shore.
;;; This model attempts to answer the following question:
;;; Under what environment and surfer conditions result in surfers being able to surf for longer durations of time?

;; TO ADD?

;; Strategies
;; (paddle out in channel,
;; dont paddle to backline,
;; paddle to the beach and warm up,
;; dont catch waves if tired and sit and wait for longer)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;       Setup         ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

breed[surfers surfer]
breed[umbrellas umbrella]

surfers-own [energy temperature]

Globals[
  ;; Environment variables
  beach-size
  backline-size
  currentwave-size

  ;; Surfer variables
  energy-thresh
  temperature-thresh
  energy-max
  temperature-max

  ;; General info variables
  number_of_waves
  number_of_duckdives
  time_waiting
  time_surfing
  time_paddling
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;       Logic         ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  ;; set our globals
  set beach-size 10                               ;; set the size of the beach you would like
  set backline-size 5                             ;; set the size of the backline you would like
  set energy-thresh energy-threshold
  set temperature-thresh temperature-threshold
  set energy-max energy-maximum
  set temperature-max temperature-maximum

  beachsetup
  shorebreaksetup
  backlinesetup
  surfersetup

  reset-ticks
end

to go
  ;; Stopping criterion
  if all? surfers [color = blue and shape = "surfer_beach"] or ticks > 15000[   ;; if surfers are cold and tired on the beach
    stop                                                                        ;; stop ends its proceedure so we must have a stop somewhere in go.
  ]

  ;; All surfer logic,
  move                                                                          ;; paddleout, duckdive, wait, surf, paddlein

  ;; All wave logic
  pulse                                                                         ;; Move the wave that is currently around
  newwave                                                                       ;; check if new wave must come
  wavedecay                                                                     ;; fades the waves

  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;     Surf Spot       ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Beach size and backline size are globals

; Colours beach
to beachsetup

  ;; Just for aesthetics
  create-umbrellas number-of-surfers [
    set shape "umbrella1"
    set size 3
    set color 17
    set xcor random ((max-pxcor - 3 ) - min-pxcor + 3) + min-pxcor
    set ycor random ((min-pycor + beach-size - 2) - min-pycor) + min-pycor + 2
  ]

  ask patches
    [ if pycor < min-pycor + beach-size and pycor >= min-pycor
      [ set pcolor 49 ]
  ]
end

; Colours shorebreak
to shorebreaksetup
  ask patches
    [ if pycor < max-pycor - backline-size  and pycor >= min-pycor + beach-size
      [if pcolor > 89.9 or pcolor = black [
         set pcolor random-float (97 - 96) + 97
        ]
      ]
  ]
end

; Colours backline
to backlinesetup
  ask patches
    [ if pycor <= max-pycor  and pycor >= max-pycor - backline-size
      [if pcolor > 89.9 or pcolor = black [
         set pcolor random-float (94 - 93) + 94
        ]
      ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;     Surfers         ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Colours indicate the surfers readiness to surf or the willingness to keep going
;; red = Surfer is ready to paddle out energy and temperature is sufficient
;; green = Surfer has paddled out and now ready to surf energy and temperature is sufficient
;; blue = Surfer is now tired/cold and needs to paddle in energy and temperature is not sufficient

;;;;;;;;;;;;;;;;;;
; Surfers Setup  ;
;;;;;;;;;;;;;;;;;;

;; Sets up the surfers
to surfersetup
  create-surfers number-of-surfers [
    set xcor random-xcor
    set ycor random ((min-pycor + beach-size) - min-pycor) + min-pycor ;; must start on beach
    set color red
    set shape "surfer_beach"
    set size 2.5
    set heading 0                                                      ;; heading towards the ocean
    set energy energy-max
    set temperature temperature-max
    set number_of_waves 0
    set number_of_duckdives 0
    set time_waiting 0
    set time_paddling 0
  ]
end

;;;;;;;;;;;;;;;;;;
; Surfers Logic  ;
;;;;;;;;;;;;;;;;;;

;; Basic logic of a surfer
to move
  ask surfers with [energy > energy-thresh and temperature > temperature-thresh] [
    ifelse color = green  [
      surf
    ][
      paddle-out
    ]
  ]
  ask surfers with [energy < energy-thresh or temperature < temperature-thresh][
    paddle-in
  ]

end

;;;;;;;;;;;;;;;;;;;
; Surfers Actions ;
;;;;;;;;;;;;;;;;;;;

;; When a surfer is ready to surf they are waiting and green. surfing costs energy but makes the surfer warm.
;; If the wave fades/decays or the surfer gets to the beach then stop surfing

to surf
  ;; If at the backline wait for the next wave
  ifelse  pycor > max-pycor - backline-size and pcolor >= 94 and pcolor <= 95 [
    waitforwave
  ][
    ask patches with [ pcolor >= 88 and pcolor <= 89.9 ] [
      ask surfers in-radius 3 with [color = green][

        set heading  random (275 - 215) + 215
        set shape "surfer_surfing"
        fd 1.5 ;; go go go fast!

        ifelse temperature + 0.3 > temperature-max [
          set temperature temperature-max
        ][
          set temperature temperature + (0.15 *  currentwave-size) ;; Surfing bigger waves makes you warmer as its more thrilling
        ]

        set energy energy - 0.1

        ;;  if the beach is close then stop surfing
        if pycor < min-pycor + beach-size + 2 [
            set color  red
            set number_of_waves number_of_waves + 1
        ]
      ]
    ]
    ;; If the wave fades then the surfer must go red and paddle out again
      if all? patches in-radius 5 [pcolor > 89.9 or pcolor = 49] [
        set color red
        set number_of_waves number_of_waves + 1
      ]
   set time_surfing time_surfing + 1
  ]
end

;; To go from the shorebreak or backline to the beach
;; If the energy or temperature is low the surfer will go blue and want to stop
to paddle-in

  set color blue

  ifelse pycor > min-pycor + beach-size [
    set heading 180
    ifelse ticks mod 2 = 0 [
      set shape "surfer_paddling_2"][
      set shape "surfer_paddling_1"]
    fd 1
  ][
    set shape "surfer_beach"
    fd 0
    set heading 0
    ]
end

;; To go from the shorebreak to the backline
to paddle-out

  ;; If on the beach then stand up and walk towards the ocean
  ifelse pycor < (min-pycor + beach-size)[
    set shape "surfer_beach"
    fd 1
  ][
    ;; If in the shorebreak then paddle to backline
    ifelse pycor <= max-pycor - backline-size  [
      set heading 0
      duckdive
      paddle
    ][
      ;; if backline get into priority on far right
      ifelse pxcor < max-pxcor - 4 [
        set heading 90

        ;; Surfers must wait their turn to surf
        ifelse any? surfers at-points [[1 0] [2 0] [3 0] [4 0] [5 0] ] with [shape = "surfer_sitting" or color = green ] [
          waitforwave
        ][
          paddle
        ]
      ][
        waitforwave
        set color green
      ]
    ]
  ]
end

;; Waiting is cold but restores energy
to waitforwave
  set heading 0
  fd 0
  set shape "surfer_sitting"
  set temperature temperature - 0.1

   ifelse energy + 0.1 > energy-max [
    set energy energy-max
  ][
    set energy energy + 0.1
  ]
  set time_waiting time_waiting + 1
end

;; Ask a surfer to paddle. Paddling is warm but uses energy.
to paddle
  ifelse ticks mod 2 = 0 [
    set shape "surfer_paddling_2"][
    set shape "surfer_paddling_1"]
  fd 1

  ifelse temperature + 0.1 > temperature-max [
    set temperature temperature-max
  ][
    set temperature temperature + 0.1
  ]

  set energy energy - 0.1

  set time_paddling time_paddling + 1
end

;; When navigating through the shorebreak you come into contact with waves, which a surfer needs to go underneath.
;; This is a cold and tiring action
to duckdive
  ask patches with [ pcolor >= 88 and pcolor <= 89.9 ] [
    ask surfers in-radius 1.5[
      hide-turtle
      set temperature temperature - 0.5                       ;; This is colder than normal
      set energy energy - 0.3                                 ;; This is more tiring than paddling as well
      set number_of_duckdives number_of_duckdives + 1
    ]
  ]
  ask patches with [pcolor > 89.9 or pcolor = 49] [
    ask surfers-here[
      show-turtle
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;     Waves           ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; FEATURES OF WAVES
;; Running: While in the shore break waves decay and fade out. This means surfers cannot ride them when they decay away
;; Size: The waves can vary in size which is also random. The max size is set by the user.
;; Frequency: Wave period is set by a Poisson value set by user.

;; Creates waves that form in a line at the backline. wavesize determined by user.
to wavesetup

  ; global variable to store a random size of wave between 1 and wavesize
  set currentwave-size random wave-size + 1

  ;; sets the patches to become wave patches
  ask patches [
  if pycor <= max-pycor - 1 and pycor >= max-pycor - currentwave-size - 1 and pxcor > min-pxcor + 5 [
      set pcolor random-float (89.9 - 88) + 88
    ]
  ]

end

;; Creates the movement of waves as they pulse through the water
to pulse

  ;; makes the wave patches move forward
  ask patches with [ pcolor >= 88 and pcolor <= 89.9 ] [
    ask patches at-points [[0 -1]]  [
      if pycor >= min-pycor + beach-size [
        set pcolor random-float (89.9 - 88) + 88
      ]
    ]

    ;; sets the patches behind to be the same colour as before (Maybe try make it a single block colour?)
    ask patches at-points [[0 0]] [
      ifelse pycor >= max-pycor - backline-size
      [ set pcolor random-float (94 - 93) + 94] [
        if pycor >= min-pycor + beach-size [set pcolor random-float (97 - 96) + 97]
      ]
    ]
  ]

end

;; Determines when the new wave will arrive (Frequency)
to newwave
  ifelse ticks mod random-poisson(wave-period) = 0 [
    wavesetup
  ][
    ;; This just makes the background change colours to mimic water
    shorebreaksetup
    backlinesetup
  ]

end

;; Allows waves to decay and fade as they get to the shore
to wavedecay

  ;; if any wave patches are in the spot
  if any? patches with [ pcolor >= 88 and pcolor <= 89.9 ][
    let tempdecay wave-decay-size

    ;; Prevents from selecting more waves patches than available
    if wave-decay-size >= count patches with [ pcolor >= 88 and pcolor <= 89.9 ][
      set tempdecay min list wave-decay-size count  patches with [ pcolor >= 88 and pcolor <= 89.9 ]
    ]
    ;; Decay stage
    ask n-of tempdecay patches with [ pcolor >= 88 and pcolor <= 89.9 ] [
      ifelse pycor >= max-pycor - backline-size
      [ set pcolor random-float (94 - 93) + 94] [
        if pycor >= min-pycor + beach-size [set pcolor random-float (97 - 96) + 97]
      ]
  ]]
end
@#$#@#$#@
GRAPHICS-WINDOW
264
26
1195
646
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-35
35
-23
23
0
0
1
ticks
100.0

BUTTON
20
116
89
149
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
103
117
166
150
go
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
20
227
239
260
wave-decay-size
wave-decay-size
1
5
5.0
1
1
NIL
HORIZONTAL

SLIDER
21
275
240
308
wave-period
wave-period
30
300
90.0
10
1
NIL
HORIZONTAL

SLIDER
22
321
241
354
wave-size
wave-size
1
4
3.0
1
1
NIL
HORIZONTAL

SLIDER
18
484
241
517
energy-threshold
energy-threshold
0
85
50.0
1
1
NIL
HORIZONTAL

SLIDER
17
528
240
561
temperature-threshold
temperature-threshold
0
85
50.0
1
1
NIL
HORIZONTAL

PLOT
1216
100
1659
396
Average Surfer Attributes
Ticks
Temperature/Energy level
0.0
10.0
0.0
120.0
true
true
"" ""
PENS
"Average Temperature" 1.0 0 -13345367 true "" "plot mean [temperature] of surfers with [color != blue]"
"Average Energy" 1.0 0 -955883 true "" "plot mean [energy] of surfers with [color != blue]"
"Energy Threshold" 1.0 0 -6995700 true "" ";; we don't want the \"auto-plot\" feature to cause the\n;; plot's x range to grow when we draw the axis.  so\n;; first we turn auto-plot off temporarily\nauto-plot-off\n;; now we draw an axis by drawing a line from the origin...\nplotxy 0 energy-threshold\n;; ...to a point that's way, way, way off to the right.\nplotxy 1000000000 energy-threshold\n;; now that we're done drawing the axis, we can turn\n;; auto-plot back on again\nauto-plot-on"
"Temperature Threshold" 1.0 0 -14730904 true "" ";; we don't want the \"auto-plot\" feature to cause the\n;; plot's x range to grow when we draw the axis.  so\n;; first we turn auto-plot off temporarily\nauto-plot-off\n;; now we draw an axis by drawing a line from the origin...\nplotxy 0 temperature-threshold\n;; ...to a point that's way, way, way off to the right.\nplotxy 1000000000 temperature-threshold\n;; now that we're done drawing the axis, we can turn\n;; auto-plot back on again\nauto-plot-on"

MONITOR
1220
517
1341
562
Total waves surfed
number_of_waves
1
1
11

TEXTBOX
22
12
255
104
------------------------\nSURFING MODEL\n------------------------
25
104.0
1

MONITOR
1219
595
1343
640
Time spent surfing
time_surfing
17
1
11

MONITOR
1537
516
1660
561
Current wave size
currentwave-size
17
1
11

MONITOR
1382
516
1504
561
Total duckdives
number_of_duckdives
17
1
11

MONITOR
1384
596
1506
641
Time spent waiting
time_waiting
17
1
11

TEXTBOX
20
95
170
117
FABIO FEHR
18
104.0
1

TEXTBOX
21
152
266
219
--------------------------------\n          WAVES\n--------------------------------
20
104.0
1

TEXTBOX
19
360
266
424
--------------------------------\n        SURFERS\n--------------------------------
20
104.0
1

BUTTON
179
117
242
150
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1219
16
1687
80
--------------------------------------------------------------\n        ENERGY TEMPERATURE GRAPH\n--------------------------------------------------------------
20
104.0
1

MONITOR
1538
595
1666
640
Time spent paddling
time_paddling
17
1
11

TEXTBOX
1219
411
1674
479
--------------------------------------------------------------\n                 SURFER INFORMATION\n--------------------------------------------------------------
20
104.0
1

SLIDER
18
439
240
472
number-of-surfers
number-of-surfers
1
5
3.0
1
1
NIL
HORIZONTAL

SLIDER
15
572
240
605
energy-maximum
energy-maximum
50
150
100.0
1
1
NIL
HORIZONTAL

SLIDER
14
615
239
648
temperature-maximum
temperature-maximum
50
150
100.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model simulates the temperature-energy trade off experienced when surfing in cold water in South Africa. 

It attempts to answer the question "*Under what wave conditions result in surfers being able to surf for longer durations of time and improve their surfing*?". 

This is important because increasing the time surfers spend in the water infers more waves being caught resulting in faster improvement. This could provide insights into what conditions or factors breed competitive, professional surfers in South Africa and other cold water surf spots.

## HOW TO USE IT

1. Access the WAVES sliders. 
See Section "**Waves**" below for more information.

2. Access the SURFER sliders. 
See Section "**Surfers**" below for more information. 

3. Click **setup** button.

4. Click **go** button. 

## HOW IT WORKS

### Prelude

The only agents are `surfers` who interact with other `surfers`. The other key aspects include: `environment` and `waves`. The following fonts explained below:
 
**Actions**: Surfers can perform these actions while simulation is running.
*Areas or States*: Surfers can be in the environment area or take on the states.
USER-INPUTS: Surfer and wave characteristics are determined by sliders.


### Environment 

The surfing environment is split into three main areas: *Beach*, *Shorebreak* and *Backline*. With colours yellow, light blue and dark blue respectively. This setup holds for most styles of surfing spots.

- *Beach*: This where surfers are spawned and where they exit when finished surfing. Surfers are only in a standing position here.
- *Shorebreak*: This is where surfers must **paddle** and **duckdive** under the waves when paddling out. Once successfully paddled out they will **surf** waves diagonally through the *Shorebreak* towards the *Beach*.
- *Backline*: This is where the surfers aim to **paddle** towards. Once at the *Backline* surfers no longer need to **duckdive** under waves and will **paddle** towards the take-off-zone. This zone is on the far right of screen. Once there they will sit and **waitforwave**s to **surf**.

### Waves

The wave design was based on a "point-break" style wave where surfers only surf in a single direction, in our case towards the left. The wave also does not break on the far left hand side creating an easy paddle-out route for surfers. This is a common feature of "point-break" surf spots.

The waves are moving patches based on a poisson process to mimic the ocean waves unpredictability. These waves pulse from the *Backline* through the *Shorebreak* and end at the *Beach*. The three main factors considered are WAVE-DECAY-SIZE, WAVE-PERIOD and WAVE-SIZE.

- WAVE-DECAY-SIZE: This affects how long surfers are able to **surf** the wave. This is seen as the wave patches fade-out as they pulse through the *Shorebreak*.
- WAVE-PERIOD: This determines the time in ticks between waves or the inverse of frequency. This affects how many waves surfers need to interact with and duration a surfer needs to **waitforwave**s.
- WAVE-SIZE: This determines the upper bound size of the wave pulse. This means even when WAVE-SIZE is at a maximum, small waves can occur. This affects surfers when paddling-out towards the *Backline* and while surfing. The larger the wave the more they need to **duckdive** under the waves making them tired and cold. The larger the wave the more thrill the surfer recieves surfing it making the surfer warmer.

### Surfers

The `main logic` for these agents is as follows:
As long as the surfers are not cold or tired they will continue to paddle-out and **surf** waves. When all surfers are cold or tired they will paddle-in to the beach ending the simulation. 

The `main attributes` considered are temperature & energy:
Surfers have an initial temperature MAXIMUM-TEMPERATURE and energy MAXIMUM-ENERGY are defined by sliders. This defines the natural disposition these attributes, starting value and maximum they can take on.

- A low MAXIMUM-TEMPERATURE could simulate surfers surfing in boardshorts/bikini's as apposed to in wetsuits. 
- A high MAXIMUM-ENERGY would suggest surfers with a higher stamina or fitness and can surf for longer durations.

If a surfers temperature or energy goes below the TEMPERATURE-THRESHOLD or ENERGY-THRESHOLD respectively the surfer will paddle-in to the beach. 

- Increasing the TEMPERATURE-THRESHOLD suggests the water temperature is very cold. 
- Increasing the ENERGY-THRESHOLD suggests difficulty of water conditions and will make it more tiring.

The surfers have three states *Red*, *Green*, *Blue* which indicate the surfers readiness to surf or the willingness to keep going.

- *Red*: Surfer is ready to paddle-out. Energy and temperature are above respective thresholds.
- *Green*: Surfer is now ready to **surf**. Energy and temperature are still above thresholds.
- *Blue*: Surfer is now too tired or cold and needs to paddle-in to the beach. Energy or temperature are below thresholds.

Surfers obey a hierachy system known as "priority". This means that the first surfer to the get to the take-off-zone (far right of backline) will have priority and go *Green*. The other surfers remain *Red* and must wait their turn. This forces the turn based approach seen in real life surfing.

Surfers can take one of four actions: **paddle**, **waitforwave**, **surf** and **duckdive**.

- **paddle**: This action occurs only in the *Shorebreak* and *Backline* during paddle-out or paddle-in. The action makes a surfer warm (increase temperature), but makes a surfer tired (decrease energy) at the same rate.
- **waitforwave**: This action only occurs in the *Backline* once a surfer reaches the take off zone or is waiting for priority. The action makes a surfer cold (decrease temperature), but lets a surfer rest (increase energy) at the same rate.
- **surf**: This action only occurs in the *Shorebreak* once a surfer is in the take-off-zone and is *Green*. The surfer will respond to the wave and ride along it towards the left of the screen. The surfer will only stop if they reach the beach or if the wave fades-out due to a high WAVE-DECAY-SIZE. This action makes a surfer warm (increase temperature), but makes a surfer tired (decrease energy). The thrill of surfing warms the surfer at a faster rate then the energy expense. The larger the WAVE-SIZE the more thrill they recieve.
- **duckdive**: This action occurs in the *Shorebreak* during paddle-out. Whenever a surfer encounters a wave before reaching the take-off-zone and in state *Red*, the surfer dives under the wave to get past it. The action makes a surfer cold (decrease temperature) and makes a surfer tired (decrease energy). Being completely submerged in the water causes brain-freeze and dramatically decreases the temperature, it is also incredibly energy consuming. This action chills a surfer more than the energy expense.

## THINGS TO NOTICE & TRY 

- **Where surfers start**: After clicking setup notice that the surfer(s) are placed randomly on the beach. If the surfer is placed on the far left they do not need to duckdive but use a lot of energy. If the surfer if placed on the far right they will most likely need to duckdive but get to the take-off-zone quickly.
- **Length of ride**: The WAVE-DECAY-SIZE slider affects how quickly a wave will fade. Notice that if the wave fades quickly the surfer does not surf all the way to the beach.
- **Multiple surfers**: Adding many surfers means that they need to wait longer due to the "priority" system. This means many surfers will paddle-out due to being cold. The last surfer stays in longer and has first choice on all the waves. The last surfer usually only gets out due to being too tired.
- **Wave size**: Slow the ticks down and watch the individual wave pulses come through. Notice the monitor on the right hand size that tracks "current wave size". Larger waves means more thrill while surfing, but also more difficult to paddle-out. Watch the jumps in the average energy and temperature graph.
- **Surfer information**: Keep the SURFERS sliders constant and change the WAVES sliders. Notice the amount of variation in the monitors under SURFERS INFORMATION.

## ASSUMPTIONS & RESTRICTIONS

- **Surfer homogeneity**: All surfers are equal skill level, fitness and ability to withstand temperature. 

- **Greedy for waves**: All surfers are greedy to catch waves. We assume if a surfer is in the take-off-zone and *Green* they will always catch the wave regardless of their own energy level.

- **Get to the take-off-zone**: Surfers must get to the take-off-zone in the *Backline* before surfing any waves. In real life you can catch waves in the *Shorebreak* and not required to paddle to the *Backline*.

- **No breaks on this train**: Once a surfer paddles out they will continue until they are too tired or cold. They are not allowed to come to the shoreline and take breaks.

- **Obey the law**: Surfers must obey the hierachy system "priority". In real life this is a guideline and can be broken but makes people upset.

- **Surf spot**: The surf spot chosen was a "point break" style which only breaks in a single direction and surfers only surf in a single direction. This is also accompanied with a area on the far left that waves do not occur. This was chosen for ease of testing but could be extended to other styles such as "beach break" or "reef break" which have different characteristics.

- **The graph is a bit average**: The graph shows the average temperature and energy for all surfers. This is not that helpful when there are many surfers in the water as it does not capture individual levels.

## EXTENDING THE MODEL

To extend this model we can access the section **Assumptions & Restrictions** above and try to improve these areas. These restrictions were going to be explored using different surfing strategies given more time.

- **Surfer homogeneity**: Let individual surfers have a skill level and  fitness. This could be done but allowing the user to define the attributes manually ot done randomly. This might reduce the userfriendliness.

- **Greedy for waves**: Let surfers recuperate their energy levels before going *Green* and see if surfers could sustainably remain in the ocean. This was going to be added in as a "Surfing Strategy" implemented with a switch.

- **Get to the take-off-zone**: Add another "Surfing Strategy" which allows a surfer to not need to paddle to the *Backline* before surfing any waves. This will allow the surfer to get warmer faster and combat the "priority" system.

- **No breaks on this train**: A surfer could paddle-in before getting too tired and cold as a "Surfing Strategy". This will allow the surfers temperature and energy to recover to a point where they could paddle-out and continue surfing.

- **Obey the law**: Surfers could disobey the hierachy system "priority" as a "Surfing Strategy". This would only apply in a multiple surfer model and would need to have consequences. Other surfers would get aggressive and beat the traitor up. 

- **Surf spot**:  A "beach break" or "reef break" which have different characteristics could be simulated. 

- **The graph is a bit average**: The graph could show the individuals temperature and energy levels. This would get a bit confusing and messy when more than two surfers.

@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

surfer_beach
false
0
Rectangle -16777216 true false 120 105 150 135
Rectangle -16777216 true false 105 195 165 225
Circle -16777216 true false 101 41 67
Polygon -7500403 true true 17 132 45 120 84 118 129 120 170 126 205 130 257 148 300 165 255 195 207 210 150 210 120 210 75 195 45 180 15 165 30 150 10 135 33 129
Polygon -7500403 true true 75 150
Rectangle -16777216 true false 120 120 150 150
Rectangle -16777216 true false 135 135 165 210
Circle -16777216 true false 150 195 30
Polygon -16777216 true false 105 225 90 285 120 285 135 225 165 285 195 285 165 225
Rectangle -16777216 true false 135 105 165 135

surfer_paddling_1
true
0
Polygon -7500403 true true 105 270 90 255 88 216 90 171 90 135 90 90 105 45 135 0 165 45 180 93 180 150 180 180 180 225 180 255 150 285 135 270 120 285 99 267
Polygon -7500403 true true 150 225
Circle -16777216 true false 45 210 30
Circle -16777216 true false 101 72 67
Rectangle -16777216 true false 105 150 165 225
Polygon -16777216 true false 135 180 75 180 75 225 45 225 45 225 45 165 120 135 120 165
Polygon -16777216 true false 165 135 210 120 210 75 240 75 240 75 240 135 150 180 150 135
Circle -16777216 true false 210 60 30
Rectangle -16777216 true false 120 135 150 165
Polygon -16777216 true false 105 225 105 225 105 300 135 300 135 255 135 300 165 300 165 225 105 225
Line -1 false 135 300 135 240

surfer_paddling_2
true
0
Polygon -7500403 true true 105 270 90 255 88 216 90 171 90 135 90 90 105 45 135 0 165 45 180 93 180 150 180 180 180 225 180 255 150 285 135 270 120 285 99 267
Polygon -7500403 true true 150 225
Circle -16777216 true false 195 210 30
Circle -16777216 true false 101 72 67
Rectangle -16777216 true false 105 150 165 225
Polygon -16777216 true false 135 180 195 180 195 225 225 225 225 225 225 165 150 135 150 165
Polygon -16777216 true false 105 135 60 120 60 75 30 75 30 75 30 135 120 180 120 135
Circle -16777216 true false 30 60 30
Rectangle -16777216 true false 120 135 150 165
Polygon -16777216 true false 105 225 105 225 105 300 135 300 135 255 135 300 165 300 165 225 105 225
Line -1 false 135 300 135 240

surfer_sitting
true
0
Polygon -7500403 true true 120 225 105 225 90 210 90 171 90 135 90 90 105 45 135 0 165 45 180 93 180 150 180 180 180 210 165 225 150 225 135 225 120 225 120 225
Polygon -7500403 true true 150 225
Circle -16777216 true false 101 102 67
Rectangle -16777216 true false 105 150 165 225
Polygon -16777216 true false 135 165 180 150 180 105 210 105 210 105 210 165 120 210 120 165
Circle -16777216 true false 60 90 30
Rectangle -16777216 true false 120 135 150 165
Polygon -16777216 true false 135 165 90 150 90 105 60 105 60 105 60 165 150 210 150 165
Circle -16777216 true false 180 90 30

surfer_surfing
false
0
Rectangle -1 true false 120 105 150 135
Rectangle -16777216 true false 105 180 165 210
Circle -16777216 true false 101 56 67
Polygon -7500403 true true 255 240 255 240 240 240 180 240 135 240 105 240 45 240 0 240 60 270 90 270 150 270 180 270 225 285 255 255 285 240 255 240 225 240 270 240
Polygon -7500403 true true 75 150
Rectangle -1 true false 120 120 150 150
Rectangle -16777216 true false 135 120 165 195
Polygon -16777216 true false 105 195 90 255 120 255 135 195 165 255 195 255 165 195
Rectangle -16777216 true false 105 120 135 195
Polygon -16777216 true false 150 135 150 135 150 105 180 135 210 135 210 150 180 150 135 135 150 105
Polygon -1 true false 105 135
Polygon -16777216 true false 120 135 120 135 120 105 90 135 60 135 60 150 90 150 135 135 120 105

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

umbrella1
false
0
Polygon -16777216 true false 30 75 210 285 225 285 225 270 30 75
Line -1 false 30 75 60 270
Line -1 false 30 75 150 255
Line -1 false 30 75 195 135
Line -1 false 30 75 180 75
Line -7500403 true 30 75 150 45
Polygon -7500403 true true 60 255 30 75 135 240 60 255
Line -1 false 150 45 30 75
Line -1 false 30 75 15 210
Polygon -7500403 true true 30 75 15 195 60 225 30 75
Polygon -7500403 true true 30 75 135 225 180 135 30 75
Polygon -7500403 true true 30 75 165 120 165 75 45 75
Polygon -7500403 true true 30 75 135 45 165 75 45 75
Line -1 false 150 255 30 75
Line -1 false 30 75 135 45
Line -1 false 30 75 195 135
Line -1 false 30 75 180 75
Line -1 false 30 75 60 270
Line -1 false 30 75 15 210
Circle -1 true false 60 270 0
Rectangle -1 true false 15 210 15 210
Rectangle -1 true false 15 210 15 225
Polygon -7500403 true true 195 135 150 195 150 255 120 210 180 135 195 135
Polygon -7500403 true true 150 255 90 240 60 270 60 255 120 225 150 255
Polygon -7500403 true true 15 210 45 210 60 270 45 210 15 195 15 210
Polygon -7500403 true true 30 210
Polygon -7500403 true true 195 135 165 105 180 75 165 75 165 120 195 135
Polygon -7500403 true true 150 45 150 60 180 75 165 75 135 45 150 45
Line -1 false 195 135 30 75
Line -1 false 150 255 30 75
Circle -1 true false 150 45 0
Circle -1 true false -90 45 30
Line -16777216 false 15 195 30 75
Line -16777216 false 30 75 60 270
Line -16777216 false 30 75 150 255
Line -16777216 false 30 75 195 135
Line -16777216 false 30 75 180 75
Line -16777216 false 30 75 135 45
Line -16777216 false 30 75 15 210

umbrella2
false
0
Polygon -16777216 true false 270 75 90 285 75 285 75 270 270 75
Line -1 false 270 75 240 270
Line -1 false 270 75 150 255
Line -1 false 270 75 105 135
Line -1 false 270 75 120 75
Line -7500403 true 270 75 150 45
Polygon -7500403 true true 240 255 270 75 165 240 240 255
Line -1 false 150 45 270 75
Line -1 false 270 75 285 210
Polygon -7500403 true true 270 75 285 195 240 225 270 75
Polygon -7500403 true true 270 75 165 225 120 135 270 75
Polygon -7500403 true true 270 75 135 120 135 75 255 75
Polygon -7500403 true true 270 75 165 45 135 75 255 75
Line -1 false 150 255 270 75
Line -1 false 270 75 165 45
Line -1 false 270 75 105 135
Line -1 false 270 75 120 75
Line -1 false 270 75 240 270
Line -1 false 270 75 285 210
Circle -1 true false 240 270 0
Rectangle -1 true false 285 210 285 210
Rectangle -1 true false 285 210 285 225
Polygon -7500403 true true 105 135 150 195 150 255 180 210 120 135 105 135
Polygon -7500403 true true 150 255 210 240 240 270 240 255 180 225 150 255
Polygon -7500403 true true 285 210 255 210 240 270 255 210 285 195 285 210
Polygon -7500403 true true 270 210
Polygon -7500403 true true 105 135 135 105 120 75 135 75 135 120 105 135
Polygon -7500403 true true 150 45 150 60 120 75 135 75 165 45 150 45
Line -1 false 105 135 270 75
Line -1 false 150 255 270 75
Circle -1 true false 150 45 0
Circle -1 true false 360 45 30

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="single_surfer" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <metric>number_of_waves</metric>
    <metric>number_of_duckdives</metric>
    <metric>currentwave-size</metric>
    <metric>time_surfing</metric>
    <metric>time_waiting</metric>
    <metric>time_paddling</metric>
    <enumeratedValueSet variable="temperature-maximum">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <steppedValueSet variable="wave-period" first="30" step="30" last="300"/>
    <enumeratedValueSet variable="number-of-surfers">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="wave-size" first="1" step="1" last="4"/>
    <enumeratedValueSet variable="energy-maximum">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="wave-decay-size" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="temperature-threshold">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="multi_surfer" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <metric>number_of_waves</metric>
    <metric>number_of_duckdives</metric>
    <metric>currentwave-size</metric>
    <metric>time_surfing</metric>
    <metric>time_waiting</metric>
    <metric>time_paddling</metric>
    <enumeratedValueSet variable="temperature-maximum">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="energy-threshold" first="25" step="25" last="75"/>
    <enumeratedValueSet variable="wave-period">
      <value value="60"/>
    </enumeratedValueSet>
    <steppedValueSet variable="number-of-surfers" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="wave-size">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-maximum">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wave-decay-size">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="temperature-threshold" first="25" step="25" last="75"/>
  </experiment>
  <experiment name="multi_surfer_env" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <metric>number_of_waves</metric>
    <metric>number_of_duckdives</metric>
    <metric>currentwave-size</metric>
    <metric>time_surfing</metric>
    <metric>time_waiting</metric>
    <metric>time_paddling</metric>
    <enumeratedValueSet variable="temperature-maximum">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <steppedValueSet variable="wave-period" first="30" step="30" last="300"/>
    <enumeratedValueSet variable="number-of-surfers">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="wave-size" first="1" step="1" last="4"/>
    <enumeratedValueSet variable="energy-maximum">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="wave-decay-size" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="temperature-threshold">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@

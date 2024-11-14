globals [
  tick-count            ; Keeps track of the number of ticks
  spread-list           ; List to store spread over time
  dispersion-list       ; List to store dispersion over time
  coverage-list         ; List to store coverage over time
  spread                ; Current spread calculation
  dispersion            ; Current dispersion calculation
  coverage              ; Current coverage calculation
  births                ; Number of births
  deaths                ; Number of deaths
]

turtles-own [
  opinion               ; The agent's opinion, ranging from 0 to 1
  opinion-difference    ; Temporary variable to store opinion difference
  group-strengths       ; List of group strengths
]

; Setup procedure
to setup
  ; Error checks
  if avg-num-groups-per-agent > num-groups [
    user-message "Error: avg-num-groups-per-agent cannot be greater than num-groups."
    stop
  ]
  if avg-num-groups-per-agent < 1 [
    user-message "Error: avg-num-groups-per-agent must be at least 1."
    stop
  ]
  if sd-num-groups-per-agent < 0 [
    user-message "Error: sd-num-groups-per-agent must be non-negative."
    stop
  ]
  if sd-num-groups-per-agent > (num-groups / 2) [
    user-message "Error: sd-num-groups-per-agent must be less than or equal to num-groups divided by 2."
    stop
  ]

  clear-all
  create-turtles num-agents [
    set opinion random-float 1
    ; Initialise group-strengths
    set group-strengths n-values num-groups [ 0 ]

    ; Agent can belong to multiple groups
    ifelse multiple-group-membership? [
      ; Sample num-groups-per-agent from a normal distribution
      let num-groups-per-agent round random-normal avg-num-groups-per-agent sd-num-groups-per-agent
      ; Ensure num-groups-per-agent is within 1 and num-groups
      set num-groups-per-agent max list 1 min list num-groups num-groups-per-agent
      ; Select num-groups-per-agent unique group IDs
      let group-ids n-of num-groups-per-agent n-values num-groups [ [i] -> i + 1 ]
      foreach group-ids [
        id ->  ; 'id' represents each group ID
        let index (id - 1)  ; Adjust to zero-based index
        ifelse binary-group-membership? [
          ; Assign strength of 1
          set group-strengths replace-item index group-strengths 1
        ][
          ; Assign random strength between 0 and 1
          set group-strengths replace-item index group-strengths random-float 1
        ]
      ]
    ][
      ; Agent belongs to only one group
      let group-id 1 + random num-groups
      let index (group-id - 1)
      ifelse binary-group-membership? [
        ; Assign strength of 1
        set group-strengths replace-item index group-strengths 1
      ][
        ; Assign random strength between 0 and 1
        set group-strengths replace-item index group-strengths random-float 1
      ]
    ]
    set size 1.5
  ]

  ; Initialise global variables
  set tick-count 0
  set spread-list []
  set dispersion-list []
  set coverage-list []
  set spread 0
  set dispersion 0
  set coverage 0
  set births 0
  set deaths 0

  ; Setup plot with specific number of bins for the histogram
  set-current-plot "Opinion Distribution"
  set-histogram-num-bars 20  ; Adjust this number to change the bin size

  reset-ticks
end

; Procedure for agent births
to agent-births
  ask turtles [
    if random-float 1 < 0.01 [ ; 1% chance of giving birth each tick
      hatch 1 [ ; create one new agent
        set opinion random-float 1
        set group-strengths n-values num-groups [ 0 ]
        ; Initialize group memberships
        ifelse multiple-group-membership? [
          let num-groups-per-agent round random-normal avg-num-groups-per-agent sd-num-groups-per-agent
          set num-groups-per-agent max list 1 min list num-groups num-groups-per-agent
          let group-ids n-of num-groups-per-agent n-values num-groups [ [i] -> i + 1 ]
          foreach group-ids [
            id ->  
            let index (id - 1)
            ifelse binary-group-membership? [
              set group-strengths replace-item index group-strengths 1
            ][
              set group-strengths replace-item index group-strengths random-float 1
            ]
          ]
        ][
          let group-id 1 + random num-groups
          let index (group-id - 1)
          ifelse binary-group-membership? [
            set group-strengths replace-item index group-strengths 1
          ][
            set group-strengths replace-item index group-strengths random-float 1
          ]
        ]
        set size 1.5
      ]
      set births births + 1
    ]
  ]
end

; Procedure for agent deaths
to agent-deaths
  ask turtles [
    if random-float 1 < 0.01 [ ; 1% chance of dying each tick
      die
      set deaths deaths + 1
    ]
  ]
end

; Go procedure
to go
  if ticks >= max-ticks [ stop ]
  ; Select a random receiver
  let receiver one-of turtles
  ; Determine bubble size (as a number of agents)
  let bubble-size-proportion bubble-size / 100  ; Convert percentage to proportion
  let num-in-bubble max list 1 round (bubble-size-proportion * (count turtles - 1)) ; Agents that are within the bubble
  ; Exclude the receiver from the list of potential senders
  let other-turtles turtles with [ self != receiver ]
  ; Calculate opinion differences for all other turtles
  ask other-turtles [
    set opinion-difference abs (opinion - [opinion] of receiver)
  ]
  ; Sort other turtles by opinion difference
  let sorted-turtles sort-by [[a b] -> [opinion-difference] of a < [opinion-difference] of b ] other-turtles
  ; Select the bubble (the closest agents in opinion)
  let bubble-agents sublist sorted-turtles 0 num-in-bubble
  ; Pick a random sender from the bubble
  let sender one-of bubble-agents
  ; Compute opinion difference between sender and receiver
  let delta ([opinion] of sender - [opinion] of receiver)
  let delta_abs abs delta
  ; Compute group similarity delta_eij
  let delta_eij group-similarity receiver sender
  let one_minus_delta_eij 1 - delta_eij
  ; Compute influence weight w_ijt
  let w_ijt 1 - gamma0 * delta_abs + gamma1 * one_minus_delta_eij * delta_abs
  ; Ensure w_ijt is between -1 and 1
  if w_ijt > 1 [ set w_ijt 1 ]
  if w_ijt < -1 [ set w_ijt -1 ]
  ; Compute s_i
  let s_i mean [ group-strengths ] of receiver
  ; Compute total alpha
  let total_alpha alpha0 + alpha1 * delta_eij + alpha2 * s_i
  ; Update receiver's opinion
  let delta_opinion total_alpha * w_ijt * delta
  ask receiver [
    set opinion opinion + delta_opinion
    ; Truncate opinion to [0,1]
    if opinion > 1 [ set opinion 1 ]
    if opinion < 0 [ set opinion 0 ]
  ]
  ; Update tick count and record data
  set tick-count tick-count + 1
  ; Record polarisation measures
  record-polarisation
  ; Refresh plots automatically
  update-plots
  if ticks mod 100 = 0 [
    show (word "Current opinions at tick " ticks ": " (sort [opinion] of turtles))
  ]
  ; Add agent births and deaths
  agent-births
  agent-deaths
  tick
end

; Procedure to compute group similarity between two agents
to-report group-similarity [ t1 t2 ]
  let gs1 [ group-strengths ] of t1
  let gs2 [ group-strengths ] of t2
  let n length gs1
  let total 0
  let i 0
  while [ i < n ] [
    let s1 item i gs1
    let s2 item i gs2
    set total total + (s1 * s2) ; We use the dot product to measure similarity
    set i i + 1
  ]
  report total / n
end

; Procedure to record polarisation measures
to record-polarisation
  ; Get list of opinions
  let opinions [opinion] of turtles
  ; Spread: difference between max and min opinions
  set spread (max opinions) - (min opinions)
  ; Dispersion: average absolute deviation from mean opinion
  let mean-opinion mean opinions
  set dispersion mean map [ x -> abs (x - mean-opinion) ] opinions

  ; Bucketing opinions into intervals (e.g., 0.0-0.1, 0.1-0.2, ...)
  let buckets map [x -> floor (x * 100) / 100] opinions  ; Adjust bucket size by changing the multiplier/divisor
  let unique-buckets remove-duplicates buckets

  ; Coverage calculation adjusted for bucketing
  set coverage (length unique-buckets) / 100  ; Assuming 100 buckets (0 to 1 in 0.01 increments)

  ; Store the measures
  set spread-list lput spread spread-list
  set dispersion-list lput dispersion dispersion-list
  set coverage-list lput coverage coverage-list

  ; Plot the measures
  set-current-plot "Spread"
  plot spread
  set-current-plot "Dispersion"
  plot dispersion
  set-current-plot "Coverage"
  plot coverage
  set-current-plot "Opinion Distribution"
  histogram [opinion] of turtles
end
@#$#@#$#@
GRAPHICS-WINDOW
1194
275
1243
305
-1
-1
1.0
1
10
1
1
1
0
1
1
1
-20
20
-10
10
0
0
1
ticks
30.0

BUTTON
33
16
99
49
NIL
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
114
17
177
50
NIL
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

SLIDER
29
124
257
157
num-agents
num-agents
10
1000
313.0
1
1
NIL
HORIZONTAL

SLIDER
27
352
258
385
alpha0
alpha0
0
1
0.58
0.01
1
NIL
HORIZONTAL

SLIDER
28
198
257
231
bubble-size
bubble-size
1
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
263
124
492
157
max-ticks
max-ticks
100
100000
17920.0
10
1
NIL
HORIZONTAL

PLOT
543
476
754
626
Spread
Ticks
Spread
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -3844592 true "" "plot spread"

PLOT
762
319
969
469
Dispersion
Ticks
Dispersion
0.0
10.0
0.0
0.5
true
false
"" ""
PENS
"Dispersion Pen" 1.0 0 -3844592 true "" "plot dispersion"

PLOT
543
319
754
469
Coverage
Ticks
Coverage
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"Coverage Pen" 1.0 0 -3844592 true "" "plot coverage"

PLOT
543
118
969
311
Opinion Distribution
Opinion
Number of Users
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"current" 1.0 1 -14439633 true "" "histogram [ opinion ] of turtles"

SLIDER
263
197
490
230
num-groups
num-groups
2
10
8.0
1
1
NIL
HORIZONTAL

SLIDER
27
392
258
425
gamma0
gamma0
0
5
2.32
0.01
1
NIL
HORIZONTAL

SLIDER
265
390
493
423
gamma1
gamma1
-5
5
0.49
0.01
1
NIL
HORIZONTAL

SLIDER
265
350
493
383
alpha1
alpha1
-1
1
1.0
0.01
1
NIL
HORIZONTAL

MONITOR
763
477
971
522
Current Spread
spread
17
1
11

MONITOR
763
522
971
567
Current Dispersion
dispersion
17
1
11

MONITOR
763
568
972
613
Current Coverage
coverage
17
1
11

TEXTBOX
33
100
183
118
Model Dynamics
14
0.0
1

TEXTBOX
29
332
240
352
Opinion Influence Parameters
14
0.0
1

TEXTBOX
32
178
182
196
Simulation Settings
14
0.0
1

SWITCH
28
237
256
270
multiple-group-membership?
multiple-group-membership?
1
1
-1000

SWITCH
264
237
492
270
binary-group-membership?
binary-group-membership?
0
1
-1000

SLIDER
28
276
255
309
avg-num-groups-per-agent
avg-num-groups-per-agent
1
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
26
431
259
464
alpha2
alpha2
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
263
276
493
309
sd-num-groups-per-agent
sd-num-groups-per-agent
1
5
1.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
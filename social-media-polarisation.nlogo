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
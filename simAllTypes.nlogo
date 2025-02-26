; Pedestrian model v 3.0
; Decoding Pedestrian Behaviour

extensions [gis time nw csv table]
breed [targets target]
breed [walkers walker]
breed [crowds crowd]
breed [nodes node]
undirected-link-breed [routes route]

globals [
  paths
  build
  parks
  foot
  hist
  noise
  trees
  lights
  retail
  constr
  embar
  cross
  inter
  tram
  cr
  land
  land-rational
  land-maintainer
  land-environ
  land-land
  land-spon
  bui-res
  patch_size
  tick-datetime
  tram-data
  pois-data
  pois
  sensitivities
 ]

patches-own [
  walkers-num   ;; number of walkers on the starting patch
  counter
  walkable-environment
  tag
  tag_parks
  tag_lights
  tag_crossing
  tag_hist
  tag_noise
  tag_retail
  tag_constr
  tag_emban
  tag_tram
  tag_pois
  tag_int
  tag_crowd
  tag_land
  tag_bui-res
  traffic-intensity
  pois-intensity
]

nodes-own [
  nodal-tags
  pois-tags
  dijkstra-visited?
  dijkstra-distance
  dijkstra-previous
  junction?
  traf-int
  pois-int
  tram-stop
  residential?
]

walkers-own [
  dijkstra-visited?
  reached-target?
  recalculate-route?
  destination
  speed-limit
  memoryxy
  memoryx
  memoryy
  coordinates

  atractor
  distractor
  path
  cost-list
  sum-cost
  dist-list
  sum-dist
  walkers-density
  speed
  walk-time
  getting-back?
  my-type
  attractor-sensitivity
  distractor-sensitivity
  stochastic-component
  spontainity
  discount
]

routes-own [
  ]

to setup

  clear-all
  clear-output
  reset-ticks
  ask patches [set pcolor black]

 ; importing GIS

  set paths gis:load-dataset "data/paths27.shp"
  set build gis:load-dataset "data/bui3.shp"
  set parks gis:load-dataset "data/trees.shp"
  set embar gis:load-dataset "data/walls.shp"
  set lights gis:load-dataset "data/crossing_signals.shp"
  set cross gis:load-dataset "data/crossing.shp"
  set hist gis:load-dataset "data/hist.shp"
  set retail gis:load-dataset "data/shops.shp"
  set constr gis:load-dataset "data/constr.shp"
  set noise gis:load-dataset "data/noise3.shp"
  set tram gis:load-dataset "data/tram3.shp"
  set pois gis:load-dataset "data/pois3.shp"
  set land gis:load-dataset "data/landmarks_full.shp" ; just one shapefile for all landmarks
  set bui-res gis:load-dataset "data/bui_res.shp"
  set cr gis:load-dataset "data/crowd.shp"

 ; coloring world

  gis:set-drawing-color 126  gis:fill embar 1
  gis:set-drawing-color 62  gis:fill parks 2
  gis:set-drawing-color 2  gis:draw paths 3
  gis:set-drawing-color red  gis:fill noise 1
  gis:set-drawing-color yellow  gis:fill retail 1
  gis:set-drawing-color 114  gis:fill land 1
  gis:set-drawing-color 66 gis:fill hist 2
  gis:set-drawing-color white  gis:fill lights 1
  gis:set-drawing-color orange  gis:fill cross 2
  gis:set-drawing-color gray  gis:fill constr 2
  gis:set-drawing-color blue  gis:fill hist 2


  gis:set-world-envelope-ds ( gis:envelope-union-of (gis:envelope-of build)
  (gis:envelope-of constr) (gis:envelope-of hist) (gis:envelope-of embar) (gis:envelope-of parks) (gis:envelope-of noise)
  (gis:envelope-of retail) (gis:envelope-of land) (gis:envelope-of parks) (gis:envelope-of tram) (gis:envelope-of cr) )

  display-streets-in-patches

reset-ticks

end

to display-streets-in-patches

 ask patches [set walkable-environment FALSE ]
 ask patches gis:intersecting paths [
    set pcolor black
    set walkable-environment TRUE
 ]

make-road-network

end

to make-road-network

output-print "--------------- Starting setup procedure... ------------------"
foreach gis:feature-list-of paths [
i ->
  foreach gis:vertex-lists-of i [
  j ->
  let first-node-point nobody
  let previous-node-point nobody
    foreach j [
    k ->
    let location gis:location-of k
    if not empty? location [
    ifelse any? nodes with [xcor = item 0 location and ycor = item 1 location]
    []
    [
    create-nodes 1 [
    set xcor item 0 location
    set ycor item 1 location
    set size 0.6
    set shape "circle"
    set color 23
    set hidden? true
    ]
  ]

; to create links

  let node-here (nodes with [xcor = item 0 location and ycor = item 1 location])
  ifelse previous-node-point = nobody
  [set first-node-point node-here]
  [let who-node 0
   let who-prev 0
   ask node-here
   [create-route-with previous-node-point
   set who-node who]
   ask previous-node-point [
   set who-prev who
   ]
 ]
  set previous-node-point one-of node-here
        ]
      ]
    ]
  ]

  ask routes [set hidden? true ]
  ask nodes  [set traf-int [] ]

;; importing properties from GIS files to patches
  ask patches [ set tag_land [] ]

 ask patches gis:intersecting parks [
      set tag_parks "green"
    ]

output-print "green done"

     ask patches gis:intersecting cross [
      set tag_crossing "crossing"  ]

output-print "crossings done"

     ask patches gis:intersecting lights [
      set tag_lights "lights" ]

output-print "sygnalized crossings done"

 ask patches gis:intersecting embar [
      set tag_emban "emban"
 ;     set pcolor 126
    ]

output-print "retaining walls done"

 ask patches gis:intersecting hist [
    set tag_hist "historic" ]
;      set pcolor 66

print "historic places done"

 ask patches gis:intersecting constr [
  set tag_constr "constr"
    ;  set pcolor 25

    ]
 ; ]
output-print "constructions done"

 let noise-patches patches gis:intersecting noise
 ask n-of (noise-intensity ^ 2 + 58) noise-patches [
  set tag_noise "noise"
    ]
 ; ]

output-print "noise done"

; iterate to get landmarks for each type
 foreach gis:feature-list-of land [
 polygon ->
 ask patches gis:intersecting land [ set tag_land fput (gis:property-value polygon "Type") tag_land ]
  ]

output-print "landmarks done"

 ask patches gis:intersecting bui-res [
 set tag_bui-res "bui-res"

    ]

 output-print "residential buildings done"

 ask patches gis:intersecting retail [
  set tag_retail "retail"
  set pcolor yellow
    ]

output-print "retail done"

 foreach gis:feature-list-of tram [ ;for each polygon
 point ->
 ask patches gis:intersecting point [ set tag_tram (gis:property-value point "tram")
      set pcolor brown ]
  ]

output-print "tram done"

 foreach gis:feature-list-of pois [ ;for each polygon
 point ->
 ask patches gis:intersecting point [ set tag_pois (gis:property-value point "name") ]
  ]

output-print "POIS done"

 foreach gis:feature-list-of cr [ ;for each polygon
 point ->
 ask patches gis:intersecting point [ set tag_crowd "crowd"  ]
  ]

output-print "crowd done"


  setup-data

end

to setup-data
  ; transfering Google populartimes data to nodes: tram stops & pois
   set tram-data csv:from-file "data/tram_dta_transposed.csv"

  ask patches with [ tag_tram != 0] [

    let i 0
    let data tram-data
    while [ i < length tram-data ]
    [
    let in-id item 0 item i tram-data
      if tag_tram = in-id  [
    ;    show "match"
    set traffic-intensity item i tram-data
    set traffic-intensity remove-item 0 traffic-intensity
    ]
      set i i + 1
    ]

  let tram-nodes min-one-of nodes [ distance myself ]

  ask tram-nodes [ set color orange set size 6 set shape "car" set hidden? false ]

  ]

  set pois-data csv:from-file "data/pois_traffic.csv"

  ask patches with [ tag_pois != 0] [
     set pcolor white
    ; let in-id item 1 item 0 tram-data
    let x 0
   ; let datap pois-data
    while [ x < length pois-data ]
    [
    let in-id item 0 item x pois-data
      if tag_pois = in-id  [
    ;    show "match"
    set pois-intensity item x pois-data
    set pois-intensity remove-item 0 pois-intensity
    ]
      set x x + 1
    ]
  let pois-nodes min-one-of nodes [ distance myself ]
  ask pois-nodes [set color 44 set size 4 set shape "house" set hidden? false
      set pois-tags [tag_pois] of myself
  ]

    if item hour pois-intensity > crowd-tolerance [set tag_int "crowd" ]
    sprout-crowds item hour pois-intensity
    ask crowds [set shape "person" set size 2 set color grey
    let nd nodes in-radius 20
    let my-nd one-of nd
    move-to my-nd
    ]

  ]

  ask nodes with [ shape = "car" ] [
  let p patches with [tag_tram != 0 ]
  let myp min-one-of p [ distance myself ]
  set traf-int [ traffic-intensity ] of myp
    set tram-stop [ tag_tram ] of myp ]


   ask patches with [ tag_bui-res != 0] [

  let res-nodes min-one-of nodes [ distance myself ]
    ask res-nodes [ set residential? true ]
  ]

with-local-randomness [ random-seed 47822
  ask n-of num-agen nodes with [residential? = true] [

  ifelse replicate-walking-task? = TRUE ;; if this is true O-D points are set according to the Walking Task

    [ let my-patch patch-here
    ; each residential patch sprouts 1 walker; 660 residential patches = 660 walkers
    ask my-patch [ sprout-walkers 1
      ask walkers-here [ set getting-back? FALSE
      let starting-point nodes with [tram-stop = "teatralny"]
      move-to one-of starting-point ] ] ]

    [ set shape "house"
    set size 2
    let my-patch patch-here
      print my-patch
    ; each residential patch sprouts 1 walker; 660 residential patches = 660 walkers
    ask my-patch [ sprout-walkers 1

      ask walkers-here [ set getting-back? FALSE ] ] ]
    ]

  ]

print "------------------------------------------------------"
  show word "The total number of walkers going to the POIS is " count walkers with [getting-back? = FALSE]
  show word "The total number of walkers going back is " count walkers with [getting-back? = TRUE]
output-print "-----------------------------------------------"

; trying to combine tags from different shapefiles into one list
; maybe more elegant solution for pacthes and nodal tags could be developed but this works fine

  ask patches [ set tag_lights sentence tag_lights tag_hist
                set tag_lights sentence tag_lights tag_noise
                set tag_lights sentence tag_lights tag_emban
                set tag_lights sentence tag_lights tag_constr
                set tag_lights sentence tag_lights tag_int
                set tag_lights sentence tag_lights tag_retail
                set tag_lights sentence tag_lights tag_crossing
                set tag_lights sentence tag_lights tag_land
                set tag_lights sentence tag_lights tag_bui-res
                set tag_lights sentence tag_lights tag_crowd
                set tag sentence tag_lights tag_parks ]

  ask nodes [ set nodal-tags [tag] of patches in-radius GIS-distance  ;; import list of tags to nodes
  set nodal-tags reduce sentence reduce sentence nodal-tags ;; escaping from these double brackets [[]]
  set nodal-tags remove 0 nodal-tags
  set nodal-tags remove-duplicates nodal-tags
  set junction? false ]

  create-sensitivities-table

end

to create-sensitivities-table

set sensitivities table:make

table:put sensitivities "very_low" 0.20
table:put sensitivities "low" 0.35
table:put sensitivities "medium" 0.50
table:put sensitivities "high" 0.65
table:put sensitivities "very_high" 0.80

  setup-agents

end


to setup-agents

  ask walkers [

  set walk-time 0
  set memoryx []
  set memoryy []
  set coordinates []
   ; let attr ["green" "historic" "retail" "crossing" "landmarks" ]
   ; let dis ["constr" "noise" "emban" "crowd" "lights"]
    let types ["rational-walker" "maintainer" "environmental" "landmark" "spontaneous"]
    set my-type one-of types

    if my-type = "rational-walker" [

      set atractor ["rational" "crossing"]
      set distractor [ "lights" ]
    set spontainity 0 ;0.5
    set attractor-sensitivity  table:get sensitivities "low" ;0.18
    set distractor-sensitivity table:get sensitivities "very_low" ;0.2
    set discount discount-rate ;0.5

    ]

  if my-type = "maintainer" [

      set atractor ["maintainer" "green"]
      set distractor ["noise" "crowd"]
      set spontainity 0;0.4
      set attractor-sensitivity table:get sensitivities "medium" ;0.4
      set distractor-sensitivity table:get sensitivities "very_high" ;0.2
      set discount discount-rate;0.08

    ]

    if my-type = "environmental" [

      set atractor ["environ" "emban" ]
      set distractor [ "constr"]
      set spontainity 0;0.9 + random-float 0.2
      set attractor-sensitivity table:get sensitivities "medium" ;2.5
      set distractor-sensitivity table:get sensitivities "medium" ;1
      set discount discount-rate ;0.08

    ]

     if my-type = "landmark" [

      set atractor ["landmark" "historic"]
      set distractor [ "noise"]
      set spontainity 0 ;0.9 + random-float 0.2
      set attractor-sensitivity table:get sensitivities "high" ;1.5
      set distractor-sensitivity table:get sensitivities "low" ;0.7
       set discount discount-rate ;0.08

    ]

     if my-type = "spontaneous" [

      set atractor ["spontan" "crossing"]
      set distractor [ "emban" ]
      set spontainity 0 ;1
      set attractor-sensitivity table:get sensitivities "very_high" ;1.3
      set distractor-sensitivity table:get sensitivities "low";0.8
      set discount discount-rate ;0.05

    ]

     set cost-list []
     set dist-list []
     set reached-target? false

  ]


with-local-randomness [ random-seed 47822 ask walkers with [getting-back? = FALSE]

     [ ifelse replicate-walking-task? = TRUE                  ;; if this is true O-D points are set according to the Walking Task

        [ ask patch 67 -140 [ let dest-nodes nodes in-radius 3
          ask walkers [
          set destination one-of dest-nodes
          ask destination [ set color red set size 4]
          ] ] ]

        [ let dest-nodes nodes with [member? "retail" nodal-tags or pois-tags != 0]
          let dest-nodes2 dest-nodes with [ distance myself < trip-distance ]

        ifelse fixed-OD? = TRUE
           [ set destination one-of dest-nodes2 with-max [ distance myself ] ]
           [ set destination one-of dest-nodes2 ]
          ask destination [ set color white set size 2]
          set color one-of remove grey base-colors ] ]

  ]


ask walkers with [getting-back? = FALSE] [
     let start-node one-of nodes-here
     set speed random-normal 0.7 0.07
          ifelse utility?
      [ set path dijkstra-utility start-node destination show "computing Dijkstra with utility..." ] ;; compute the path according to dijstra-utility
      [ set path dijkstra start-node destination show "computing Dijkstra..." ]

    set sum-cost sum cost-list
    set sum-dist sum dist-list
]

ask walkers with [getting-back? = TRUE] [
    let d nodes with [ shape = "car" ]
    set destination min-one-of d [ distance myself ]
    set color one-of remove grey base-colors
    set reached-target? false
    let start-node one-of nodes-here
    set speed 0.5
    set cost-list []
    set dist-list []

           ifelse utility?
      [ set path dijkstra-utility start-node destination show "computing Dijkstra with utility..." ] ;; compute the path according to dijstra-utility
      [ set path dijkstra start-node destination show "computing Dijkstra..." ]

    set sum-cost sum cost-list
    set sum-dist sum dist-list

]

;; adjust hour; crowd intensity depends on hour
let tdt hour + 5
ifelse tdt < 10  ; control for proper format of time:create

[ let time (word "2024-11-22 " 0 tdt  ":00:00")
  print time
  set tick-datetime time:anchor-to-ticks (time:create time ) 2.5 "second" ]

[ let time (word "2024-11-22 " tdt  ":00:00")
  print time
  set tick-datetime time:anchor-to-ticks (time:create time ) 2.5 "second" ]

print "Ready to go my lord!"

end

to go

  ;; save coordinates to file
  if count walkers with [ reached-target? = false ] < 1 [
  let out-list reduce sentence [self-who-tick-coords] of walkers
  set out-list fput [ "who" "tick" "lon" "lat" ] out-list
  print out-list
    ifelse utility?
    [ csv:to-file "C:/Users/wozni/OneDrive/Documents/GitHub/NetLogo_Pedestrian_Model/sim_data/maintainer.csv" out-list ]
    [ csv:to-file "C:/Users/wozni/OneDrive/Documents/GitHub/NetLogo_Pedestrian_Model/sim_data/coords_trivial.csv" out-list ]

  show "Experiment is done"

    stop ]

   ask walkers  [
    set coordinates lput self-ticks-coords coordinates
    ifelse draw-path?
    [ pen-down ]
    [ pen-up]

   ]

 go-to-destination

tick

end

to go-to-destination  ;; turtle procedure

  ask walkers [

    let dest nodes in-radius 7
    if one-of dest = destination [ set reached-target? true ]

  ]

  ask walkers with [not reached-target? and length path > 0] [

    let grid-node nodes in-radius abs(speed)
    let path-node item 0 path
    face path-node
    forward speed
    set walk-time walk-time + 1
    if count grid-node > 0 and one-of grid-node = path-node and length path > 0 [
        set path remove-item 0 path ]

    let crowd-num count crowds in-cone 1 45
    let hum-num crowd-num
    ifelse hum-num > crowd-tolerance
    [ draw-manouver ]
    [ speed-up ]

  ]

end

to draw-manouver
  lt random 180
  fd random-float 0.5 + 0.3

  slow-down

end

to slow-down

   let people-ahead-x other crowds in-cone GIS-distance 90
   let person-ahead-x min-one-of people-ahead-x [distance myself]

   if person-ahead-x != nobody and speed > 0.2 [
    set speed speed - 0.1 ]

   let crossings-ahead nodes in-cone GIS-distance 90
   let cross-ahead min-one-of crossings-ahead [distance myself]
   if cross-ahead != nobody [
   let nt [nodal-tags] of cross-ahead
    if not empty? nt [
      if one-of nt = "lights" [set speed 0.05] ] ] ;; always slow down before entering light crossings

 end

to speed-up

 let people-ahead-x other crowds in-cone GIS-distance 90
 let person-ahead-x min-one-of people-ahead-x [distance myself]
 if speed <= 0.5 and person-ahead-x = nobody [
    set speed speed + random-float 0.2 ]

end


to-report dijkstra [ start-node finish-node ] ;; basic Dijkstra

let current-walker walker who
  ask nodes [
    set dijkstra-visited? false
    set dijkstra-distance ifelse-value (self = start-node) [0] [10 ^ 4] ; 'infinity'
    set dijkstra-previous nobody
  ]

  let unvisited-nodes nodes
  let current-node start-node


  while [ count unvisited-nodes > 0  ] [

 ;   print (word ([breed] of current-node) " " ([who] of current-node))
    set current-node min-one-of unvisited-nodes [dijkstra-distance]
    ask current-node [

      let me who
      let d dijkstra-distance
      ask route-neighbors with [not dijkstra-visited? ] [

        let cb [link-length] of route me who  ; may be the better option, e.g. [link-length] of route me who
        let dd d + cb
        if  dd < dijkstra-distance [

          set dijkstra-distance dd
          set dijkstra-previous current-node

        ]

      ]

      set dijkstra-visited? true
    ]

    set unvisited-nodes unvisited-nodes with [ not dijkstra-visited? ]

  ]

    let node-list []
    set current-node finish-node

    while [ current-node != start-node and current-node != nobody ] [
      ask current-node [
        set node-list fput self node-list

        if length node-list > 1 [

        let previous-node [ who ] of item 1 node-list
      ;  let node-id [who] of previous-node
        let dist-stage [link-length] of route previous-node who

        ask current-walker [

          let d [dijkstra-distance] of current-node
          set dist-list fput dist-stage dist-list
          set cost-list fput d cost-list ]
      ]

        set current-node dijkstra-previous
      ]
    ]

    report node-list
end


to-report dijkstra-utility [ start-node finish-node ] ;; Dijkstra utility

  let current-walker walker who
  let good-value 0
  let bad-value 0

  ask nodes [
    set dijkstra-visited? false
    set dijkstra-distance ifelse-value (self = start-node) [0] [10 ^ 200] ; 'infinity'
    set dijkstra-previous nobody
  ]

  let unvisited-nodes nodes
  let current-node start-node

  while [ count unvisited-nodes > 0  ] [
    set current-node min-one-of unvisited-nodes [dijkstra-distance]
    ask current-node [ ifelse count my-routes < 2 [    ; ifelse calculates TAGS' costs only if my-links > 2

      let me who
      let d dijkstra-distance
      ask route-neighbors with [not dijkstra-visited? ] [

        let cb [link-length] of route me who
        let dd d + cb

        if  dd < dijkstra-distance [

          set dijkstra-distance dd
          set dijkstra-previous current-node
        ]

      ]

      set dijkstra-visited? true
    ]

      ; cost calculation below
      ; cost rises as the agent approach the destination
      ; bad values increase the cost and repel agent
      ; good values diminish the cost and attract agents
      ; discount is constant value that diminish cost; dependent on link-length

      [

      let me who
      let d dijkstra-distance

      ask route-neighbors with [not dijkstra-visited? ] [

         let attr [atractor] of current-walker
         let dist [distractor] of current-walker
          let add [attractor-sensitivity] of current-walker
          let sub [distractor-sensitivity] of current-walker
        ;  let stoch [stochastic-component] of current-walker
          let spon [spontainity] of current-walker
          let disc [discount] of current-walker

         let c-good sum map [ i -> frequency I attr] nodal-tags ;; for each match "walker - node tags" +1 (counts frequency)
         let c-bad sum map [ i -> frequency I dist] nodal-tags ;; for each match "walker - node tags" +1 (counts frequency)
         let cb [link-length] of route me who
         let my-lnks count my-routes

          ;; each turtle differ in-term of costs
       ;  ifelse count my-routes > 1 [
          let lower-add add - route-variability * add
          let upper-add add + route-variability * add

          let lower-sub sub - route-variability * sub
          let upper-sub sub + route-variability * sub

          set good-value c-good * (lower-add + (random-float (upper-add - lower-add))); frequency of attractor * sensitivity to attractor
          set bad-value c-bad * (lower-sub + (random-float (upper-sub - lower-sub)))



        ;  set good-value c-good * (random-normal add route-variability); frequency of attractor * sensitivity to attractor
        ;  set bad-value c-bad * (random-normal sub route-variability)

      ; total cost of given road segment (link); the bad and good values are weighted by link-length (cb)
      ; d - distance to destination; cb - link-length of given segment; disc - constans;
      ; bad-value - frequency count of repellers at given node
      ; good-value - frequency of attractors at given node

          let dd d + (cb * discount-rate) + (cb * bad-value) - (cb * good-value)

         ifelse  dd < dijkstra-distance [
            set dijkstra-distance dd
            set dijkstra-previous current-node
            set junction? true ]

          [set junction? false]

      ]

      set dijkstra-visited? true

    ]

 ]    ; ifelse finishes here

    set unvisited-nodes unvisited-nodes with [ not dijkstra-visited? ]
 ;   ask current-walker [ let d [dijkstra-distance] of current-node
 ;   set cost-list fput d cost-list ]


  ]  ; while finishes here

    let node-list []
    set current-node finish-node

  ; built a path
    while [ current-node != start-node and current-node != nobody ] [
      ask current-node [
        set node-list fput self node-list

        if length node-list > 1 [

        let previous-node [ who ] of item 1 node-list
      ;  let node-id [who] of previous-node
        let dist-stage [link-length] of route previous-node who

        ask current-walker [

          let d [dijkstra-distance] of current-node
          set dist-list fput dist-stage dist-list
          set cost-list fput d cost-list ]


      ]

        set current-node dijkstra-previous
      ]
    ]

    report node-list

end

 to-report frequency [x the-list]

  report reduce
    [ [occurrence-count next-item] -> ifelse-value (next-item = x) [occurrence-count + 1] [occurrence-count] ] (fput 0 the-list)

end


to-report self-ticks-coords
  ; Report the current ticks and then middle two 'envelope' values of the turtle
  report  sentence ticks (reduce sentence sublist gis:envelope-of self 1 3)
end


to-report self-who-tick-coords
  ; Report a formatted list of who, tick, and coordinate vlaues
  let who-tick-coord-list map [ i -> ( sentence my-type i ) ] coordinates
  report who-tick-coord-list
end

to-report simtime
  report mean [ walk-time ] of walkers
end

to-report mean-link-length
  report mean [link-length] of links
end

to-report simdist
  report mean [ sum-dist ] of walkers
end

to-report times
  let tlist ( [walk-time] of walkers )
  report tlist
end

to-report distances
  let dlist ( [sum-dist] of walkers )
  report dlist
end

to-report typ
  let tlist ( [my-type] of walkers )
  report tlist
end
@#$#@#$#@
GRAPHICS-WINDOW
403
10
1615
1223
-1
-1
4.0
1
10
1
1
1
0
0
0
1
-150
150
-150
150
1
1
1
ticks
30.0

BUTTON
168
62
280
95
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
285
64
375
99
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
217
183
389
216
num-agen
num-agen
0
660
15.0
1
1
NIL
HORIZONTAL

SWITCH
265
106
384
139
draw-path?
draw-path?
0
1
-1000

SLIDER
217
260
389
293
GIS-distance
GIS-distance
0
15
10.0
1
1
NIL
HORIZONTAL

MONITOR
166
12
392
57
NIL
tick-datetime
17
1
11

MONITOR
84
11
159
56
distance
mean [sum-dist] of walkers
17
1
11

MONITOR
84
58
160
103
cost
mean [sum-cost] of walkers
17
1
11

SLIDER
215
373
387
406
hour
hour
1
12
12.0
1
1
NIL
HORIZONTAL

MONITOR
86
110
162
155
cost per dist
mean [sum-dist] of walkers / mean [sum-cost] of walkers
17
1
11

MONITOR
11
159
77
204
searching
count walkers with [not reached-target? and length path > 0]
17
1
11

MONITOR
86
158
152
203
walkers
count walkers
17
1
11

SLIDER
216
334
388
367
crowd-tolerance
crowd-tolerance
1
10
10.0
1
1
NIL
HORIZONTAL

SWITCH
19
304
129
337
get-back?
get-back?
1
1
-1000

SWITCH
19
267
122
300
utility?
utility?
0
1
-1000

MONITOR
9
10
76
55
Total time
(ticks * 2.5) / 60
17
1
11

MONITOR
11
60
73
105
walk-time
simtime
17
1
11

MONITOR
21
215
125
260
NIL
mean-link-length
17
1
11

MONITOR
12
109
69
154
NIL
simdist
17
1
11

SLIDER
217
222
389
255
trip-distance
trip-distance
10
200
200.0
1
1
NIL
HORIZONTAL

SLIDER
7
383
179
416
discount-rate
discount-rate
0
1
0.73
0.01
1
NIL
HORIZONTAL

SLIDER
217
297
389
330
noise-intensity
noise-intensity
0
42
42.0
1
1
NIL
HORIZONTAL

SWITCH
219
143
385
176
replicate-walking-task?
replicate-walking-task?
0
1
-1000

SWITCH
56
460
167
493
fixed-OD?
fixed-OD?
0
1
-1000

SLIDER
214
420
386
453
route-variability
route-variability
0
0.5
0.3
0.1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model uses GIS extension in order to simulate traffic in the city of Torino (Italy) and it shows how traffic conditions influence pollution in the city; in addition it is possible to approximate the amount of money lost due to traffic delays.

## HOW IT WORKS

Patches not intersecting the GIS represent streets and, of course, turtles (cars) can only move on these patches. Turtles are expected to "drive" on the right, speed is represented by the number of patches they go forward and it decreases if there are any other turtles ahead.
Each patch has an indicator of its pollution levels depending on the number of cars on it and pollution diffuses to other patches as time passes.
Each turtle shows speed, waiting time and motion time.

## HOW TO USE IT

First of all setup allows to import the GIS, then it is possible to move on the map and choose different areas of the city of Torino; there is a zoom utility but it is recommended to set zoom between 0.05 and 0.08 before going on.
Display-streets-in-patches (a bit slow) makes the distinction between streets and buildings, while draw-streets draws roadways. Notice that it is possible to open or close parts of a street using close-street-here and open-street-here.
Setup-cars creates the selected number of turtles and Go makes them move.
Two buttons allow to follow one of the turtles and to change color to its path.
Two switches allow to consider pollution and to show its concentration on the map; notice that original colors can be brought back using cancel-colors.
Change-street-color makes streets fade at car passage.

## THINGS TO NOTICE

It is advisable to follow this order in pressing buttons:
setup / display-streets-in-patches / draw-streets / setup-cars / go.

## THINGS TO TRY

Sliders:

cost-of-working represents the average cost of an hour of work (in euros or dollars)

poll-dispersion, if positioned at 1.00 no pollution is dissipated, if positioned at 2.00 50% of pollution disappears

The pollution growth caused by cars is represented by a normal probability distribution with parameters pollution-mean and deviation-mean

## CREDITS AND REFERENCES

SantaFeStreets model -- http://backspaces.net/wiki/NetLogo_Bag_of_Tricks#NetLogo_GIS
Traffic Grid model -- Netlogo Library
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
<experiments>
  <experiment name="experiment3" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <timeLimit steps="3"/>
    <metric>mean [sum-dist] of walkers</metric>
    <metric>mean [sum-cost] of walkers</metric>
    <enumeratedValueSet variable="trip-length">
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
      <value value="80"/>
      <value value="85"/>
      <value value="90"/>
      <value value="95"/>
      <value value="100"/>
      <value value="105"/>
      <value value="110"/>
      <value value="115"/>
      <value value="120"/>
      <value value="125"/>
      <value value="130"/>
      <value value="135"/>
      <value value="140"/>
      <value value="145"/>
      <value value="150"/>
      <value value="155"/>
      <value value="160"/>
      <value value="165"/>
      <value value="170"/>
      <value value="175"/>
      <value value="180"/>
      <value value="185"/>
      <value value="190"/>
      <value value="195"/>
      <value value="200"/>
      <value value="210"/>
      <value value="215"/>
      <value value="220"/>
      <value value="225"/>
      <value value="230"/>
      <value value="235"/>
      <value value="240"/>
      <value value="245"/>
      <value value="250"/>
      <value value="255"/>
      <value value="260"/>
      <value value="265"/>
      <value value="270"/>
      <value value="275"/>
      <value value="280"/>
      <value value="285"/>
      <value value="290"/>
      <value value="295"/>
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>count walkers = 0</exitCondition>
    <metric>ask walkers [self-who-tick-coords]</metric>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="trip-length">
      <value value="285"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agen">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-added">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bad-added">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hour">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment4" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>positions</metric>
  </experiment>
  <experiment name="integration" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>integ</metric>
    <enumeratedValueSet variable="threshold-crowd">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="get-back?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agen">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-added">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bad-added">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hour">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-distance">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="distances" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt; 0</exitCondition>
    <metric>distances</metric>
    <metric>typ</metric>
    <enumeratedValueSet variable="crowd-tolerance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="get-back?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="time" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>times</metric>
    <metric>distances</metric>
    <metric>typ</metric>
    <enumeratedValueSet variable="crowd-tolerance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="get-back?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
1.0
-0.2 1 1.0 0.0
0.0 1 1.0 0.0
0.2 1 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@

breed [nodes node]
nodes-own [hid pred suc]
breed [outs out]
outs-own [Hashdest NodeDest origin note age]

breed [ins in]
ins-own [Hashdest NodeDest origin idealorigin]

links-own [idealDest]

to respond [mymsg]
  hatch-ins 1 [
    set NodeDest ([origin] of mymsg)
    set origin myself
    set Hashdest [hid] of ([origin] of mymsg)   
    set color blue 
    set label ""
    set idealorigin [Hashdest] of mymsg
  ]
  ask mymsg [ die ] 
  
end

to prune_my_links
  foreach n-values Hash_Degree [(hid + (2 ^ ?)) mod (2 ^ Hash_Degree)]
  [
    let c 0
    ask my-out-links  
    [
      if ? = idealDest
      [
        ifelse c = 0
        [
          set c c + 1
        ]
        [
          die
        ]
        
      ]
      
    ]
  ]
end

to go
  
  ask outs [
    set age age + 1
    ifelse NodeDest != nobody
    [
      face NodeDest
      let speed 3
      if distance NodeDest < speed
      [
        set speed distance NodeDest
      ] 
      forward speed    
    ]
    [
      ;;;;;;show (list self " is stuck")
    ]
    if age > Timeout
    [
      die 
    ]
  ]
  ask ins [
    if NodeDest != nobody
    [
      face NodeDest
      let speed 3
      if distance NodeDest < speed
      [
        set speed distance NodeDest
      ] 
      forward speed    
    ]
    
  ]
  ask nodes[
    if random 10 = 1 [ notify]
    if random 20 = 1 [ send_requests ]
    prune_my_links
    ask outs-here [
      if [pred] of myself = 0 and origin != myself
      [
        ask myself [set pred [origin] of myself]
      ]
      if NodeDest = myself
        [
          ifelse note != True
          [
            ask myself [
              let newdest best_finger ([Hashdest] of myself)
              ask myself
              [
                set NodeDest newdest
              ]          
              if newdest = self
              [
                respond myself
              ]
            ]
          ]
          [
            ask myself [get-notified myself]
            die
          ]
        ]
    ]
  ]
  ask nodes[
    ask my-out-links
    [
      if idealDest = ([hid] of myself + 1) mod (2 ^ Hash_Degree)
      [
        
        ask myself [set suc [end2] of myself]
        
      ]
      
      
    ]
    
    
    
    ask ins-here [
      if NodeDest = myself
      [
        let ideal idealorigin
        let node_pointer origin
        ifelse color = violet
        [
          
          ask myself
          [
            set suc [origin] of myself
            ask my-out-links
            [
              if idealDest = (([hid] of myself + 1) mod (2 ^ Hash_Degree))
              [
                die                
              ]
            ]
            create-link-to node_pointer [set idealDest (([hid] of myself + 1) mod (2 ^ Hash_Degree))]
          ]
        ]
        [
          if node_pointer != myself
          [
            ask myself
            [
              ask my-out-links
              [
                if idealDest = ideal 
                [
                  die
                ]
                
              ]
              create-link-to node_pointer [set idealDest ideal]
            ]
          ]
        ]
        ask self [die]
      ]
    ]
  ]
  tick
end



to setup
  clear-all
  reset-ticks
  create-nodes Population
  ask nodes [
    set suc -1
    set pred 0
    set shape "circle"
    set xcor (random max-pxcor * 2) - max-pxcor
    set ycor (random max-pycor * 2) - max-pycor
    set hid (random ((2 ^ Hash_Degree)))
  ]
  ask nodes [
    set label hid
    init
  ]
end

to init ;;scope is on each turtle
  
  foreach n-values Hash_Degree [?]
    [
      let maybe -1
      let ideal 0
      set ideal (hid + 2 ^ ?) mod (2 ^ Hash_Degree)
      set maybe best_node_by_hash_from_subset ideal Nodes in-radius Radius
      if maybe != self and maybe != -1
        [
          ask my-out-links
            [
              if idealDest = ideal
              [
                die
              ]
            ]
          if ? = 0
            [
              set suc maybe
            ]
          create-link-to maybe [set idealDest ideal]
        ]
    ]
  let ideal (hid - 1) mod (2 ^ Hash_Degree)
  let maybe best_node_by_hash_from_subset ideal Nodes in-radius Radius
  if maybe != self
  [
    set pred maybe
  ]
  ask links [set shape "pretty"]     
end

to cheat
  ask nodes [
    foreach n-values Hash_Degree [?]
    [
      let maybe -1
      set maybe best_node_by_hash ((hid + 2 ^ ?) mod (2 ^ Hash_Degree))
      if maybe != self and maybe != -1
      [
        create-link-to maybe
      ]
    ]
    
  ]
  ask links [set shape "pretty"]
end


to-report node_by_hash [hash]
  let output nobody
  ask nodes [
    if [hid] of self = hash
    [
      set output self
    ] 
  ]
  report output
end

to-report best_node_by_hash [hash]
  let output -1
  let dist (2 ^ Hash_Degree)
  ask nodes [
    if (hid - hash) mod (2 ^ Hash_Degree) < dist
    [
      set output hid
      ;;;;;;;;show hid
      set dist (hid - hash) mod (2 ^ Hash_Degree)
    ] 
  ]
  ;;;;;;;;show (list hash output)
  report node_by_hash output  
  
end

to-report best_node_by_hash_from_subset [hash subset]
  let output -1
  let dist (2 ^ Hash_Degree)
  ask subset [
    if (hid - hash) mod (2 ^ Hash_Degree) < dist
    [
      set output hid
      ;;;;;;;;show hid
      set dist (hid - hash) mod (2 ^ Hash_Degree)
    ] 
  ]
  ;;;;show (list hash output)
  report node_by_hash output  
  
end


to send_requests
  foreach n-values Hash_Degree [(hid + (2 ^ ?)) mod (2 ^ Hash_Degree)]
  [
    let localbest 0
    set localbest best_finger ? 
    hatch-outs 1 [
      set age 0
      set color red
      set Hashdest ?
      set NodeDest localbest 
      set origin myself
      set label ""
    ]
  ]
end


to-report best_finger [hash];;call from node or else
  let output -1
  let dist (2 ^ Hash_Degree)
  if nodeInRange hid [hid] of suc (hash) 
    [
      ;;;;show "Arrived!"
      report self 
    ]
  
  
  set output best_node_by_hash_from_subset hash out-link-neighbors
  ;;;;;;show output
  ;;;;;;;;show (list hash output)
  report output  
  
end


;; m frtom node n just told us they might be our pred
to notify
  if suc != -1
  [
    hatch-outs 1 [
      set note true
      set HashDest (([hid] of myself) + 1) mod (2 ^ Hash_Degree)
      set NodeDest [suc] of myself
      set origin myself
      set label ""
      set color yellow
    ]
  ]
end

to get-notified [msg]
  ifelse pred = 0 and [origin] of msg != self
  [
    set pred [origin] of msg
  ]
  [
    let possible ([hid] of ([origin] of msg))
    ifelse nodeInRange ([hid] of pred) ([hid] of self) possible
      [
        let oldpred pred
        let newpred [origin] of msg
        if oldpred != newpred
        [
          hatch-ins 1 [
            set NodeDest oldpred
            set origin newpred
            set Hashdest [hid] of oldpred   
            set color violet
            set label ""
            set idealorigin ([hid] of newpred)
          ]
        set pred newpred
        
        ]
      ]
      [
        hatch-ins 1 [
          set NodeDest ([origin] of msg)
          set origin [pred] of myself
          set Hashdest [hid] of [origin] of msg   
          set color blue 
          set label ""
          set idealorigin [Hashdest] of msg
        ]
      ]
  ]
end

;;called by a node to ensure the ring is properly maintained
to stabalize
  let x [pred] of suc
end


;; reports true if the node is somewhere in the arc of the chord ring spanning nodes x to y, inclusive
to-report nodeInRange [low high test ]
  ;;show (list low high test)
  let delta (high - low) mod  (2 ^ Hash_Degree) 
  ;;show (test - low) mod  (2 ^ Hash_Degree) < delta
  report (test - low) mod  (2 ^ Hash_Degree) < delta
end
@#$#@#$#@
GRAPHICS-WINDOW
279
10
900
626
23
22
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
-23
23
-22
22
1
1
1
ticks
30.0

SLIDER
6
15
178
48
Radius
Radius
0
100
24
1
1
NIL
HORIZONTAL

SLIDER
5
58
177
91
Hash_Degree
Hash_Degree
4
20
20
1
1
NIL
HORIZONTAL

SLIDER
6
99
178
132
Population
Population
0
100
13
1
1
NIL
HORIZONTAL

BUTTON
13
175
77
208
Setup
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
89
176
164
209
Make Pretty
layout-circle (sort-by [[hid] of ?1 < [hid] of ?2]  (sort-on [who] nodes)) max-pxcor * 0.8
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
52
315
115
348
cheat
cheat
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
17
272
80
305
Run
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

PLOT
13
366
213
516
Links
time
links
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -7500403 true "" "plot (count links) / (Hash_Degree * count nodes + 1)"

BUTTON
24
223
150
256
Make New Nodes
  if mouse-down?\n  [\n  \n    ask patch mouse-xcor mouse-ycor\n    [\n    if not any? nodes-here\n    [\n    \n        sprout-nodes 1 [\n          setxy mouse-xcor mouse-ycor\n          set shape \"circle\"\n          set hid (random (2 ^ Hash_Degree) - 1)\n          set label hid\n          init\n          set Population Population + 1\n        ]\n    \n    ]\n    \n  ]\n  tick\n  ]\n  
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
99
273
162
306
step
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
7
137
179
170
Timeout
Timeout
100
10000
10000
100
1
Ticks
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This is an agent based simulation of a dynamic Chord Protocol.  We have three breeds of turtle agents: node, ins, and outs.  Nodes link to other nodes and send messgaes.  Messages are either outs or ins.   

In Chord, nodes are arranged in a ring, ordered by the hash id.  Each node has a directed link to the node with the next highest id it knows about.  In addition, each node has an additional number of directed links, linking to nodes up to half way across the network. 

Outs travel along these directed links to their destinations.  In an ideal Chord network,a message will traverse log n links to it's destination.

Ins are responses to the out messages; while outs travel along links, ins travel over a "direct connection," not needing the links.

For greater detail, see the Chord paper in the references.

## HOW IT WORKS

Nodes begin by creating local networks, looking within a certain radius for nodes to link to.  Using those connections, nodes then try to create links with other nodes best fitting a hash id corresponding to their finger entries (eg, how far can it skip across the network).  

The best matching node for a particular target hash id is the node that equals that hash or has the closest matching hash above this.

Nodes hatch out messages and send them along the links to find the node matching the particular id it wants to link to.  The message gets passed along until it meets the desired node, which sends back an in message.  The original sender then creates a link to the node that sent the in message.

Nodes will periodically discover they have new nodes preceding them.  


## SLIDERS
Radius is the initial "vision" of the node;  when initially determining links, nodes will only look at nodes within this radius.  This creates the initial state of the network.

The hash degree specifies the size of the hash;  each node will be given a random hash id between 0 and 2^(hash_degree)  - 1.

Population specifies the initial number of nodes.

If ins or outs are alive for a certain number of ticks, they are automatically killed based on the timeout value.  It is only for debugging purposes to find loops.


## RUNNING THE SIMULATION
The first step is to run setup to create the initial states of the simulation and connect the nodes locally. The next step is to click make pretty to arrange the nodes in a ring ordered by node id.  

While the simulation is running, nodes will periodically attempt to update each of their links with the best node, creating nnew links if no link for that hash degree existed before, or replacing the current hash degree link.

Additional nodes can be manually added to the the network at any point.  Those nodes will immediatelly connect locally to neighbors, then perform link mainentence like all the rest of the nodes.

Each node needs to keep track of its predecessor and successor to properly handle insertion. To correct for insertions and deletions, each node periodically notifies its successor of its existence.  This allows the receiving nodes to update thier predecessor. To update the successor, a node asks its successor for its predecessor, and updates accordingly based on the responce.


The Cheat button is for debugging; it creates the ideal links for each node in the network without message passing.

## MESSAGE COLOR CODES
RED = out, finger update
YELLOW = out, predecessor notification
BLUE = in, finger update response
PURPLE = in, update successor.

## CREDITS AND REFERENCES

Chord Paper: http://pdos.csail.mit.edu/papers/ton:chord/
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
NetLogo 5.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

pretty
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 165 210

@#$#@#$#@
0
@#$#@#$#@

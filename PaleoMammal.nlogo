extensions [
  gis
]

globals[
  vegetation                ; input data of vegetation types for each patch
  patches-vt                ; patchset of locations with vegetation - aka not the ocean
  water-patches             ; patches which should contain water for animals to drink
  herbivores
  day-count
  hour-of-day
  predation-risk1
  predation-risk2
  predation-risk3
  predation-risk4
  predation-risk5

  veg-type1-encountered
  veg-type2-encountered
  veg-type3-encountered
  veg-type4-encountered
  veg-type5-encountered
  veg-type6-encountered
  veg-type7-encountered
  veg-type8-encountered
  veg-type9-encountered
  veg-type10-encountered
  veg-type11-encountered
  veg-type12-encountered
  veg-type13-encountered
  veg-type14-encountered

]

patches-own [
  vt                        ; vegetation/coastal resource type
  SNSBr-deaths-here
  MSMix-deaths-here
  LBr-deaths-here
  WDGr-deaths-here
  NRum-deaths-here
  total-kills-here
  vegetation-condition      ; 1-10 scale of the quality of forage in a location
]

turtles-own [
  hours-since-water
  herbivore?
  hours-without-water
  target-water-patch
  heading-to-water?
  population-size
  predation-risk

  veg-type1-traversed
  veg-type2-traversed
  veg-type3-traversed
  veg-type4-traversed
  veg-type5-traversed
  veg-type6-traversed
  veg-type7-traversed
  veg-type8-traversed
  veg-type9-traversed
  veg-type10-traversed
  veg-type11-traversed
  veg-type12-traversed
  veg-type13-traversed
  veg-type14-traversed

]

breed [lions lion]
breed [SNSBrS SNSBr]        ; Small nonsocial browsers
breed [MSMixS MSMix]        ; Medium-sized social mixed diets
breed [LBrS LBr]            ; Large browsers
breed [WDGrS WDGr]          ; Water-dependent grazers
breed [NRumS NRum]          ; Nonruminants


lions-own[time-since-last-meal]

to setup
  clear-all
  reset-ticks

  load-map
  load-animals

  set day-count 0
  set hour-of-day 0


  set predation-risk1 Low-Risk-of-Death
  set predation-risk2 ((High-Risk-of-Death - Low-Risk-of-Death) / 4) + Low-Risk-of-Death
  set predation-risk3 ((High-Risk-of-Death - Low-Risk-of-Death) / 4) + predation-risk2
  set predation-risk4 ((High-Risk-of-Death - Low-Risk-of-Death) / 4) + predation-risk3
  set predation-risk5 High-Risk-of-Death

  if display-mode? [modify-for-display]


end

to go

  ask turtles[
    if is-lion? self [
      if hour-of-day > heat-of-the-day-begins and hour-of-day < heat-of-the-day-ends  [repeat lion-speed [move-lions]]
      if lions-move-more-at-night [ if hour-of-day > 19 or hour-of-day < 7 [repeat (lion-speed + 1) [move-lions]]]
    ]
    if is-SNSBr? self [ repeat SNSBr-speed [move-herbivores]]
    if is-MSMix? self [ repeat MSMix-speed [move-herbivores]]
    if is-LBr? self [ repeat LBr-speed [move-herbivores]]
    if is-WDGr? self [ repeat WDGr-speed [move-herbivores]]
    if is-NRum? self [ repeat NRum-speed [move-herbivores]]
  ]

  ask herbivores [set hours-since-water hours-since-water + 1 ]

  update-vegetation
  update-herbivore-population
  if display-kill-locations [ask patches with [total-kills-here > 0 ][set pcolor red]]
  ask lions [set time-since-last-meal time-since-last-meal + 1]
  set hour-of-day hour-of-day + 1

  if hour-of-day > 23 [set hour-of-day 0 set day-count day-count + 1]
  set herbivores turtles with [herbivore? = true] ; this needs to be reset each step in case some die / are created

  tick

end

to move-herbivores

    ifelse hours-since-water > hours-without-water[
   ; Needs Some Water- Thirsty
      ifelse heading-to-water? [ ; already heading to a water patch
         ifelse distance target-water-patch < 1
         [ move-to target-water-patch ]
         [ face target-water-patch fd 1 ]
      ][; heading to a water patch for the first time
         set target-water-patch min-one-of water-patches [distance myself]
         set heading-to-water? true
         ifelse distance target-water-patch < 1
         [ move-to target-water-patch ]
         [ face target-water-patch fd 1 ]
      ]
      if [vt] of patch-here = 1 [ set hours-since-water 0 set heading-to-water? false]
    ]

    [; Foraging

    ;Rank Destinations by the vegetation types for each herbivore type
    let best-vegetation 0
    if is-SNSBr? self [ set best-vegetation neighbors with [vt = 3 or vt = 4 or vt = 5 or vt = 6 or vt = 8 or vt = 10]]
    if is-MSMix? self [ set best-vegetation neighbors with [vt = 3 or vt = 4 or vt = 5 or vt = 6 or vt = 8 or vt = 10 or vt = 2]]
    if is-LBr? self [ set best-vegetation neighbors with [vt = 10]]
    if is-WDGr? self [ set best-vegetation neighbors with [vt = 7]]
    if is-NRum? self [set best-vegetation neighbors with [vt = 1 or vt = 7 or vt = 10] ]

     ;Rank Destinations by the vegetation types for the second tier of preference
    if not any? best-vegetation[
      if is-SNSBr? self [ set best-vegetation neighbors with [vt = 1 or vt = 9 or vt = 11]]
      if is-MSMix? self [ set best-vegetation neighbors with [vt = 1 or vt = 7 or vt = 11]]
      if is-LBr? self [ set best-vegetation neighbors with [vt = 1]]
      if is-WDGr? self [ set best-vegetation neighbors with [vt = 1]]
      if is-NRum? self [set best-vegetation neighbors with [vt = 9 or vt = 11] ]
    ]
     ;Rank Destinations by the vegetation types for the third tier of preference
     if not any? best-vegetation[
      if is-SNSBr? self [ set best-vegetation neighbors with [vt = 7]]
      if is-MSMix? self [ set best-vegetation neighbors with [vt = 9]]
      if is-LBr? self [ set best-vegetation neighbors with [vt = 7 or vt = 9 or vt = 11]]
      if is-WDGr? self [ set best-vegetation neighbors with [vt = 11]]
      if is-NRum? self [set best-vegetation neighbors with [vt > 0] ]
    ]
    ; Include all other patches since the intial preferences were not found
      if not any? best-vegetation  [ set best-vegetation neighbors with [vt > 0]]

      let highest-value max [vegetation-condition] of best-vegetation
      let my-destinations best-vegetation with [vt > 0 and vegetation-condition = highest-value]
      move-to min-one-of my-destinations [total-kills-here]
      ask patch-here [set vegetation-condition vegetation-condition - 1]
    ]

  ;Record the vegetation type of the patch the animal ended up on
  let veg-traversed [vt] of patch-here
  if veg-traversed = 1 [set veg-type1-traversed veg-type1-traversed + 1]
  if veg-traversed = 2 [set veg-type2-traversed veg-type1-traversed + 1]
  if veg-traversed = 3 [set veg-type3-traversed veg-type1-traversed + 1]
  if veg-traversed = 4 [set veg-type4-traversed veg-type1-traversed + 1]
  if veg-traversed = 5 [set veg-type5-traversed veg-type1-traversed + 1]
  if veg-traversed = 6 [set veg-type6-traversed veg-type1-traversed + 1]
  if veg-traversed = 7 [set veg-type7-traversed veg-type1-traversed + 1]
  if veg-traversed = 8 [set veg-type8-traversed veg-type1-traversed + 1]
  if veg-traversed = 9 [set veg-type9-traversed veg-type1-traversed + 1]
  if veg-traversed = 10 [set veg-type10-traversed veg-type1-traversed + 1]
  if veg-traversed = 11 [set veg-type11-traversed veg-type1-traversed + 1]
  if veg-traversed = 12 [set veg-type12-traversed veg-type1-traversed + 1]
  if veg-traversed = 13 [set veg-type13-traversed veg-type1-traversed + 1]
  if veg-traversed = 14 [set veg-type14-traversed veg-type1-traversed + 1]

end

to move-lions
if time-since-last-meal >= hours-between-lion-meals[
  set color blue
  let nearby-patches neighbors with [vt > 0]
  ; should move to a neighbor patch if they are occupied
  let nearby-prey one-of nearby-patches with [any? turtles-here]

     ifelse nearby-prey = nobody [ ; No prey is nearby so move around randomly
       move-to one-of neighbors with [vt > 0]
     ][
       ;move to and attack animal
       move-to nearby-prey
       let prey one-of turtles-here

       let chance-of-death 0
       ifelse is-lion? prey[] [ ;record a kill as long as the other animal is not another lion

        ; Record encounter rate for each veg type
          if [vt] of patch-here = 1 [set veg-type1-encountered veg-type1-encountered + 1]
          if [vt] of patch-here = 2 [set veg-type2-encountered veg-type2-encountered + 1]
          if [vt] of patch-here = 3 [set veg-type3-encountered veg-type3-encountered + 1]
          if [vt] of patch-here = 4 [set veg-type4-encountered veg-type4-encountered + 1]
          if [vt] of patch-here = 5 [set veg-type5-encountered veg-type5-encountered + 1]
          if [vt] of patch-here = 6 [set veg-type6-encountered veg-type6-encountered + 1]
          if [vt] of patch-here = 7 [set veg-type7-encountered veg-type7-encountered + 1]
          if [vt] of patch-here = 8 [set veg-type8-encountered veg-type8-encountered + 1]
          if [vt] of patch-here = 9 [set veg-type9-encountered veg-type9-encountered + 1]
          if [vt] of patch-here = 10 [set veg-type10-encountered veg-type10-encountered + 1]
          if [vt] of patch-here = 11 [set veg-type11-encountered veg-type11-encountered + 1]
          if [vt] of patch-here = 12 [set veg-type12-encountered veg-type12-encountered + 1]
          if [vt] of patch-here = 13 [set veg-type13-encountered veg-type13-encountered + 1]
          if [vt] of patch-here = 14 [set veg-type14-encountered veg-type14-encountered + 1]

         ; Identify the predation risk based on species and vegetation type
         if is-SNSBr? prey [
          if [vt] of patch-here = 1 [set chance-of-death predation-risk4]
          if [vt] of patch-here = 2 [set chance-of-death predation-risk4]
          if [vt] of patch-here = 3 [set chance-of-death predation-risk4]
          if [vt] of patch-here = 4 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 5 [set chance-of-death predation-risk3]
          if [vt] of patch-here = 6 [set chance-of-death predation-risk4]
          if [vt] of patch-here = 7 [set chance-of-death predation-risk1]
          if [vt] of patch-here = 8 [set chance-of-death predation-risk3]
          if [vt] of patch-here = 10 [set chance-of-death predation-risk5]

          if random 100 < chance-of-death [
           ask patch-here [set SNSBr-deaths-here SNSBr-deaths-here + 1]
           set time-since-last-meal 0
          ]
         ]
         if is-MSMix? prey [
          if [vt] of patch-here = 1 [set chance-of-death predation-risk3]
          if [vt] of patch-here = 2 [set chance-of-death predation-risk3]
          if [vt] of patch-here = 3 [set chance-of-death predation-risk3]
          if [vt] of patch-here = 4 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 5 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 6 [set chance-of-death predation-risk3]
          if [vt] of patch-here = 7 [set chance-of-death predation-risk3]
          if [vt] of patch-here = 8 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 10 [set chance-of-death predation-risk5]

          if random 100 < chance-of-death [
           ask patch-here [set MSMix-deaths-here MSMix-deaths-here + 1]
           set time-since-last-meal 0
           ask prey [set population-size population-size - 1]
          ]
         ]
         if is-LBr? prey [
          if [vt] of patch-here = 1 [set chance-of-death predation-risk3]
          if [vt] of patch-here = 2 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 3 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 4 [set chance-of-death predation-risk1]
          if [vt] of patch-here = 5 [set chance-of-death predation-risk1]
          if [vt] of patch-here = 6 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 7 [set chance-of-death predation-risk1]
          if [vt] of patch-here = 8 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 10 [set chance-of-death predation-risk4]

          if random 100 < chance-of-death [
           ask patch-here [set LBr-deaths-here LBr-deaths-here + 1]
           set time-since-last-meal 0
           ask prey [set population-size population-size - 1]
          ]
         ]
         if is-WDGr? prey [
          if [vt] of patch-here = 1 [set chance-of-death predation-risk4]
          if [vt] of patch-here = 2 [set chance-of-death predation-risk3]
          if [vt] of patch-here = 3 [set chance-of-death predation-risk3]
          if [vt] of patch-here = 4 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 5 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 6 [set chance-of-death predation-risk3]
          if [vt] of patch-here = 7 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 8 [set chance-of-death predation-risk3]
          if [vt] of patch-here = 10 [set chance-of-death predation-risk4]

          if random 100 < chance-of-death [
           ask patch-here [set  WDGr-deaths-here  WDGr-deaths-here + 1]
           set time-since-last-meal 0
           ask prey [set population-size population-size - 1]
          ]
         ]
         if is-NRum? prey [
          if [vt] of patch-here = 1 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 2 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 3 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 4 [set chance-of-death predation-risk1]
          if [vt] of patch-here = 5 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 6 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 7 [set chance-of-death predation-risk1]
          if [vt] of patch-here = 8 [set chance-of-death predation-risk2]
          if [vt] of patch-here = 10 [set chance-of-death predation-risk3]

          if random 100 < chance-of-death [
           ask patch-here [set NRum-deaths-here NRum-deaths-here + 1]
           set time-since-last-meal 0
           ask prey [set population-size population-size - 1]
          ]
         ]
     ]]
  ]

end


to make-SNSBrS [ amount veg-to-go-to]
  create-SNSBrS amount [
    set shape "duiker"
    set color 33
    move-to one-of patches-vt with [vt = veg-to-go-to]
    set size 2
    set hours-without-water 100000000000000 ;not an important factor so this number is a stand in for infinity
    set population-size 1
    set predation-risk 0.002
  ]
end

to make-MSMixS [ amount veg-to-go-to]
    create-MSMixS amount[
    set shape "gazelle"
    set color brown
    move-to one-of patches-vt with [vt = veg-to-go-to]
    set size 4
    set hours-without-water (random 12) + 48 ; 2-3 DAYS
    ;set population-size (random 121) + 30
    set predation-risk 0.204
  ]
end

to make-LBrS [ amount veg-to-go-to]
    create-LBrS amount[
    set shape "giraffe"
    set color 47
    move-to one-of patches-vt with [vt = veg-to-go-to]
    set size 4
    set hours-without-water (random 12) + 24 ; 2-3 DAYS
    ;set population-size (random 11) + 5
    set predation-risk 0.174
  ]

end

to make-WDGrS [ amount veg-to-go-to]
    create-WDGrS amount[
    set shape "wildebeest"
    set color 33
    move-to one-of patches-vt with [vt = veg-to-go-to]
    set size 4
    set hours-without-water 24
    ;set population-size (random 121) + 30
    set predation-risk 0.441
  ]

end

to make-NRumS [ amount veg-to-go-to]
  create-NRumS amount[
    set shape "mammoth"
    set color gray
    move-to one-of patches-vt with [vt = veg-to-go-to]
    set size 7
    set hours-without-water 24
    ;set population-size (random 11) + 5
    set predation-risk 0.178
  ]

end

to load-animals

  let veg-type 1
  let veg-type-area count patches-vt with [vt = veg-type]
  make-SNSBrS (veg-type-area * 0.13)  veg-type
  make-MSMixS ((veg-type-area * 3.58) / 90)  veg-type
  make-LBrS ((veg-type-area * 0.52) / 10)  veg-type
  make-WDGrS ((veg-type-area * 4.57) / 90)  veg-type
  make-NRumS ((veg-type-area * 0.97) / 10)  veg-type

  set veg-type 2
  set veg-type-area count patches-vt with [vt = veg-type]
  make-SNSBrS (veg-type-area * 3.36)  veg-type
  make-MSMixS ((veg-type-area * 1.66) / 90)  veg-type
  make-LBrS ((veg-type-area * 0.85) / 10)  veg-type
  make-WDGrS ((veg-type-area * 2.75) / 90)  veg-type
  make-NRumS ((veg-type-area * 1.11) / 10)  veg-type

  set veg-type 3
  set veg-type-area count patches-vt with [vt = veg-type]
  make-SNSBrS (veg-type-area * 0.66)  veg-type
  make-MSMixS ((veg-type-area * 3.55) / 90)  veg-type
  make-LBrS ((veg-type-area * 0.04) / 10)  veg-type
  make-WDGrS ((veg-type-area * 0.54) / 90)  veg-type
  make-NRumS ((veg-type-area * 0.07) / 10)  veg-type

  set veg-type 4
  set veg-type-area count patches-vt with [vt = veg-type]
  make-SNSBrS (veg-type-area * 0.61)  veg-type
  make-MSMixS ((veg-type-area * 2.01) / 90)  veg-type
  make-LBrS ((veg-type-area * 0.04) / 10)  veg-type
  make-WDGrS ((veg-type-area * 0.38) / 90)  veg-type
  make-NRumS ((veg-type-area * 0.06) / 10)  veg-type

  set veg-type 5
  set veg-type-area count patches-vt with [vt = veg-type]
  make-SNSBrS (veg-type-area * 0.62)  veg-type
  make-MSMixS ((veg-type-area * 6.18) / 90)  veg-type
  make-LBrS ((veg-type-area * 0.14) / 10)  veg-type
  make-WDGrS ((veg-type-area * 2.92) / 90)  veg-type
  make-NRumS ((veg-type-area * 0.44) / 10)  veg-type

  set veg-type 6
  set veg-type-area count patches-vt with [vt = veg-type]
  make-SNSBrS (veg-type-area * 0.79)  veg-type
  make-MSMixS ((veg-type-area * 6.33) / 90)  veg-type
  make-LBrS ((veg-type-area * 0.05) / 10)  veg-type
  make-WDGrS ((veg-type-area * 0.88) / 90)  veg-type
  make-NRumS ((veg-type-area * 0.12) / 10)  veg-type

  set veg-type 7
  set veg-type-area count patches-vt with [vt = veg-type]
  make-SNSBrS (veg-type-area * 0.61)  veg-type
  make-MSMixS ((veg-type-area * 6.66) / 90)  veg-type
  make-LBrS ((veg-type-area * 0.29) / 10)  veg-type
  make-WDGrS ((veg-type-area * 5.37) / 90)  veg-type
  make-NRumS ((veg-type-area * 0.82) / 10)  veg-type

  set veg-type 8
  set veg-type-area count patches-vt with [vt = veg-type]
  make-SNSBrS (veg-type-area * 0.75)  veg-type
  make-MSMixS ((veg-type-area * 5.71) / 90)  veg-type
  make-LBrS ((veg-type-area * 0.04) / 10)  veg-type
  make-WDGrS ((veg-type-area * 0.77) / 90)  veg-type
  make-NRumS ((veg-type-area * 0.01) / 10)  veg-type

  set veg-type 10
  set veg-type-area count patches-vt with [vt = veg-type]
  make-SNSBrS (veg-type-area * 3.36)  veg-type
  make-MSMixS ((veg-type-area * 1.67) / 90)  veg-type
  make-LBrS ((veg-type-area * 0.85) / 10)  veg-type
  make-WDGrS ((veg-type-area * 2.75) / 90)  veg-type
  make-NRumS ((veg-type-area * 1.11) / 10)  veg-type


  ask turtles [ ; Only herbivores have been created so this is really only herbivores
    set hours-since-water random 10 ; so that not everyone starts out at the exact same thirst level
    set herbivore? true ; lions are updated below and there aren't any lions yet
    set heading-to-water? false
    set veg-type1-traversed 0
    set veg-type2-traversed 0
    set veg-type3-traversed 0
    set veg-type4-traversed 0
    set veg-type5-traversed 0
    set veg-type6-traversed 0
    set veg-type7-traversed 0
    set veg-type8-traversed 0
    set veg-type9-traversed 0
    set veg-type10-traversed 0
    set veg-type11-traversed 0
    set veg-type12-traversed 0
    set veg-type13-traversed 0
    set veg-type14-traversed 0
  ]

  set herbivores turtles with [herbivore? = true]

  let lion-pop (count patches-vt) * lion-density
  create-lions lion-pop [
    set shape "lion"
    set color 45
    move-to one-of patches-vt
    set size 2
    set herbivore? false
    set predation-risk 0
    set time-since-last-meal random 10
  ]

end

to update-vegetation
   ask patches-vt [set total-kills-here SNSBr-deaths-here + MSMix-deaths-here + LBr-deaths-here + WDGr-deaths-here + NRum-deaths-here]
   ask patches-vt with [vegetation-condition < 10 ] [set vegetation-condition vegetation-condition + 0.5]
   ask patches-vt with [vegetation-condition < 0 ] [set vegetation-condition 0]
   ask patches-vt with [vegetation-condition > 10 ] [set vegetation-condition 10]
end

to update-herbivore-population
  ask SNSBrS with [population-size < 1][ set population-size 1 move-to one-of patches-vt]
  ask MSMixS with [population-size < 1][ set population-size (random 121) + 30 move-to one-of patches-vt]
  ask LBrS with [population-size < 1][ set population-size (random 11) + 5 move-to one-of patches-vt]
  ask WDGrS with [population-size < 1][ set population-size (random 121) + 30 move-to one-of patches-vt]
  ask NRumS with [population-size < 1][ set population-size (random 11) + 5 move-to one-of patches-vt]


end

to load-map

  ;Load the LGM map at 1km resolution
  set vegetation gis:load-dataset "data/lgm_km.asc"
  resize-world 0 110 0 198 set-patch-size 2.5

  gis:set-world-envelope gis:envelope-of vegetation
  gis:apply-raster vegetation vt
  ask patches with [vt = 0] [set pcolor blue]
  set patches-vt patches with [vt > 0]
  set water-patches patches with [vt = 1]

;  ask patches-vt [
;    if vt = 1  [set pcolor 88]      ; Freshwater wetlands
;    if vt = 2  [set pcolor 86]      ; Alluvial Vegetation
;    if vt = 3  [set pcolor 116]     ; Strandveld
;    if vt = 4  [set pcolor 16]      ; Saline Vegetation
;    if vt = 5  [set pcolor 43]      ; Renosterveld
;    if vt = 7  [set pcolor 48]      ; Grassland
;    if vt = 6  [set pcolor 56]      ; Sand Fynbos
;    if vt = 8  [set pcolor 76]      ; Thicket
;    if vt = 9  [set pcolor 126]     ; Limestone Fynbos
;    if vt = 10 [set pcolor 53]      ; Aeolianite (Coastal)
;    if vt = 11 [set pcolor 26]      ; Sandy Beach (Coastal)
;    if vt = 12 [set pcolor 34]      ; TMS Boulders (Coastal)
;    if vt = 13 [set pcolor 35]      ; TMS Eroded Rocky Headlands (Coastal)
;    if vt = 14 [set pcolor 36]      ; TMS Wave Cut Platforms (Coastal)
;  ]


  ask patches-vt [
    set pcolor scale-color green vt -5 14
    set SNSBr-deaths-here 0
    set MSMix-deaths-here 0
    set LBr-deaths-here 0
    set WDGr-deaths-here 0
    set NRum-deaths-here 0
    set total-kills-here 0
    set vegetation-condition 10

    set veg-type1-encountered 0
    set veg-type2-encountered 0
    set veg-type3-encountered 0
    set veg-type4-encountered 0
    set veg-type5-encountered 0
    set veg-type6-encountered 0
    set veg-type7-encountered 0
    set veg-type8-encountered 0
    set veg-type9-encountered 0
    set veg-type10-encountered 0
    set veg-type11-encountered 0
    set veg-type12-encountered 0
    set veg-type13-encountered 0
    set veg-type14-encountered 0
  ]

  ask water-patches [set pcolor 88]

  ask patches with [pcolor = black] [
    set vt 0
    set pcolor blue]




end


to-report count-SNSBr
  report count herbivores with [ is-SNSBr? self ]
end

to-report count-MSMix
  let animals herbivores with [ is-MSMix? self ]
  let total sum [population-size] of animals
  report total
end

to-report count-LBr
  let animals herbivores with [ is-LBr? self ]
  let total sum [population-size] of animals
  report total
end

to-report count-WDGr
  let animals herbivores with [ is-WDGr? self ]
  let total sum [population-size] of animals
  report total
end

to-report count-NRum
  let animals herbivores with  [ is-NRum? self ]
  let total sum [population-size] of animals
  report total
end



to modify-for-display
  ; to make viewing and testing the model simpler this procedure lowers the number of agents in the model

let total-animals count turtles
  repeat (total-animals * 0.75) [ask one-of turtles [die]]

end



to-report save-model-output
; - Number of animals encountered on each vegetation type (14 columns)
; - Death total for each herbivore type for each vegetation type (5 * 14  = 70 columns)
; - Time spent for each herbivore type on each vegetation type (5 * 14  = 70 columns)


  let v1h1-death  sum [SNSBr-deaths-here] of patches with [vt = 1]
  let v1h2-death  sum [MSMix-deaths-here] of patches with [vt = 1]
  let v1h3-death  sum [LBr-deaths-here] of patches with [vt = 1]
  let v1h4-death  sum [WDGr-deaths-here] of patches with [vt = 1]
  let v1h5-death  sum [NRum-deaths-here] of patches with [vt = 1]

  let v2h1-death  sum [SNSBr-deaths-here] of patches with [vt = 2]
  let v2h2-death  sum [MSMix-deaths-here] of patches with [vt = 2]
  let v2h3-death  sum [LBr-deaths-here] of patches with [vt = 2]
  let v2h4-death  sum [WDGr-deaths-here] of patches with [vt = 2]
  let v2h5-death  sum [NRum-deaths-here] of patches with [vt = 2]

  let v3h1-death  sum [SNSBr-deaths-here] of patches with [vt = 3]
  let v3h2-death  sum [MSMix-deaths-here] of patches with [vt = 3]
  let v3h3-death  sum [LBr-deaths-here] of patches with [vt = 3]
  let v3h4-death  sum [WDGr-deaths-here] of patches with [vt = 3]
  let v3h5-death  sum [NRum-deaths-here] of patches with [vt = 3]

  let v4h1-death  sum [SNSBr-deaths-here] of patches with [vt = 4]
  let v4h2-death  sum [MSMix-deaths-here] of patches with [vt = 4]
  let v4h3-death  sum [LBr-deaths-here] of patches with [vt = 4]
  let v4h4-death  sum [WDGr-deaths-here] of patches with [vt = 4]
  let v4h5-death  sum [NRum-deaths-here] of patches with [vt = 4]

  let v5h1-death  sum [SNSBr-deaths-here] of patches with [vt = 5]
  let v5h2-death  sum [MSMix-deaths-here] of patches with [vt = 5]
  let v5h3-death  sum [LBr-deaths-here] of patches with [vt = 5]
  let v5h4-death  sum [WDGr-deaths-here] of patches with [vt = 5]
  let v5h5-death  sum [NRum-deaths-here] of patches with [vt = 5]

  let v6h1-death  sum [SNSBr-deaths-here] of patches with [vt = 6]
  let v6h2-death  sum [MSMix-deaths-here] of patches with [vt = 6]
  let v6h3-death  sum [LBr-deaths-here] of patches with [vt = 6]
  let v6h4-death  sum [WDGr-deaths-here] of patches with [vt = 6]
  let v6h5-death  sum [NRum-deaths-here] of patches with [vt = 6]

  let v7h1-death  sum [SNSBr-deaths-here] of patches with [vt = 7]
  let v7h2-death  sum [MSMix-deaths-here] of patches with [vt = 7]
  let v7h3-death  sum [LBr-deaths-here] of patches with [vt = 7]
  let v7h4-death  sum [WDGr-deaths-here] of patches with [vt = 7]
  let v7h5-death  sum [NRum-deaths-here] of patches with [vt = 7]

  let v8h1-death  sum [SNSBr-deaths-here] of patches with [vt = 8]
  let v8h2-death  sum [MSMix-deaths-here] of patches with [vt = 8]
  let v8h3-death  sum [LBr-deaths-here] of patches with [vt = 8]
  let v8h4-death  sum [WDGr-deaths-here] of patches with [vt = 8]
  let v8h5-death  sum [NRum-deaths-here] of patches with [vt = 8]

  let v9h1-death  sum [SNSBr-deaths-here] of patches with [vt = 9]
  let v9h2-death  sum [MSMix-deaths-here] of patches with [vt = 9]
  let v9h3-death  sum [LBr-deaths-here] of patches with [vt = 9]
  let v9h4-death  sum [WDGr-deaths-here] of patches with [vt = 9]
  let v9h5-death  sum [NRum-deaths-here] of patches with [vt = 9]

  let v10h1-death  sum [SNSBr-deaths-here] of patches with [vt = 10]
  let v10h2-death  sum [MSMix-deaths-here] of patches with [vt = 10]
  let v10h3-death  sum [LBr-deaths-here] of patches with [vt = 10]
  let v10h4-death  sum [WDGr-deaths-here] of patches with [vt = 10]
  let v10h5-death  sum [NRum-deaths-here] of patches with [vt = 10]

  let v11h1-death  sum [SNSBr-deaths-here] of patches with [vt = 11]
  let v11h2-death  sum [MSMix-deaths-here] of patches with [vt = 11]
  let v11h3-death  sum [LBr-deaths-here] of patches with [vt = 11]
  let v11h4-death  sum [WDGr-deaths-here] of patches with [vt = 11]
  let v11h5-death  sum [NRum-deaths-here] of patches with [vt = 11]

  let v12h1-death  sum [SNSBr-deaths-here] of patches with [vt = 12]
  let v12h2-death  sum [MSMix-deaths-here] of patches with [vt = 12]
  let v12h3-death  sum [LBr-deaths-here] of patches with [vt = 12]
  let v12h4-death  sum [WDGr-deaths-here] of patches with [vt = 12]
  let v12h5-death  sum [NRum-deaths-here] of patches with [vt = 12]

  let v13h1-death  sum [SNSBr-deaths-here] of patches with [vt = 13]
  let v13h2-death  sum [MSMix-deaths-here] of patches with [vt = 13]
  let v13h3-death  sum [LBr-deaths-here] of patches with [vt = 13]
  let v13h4-death  sum [WDGr-deaths-here] of patches with [vt = 13]
  let v13h5-death  sum [NRum-deaths-here] of patches with [vt = 13]

  let v14h1-death  sum [SNSBr-deaths-here] of patches with [vt = 14]
  let v14h2-death  sum [MSMix-deaths-here] of patches with [vt = 14]
  let v14h3-death  sum [LBr-deaths-here] of patches with [vt = 14]
  let v14h4-death  sum [WDGr-deaths-here] of patches with [vt = 14]
  let v14h5-death  sum [NRum-deaths-here] of patches with [vt = 14]


  let h1v1-time-mean mean [veg-type1-traversed] of SNSBrS
  let h2v1-time-mean mean [veg-type1-traversed] of MSMixS
  let h3v1-time-mean mean [veg-type1-traversed] of LBrS
  let h4v1-time-mean mean [veg-type1-traversed] of WDGrS
  let h5v1-time-mean mean [veg-type1-traversed] of NRumS

  let h1v2-time-mean mean [veg-type2-traversed] of SNSBrS
  let h2v2-time-mean mean [veg-type2-traversed] of MSMixS
  let h3v2-time-mean mean [veg-type2-traversed] of LBrS
  let h4v2-time-mean mean [veg-type2-traversed] of WDGrS
  let h5v2-time-mean mean [veg-type2-traversed] of NRumS

  let h1v3-time-mean mean [veg-type3-traversed] of SNSBrS
  let h2v3-time-mean mean [veg-type3-traversed] of MSMixS
  let h3v3-time-mean mean [veg-type3-traversed] of LBrS
  let h4v3-time-mean mean [veg-type3-traversed] of WDGrS
  let h5v3-time-mean mean [veg-type3-traversed] of NRumS

  let h1v4-time-mean mean [veg-type4-traversed] of SNSBrS
  let h2v4-time-mean mean [veg-type4-traversed] of MSMixS
  let h3v4-time-mean mean [veg-type4-traversed] of LBrS
  let h4v4-time-mean mean [veg-type4-traversed] of WDGrS
  let h5v4-time-mean mean [veg-type4-traversed] of NRumS

  let h1v5-time-mean mean [veg-type5-traversed] of SNSBrS
  let h2v5-time-mean mean [veg-type5-traversed] of MSMixS
  let h3v5-time-mean mean [veg-type5-traversed] of LBrS
  let h4v5-time-mean mean [veg-type5-traversed] of WDGrS
  let h5v5-time-mean mean [veg-type5-traversed] of NRumS

  let h1v6-time-mean mean [veg-type6-traversed] of SNSBrS
  let h2v6-time-mean mean [veg-type6-traversed] of MSMixS
  let h3v6-time-mean mean [veg-type6-traversed] of LBrS
  let h4v6-time-mean mean [veg-type6-traversed] of WDGrS
  let h5v6-time-mean mean [veg-type6-traversed] of NRumS

  let h1v7-time-mean mean [veg-type7-traversed] of SNSBrS
  let h2v7-time-mean mean [veg-type7-traversed] of MSMixS
  let h3v7-time-mean mean [veg-type7-traversed] of LBrS
  let h4v7-time-mean mean [veg-type7-traversed] of WDGrS
  let h5v7-time-mean mean [veg-type7-traversed] of NRumS

  let h1v8-time-mean mean [veg-type8-traversed] of SNSBrS
  let h2v8-time-mean mean [veg-type8-traversed] of MSMixS
  let h3v8-time-mean mean [veg-type8-traversed] of LBrS
  let h4v8-time-mean mean [veg-type8-traversed] of WDGrS
  let h5v8-time-mean mean [veg-type8-traversed] of NRumS

  let h1v9-time-mean mean [veg-type9-traversed] of SNSBrS
  let h2v9-time-mean mean [veg-type9-traversed] of MSMixS
  let h3v9-time-mean mean [veg-type9-traversed] of LBrS
  let h4v9-time-mean mean [veg-type9-traversed] of WDGrS
  let h5v9-time-mean mean [veg-type9-traversed] of NRumS

  let h1v10-time-mean mean [veg-type10-traversed] of SNSBrS
  let h2v10-time-mean mean [veg-type10-traversed] of MSMixS
  let h3v10-time-mean mean [veg-type10-traversed] of LBrS
  let h4v10-time-mean mean [veg-type10-traversed] of WDGrS
  let h5v10-time-mean mean [veg-type10-traversed] of NRumS

  let h1v11-time-mean mean [veg-type11-traversed] of SNSBrS
  let h2v11-time-mean mean [veg-type11-traversed] of MSMixS
  let h3v11-time-mean mean [veg-type11-traversed] of LBrS
  let h4v11-time-mean mean [veg-type11-traversed] of WDGrS
  let h5v11-time-mean mean [veg-type11-traversed] of NRumS

  let h1v12-time-mean mean [veg-type12-traversed] of SNSBrS
  let h2v12-time-mean mean [veg-type12-traversed] of MSMixS
  let h3v12-time-mean mean [veg-type12-traversed] of LBrS
  let h4v12-time-mean mean [veg-type12-traversed] of WDGrS
  let h5v12-time-mean mean [veg-type12-traversed] of NRumS

  let h1v13-time-mean mean [veg-type13-traversed] of SNSBrS
  let h2v13-time-mean mean [veg-type13-traversed] of MSMixS
  let h3v13-time-mean mean [veg-type13-traversed] of LBrS
  let h4v13-time-mean mean [veg-type13-traversed] of WDGrS
  let h5v13-time-mean mean [veg-type13-traversed] of NRumS

  let h1v14-time-mean mean [veg-type14-traversed] of SNSBrS
  let h2v14-time-mean mean [veg-type14-traversed] of MSMixS
  let h3v14-time-mean mean [veg-type14-traversed] of LBrS
  let h4v14-time-mean mean [veg-type14-traversed] of WDGrS
  let h5v14-time-mean mean [veg-type14-traversed] of NRumS




  let filename  "pap-mammals-abm-output_"
  set filename word filename behaviorspace-experiment-name
  set filename word filename ".csv"
  let text-out 0

  ifelse file-exists? filename [][
    file-open filename
    set text-out (sentence ", behaviorspace-run-number , High-Risk-of-Death , Low-Risk-of-Death , lion-density , heat-of-the-day-begins , heat-of-the-day-ends , lion-speed , lions-move-more-at-night , SNSBr-speed , MSMix-speed , WDGr-speed , NRum-speed , LBr-speed , veg-type1-encountered , veg-type2-encountered , veg-type3-encountered , veg-type4-encountered , veg-type5-encountered , veg-type6-encountered , veg-type7-encountered , veg-type8-encountered , veg-type9-encountered , veg-type10-encountered , veg-type11-encountered , veg-type12-encountered , veg-type13-encountered , veg-type14-encountered ,  v1h1-death , v1h2-death , v1h3-death , v1h4-death , v1h5-death , v2h1-death , v2h2-death , v2h3-death , v2h4-death , v2h5-death , v3h1-death , v3h2-death , v3h3-death , v3h4-death , v3h5-death , v4h1-death , v4h2-death , v4h3-death , v4h4-death , v4h5-death , v5h1-death , v5h2-death , v5h3-death , v5h4-death , v5h5-death , v6h1-death , v6h2-death , v6h3-death , v6h4-death , v6h5-death , v7h1-death , v7h2-death , v7h3-death , v7h4-death , v7h5-death , v8h1-death , v8h2-death , v8h3-death , v8h4-death , v8h5-death , v9h1-death , v9h2-death , v9h3-death , v9h4-death , v9h5-death , v10h1-death , v10h2-death , v10h3-death , v10h4-death , v10h5-death , v11h1-death , v11h2-death , v11h3-death , v11h4-death , v11h5-death , v12h1-death , v12h2-death , v12h3-death , v12h4-death , v12h5-death , v13h1-death , v13h2-death , v13h3-death , v13h4-death , v13h5-death , v14h1-death , v14h2-death , v14h3-death , v14h4-death , v14h5-death , h1v1-time-mean , h2v1-time-mean , h3v1-time-mean , h4v1-time-mean , h5v1-time-mean , h1v2-time-mean , h2v2-time-mean , h3v2-time-mean , h4v2-time-mean , h5v2-time-mean , h1v3-time-mean , h2v3-time-mean , h3v3-time-mean , h4v3-time-mean , h5v3-time-mean , h1v4-time-mean , h2v4-time-mean , h3v4-time-mean , h4v4-time-mean , h5v4-time-mean , h1v5-time-mean , h2v5-time-mean , h3v5-time-mean , h4v5-time-mean , h5v5-time-mean , h1v6-time-mean , h2v6-time-mean , h3v6-time-mean , h4v6-time-mean , h5v6-time-mean , h1v7-time-mean , h2v7-time-mean , h3v7-time-mean , h4v7-time-mean , h5v7-time-mean , h1v8-time-mean , h2v8-time-mean , h3v8-time-mean , h4v8-time-mean , h5v8-time-mean , h1v9-time-mean , h2v9-time-mean , h3v9-time-mean , h4v9-time-mean , h5v9-time-mean , h1v10-time-mean , h2v10-time-mean , h3v10-time-mean , h4v10-time-mean , h5v10-time-mean , h1v11-time-mean , h2v11-time-mean , h3v11-time-mean , h4v11-time-mean , h5v11-time-mean , h1v12-time-mean , h2v12-time-mean , h3v12-time-mean , h4v12-time-mean , h5v12-time-mean , h1v13-time-mean , h2v13-time-mean , h3v13-time-mean , h4v13-time-mean , h5v13-time-mean , h1v14-time-mean , h2v14-time-mean , h3v14-time-mean , h4v14-time-mean , h5v14-time-mean , ticks ,")
    file-type text-out
    file-print ""
    file-close
  ]

  file-open filename

  set text-out (sentence "," behaviorspace-run-number "," High-Risk-of-Death "," Low-Risk-of-Death "," lion-density "," heat-of-the-day-begins "," heat-of-the-day-ends "," lion-speed ","
         lions-move-more-at-night "," SNSBr-speed "," MSMix-speed "," WDGr-speed "," NRum-speed "," LBr-speed "," veg-type1-encountered "," veg-type2-encountered "," veg-type3-encountered ","
         veg-type4-encountered "," veg-type5-encountered "," veg-type6-encountered "," veg-type7-encountered "," veg-type8-encountered "," veg-type9-encountered "," veg-type10-encountered ","
         veg-type11-encountered "," veg-type12-encountered "," veg-type13-encountered "," veg-type14-encountered ","
         v1h1-death "," v1h2-death "," v1h3-death "," v1h4-death "," v1h5-death ","
         v2h1-death "," v2h2-death "," v2h3-death "," v2h4-death "," v2h5-death ","
         v3h1-death "," v3h2-death "," v3h3-death "," v3h4-death "," v3h5-death ","
         v4h1-death "," v4h2-death "," v4h3-death "," v4h4-death "," v4h5-death ","
         v5h1-death "," v5h2-death "," v5h3-death "," v5h4-death "," v5h5-death ","
         v6h1-death "," v6h2-death "," v6h3-death "," v6h4-death "," v6h5-death ","
         v7h1-death "," v7h2-death "," v7h3-death "," v7h4-death "," v7h5-death ","
         v8h1-death "," v8h2-death "," v8h3-death "," v8h4-death "," v8h5-death ","
         v9h1-death "," v9h2-death "," v9h3-death "," v9h4-death "," v9h5-death ","
         v10h1-death "," v10h2-death "," v10h3-death "," v10h4-death "," v10h5-death ","
         v11h1-death "," v11h2-death "," v11h3-death "," v11h4-death "," v11h5-death ","
         v12h1-death "," v12h2-death "," v12h3-death "," v12h4-death "," v12h5-death ","
         v13h1-death "," v13h2-death "," v13h3-death "," v13h4-death "," v13h5-death ","
         v14h1-death "," v14h2-death "," v14h3-death "," v14h4-death "," v14h5-death ","
         h1v1-time-mean "," h2v1-time-mean "," h3v1-time-mean "," h4v1-time-mean "," h5v1-time-mean ","
         h1v2-time-mean "," h2v2-time-mean "," h3v2-time-mean "," h4v2-time-mean "," h5v2-time-mean ","
         h1v3-time-mean "," h2v3-time-mean "," h3v3-time-mean "," h4v3-time-mean "," h5v3-time-mean ","
         h1v4-time-mean "," h2v4-time-mean "," h3v4-time-mean "," h4v4-time-mean "," h5v4-time-mean ","
         h1v5-time-mean "," h2v5-time-mean "," h3v5-time-mean "," h4v5-time-mean "," h5v5-time-mean ","
         h1v6-time-mean "," h2v6-time-mean "," h3v6-time-mean "," h4v6-time-mean "," h5v6-time-mean ","
         h1v7-time-mean "," h2v7-time-mean "," h3v7-time-mean "," h4v7-time-mean "," h5v7-time-mean ","
         h1v8-time-mean "," h2v8-time-mean "," h3v8-time-mean "," h4v8-time-mean "," h5v8-time-mean ","
         h1v9-time-mean "," h2v9-time-mean "," h3v9-time-mean "," h4v9-time-mean "," h5v9-time-mean ","
         h1v10-time-mean "," h2v10-time-mean "," h3v10-time-mean "," h4v10-time-mean "," h5v10-time-mean ","
         h1v11-time-mean "," h2v11-time-mean "," h3v11-time-mean "," h4v11-time-mean "," h5v11-time-mean ","
         h1v12-time-mean "," h2v12-time-mean "," h3v12-time-mean "," h4v12-time-mean "," h5v12-time-mean ","
         h1v13-time-mean "," h2v13-time-mean "," h3v13-time-mean "," h4v13-time-mean "," h5v13-time-mean ","
         h1v14-time-mean "," h2v14-time-mean "," h3v14-time-mean "," h4v14-time-mean "," h5v14-time-mean ","
         ticks ",")
  file-type text-out
  file-print ""

  file-close

  report""

end








@#$#@#$#@
GRAPHICS-WINDOW
322
11
607
517
-1
-1
2.5
1
10
1
1
1
0
0
0
1
0
110
0
198
0
0
1
Hours
30.0

BUTTON
19
31
125
64
Setup Model
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
20
73
124
106
Run Model
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

BUTTON
19
113
124
146
Run Once
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
649
440
827
473
lion-density
lion-density
0
0.1
0.08
0.001
1
per km
HORIZONTAL

SLIDER
8
199
180
232
SNSBr-speed
SNSBr-speed
1
5
1.0
1
1
km
HORIZONTAL

SLIDER
7
235
179
268
MSMix-speed
MSMix-speed
1
5
2.0
1
1
km
HORIZONTAL

SLIDER
8
272
180
305
LBr-speed
LBr-speed
1
5
2.0
1
1
km
HORIZONTAL

SLIDER
9
308
181
341
WDGr-speed
WDGr-speed
1
5
2.0
1
1
km
HORIZONTAL

SLIDER
8
343
180
376
NRum-speed
NRum-speed
1
5
2.0
1
1
km
HORIZONTAL

SWITCH
9
384
181
417
display-kill-locations
display-kill-locations
1
1
-1000

SLIDER
649
477
837
510
hours-between-lion-meals
hours-between-lion-meals
1
50
20.0
1
1
NIL
HORIZONTAL

MONITOR
716
23
790
68
Time of Day
hour-of-day
17
1
11

MONITOR
656
23
713
68
Days
day-count
17
1
11

SLIDER
654
73
875
106
heat-of-the-day-begins
heat-of-the-day-begins
0
23
11.0
1
1
: 00
HORIZONTAL

SLIDER
654
109
876
142
heat-of-the-day-ends
heat-of-the-day-ends
1
23
16.0
1
1
: 00
HORIZONTAL

PLOT
655
167
1030
386
Herbivore Populations
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"SNSBr" 1.0 0 -1184463 true "" "if ticks > 1 [plot count-SNSBr]"
"MSMix" 1.0 0 -14454117 true "" "if ticks > 1 [plot count-MSMix]"
"LBr" 1.0 0 -2674135 true "" "if ticks > 1 [plot count-LBr]"
"WDGr" 1.0 0 -955883 true "" "if ticks > 1 [plot count-WDGr]"
"NRum" 1.0 0 -15637942 true "" "if ticks > 1 [plot count-NRum]"

SLIDER
7
426
184
459
High-Risk-of-Death
High-Risk-of-Death
1
100
90.0
1
1
NIL
HORIZONTAL

SLIDER
8
464
184
497
Low-Risk-of-Death
Low-Risk-of-Death
1
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
649
517
821
550
lion-speed
lion-speed
1
5
1.0
1
1
km
HORIZONTAL

SWITCH
648
556
849
589
lions-move-more-at-night
lions-move-more-at-night
0
1
-1000

TEXTBOX
651
420
801
438
LION SETTINGS
11
0.0
1

SWITCH
6
557
154
590
display-mode?
display-mode?
1
1
-1000

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

duiker
false
0
Polygon -7500403 true true 182 200 188 249 177 249 172 199 164 187 138 189 91 191 76 179 64 209 47 209 46 181 35 149 44 135 77 125 109 125 179 131 185 88 199 87 209 95 217 110 227 116 223 124 201 122 187 151 188 173
Polygon -7500403 true true 64 208 75 249 62 249 48 208
Polygon -16777216 true false 205 104 204 107 207 108 209 108 210 106 209 104
Polygon -7500403 true true 185 179 191 171 194 150 201 137 201 133 203 128 205 126 210 123 203 117 186 132 180 167
Polygon -7500403 true true 156 133 168 128 174 120 178 116 185 109 186 98 186 88 185 88 183 85 181 82 185 80 190 79 193 83 193 87 190 97 187 135 167 143

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

gazelle
false
0
Polygon -7500403 true true 182 200 188 249 177 249 172 199 164 187 138 189 91 191 76 179 64 209 47 209 46 181 35 149 44 135 77 125 109 125 179 131 185 88 199 87 209 95 217 110 235 119 228 135 203 125 205 156 188 173
Polygon -7500403 true true 64 208 75 249 62 249 48 208
Polygon -16777216 true false 195 94 194 78 191 69 175 57 159 47 154 40 166 40 179 45 190 55 202 69 206 83 205 97
Polygon -1 true false 79 180 90 191 141 192 154 188 163 187 165 182 140 183 112 183 99 182 87 175 80 175
Polygon -1 true false 202 127 200 144 200 158 193 164 187 171 186 175 196 172 207 154 207 139 203 126
Polygon -16777216 true false 164 186 151 182 136 183 112 184 99 184 94 180 90 174 111 176 143 176 159 176
Polygon -16777216 true false 205 104 204 107 207 108 209 108 210 106 209 104

giraffe
false
0
Polygon -7500403 true true 196 193 192 284 182 286 180 233 169 224 155 210 115 210 74 215 67 243 52 246 51 218 40 186 48 164 72 148 140 134 150 120 184 82 195 55 205 31 225 39 230 51 246 67 241 79 213 66 187 152
Polygon -7500403 true true 67 244 78 283 66 283 52 242
Polygon -7500403 true true 202 49 202 24 213 28 211 44

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

lion
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true -2 195 32 179 30 183 34 194 34 206 16 227 16 258 23 266 34 267 36 261 27 254 27 231 56 207 64 199 71 210 62 229 61 244 78 262 80 269 96 268 99 262 73 240 75 232 96 208 94 197 109 212 138 214 158 214 162 211 168 214 169 239 163 252 156 249 150 266 165 265 174 248 182 241 194 261 196 272 213 272 215 263 203 259 188 207 202 184 206 185 223 165 241 159 255 146 280 152 273 142 288 147 295 135 293 128 275 114 266 106
Polygon -7500403 true true 13 192 17 182 26 166 31 154 44 143 63 134 137 135 162 128 191 117 201 110 217 103 228 92 249 87 272 94 273 107 272 105 282 117
Line -7500403 true 12 188 7 146
Polygon -7500403 true true 30 182 15 170 12 138 7 133 8 148 8 171 9 185 10 192 27 180
Polygon -16777216 true false 267 112 262 116 272 117 269 113

mammoth
false
0
Polygon -7500403 true true 195 181 180 196 165 196 166 178 151 148 151 163 136 178 61 178 45 196 30 196 16 178 16 163 1 133 16 103 46 88 106 73 166 58 196 28 226 28 255 78 271 193 256 193 241 118 226 118 211 133
Rectangle -7500403 true true 165 195 180 225
Rectangle -7500403 true true 30 195 45 225
Rectangle -16777216 true false 165 225 180 240
Rectangle -16777216 true false 30 225 45 240
Line -16777216 false 255 90 240 90
Polygon -7500403 true true 0 165 0 135 15 135 0 165
Polygon -1 true false 224 122 234 129 242 135 260 138 272 135 287 123 289 108 283 89 276 80 267 73 276 96 277 109 269 122 254 127 240 119 229 111 225 100 214 112

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

test
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

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

wildebeest
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123
Polygon -1 true false 233 85 225 76 223 62 232 49 243 44 247 44 243 49 239 52 238 56 238 59 239 63 239 66 243 72 250 70 252 68 255 69 255 77 249 82 243 85 237 85

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
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment-test" repetitions="2" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>day-count = 30</exitCondition>
    <metric>save-model-output</metric>
    <enumeratedValueSet variable="display-kill-locations">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="High-Risk-of-Death">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-mode?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LBr-speed">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lion-density">
      <value value="0.08"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heat-of-the-day-ends">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heat-of-the-day-begins">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lion-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lions-move-more-at-night">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NRum-speed">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours-between-lion-meals">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MSMix-speed">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Low-Risk-of-Death">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SNSBr-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WDGr-speed">
      <value value="2"/>
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

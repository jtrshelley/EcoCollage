breed [ sewers sewer ]                ;; This creates icons for the sewers
breed [ GI a-GI ]                     ;; This creates icons for green infrastructure
breed [ outflow-cells outflow-cell ]  ;; This creates an icon for the outflow cell
breed [ road-cells road-cell ]        ;; This creates icons to distinguish road cells

globals [
  
  ;; Constant = value will not change within a single model run.  Variables not designated as constant may be updated during a single model run, dependent upon model conditions.
  global-infiltration         ;; cumulative infiltration across entire landscape
  global-GI-infiltration      ;; cumulative infiltration in green infrastructure over entire landscape
  global-overflow             ;; cumulative volume of water which has overflowed downstream (outside of our landscape) from the storm sewers
  global-precipitation        ;; cumulative precipitation which has fallen across entire landscape
  average-water-height        ;; average water depth across landscape
  average-water-height-roads  ;; average water depth on roads
  global-evapotrans           ;; cumulative evapotranspiration across landscape
  global-evapo                ;; cumulative evaporation across landscape
  global-sewer                ;; cumulative water which has entered the sewers, in UNITS
  water-in-pipes
  above-0-ponded-water        ;; depth of ponded water on a cell, excluding water in green infrastructure storage capacity in millimeters
  water-in-storage            ;; depth of water in green infrastructure storage in millimeters
  proportion-saturated-cells  ;; proporation of green infrastructure cells which have saturated soil
  overflow-amount             ;; depth of water that has overflowed downstream from the storm sewer system in millimeters
  max-sewer-capacity          ;; the total amount of water, in liters, that the sewers can handle before they fail and lose all capacity.
                              ;; calibrated to reflect the amount of water that falls during a 5 year storm of the specified length. Constant.
  full-sewers?
  sewer-basin-capacity        ;; the volume of water in m^3 a basin can hold.
  adjusted-sewer-basin-capacity ;; height of the water in mm if the basins had the same dimensions as the cells
  sewer-basin-height-below-pipe     ;; the amount of water that will never flow out of a sewer catchment basin through the pipe. We calculate it is 62% of the sewer-basin-capacity
  
  total-rainfall              ;; the total amount in mm of rain that will fall during the storm event. Constant.
  av-infil-rate               ;; average infiltration rate over the landscape, for permeable and green infrastructure cells combined
  ponded-water                ;; cumulative ponded water, includes water in green infrastructure storage and all other surface water
  cell-dimension              ;; length represented by one side of a cell in millimeters.  All cells are square, so either length or width could be represented by cell-dimension. Constant.
  surfCell                    ;; area represented by a cell in square meters - for now it will be 10000 mm by 10000 mm (10m by 10m). Constant.
  sewer-rate                  ;; rate at which water enters the storm drains, with units converted to cubic millimeter per minute per drain. Constant.
  base-sewer-rate             ;; the rate at which water enters the storm drains when the sewer system is not full or if CSOs are allowed
  full-sewer-rate             ;; WHAT IS THIS???????????????????????????????????????????????????????????????????????
  used-sewer-rate
  benchmark-storm             ;; total millimeters of rain that will fall in a storm of a given duration which happens at a given frequency. Constant.
  sewer-drain-rate            ;; the amount of water treated by the sewage treatment plant each model iteration. 
                              ;; Sewer-drain-rate scales with the landscape so that larger landscapes have correspondingly higher treatment rates. Constant.
  
  global-sewer-drain          ;; cumulative water which has been treated by sewage treatment plant
  evapotrans-rate             ;; in millimeters, the amount of water that evapotranspirates in 1 minute ( daily-evapotranspiration-rate / 1440 ). Constant.
  rainfall-rate               ;; in millimeters, the amount of rainfall that falls in one minute (daily-rainfall-rate/1440). Constant until rainfall ends.
  evapo-rate                  ;; in millimeters, the amount of water that evaporates from IMPERVIOUS cover in 1 minute. Constant after rainfall stops.
  hydraulic-conductivity      ;; in millimeters per minute or ( hourly-hydraulic-conductivity / 60 ). Constant.
  global-outflow              ;; cumulative water which has flowed into outlet cell and left the landscape
  conversion-multiplier       ;; a value which converts millimeters of water depth into cubic meters for any patch size.  Cell-dimension must be in millimeters. Constant.
  cumulative-margin-of-error  ;; global tracker which determines proportion difference between all water which has fallen and water with known outcomes.  Due to flow code.
  margin-of-error             ;; global tracker which determines proportion difference within an iteration between water which has fallen and water with known outcomes.  Due to flow code.
  daily-evaporation-rate      ;; the daily rate of evaporation, calibrated for Chicago at 4.66 mm per 24 hour period
  daily-evapotranspiration-rate ;; the daily rate of evapotranspiration. set to 
  
  decimal-places
  curbs
  base-max-wet-depth
  num-gardens
  total-cost
  
]

patches-own [
  
  ;; Variables tracking water and water movement
  iteration-infiltration      ;; the amount of water in millimeters which infiltrated on a cell in a given iteration
  iteration-precipitation     ;; the amount of precipitation in millimeters which fell on a cell in given iteration
  iteration-water-balance     ;; water balance= iteration precipitation minus all water outcomes, in millimeters, for a given cell in a given iteration
  iteration-evapotrans        ;; the amount of water in millimeters which evapotransporates in a cell in a given iteration
  iteration-evapo             ;; the amount of water in millimeters which evaporates in a cell in a given iteration
  iteration-sewers            ;; the amount of water in millimeters which leaves the system through the storm sewers in a cell in a given iteration.  Process only occurs in sewer cells.
  iteration-outflow           ;; the amount of water in millimeters which leaves the system though the outlet in a cell in a given iteration.  Process only occurs in outlet cell.
  infiltration-amount         ;; amount of water infiltrated on a cell in a given iteration
  
  ;; Variables for type of cell and cell soil properties
  cover-type                  ;; type of surface on the cell, 1 = Green Infrastructure ; 2 = impermeable ; 3 = permeable .  Constant.
  total-water                 ;; pooled water depth on a cell at the start of an iteration, then both pooled and new rain water after precipitation occurs
  storage-capacity            ;; the potential amount of water which can stay behind on a cell in storage rather than flowing. Constant.
  sewers?                     ;; yes/no whether the cell contains a storm sewer. Constant.
  roads?                      ;; yes/no whether the cell is a road.  Constant.
  outflow?                    ;; yes/no whether the cell is the outflow cell.  Constant.
  height-in-sewer-basin       ;; height in mm of water in the sewer catchment basin, if the basin had the same dinemsions of the cells.
  
  ;; Variables for surface flow - taken from the wetland flow model
  water-column                ;; the height of surface water on a cell in millimeters
  water-column-future         ;; temporary storage of the future-water-column values
  elevation                   ;; the height of the non-water portion of a cell's elevation. e.g. the underlying elevation. Constant.
  adjusted-elevation          ;; elevion minus the storage capacity
  total-height                ;; elevation and water column heights combined
  
  ;; Variables for green-ampt infiltration model
  max-wet-depth                    ;; depth that water can infiltrate in millimeters. Represents the depth to bedrock or the water table.  Set by slider, revised by storage capacity. Constant.
  initial-moisture-deficit         ;; hydrologic characteristic of a cell's soil, determined from a table, indicating initial moisture condition of a cell (Vol. of Air / Vol. of Voids, 
                                   ;; expressed as a fraction). Constant. 
  capillary-suction                ;; the suction at the wetting front, a measure of the pressure with which water moves into soil voids, Psi, based on soil type, from a table. Constant.
  saturated-hydraulic-conductivity ;; the hydraulic conductivity of the soil, a measure of the ease at which water can move between voids
                                   ;; stays constant for a given soil type at a specific temperature.  May need to be modified for cold soils. Constant.
  cumulative-infiltration-amount   ;; the amount of water that has infiltrated so far, in millimeters 
  max-infil-value                  ;; calculated value for the maximum amount of water that can be infiltrated given the moisture deficit and the the max wet depth. In millimeters. Constant.
  saturated-water-amount           ;; REMOVE- No longer needed
  water-volume-deficit             ;; REMOVE- No longer needed
  new-water                        ;; REMOVE- No longer needed
  pool-depth                       ;; REMOVE- No longer needed
  time-to-saturated                ;; REMOVE- No longer needed
  infiltration-rate                ;; maximum rate at which water could theoretically infiltrate into a given soil type given the amount of water that has already infiltrated.
                                   ;;   May be higher than the actual infiltration rate which is limited by the rainfall-rate.

  ;; Variables for groundwater flow - MAY BE ABLE TO REMOVE ALL IF WE PERMANENTLY REMOVE GROUNDWATER FLOW
  sedimDepth                  ;;depth of sediment. Moira uses 100 for all cells
  head-boundary?              ;; binary variable, true if it's a boundary
  specYield                   ;;porosity, empty space in a medium through which water can flow
  conductivity                ;; hydraulic conductivity, measures resistance to flow and depends on the material in millimeters/day
  initial-head                ;; stored head value
  head                        ;;water level in millimeters
  headNext                    ;; Buffer layer - New head after flow (waterVolume / (surfCell * specYield)) - (sedimDepth - elevation)
  waterVolume                 ;; (head - (elevation - sedimDepth)) * surfCell * specYield)
  waterVolumeNext             ;; stored value of new volume used to calculate new head level
  

]
;; Sets variables which belong to agents.  Empty because we use agents (turtles) as graphics to show green infrastructure, roads, sewers, and the outlet, and they have no variables of their own.
turtles-own [
]

;; reads in green-space
to read-file
  ask patches[
    set cover-type 2
    if(not roads?)[
    set pcolor grey + 1]
  ]
  file-close
  file-open "results.txt"
  while[not file-at-end?][
    let inX file-read
    let inY file-read
    if ( min-pxcor < inX / 25 ) and ( inX / 25 < max-pxcor)[
      if( min-pycor < inY / 25 ) and ( inY / 25 < max-pycor)[
        ask patch floor( inX / 25 ) ( max-pycor - ceiling(inY / 25) )[
          if(not roads?)[
            set cover-type 1
            set pcolor green
            set num-gardens (num-gardens + 1)
          ]
        ]
      ]
    ]
  ]
  file-close
end

to setup-storm-type
  if storm-type = "100-year" [
    if storm-hours = 1 [ set total-rainfall 75.9968]
    if storm-hours = 2 [ set total-rainfall 91.7702]
    if storm-hours = 3 [ set total-rainfall 100.5078]
    if storm-hours = 4 [ set total-rainfall 106.553]
    if storm-hours = 5 [ set total-rainfall 111.2266]
    if storm-hours = 6 [ set total-rainfall 115.0366]
    if storm-hours = 7 [ set total-rainfall 118.2878]
    if storm-hours = 8 [ set total-rainfall 121.0818]
    if storm-hours = 9 [ set total-rainfall 123.571]
    if storm-hours = 10 [ set total-rainfall 125.8062]
    if storm-hours = 11 [ set total-rainfall 127.8382]
    if storm-hours = 12 [ set total-rainfall 129.7178]
    if storm-hours = 13 [ set total-rainfall 131.445]
    if storm-hours = 14 [ set total-rainfall 133.0706]
    if storm-hours = 15 [ set total-rainfall 134.5692]
    if storm-hours = 16 [ set total-rainfall 135.9916]
    if storm-hours = 17 [ set total-rainfall 137.3378]
    if storm-hours = 18 [ set total-rainfall 138.6078]
    if storm-hours = 19 [ set total-rainfall 139.8016]
    if storm-hours = 20 [ set total-rainfall 140.97]
    if storm-hours = 21 [ set total-rainfall 142.0622]
    if storm-hours = 22 [ set total-rainfall 143.129]
    if storm-hours = 23 [ set total-rainfall 144.145]
    if storm-hours = 24 [ set total-rainfall 145.1102]
  ]
end

;; Create storm sewers and set the rate at which they drain water from the landscape
to setup-sewers
    ;; volume per drain per minute = drainage-rate * patch-area * distance-btwn-drains^2
    ;; sewer rate is in mm3 per minute per drain.
    ;; the 251,902.79 is the cubic mm per square meter per minute
  ;; define which patches are storm sewers based upon the sewer-spacing variable (set via slider).  
  ;; Storm sewers are created only on cells which are both impermeable and roads.  This redundancy makes it easier to define different rules for storm sewer placement.
  ;temporarily assigning sewer-spacing automatically
  let sewer-spacing 6
  set decimal-places 5
  ask patches [
    ifelse ( ( ( pxcor - 1 ) mod ( sewer-spacing * 2) ) = 0 and ( ( pycor - 1 ) mod ( sewer-spacing * 2 ) ) = 0 and cover-type != 1 and roads? = true )
    or ( ( ( pxcor ) mod ( sewer-spacing * 2) ) = 0 and ( ( pycor - sewer-spacing - 1) mod ( sewer-spacing * 2 ) ) = 0 and cover-type != 1 and roads? = true )
    or ( ( ( pxcor - sewer-spacing - 1 ) mod ( sewer-spacing * 2) ) = 0 and ( ( pycor ) mod ( sewer-spacing * 2 ) ) = 0 and cover-type != 1 and roads? = true )
    [
      set sewers? true
    ]
    [ set sewers? false ]
  ]
  
  ;; Revises overall sewer rate into a per-sewer rate so that for a given landscape size, the total amount of water entering all storm sewers is constant and does not change with number of sewers
  ;; First, counts the storm sewers
  let sewer-count ( count patches with [ sewers? = true ] )
  let sewer-% ( sewer-count / (count patches ) )
  let sewer-multiplier ( 1 / sewer-% )
  set sewer-rate ( 0.155340047 * sewer-multiplier )
  ;; divides the sewer rate into a per iteration rate and rounds to the precision number of decimal places
  set base-sewer-rate precision ( sewer-rate / Repetitions-per-Iteration ) decimal-places
  
  ;; sets the amount of rain which will fall in a 5-year storm of a given length in order to calibrate overall sewer capacity for a 5-year storm
  if storm-hours = 1 [ set benchmark-storm 43.154 ]
  if storm-hours = 2 [ set benchmark-storm 49.913 ]
  if storm-hours = 3 [ set benchmark-storm 58.0644]
  if storm-hours = 4 [ set benchmark-storm 61.0616]
  if storm-hours = 5 [ set benchmark-storm 63.2968]
  if storm-hours = 6 [ set benchmark-storm 65.0494]
  if storm-hours = 7 [ set benchmark-storm 66.5226]
  if storm-hours = 8 [ set benchmark-storm 67.7672]
  if storm-hours = 9 [ set benchmark-storm 68.834]
  if storm-hours = 10 [ set benchmark-storm 69.7992]
  if storm-hours = 11 [ set benchmark-storm 70.6882]
  if storm-hours = 12 [ set benchmark-storm 71.3232]
  if storm-hours = 13 [ set benchmark-storm 72.3138]
  if storm-hours = 14 [ set benchmark-storm 72.898]
  if storm-hours = 15 [ set benchmark-storm 73.533]
  if storm-hours = 16 [ set benchmark-storm 73.9648]
  if storm-hours = 17 [ set benchmark-storm 74.7014]
  if storm-hours = 18 [ set benchmark-storm 75.057]
  if storm-hours = 19 [ set benchmark-storm 75.7682]
  if storm-hours = 20 [ set benchmark-storm 76.2]
  if storm-hours = 21 [ set benchmark-storm 76.2762]
  if storm-hours = 22 [ set benchmark-storm 77.1144]
  if storm-hours = 23 [ set benchmark-storm 77.1144]
  if storm-hours = 24 [ set benchmark-storm 40.789]
    ;; to get the maximum amount that sewers can drain in a 5 year storm for the given time period,
    ;; converts the amount of rain that falls in a 5 year storm of the appropriate length (benchmark-storm) to meters and
    ;; multiplies by the area of a cell in square meters
    ;; multiplies by the count of cells
    ;;;; this results in the volume of water that falls over the entire landscape during a 5 year storm of different durations
  set max-sewer-capacity ( ( benchmark-storm * .001 ) * ( cell-dimension * .001 ) * (cell-dimension * .001 ) * ( count patches ) )
  ;; adjust the rate that the sewer capacity renews (tratment rate) by the size of the landscape
  set sewer-drain-rate ( 0.0018563 * ( count patches ) )
  ;; Calculate the rate at which individual sewers regain capacity by dividing the treatment rate by the number of sewers
  set full-sewer-rate ( sewer-drain-rate / ( count patches with [ sewers? = true ] ) )
  ;; the volume in cubic mmm of a catch basin
  set sewer-basin-capacity 9477000000
  set adjusted-sewer-basin-capacity ( sewer-basin-capacity / ( 10000 * 10000 ) )
  set sewer-basin-height-below-pipe ( adjusted-sewer-basin-capacity * .62)
  
end


to setup
  ;;Reset all conditions
  clear-all
  resize-world 0 21 0 21
  ;; set the length of each side of each cell in millimeters
    ;; 10000 cell size is 10 by 10 meters - converted to millimeters
    set cell-dimension 10000
        
    ;; set the variable which converts water heights into volumes in liters
    set conversion-multiplier ( ( cell-dimension * .001 ) * (cell-dimension * .001 ) )
    
    ;; set the area of a cell to be the square of its side length
    set surfCell ( cell-dimension * cell-dimension )
    
    ;;set decimal places arbitarily for now
    set decimal-places 5
    set curbs true
    set base-max-wet-depth 2000
    
    ;; set the storm-type using code below which considers the length and statistical frequency of a storm to determine cumulative rainfall
    setup-storm-type
    ;; set the evapotranspiration rate to be the daily rate divided by the number of iterations in a day, rounded to decimal-places of decimal places.
    set daily-evaporation-rate 3.5625 ;; in mm
    set daily-evapotranspiration-rate 1.66 ;; in mm
    set evapotrans-rate ( precision ( ( ( daily-evapotranspiration-rate  ) / ( 24 * 60 ) ) / Repetitions-per-Iteration ) decimal-places )
    ;; set the rainfall rate to be the total rainfall which will occur during a storm of a given length which occurs at a given storm frequency 
    set rainfall-rate precision ( ( total-rainfall  ) / ( storm-hours * 60 * Repetitions-per-Iteration ) ) decimal-places
    ;; set the evaporation rate to be the daily rate divided by the number of iterations in a day, rounded to decimal-places of decimal places
    set evapo-rate ( precision ( ( ( daily-evaporation-rate  ) / ( 24 * 60 ) ) / Repetitions-per-Iteration )decimal-places )

    
    ;; Creates land cover for landscape
    setup-land-cover
    if map-name = "map a"
    [;;import-drawing "mapanlogo.png"
      ]
    if map-name = "map b"
    [;;import-drawing "mapbnlogo.png"
      ]
    if map-name = "map c"
    [;;import-drawing "mapcnlogo.png"
      ]
    ask patches [
        ;; Assume that starting conditions include no standing aboveground water 
        set water-column 0
        set adjusted-elevation ( elevation - storage-capacity )
                       
    ]
    ;; setup the sewer locations
    setup-sewers
    ;; setup soil conditions for infiltration
    setup-green-ampt
    
    ;; setup the icons which show green infrastructure, sewers, roads, and the outlet
    setup-agents
    ask patches [
      set total-height ( elevation + water-column )
    ]

end

to setup-land-cover
  ask patches[
    ifelse(
    ;;Sets up roadness of each patch
      pxcor = 0 or pxcor = 7 or pxcor = 14 or pxcor = 21 or pycor = 0 or pycor = 7 or pycor = 14 or pycor = 21)
    [set roads? true
      set pcolor (grey - 2)
      ]
    [set roads? false
      set pcolor orange
      ]
  ]
  read-file
  set total-cost (num-gardens * 10000)
  ask n-of ( count patches * ( 25 / 100 ) )  patches  with [ cover-type = 2 and roads? = false ] [ set cover-type 3 ]
    ;; Set color, storage capacity, soil characteristics, and elevation of all three land covers
  ask patches [
    ;; sets conditions for cover type 1, green infrastructure
    if cover-type = 1 [
      ;; color cells which are green infrastructure green
      set pcolor green
      ;; set storage capacity of green infrastructue, currently set at 200 millimeters or 0.20 meters
      set storage-capacity 750 ;; .2 M
      ;; set capillary-suction to 61.3, the value for loamy sand
      set capillary-suction 91.3 
      ;; set initial moisture deficit to 0.312, the value for loamy sand
      set initial-moisture-deficit .312 
      ;; set saturated hydraulic conductivity to 59.8 mm/hr and then convert to mm/iteration and rounded to the precision number of decimal places
      set saturated-hydraulic-conductivity ( precision ( ( 90.8 / 60 ) / Repetitions-per-Iteration ) decimal-places )
      ;; set elevation.  If a cell is green infrastructure and is next to a road and curbs are turned on, set the elevation to 350.  
      ;; places green infrastructure immediately adjacent to the road at the same level as the road when curbs are turned on
      ifelse any? neighbors with [ roads? = true ]
      [ 
        set elevation 350 ;+ random 5 ) ;( ( abs ( pxcor ) ) + 20 )
      ]
      ;; if a cell is green infrastructure but one or both of the following conditions is not met 1) located next to a road, 2) curbs are turned on, set elevation to 500
      [
        set elevation 500
      ]
    ]
    ;; sets conditions for type 2, impermeable surfaces. 
    if cover-type = 2 [
      ;; color impermeable cells gray
      ;;set pcolor grey
      ;; impermeable cells don't have storage capacity
      set storage-capacity 0
      ;; capillary-suction doesn't matter in impermeable cells because they do not infiltrate water
      set capillary-suction 0
      ;; initial-moisture-deficit doesn't matter in impermeable cells because they do not infiltrate water
      set initial-moisture-deficit 0
      ;; saturated-hydraulic-conductivity doesn't matter in impermeable cells because they do not infiltrate water
      set saturated-hydraulic-conductivity 0
      ;; set elevation for impermeable cells to 500
      set elevation 500 ;+ random 5 ) ;( ( abs ( pxcor ) ) + 20 )
    ]
    
     ;; sets conditions for land cover type 3, permeable ground
    if cover-type = 3 [
      ;; color permeable cells brown
      set pcolor brown
      ;; permeable cells don't have storage capacity
      set storage-capacity 0
      ;; set capillary suction to 273, the value for Silty Clay Loam
      set capillary-suction 273
      ;; set initial moisture deficit to 0.105, the value for silty clay loam
      set initial-moisture-deficit .105
      ;; set saturated hydraulic conductivity to 2 mm/hr, then convert to mm/ iteration and rounded to the precision number of decimal places
      set saturated-hydraulic-conductivity ( precision ( ( 2 / 60 ) / Repetitions-per-Iteration ) decimal-places )
      ;; set elevation to 500, which is 150mm higher than roads when curbs are turned on
      set elevation 500 ;+ random 5 ) ;( ( abs ( pxcor ) ) + 20 )
    ]
    ;; Create curbs.  For patches which are roads, when curbs are turned on, set elevation 150mm shorter than surrounding elevation
    if roads? = true [
      set elevation elevation - 150
    ]
  ]
  ask patches [
    ;; Make all cells unable to do outflow
    set outflow? false
  ]
   ;; create an underlying slope in the base elevation of cells which slopes downwards to the lower left (southwest) corner of the landscape
  if map-name = "map a"[
    ask patches [
    ;; Create an elevation multiplier which is the distance from the outlet to create a smooth slope
      let elevation-multiplier distance patch 0 0
    ;; adjusts the elevation of all cells based upon the slope-percent, set by a slider, and the elevation-multiplier.    
      set elevation ( elevation + ( elevation-multiplier * ( Slope-percent / 100 ) * cell-dimension  ) ) 
    ]
    ask patch 0 0 [
    set outflow? true
      ]
  ]
  ;; creates a slope towards the center
  if map-name = "map b"[
    ask patches [
      let elevation-multiplier distance patch 11 11
      set elevation ( elevation + ( elevation-multiplier * ( Slope-percent / 100 ) * cell-dimension  ) )
    ]
    ask patch 14 14[
      set outflow? true
    ]
  ]
  ;; creates a slope towards the top center
  if map-name = "map c"[
    ask patches[
     let elevation-multiplier distance patch 10 22
     set elevation ( elevation + ( elevation-multiplier * ( Slope-percent / 100 ) * cell-dimension  ) )
    ]
    ask patch 14 21[
      set outflow? true
    ]
  ]
  ;; creates puddles
    if map-name = "puddle 1"[
    ask patches[
     let elevation-multiplier distance patch 0 0
     set elevation ( elevation + ( elevation-multiplier * ( Slope-percent / 100 ) * cell-dimension  ) )
    ]
    ask patches[
      if ( (pxcor > 16 and pxcor < 20 ) and (pycor > 16 and pycor < 20) ) or ( (pxcor > 9 and pxcor < 14 ) and (pycor > 2 and pycor < 7) )  [
        set elevation ( elevation - 75)
      ]
    ]
    ask patch 0 0[
      set outflow? true
    ]
  ]
  ;; Create a single outflow cell in the lower left (southwest) corner of the landscape

  ;; Set the lower left (southwest) corner cell as the outflow cell

end

to setup-green-ampt
    ;; Designate cells which are green infrastructure (cover-type 1) and permeable cover (cover-type 3) as capable of infiltrating water and setup infiltration variables
  ask patches with [ cover-type = 1 or cover-type = 3 ] [
          ;; cumulative-infiltration-amount, the amount of water which has infiltrated so far, is set to zero (dry).  
          ;; The soil is not completely dry since initial-moisture-deficit, set from a table, takes into account existing water in the soil
        set cumulative-infiltration-amount 0
          ;; max-wet-depth is depth of subsurface water table or bedrock.  It is set via a slider.  Reduces this value by depth of storage capacity to create level bottom to water column 
        set max-wet-depth ( base-max-wet-depth - storage-capacity )
        ;; calculate the maximum amount of water which can infiltrate, using equation from Albrecht and Cartwright 1989
        set max-infil-value ( max-wet-depth * initial-moisture-deficit )
    
  ]
end

to setup-agents
    ask patches with [ sewers? = true ] [
    sprout-sewers 1 [
      set shape "circle 2"
      set color 6
      set size .8
    ]
  ]
  ;; Creates icons for the outlet and sets its shape, color, and size
  ask patches with [ outflow? = true ] [
    sprout-outflow-cells 1 [
      set shape "triangle 2"
      set color red
      set size .8
    ]
  ]
  ;; Creates icons for green infrastructure and sets their shape, color, and size
  ask patches with [ cover-type = 1 ] [
    sprout-GI 1 [
      set shape "garden"
      set color green
      set size .8
    ]
  ]
  ;; Creates icons for roads and sets their shape, color, and size
  ask patches with [ roads? = true ] [
    sprout-road-cells 1 [
      set shape "dot"
      set size .4
      set color yellow
    ]
  ]

end
;; "Go" runs all of the operations of the model
to go

  ;; Set global water budget variables to 0
  ask patches [
    set iteration-infiltration 0
    set iteration-precipitation 0
    set iteration-evapotrans 0
    set iteration-evapo 0
    set iteration-sewers 0
    set iteration-water-balance 0
    set iteration-outflow 0
    
  ]
  ;; each tick consists of as many repetitions as the value set via the repetitions-per-iteration slider
  repeat Repetitions-per-Iteration [
      ;; Rain continues until the number of ticks equals the storm duration in minutes (set via the storm-hours slider)
    if ticks < (60 * storm-hours) [ add-rain ]
    ;; Infiltrate water using the Green Ampt equation
    Green-Ampt
    ;; If sewers are on, water leaves through sewers
    sewer-intake 
  ]

   ;; Water will evaporate only after the rain stops
    if ticks >= (60 * storm-hours) [ evaporate ]
    ;; Evapotranspiration occurs every tick, including during rain
    evapotranspiration
    ;; Cells calculate the height of the top of their water columns, including underlying elevation
    ask patches [
      set total-height ( elevation + water-column )
    ]

    ;; Surface flow occurs after water infiltrates, and leaves through sewers, evaporation, and evapotranspiration
    flow-surface
   
    ;; if the outlet is turned on, outlet releases water
    ;; RENAME THE BOUNDARY-CONDITIONS VARIABLE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    flow-outlet 
    
    ;; cells recalculate their total-height, which is the height to the top of the water column, including underlying elevation
    ask patches [
      set total-height ( elevation + water-column )
    ]

  ;; Plot current values on graphs and update globals  
  do-plots-and-globals

  ;; Visualize processes using colors
  color-patches

  ;; Add 1 to the number of ticks (iterations)
  tick

  
  ;; if the rain has stopped and either there is no ponded water, stop
  if ticks >= (60 * storm-hours) and above-0-ponded-water <= 0 [ stop ]
    


end
;; Precipitation 
to add-rain
  ;; add rain at the rainfall rate to the water-column
  ask patches [
    set water-column ( precision (water-column + rainfall-rate ) decimal-places )
    ;;update the global iteration-precipitation with the rain-fall for a given iteration
    set iteration-precipitation precision ( iteration-precipitation + rainfall-rate ) decimal-places
  ]
end

;; Evapotranspiration
to evapotranspiration
 
  ;; Water is taken out of the water that has infiltrated, from green infrastructure and permeable cells through the process of evapotranspiration
  ask patches with [ cover-type = 1 or cover-type = 3 ] [
          
          ;; set the amount of water lost to evapotransporation.  Check if the water infiltrated so far minus the evapotransportation rate is bigger than zero,
          ;; then set the amount taken out to be simply the rate. Otherwise, the amount taken out will be everything infiltrated.
        ; if the amount of water taken out of infiltrated water is less than the total infiltrated so far
        if cumulative-infiltration-amount > 0 [
          ifelse precision ( cumulative-infiltration-amount - evapotrans-rate ) decimal-places > 0
            [
            ;; Set iteration-evapotrans to the amount of water which has been evapotranspirated so far this tick plus the evapotranspiration rate
            set iteration-evapotrans precision ( iteration-evapotrans + evapotrans-rate ) decimal-places
            ;; Set the cumulative amount of water infiltrated to the amount of water infiltrated so far minus the evapotranspiration rate
            set cumulative-infiltration-amount precision ( cumulative-infiltration-amount - evapotrans-rate ) decimal-places

            ]
            ;; if subtracting brings the rate to zero or less
            [
            ;; if the infiltration-rate is greater than the amount of water infiltrated so far, set iteration evapotranspiration to the amount of water infiltrated so far plus
            ;; the amount of water infiltrated so far this tick
            set iteration-evapotrans precision ( iteration-evapotrans + ( cumulative-infiltration-amount ) ) decimal-places
            ;; reset cumulative-infiltration-amount to zero since all of the water was evapotranspirated
            set cumulative-infiltration-amount ( 0 )

            ]
        ]
  ]

end
;; Evaporate
to evaporate
  ;; Determine whether the water column has more water than the evaporation rate, if so, evaporate water according to the evaporation rate.  If not, evaporate all water.
  ask patches [
    ;; Check whether the evaporation rate is smaller than the water column
    ifelse ( precision ( water-column - evapo-rate ) decimal-places ) > 0 [
      ;; if there is more water in the water column than the per iteration evaporation rate, evaporate water according to the evaporation rate
      set iteration-evapo precision ( iteration-evapo + evapo-rate ) decimal-places
      ;;  subtract the evaporation rate from the water column
      set water-column ( precision ( water-column - evapo-rate ) decimal-places )
    ]
    [
      ;; if there is less water in the water column than the per iteration evaporation rate, evaporate all water from the water column  
      set iteration-evapo precision ( iteration-evapo + water-column ) decimal-places
      ;; set the water column to 0
      set water-column ( 0 )
    ]
  ] 

end

;; Run sewer processes
to sewer-intake

  ;; if the sewers are full and CSOs not allowed, revise the sewer intake rate to the treatment plant rate.
  ;; if not true, then set the sewer intake rate to be the regular sewer rate 
  ;; determines whether there is sewer capacity and whether "No-CSO" has been selected with the chooser
  ;show ( ( ( water-in-pipes ) * .001 ) * conversion-multiplier )
  ;show max-sewer-capacity
  ifelse ( ( ( ( water-in-pipes ) * .001 ) * conversion-multiplier ) >= max-sewer-capacity ) 
  [
    ;; if there is no sewer capacity left and CSOs are turned off, use the rate designated for full sewers
    set used-sewer-rate full-sewer-rate
    set full-sewers? true
  ]
  [
    ;; if either there is sewer capacity left or CSOs are allowed, or both, use the base sewer rate
    set used-sewer-rate base-sewer-rate
    set full-sewers? false
  ]
  ;show used-sewer-rate
  ;; Patches with sewers discharge water into the storm sewer system at the rate defined above
  ask patches with [ sewers? = true and water-column > 0 ] [
;    show height-in-sewer-basin
;    show adjusted-sewer-basin-capacity
    ;;if the catchment basins are not full [   
    if height-in-sewer-basin < adjusted-sewer-basin-capacity [
      ;; setting the remaining volume in the basin (m^3 -m^3)
      let remaining-basin-height ( adjusted-sewer-basin-capacity - height-in-sewer-basin )
      ;; If there is more water in the water column than the sewer rate, move water from the water column into the sewers at the sewer rate
      let full-remove-amount 0

      ifelse ( water-column - used-sewer-rate ) > 0
        [ set full-remove-amount used-sewer-rate ]
        [ set full-remove-amount water-column ]
      ifelse full-remove-amount <= remaining-basin-height [
        set iteration-sewers ( precision ( iteration-sewers + full-remove-amount ) decimal-places )
          ;; Move water which is now in the sewers from the water column
        set water-column ( precision ( water-column - full-remove-amount ) decimal-places )
        set height-in-sewer-basin ( precision ( height-in-sewer-basin + full-remove-amount ) decimal-places )
      ]
      [
        set iteration-sewers ( precision ( iteration-sewers + remaining-basin-height ) decimal-places )
          ;; Move water which is now in the sewers from the water column
        set water-column ( precision ( water-column - remaining-basin-height ) decimal-places )
        set height-in-sewer-basin ( precision ( height-in-sewer-basin + remaining-basin-height ) decimal-places )
      ]
    ]
  ]
  print " "
  ask patches with [ sewers? = true and height-in-sewer-basin > 0 ] [
    if full-sewers? = false [
      let sewer-basin-height-above-pipe ( height-in-sewer-basin - sewer-basin-height-below-pipe )

      if sewer-basin-height-above-pipe > 0 [
        
        let remaining-pipe-space ( max-sewer-capacity - ( ( ( water-in-pipes ) * .001 ) * conversion-multiplier ) )

        let full-basin-remove-amount 0
        ifelse ( sewer-basin-height-above-pipe - used-sewer-rate ) > 0
          [ set full-basin-remove-amount used-sewer-rate ]
          [ set full-basin-remove-amount sewer-basin-height-above-pipe ]
        set water-in-pipes ( water-in-pipes + full-basin-remove-amount )
        set height-in-sewer-basin ( height-in-sewer-basin - full-basin-remove-amount )
        
      ]
    ]
  ]
end
;; Do outflow procedures
to flow-outlet
  ;; Applies to only outflow cell(s)
  ask patches with [ outflow? = true ] [
    ;; Remove half of the water in the outflow cell and add it to the global outflow tracker
    set global-outflow ( global-outflow + ( water-column / 2 ) )
    ;; Add outflow from this iteration to the tracker which measures outflow for the entire tick
    set iteration-outflow ( iteration-outflow + ( water-column / 2 ) )
    ;; remove the water that flowed out from the outflow cell
    set water-column 0
  ]
    
end

to Green-Ampt

  ;; Ask permeable and green infrastructure patches which have water on them to reset infiltration values
  ask patches with [ cover-type = 1 or cover-type = 3 and water-column > 0 ] [
    ;; reset infiltration-amount to zero
    set infiltration-amount 0
    ;; reset infiltration-rate to zero
    set infiltration-rate 0
      
      ;; if no water has yet infiltrated, infiltration rate = rainfall-rate.  If water has infiltrated, use green-ampt  
    ifelse cumulative-infiltration-amount = 0
      [
        ;; All of the water which falls the first time step will infiltrate
        set infiltration-rate rainfall-rate

      ]
      [
        ;;Check if there is remaining infiltration capacity. If true, then infil occurs. If not, the soil is saturated and ponds.
        
        ifelse max-infil-value > cumulative-infiltration-amount
            ;; this condition is for when there is potential capacity to infiltrate
          [
            ;; Check whether the hydraulic conductivity is higher than the rainfall rate.           
          ifelse saturated-hydraulic-conductivity > rainfall-rate
              [
              ;; If hydraulic conductivity is higher than rainfall rate, the max infiltration rate is equal to the hydraulic conductivity.
              set infiltration-rate saturated-hydraulic-conductivity
              ]
              [
              ;; If hydraulic conductivity is lower than rainfall rate, the max infiltration rate is set using the Green Ampt equation. 
              set infiltration-rate  ( (saturated-hydraulic-conductivity) * ( 1 + ( ( initial-moisture-deficit * capillary-suction ) / cumulative-infiltration-amount ) ) ) 
              ]
          ]
          ;; If the maximum infiltration value has been reached (max-infil-value <= cumulative-infiltration-amount), there is no remaining capacity for infiltration
          [
          ;; The soil is saturated, so infiltration rate is set to zero
          set infiltration-rate 0
            ;; icons for saturated cells are recolored orange
          ask turtles-here [ set color orange ]
          ]
      ]
                   
         
    ;; The actual infiltration amount is set based on the available water
    ;; Determine infiltration amount based on whatever is smaller, the rate or the surface water available
    ;; Check if the infiltration rate is less than the avaiable water
    ifelse infiltration-rate < water-column
        ;; setting the infiltration amount to be the smaller of infiltration-rate water-column
        ;; infiltration rate is smaller
          [
          ;; If the infiltration rate is smaller than the water column, set the infiltration amount at the infiltration rate
          set infiltration-amount infiltration-rate
          ]
            ;; if the water-column is smaller than the infiltration rate, set the infiltration amount at the water column
          [
          set infiltration-amount water-column
          ]
    ;; this condition ensures that the infiltration amount does not bring the cumulative infiltration amount to a value that is bigger than the max-infil-value
    ;; also, if true, it essentially means the cell is saturated
    ;; check whether the amount of water infiltrated this iteration will exceed the total water holding capacity in the soil
    if ( cumulative-infiltration-amount + infiltration-amount ) > max-infil-value [
      ;; If infiltrating the full amount of water this iteration will exceed the total water holding capacity in the soil, only infiltrate up to this capacity
      set infiltration-amount ( max-infil-value - cumulative-infiltration-amount )
     ;; set color of icons for saturated cells orange
     ask turtles-here [ set color orange ]
    ]
    
  ]

    ;;update cumulative infiltration and the water column 
    ;; Ask permeable cells and green infrastructure cells which have water on them to round the infiltration amount to the decimal-places of decimal places
    ask patches with [ cover-type = 1 or cover-type = 3 and water-column > 0 ] [
      set infiltration-amount ( precision infiltration-amount decimal-places )
      ;; Add the amount of water infiltrating this iteration to the cumulative amount of water infiltrated and round to the decimal-places of decimal places
      set cumulative-infiltration-amount ( precision ( cumulative-infiltration-amount + infiltration-amount ) decimal-places )
      
      ;; WE MIGHT BE ABLE TO DELETE THE FOLLOWING TESTS
      ;; This is a test to make sure that more water is not infiltrating than is available on a cell
      ;; check whether more water is infiltrating than is available
      if ( water-column - infiltration-amount ) < 0 [
        ;; Print an error code with the values for the water column and infiltration amount
        print "water-column - infiltration-amount < 0"
        print water-column
        print infiltration-amount
        print ( water-column - infiltration-amount )
        stop
      ]
      
      ;; This is a test to check that infiltration stops when the soil water holding capacity is reached
      if cumulative-infiltration-amount > max-infil-value [
        print "too much water infiltrated based on max allowable"
        print cumulative-infiltration-amount
        stop
      ]
      
      
      ;;Calculate the new depth of the water column by subracting the water which has infiltrated
      set water-column ( precision ( water-column - infiltration-amount ) decimal-places )
        
      ;;update total amount of water infiltrated this iteration by adding the infiltration to the iteration infiltration tracker
      set iteration-infiltration precision ( iteration-infiltration + infiltration-amount ) decimal-places
  
  ]

end
;; Do surface flow
to flow-surface
  ;; Adapted from unpublished code from Wetland Flow Model by Dean Massey and Moira Zellner
  ;; Create temporary variables for flow code
  ask patches [
    ;; defining the total-flow and avg-flows for the first time
    ;; baseline = the center cell/ cell which is comparing to its neighbors
    let total-flow 0 ;; The total amount of water which flows
    let avg-flow 0 ;; The average amount of water which flows
    ;; defining the baseline values to which the neighbors will compare
    let baseline-water-column water-column ;; The baseline cell sets temporary water column variable
    let baseline-total-height total-height ;; The baseline cell sets temporary total height variable
    
    ;; creates a list of neighboring cells.  Each neighboring cell completes this code in series.  The order in which they complete it is random.
    foreach sort neighbors [
        ;; ask each neighbor to do the following process, which will set the total amount of water that will flow in or out from them (flow)
        ask ? [
            ;; access and define neighbors' values which correspond to the baseline values defined above which will be used to calculate the flow amount.
            let neighbor-water-column [water-column] of self
            let neighbor-total-height [total-height] of self
            ;; define flow, which is the amount of water that will move to or from the baseline cell
            let flow 0
            
            ;; Define local average height, which is the mean of the baseline total height and the neighbor total height. 
            ;; This is the equilibrium level between the cells.
            let half-diff-height ( abs ( ( baseline-total-height - neighbor-total-height ) / 2 ) )
            
            ;; there are ultimately only 4 possibilities for flow calculations, but after going through a decision tree, only one will be used for each neighbor.
            ;; check to see if water is available to move
            ;; if neighbor-total-height is bigger than baseline total height, there will be inflow to center cell, if water is available               
            ifelse baseline-total-height < neighbor-total-height
                
                  ; flow is positive ( potential inflow ) because the neighbor is higher than the baseline cell.  Water will flow to baseline cell.
                [
                 ;; Check whether the neighbor's water column is higher than the equilibrium level (half diff height) 
                 ifelse neighbor-water-column >= half-diff-height [
                    ;; If the height of water on the neighbor is higher than half the difference between the cell's heights, water will move to the equilibrium level
                    ;; from the neighbor cell
                    set flow half-diff-height
                  ]
                  [
                    ;; If the height of water on the neighbor cell is lower than the amount of water which would be needed achieve equilibrium, move all water
                    set flow neighbor-water-column
                  ]
                ]
            
            
                  ; flow is negative ( potential outflow ) because the neighbor is lower than the baseline cell.  Water will flow from baseline cell.
                [
                  ;; Check whether the baseline cell's water column is higher than the equilibrium level (half diff height)
                  ifelse baseline-water-column >= half-diff-height [
                    ;; If the height of water on the baseline cell is higher than have the difference between the cell's heights, water will move to the equilibrium level
                    ;; from the baseline cell
                    set flow ( half-diff-height * -1 )
                  ]
                  [
                    ;; If the height of water on the baseline cell is lower than the amount of water which would be needed achieve equilibrium, move all water
                    set flow ( baseline-water-column * -1 )
                  ]
                ]
            
            ;; add the amount of water which will flow to the total for the baseline cell's neighbors
            set total-flow (total-flow + flow )
            ;; end of neighbors portion of the code
        ]
        ;;closes the sort loop
    ]
      ;; find the average flow by dividing the total flow by the number of neighbors.  This is required because boundary cells do not have 8 neighbors.
    set avg-flow ( precision (total-flow / (count neighbors) ) decimal-places )
      ;; calculate what the water level will be for each cell, and save as a temporary variable (buffer layer) 
    set water-column-future ( water-column + avg-flow )
      ;;This is a test.  The water level should never be below 0, so it will stop. 
    if water-column-future < 0 [ stop 
      print "Water Level is below zero.  Flow Code error."
      ]
  ]
      ;; Set the water column and round to a given number of decimal places
    ask patches [
        set water-column ( precision water-column-future decimal-places )
          ;;Due to mathematical quirks, regardless of the precision number used, there needs to be a cutoff above 0, but this cutoff depends upon preselected number of decimal places used by model.
        ;; if the water column is less than a miniscule amount, defined by a given number of decimal places, set it to zero
        if water-column <= ( 4 * ( 10 ^ ( -1 * decimal-places ) ) ) [ set water-column 0 ]
        set water-column-future 0
    ]
  
end

;;visualization
to color-patches
  
      if data-visualized = "iteration-runoff" [
          ;; water ponding - net water increase on cell before flow
        
        ask patches [
          ifelse water-column > 0 [
            if iteration-water-balance > 0 [
              ifelse iteration-water-balance > ( rainfall-rate * .99)
              [ set pcolor blue ]
              [ set pcolor cyan ]
            ]
            
            if iteration-water-balance = 0 [ set pcolor green ]
            
            ;; water draining - net loss on cell before flow
            if iteration-water-balance < 0 [
              ifelse iteration-water-balance < ( rainfall-rate * -1 )
              [ set pcolor orange ]
              [ set pcolor yellow ]
            ]
          ]
          [ set pcolor grey ]
        ]
      ]
      
      if data-visualized = "ponded water not including storage capacity-total water" [
        ask patches [      
          ifelse water-column > 0
          [
            ifelse max [ ( water-column - storage-capacity ) ] of patches > 0
            [ set pcolor scale-color blue ( water-column - storage-capacity ) total-rainfall 0 ]
            [ set pcolor white ]
          ]
          [
            if cover-type = 1 [ set pcolor green ]
            if cover-type = 2 [ set pcolor grey ]
            if cover-type = 3 [ set pcolor brown ]
          ]
        ]
      ]        
      
      if data-visualized = "ponded water not including storage capacity-relative colors" [
        ask patches [      
          ifelse water-column > 0
          [
            ifelse max [ ( water-column - storage-capacity ) ] of patches > 0
            [ set pcolor scale-color blue ( water-column - storage-capacity ) max [ ( water-column - storage-capacity ) ] of patches 0 ]
            [set pcolor white ]
          ]
          [
            if cover-type = 1 [ set pcolor green ]
            if cover-type = 2 [ set pcolor grey ]
            if cover-type = 3 [ set pcolor brown ]
          ]
        ]
      ]
        
      if data-visualized = "cover type"[
        ask patches [
          if cover-type = 1 [ set pcolor green ]
          if cover-type = 2 [ set pcolor grey ]
          if cover-type = 3 [ set pcolor brown ]
        ]
      ]
      
      if data-visualized = "cumulative infiltration"[
        ask patches [
          ifelse cumulative-infiltration-amount > 0 [
            set pcolor scale-color blue ( cumulative-infiltration-amount ) 0 ( max [ cumulative-infiltration-amount ] of patches )
          ]
          [ set pcolor brown ]
        ]
      ]
          
      if data-visualized = "iteration infiltration"[
        ask patches [
          ifelse infiltration-amount > 0
          [
            set pcolor scale-color green ( infiltration-amount ) 0 ( max [ ( infiltration-amount ) ] of patches )
          ]
          [
            set pcolor brown
          ]
        ]
      ]
      
      if data-visualized = "elevation and water" [
        ask patches with [ cover-type != 1 ] [      
          ifelse water-column > 0
          [
            set pcolor scale-color blue (water-column ) ( total-rainfall ) 350
          ]
          [
            set pcolor scale-color brown ( elevation ) 350 ( max [ ( elevation ) ] of patches )
          ]
        ]
      ]
      
            
      if data-visualized = "elevation"[
        ask patches [
          set pcolor scale-color brown ( elevation ) 350 ( max [ ( elevation ) ] of patches )      
        ]
      ]
      
      if data-visualized = "catchment basin capacity"[
        ask patches [
          ifelse sewers? = true
          [ set pcolor scale-color blue height-in-sewer-basin 0 adjusted-sewer-basin-capacity ]
          [ set pcolor brown ]
        ]
      ]
end


to do-plots-and-globals
  
  if count patches with [ cover-type = 1 ] > 0 [
    set proportion-saturated-cells count ( patches with [ plabel-color = orange ] )
    set proportion-saturated-cells ( proportion-saturated-cells / ( count patches with [ cover-type = 1 ] ) )
  ]
  let outflow-sum ( sum [ iteration-outflow ] of patches )
  let infiltration-sum ( sum [ iteration-infiltration ] of patches )
  set global-infiltration ( precision ( global-infiltration + infiltration-sum ) decimal-places )
  let precipitation-sum ( sum [ iteration-precipitation ] of patches )
  set global-precipitation ( precision ( global-precipitation + precipitation-sum ) decimal-places )
  let evapotrans-sum ( sum [ iteration-evapotrans ] of patches )
  set global-evapotrans ( precision ( global-evapotrans + evapotrans-sum ) decimal-places )
  let evapo-sum ( sum [ iteration-evapo ] of patches )
  set global-evapo ( precision ( global-evapo + evapo-sum ) decimal-places )
  set ponded-water ( precision ( sum [ water-column ] of patches ) decimal-places )
  let sewer-sum ( sum [ iteration-sewers ] of patches )
  set global-sewer ( precision ( global-sewer + sewer-sum ) decimal-places )
  
  
  ifelse water-in-pipes - sewer-drain-rate > 0
    ;; if the drain does not take all of the water
  [
    set water-in-pipes ( water-in-pipes - sewer-drain-rate )
    set global-sewer-drain ( global-sewer-drain + sewer-drain-rate )
  ]
    ;; if the drains bring the global back down to 0
  [
    set global-sewer-drain ( global-sewer-drain + water-in-pipes )
    set water-in-pipes 0
  ] 
   
  ask patches [
    set iteration-water-balance ( iteration-precipitation - iteration-infiltration - iteration-sewers - iteration-evapo - iteration-evapotrans )
  ]
  let iteration-overflow 0
    ;; setting the sum of the water above the so-called 0 elevation, ie water colum minus any water in teh storace capacity of GI cells.
    ;; this is a 2 part step
  set above-0-ponded-water 0
  let above-0-ponded-water-roads 0
  ask patches with [ roads? = true ] [ set above-0-ponded-water-roads ( above-0-ponded-water-roads + water-column ) ]
  ask patches with [ cover-type = 2 or cover-type = 3 ] [
    set above-0-ponded-water ( above-0-ponded-water + water-column )
    ]
  ask patches with [ cover-type = 1 ] [
    set global-GI-infiltration ( global-GI-infiltration + iteration-infiltration)
    if ( water-column - storage-capacity ) > 0
    [
      set above-0-ponded-water ( above-0-ponded-water + ( water-column - storage-capacity ))
    ]
  ]
  set average-water-height ( above-0-ponded-water / (count patches) )
  set average-water-height-roads ( above-0-ponded-water-roads / (count patches with [ roads? = true ] ) )
  ;show above-0-ponded-water
  ;show above-0-ponded-water-roads
  ;show average-water-height
  ;show  average-water-height-roads
  ;print " "
  
  if  ( ( global-sewer * .001 ) * conversion-multiplier ) > max-sewer-capacity [
    set overflow-amount ( overflow-amount + ( sum [ iteration-sewers ] of patches ) )
    set iteration-overflow ( sum [ iteration-sewers ] of patches )
  ]
  set global-overflow ( global-overflow + iteration-overflow )
  set above-0-ponded-water precision above-0-ponded-water decimal-places
  ;set iteration-change-ponded precision ( iteration-precipitation - iteration-infiltration - iteration-evapotrans ) decimal-places
  if count ( patches with [ cover-type = 1 or cover-type = 3 ] ) > 0 [ set av-infil-rate mean [infiltration-rate] of patches with [ cover-type = 1 or cover-type = 3 ] ]
  set water-in-storage 0
  ask patches with [ cover-type = 1 ] [
    ifelse water-column <= storage-capacity
    [ set water-in-storage ( water-in-storage + water-column ) ]
    [ set water-in-storage ( water-in-storage + storage-capacity ) ]
  ]
    set-current-plot "Average Height of Standing Water"
    set-current-plot-pen "all cells"
    plot average-water-height
    set-current-plot-pen "roads"
    plot average-water-height-roads
  ;set-current-plot-pen "net change in ponded water"
  ;plot iteration-change-ponded
  
  set-current-plot "Percentage of Area Flooded"
  set-current-plot-pen "% with any water"
  plot ( ( ( count patches with [ water-column > 0 ] ) / ( count patches ) ) * 100 )
  set-current-plot-pen "% with water above 0 elevation"
  plot ( ( ( count patches with [ water-column > storage-capacity ] ) / (count patches ) ) * 100 )
  set-current-plot-pen "% with water above 5 minutes of rain"
  plot ( ( ( count patches with [ water-column > ( storage-capacity + ( rainfall-rate * 5 ) ) ] ) / (count patches ) ) * 100 )
  set-current-plot-pen "% with water above 1cm"
  plot ( ( ( count patches with [ water-column > ( storage-capacity + 10 ) ] ) / (count patches ) ) * 100 )
   
      
end
@#$#@#$#@
GRAPHICS-WINDOW
565
10
905
371
-1
-1
15.0
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
21
0
21
0
0
1
ticks

CHOOSER
1034
847
1172
892
storm-type
storm-type
"100-year"
0

SLIDER
723
847
895
880
storm-hours
storm-hours
0
24
1
1
1
Hour
HORIZONTAL

SLIDER
513
847
722
880
Repetitions-per-Iteration
Repetitions-per-Iteration
1
12
3
1
1
NIL
HORIZONTAL

BUTTON
42
38
109
71
SetUp
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

CHOOSER
896
847
1034
892
slope-percent
slope-percent
0 0.1 0.25 0.5 0.75 1 20
1

CHOOSER
2
77
419
122
data-visualized
data-visualized
"elevation and water" "iteration-runoff" "catchment basin capacity" "iteration infiltration" "cumulative infiltration" "cover type" "ponded water not including storage capacity-relative colors" "ponded water not including storage capacity-total water"
0

BUTTON
112
38
175
71
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

PLOT
2
125
560
373
Average Height of Standing Water
Time(minutes)
NIL
0.0
10.0
0.0
10.0
true
true
PENS
"all cells" 1.0 0 -16777216 true
"roads" 1.0 0 -7500403 true

PLOT
2
379
561
628
Percentage of Area Flooded
Time(minutes)
Percent Flooded
0.0
10.0
0.0
100.0
true
true
PENS
"% with any water" 1.0 0 -16777216 true
"% with water above 0 elevation" 1.0 0 -12895429 true
"% with water above 5 minutes of rain" 1.0 0 -7500403 true
"% with water above 1cm" 1.0 0 -4539718 true

CHOOSER
420
77
558
122
map-name
map-name
"map a" "map b" "map c" "puddle 1" "puddle 2"
3

MONITOR
445
31
558
76
Cost of Gardens
total-cost
17
1
11

@#$#@#$#@
WHAT IS IT?
-----------
This section could give a general understanding of what the model is trying to show or explain.


HOW IT WORKS
------------
This section could explain what rules the agents use to create the overall behavior of the model.


HOW TO USE IT
-------------
This section could explain how to use the model, including a description of each of the items in the interface tab.


THINGS TO NOTICE
----------------
This section could give some ideas of things for the user to notice while running the model.


THINGS TO TRY
-------------
This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.


EXTENDING THE MODEL
-------------------
This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.


NETLOGO FEATURES
----------------
This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.


RELATED MODELS
--------------
This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.


CREDITS AND REFERENCES
----------------------
This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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

garden
false
15
Rectangle -10899396 true false -1 0 299 300
Circle -7500403 true false 135 0 30
Circle -7500403 true false 150 30 30
Circle -7500403 true false 150 75 30
Circle -7500403 true false 135 120 30
Circle -7500403 true false 90 150 30
Circle -13840069 true false 198 198 85
Circle -13840069 true false 45 15 60
Circle -13840069 true false 15 30 60
Circle -2674135 true false 210 210 30
Circle -2674135 true false 240 240 30
Polygon -1184463 true false 240 41 255 35 266 60 258 82 239 95 220 86 206 83 198 69 207 55 205 37 219 27 234 26
Circle -6459832 true false 216 46 30
Polygon -1184463 true false 212 122 206 107 231 96 253 104 266 123 257 142 254 156 240 164 226 155 208 157 198 143 197 128
Circle -6459832 true false 217 116 30

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
NetLogo 4.1.3
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

@#$#@#$#@
0
@#$#@#$#@

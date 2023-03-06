; MAQBOOL THOUFEEQ THARAYIL - 1000023606
breed [workers worker]
workers-own [actual-salary actual-familyIncome salaryGray salarySky salaryYellow familySalaryYellow familySalaryGray familySalarySky
  skills
  native-country
  familyN myFamily
  personal-costs family-costs
  away immediate-return return long-away
  ]

patches-own [salaryL salaryM salaryH jobL jobM jobH BaseSalary
  GDP GDPlag
  job_market_flex initial_unempl_rate]

to setup
  clear-all
  setup_countries
  setup_workers
  setup_salaries
  setup_costs
  collect_info
  setup_job_market
  setup_famliar_salaries
  reset-ticks
end

to go
  update_job_market
  collect_info
  update_familiar_salaries_and_costs
  migrate
  setup_costs
  update_GDP_GDPlag
  tick

end

to setup_countries

  ask patches [if pxcor > 0 and pycor > 0 [set pcolor gray  ]]
  ask patches [if pxcor < 0 and pycor > 0 [set pcolor yellow  ]]
  ask patches [if pxcor <= 9 and pxcor > -9 and pycor < 0 [set pcolor sky ]]

  ask patches with [pcolor = sky] [set BaseSalary BaseSalarySky]
  ask patches with [pcolor = yellow] [set BaseSalary BaseSalaryYellow]
  ask patches with [pcolor = gray] [set baseSalary BaseSalaryGray]

  ask patches with [pcolor = sky] [set initial_unempl_rate initial_unempl_rate_sky]
  ask patches with [pcolor = yellow] [set initial_unempl_rate initial_unempl_rate_yellow]
  ask patches with [pcolor = gray] [set initial_unempl_rate initial_unempl_rate_gray]

end

to setup_workers
  create-workers HowManyWorkers


    ask workers [set shape "person" move-to one-of patches with [pcolor = one-of [gray yellow sky]] set native-country pcolor]


    ifelse AsymmetricSkills? [Asymmetric_setup_skills] [Symmetric_setup_skills]


    ask workers[

    ;assign each worker a "surname". Workers can only have the same surname within a country

    if pcolor = gray [ set familyN random(count(workers with [pcolor = gray])) + 500]
    if pcolor = yellow [ set familyN random(count(workers with [pcolor = yellow])) + 2000]
    if pcolor = sky [ set familyN random(count(workers with [pcolor = sky])) + 3000]
    ]

     ask workers [set myFamily workers with [familyN = [familyN] of myself ]]

end

to Asymmetric_setup_skills

  ;assign each worker a skill level. The distribution is assumed different in each country

  let developed [pcolor] of one-of patches with [BaseSalary = max (list BaseSalaryYellow BaseSalaryGray BaseSalarySky)]
  let developing [pcolor] of one-of patches with [BaseSalary = min (list BaseSalaryYellow BaseSalaryGray BaseSalarySky)]


  ask workers with [pcolor = developed] [let x random-float 1
      if x <= 0.25 [set skills 3 set color white]
      if x > 0.25 and x <= 0.85  [set skills 2 set color lime ]
      if x > 0.85  [set skills 1 set color pink]
    ]
  ask workers with [pcolor = developing] [let x random-float 1
      if x <= 0.10 [set skills 3 set color white]
      if x > 0.10 and x <= 0.50 [set skills 2 set color lime ]
      if x > 0.50  [set skills 1 set color pink]
    ]
  ask workers with [pcolor != developed and pcolor != developing][let x random-float 1
      if x <= 0.15 [set skills 3 set color white]
      if x > 0.15 and x <= 0.60  [set skills 2 set color lime ]
      if x > 0.60  [set skills 1 set color pink]
    ]


end

to Symmetric_setup_skills

     ;assign each worker a skill level. The same distribution of skills is assumed in each country

     ask workers
    [let x random-float 1
      if x <= 0.15 [set skills 3 set color white]
      if x > 0.15 and x <= 0.45  [set skills 2 set color lime ]
      if x > 0.45  [set skills 1 set color pink]
    ]


end

to setup_costs

  ;personal and familiar costs of migration. Personal costs are lower when outside the native country and for highly skilled workers

   ask workers [set personal-costs random-float 10
     if pcolor != native-country [set personal-costs personal-costs - 2]
     if skills = 3 [set personal-costs personal-costs - 2]
     if personal-costs < 0 [set personal-costs 0]
    ]
  ask workers [set family-costs sum [personal-costs] of myFamily]
end

to setup_salaries

   ask patches [if pcolor = gray

     ; setup salaries in country gray

     [ set salaryL  200 + BaseSalaryGray -  (count workers with [pcolor = gray and skills = 1] * 2)
       set salaryM  500 + BaseSalaryGray -  (count workers with [pcolor = gray and skills = 2] * (1 / 2))
       set salaryH  900 + BaseSalaryGray ]

     if pcolor = yellow

     ; setup salaries in country yellow

     [ set salaryL  200 + BaseSalaryYellow - (count workers with [pcolor = yellow and skills = 1] * 2)
       set salaryM  500 + BaseSalaryYellow - (count workers with [pcolor = yellow and skills = 2]) * (1 / 2)
       set salaryH  900 + BaseSalaryYellow ]

     if pcolor = sky

     ; setup salaries in country sky

     [ set salaryL  200 + BaseSalarySky - (count workers with [pcolor = sky and skills = 1] * 2)
       set salaryM  500 + BaseSalarySky - (count workers with [pcolor = sky and skills = 2] * (1 / 2))
       set salaryH  900 + BaseSalarySky ]


     ]

end

to setup_job_market ;

  ask patches with [pcolor = Sky][set GDPlag BaseSalarySky * (count workers with [pcolor = sky]) / 2]
  ask patches with [pcolor = gray][set GDPlag BaseSalaryGray * (count workers with [pcolor = gray]) / 2]
  ask patches with [pcolor = yellow][set GDPlag BaseSalaryYellow * (count workers with [pcolor = yellow]) / 2]
  ask patches [set GDP sum [actual-salary] of workers with [pcolor = [pcolor] of myself] ]

  ask patches [let x count workers with [skills = 1 and pcolor = [pcolor] of myself]
               let y count workers with [skills = 2 and pcolor = [pcolor] of myself]
               let z count workers with [skills = 3 and pcolor = [pcolor] of myself]


               set jobL round(x - x * initial_unempl_rate)
               set jobM round(y - y * initial_unempl_rate)
               set jobH round(z - z * initial_unempl_rate)
               ]

  ask patches with [pcolor = sky] [set job_market_flex job_market_flex_sky]
  ask patches with [pcolor = yellow] [set job_market_flex job_market_flex_yellow]
  ask patches with [pcolor = gray] [set job_market_flex job_market_flex_gray]

end

to setup_famliar_salaries

    ask workers[

    ;each worker earns the salary of its category and the total salary of the family is computed

    if skills = 1 [set actual-salary [salaryL] of patch-here]
    if skills = 2 [set actual-salary [salaryM] of patch-here]
    if skills = 3 [set actual-salary [salaryH] of patch-here]]

  ask workers [  set actual-familyIncome (sum [actual-salary] of myFamily)]

  ask workers [let x count workers with [pcolor = [pcolor] of myself]
               let tot_jobs [jobL] of patch-here + [jobM] of patch-here + [jobH] of patch-here
               let prob_employment tot_jobs / x

        set actual-familyIncome actual-familyIncome * min (list 1 prob_employment)

  ]


  ask workers [let x count workers with [pcolor = yellow]
               let tot_jobs [jobL] of one-of patches with [pcolor = yellow] + [jobM] of one-of patches with [pcolor = yellow] + [jobH] of one-of patches with [pcolor = yellow]
               let prob_employment tot_jobs / (x + 0.001)

        set familySalaryYellow familySalaryYellow * min (list 1 prob_employment)

  ]

    ask workers [let x count workers with [pcolor = gray]
               let tot_jobs [jobL] of one-of patches with [pcolor = gray] + [jobM] of one-of patches with [pcolor = gray] + [jobH] of one-of patches with [pcolor = gray]
               let prob_employment tot_jobs / (x + 0.001)

        set familySalaryGray familySalaryGray * min (list 1 prob_employment)

  ]
    ask workers [let x count workers with [pcolor = sky]
               let tot_jobs [jobL] of one-of patches with [pcolor = sky] + [jobM] of one-of patches with [pcolor = sky] + [jobH] of one-of patches with [pcolor = sky]
               let prob_employment tot_jobs / (x + 0.001)

        set familySalarySky familySalarySky * min (list 1 prob_employment)

  ]
    ask workers [set actual-familyIncome (sum [actual-salary] of myFamily)
                 set familySalarySky (sum [salarySky] of myFamily) set familySalaryGray (sum [salaryGray] of myFamily) set familySalaryYellow (sum [salaryYellow] of myFamily)

      ]
end


to collect_info

   ; workers internalize the informations about salaries in other countries

  ask workers with [pcolor = gray][

    if skills = 1 [set SalaryYellow [salaryL] of one-of patches with [pcolor = yellow] set SalarySky [salaryL] of one-of patches with [pcolor = sky] set SalaryGray [salaryL] of one-of patches with [pcolor = gray]]
    if skills = 2 [set SalaryYellow [salaryM] of one-of patches with [pcolor = yellow] set SalarySky [salaryM] of one-of patches with [pcolor = sky] set SalaryGray [salaryM] of one-of patches with [pcolor = gray]]
    if skills = 3 [set SalaryYellow [salaryH] of one-of patches with [pcolor = yellow] set SalarySky [salaryH] of one-of patches with [pcolor = sky] set SalaryGray [salaryH] of one-of patches with [pcolor = gray]]

  ]

  ask workers with [pcolor = yellow][

    if skills = 1 [set SalaryGray [salaryL] of one-of patches with [pcolor = gray] set SalarySky [salaryL] of one-of patches with [pcolor = sky] set SalaryYellow [salaryL] of one-of patches with [pcolor = yellow]]
    if skills = 2 [set SalaryGray [salaryM] of one-of patches with [pcolor = gray] set SalarySky [salaryM] of one-of patches with [pcolor = sky] set SalaryYellow [salaryM] of one-of patches with [pcolor = yellow]]
    if skills = 3 [set SalaryGray [salaryH] of one-of patches with [pcolor = gray] set SalarySky [salaryH] of one-of patches with [pcolor = sky] set SalaryYellow [salaryH] of one-of patches with [pcolor = yellow]]

   ]

  ask workers with [pcolor = sky][

    if skills = 1 [set SalaryGray [salaryL] of one-of patches with [pcolor = gray] set SalaryYellow [salaryL] of one-of patches with [pcolor = yellow] set SalarySky [salaryL] of one-of patches with [pcolor = sky]]
    if skills = 2 [set SalaryGray [salaryM] of one-of patches with [pcolor = gray] set SalaryYellow [salaryM] of one-of patches with [pcolor = yellow] set SalarySky [salaryM] of one-of patches with [pcolor = sky]]
    if skills = 3 [set SalaryGray [salaryH] of one-of patches with [pcolor = gray] set SalaryYellow [salaryH] of one-of patches with [pcolor = yellow] set SalarySky [salaryH] of one-of patches with [pcolor = sky]]

   ]

end

to migrate

   ; we mark with return = 1 workers that are returning in the native country after a period abroad
   ; with immediate-return = 1 workers that are subject to the immediate return phoenomenon (i.e. migrate and return in the same cycle),
   ; with away = 1 workers that have moved from their native country in the current cycle
   ; with long-away = 1 workers that in the previous cycle were not in their native country

  ask workers [set return 0 set immediate-return 0 ]

  ask workers with [pcolor = gray][

   if actual-FamilyIncome < FamilySalaryYellow - Distance_Gray_Yellow - family-costs and FamilySalaryYellow - Distance_Gray_Yellow > FamilySalarySky - Distance_Gray_Sky
   [set size 2 set away 1 move-to one-of patches with [pcolor = Yellow]
     ask myFamily [set size 2 set away 1 move-to one-of patches with [pcolor = yellow]]]
   if actual-FamilyIncome < FamilySalarySky - Distance_Gray_Sky - family-costs  and FamilySalaryYellow - Distance_Gray_Yellow < FamilySalarySky - Distance_Gray_Sky
   [set size 2 set away 1 move-to one-of patches with [pcolor = Sky]
     ask myFamily [ set size 2 set away 1 move-to one-of patches with [pcolor = sky]]]
  ]

  ask workers with [pcolor = sky][

   if actual-FamilyIncome < FamilySalaryYellow - Distance_Yellow_Sky - family-costs  and FamilySalaryYellow - Distance_Yellow_Sky > FamilySalaryGray - Distance_Gray_Sky
   [set size 2 set away 1 move-to one-of patches with [pcolor = Yellow]
     ask myFamily [set size 2 set away 1 move-to one-of patches with [pcolor = yellow]]]
   if actual-FamilyIncome < FamilySalaryGray - Distance_Gray_Sky - family-costs  and FamilySalaryYellow - Distance_Yellow_Sky < FamilySalaryGray - Distance_Gray_Sky
   [set size 2 set away 1 move-to one-of patches with [pcolor = Gray]
     ask myFamily [set size 2 set away 1 move-to one-of patches with [pcolor = gray]]]
  ]

  ask workers with [pcolor = yellow][

   if actual-FamilyIncome < FamilySalarySky - Distance_Yellow_Sky - family-costs and FamilySalarySky - Distance_Yellow_Sky > FamilySalaryGray - Distance_Gray_Yellow
   [set size 2 set away 1 move-to one-of patches with [pcolor = Sky]
     ask myFamily [set size 2 set away 1 move-to one-of patches with [pcolor = sky]]]
   if actual-FamilyIncome < FamilySalaryGray - Distance_Gray_Yellow - family-costs  and FamilySalarySky - Distance_Yellow_Sky < FamilySalaryGray - Distance_Gray_Yellow
   [set size 2 set away 1 move-to one-of patches with [pcolor = Gray]
     ask myFamily [set size 2 set away 1 move-to one-of patches with [pcolor = gray]]]
  ]


  ; the immediate return phoenomenon is assumed typical of singles and more likely among low skilled

   ask workers with [away = 1 and count myFamily = 1 and skills != 3][let x random-float 1
     if x < 0.10 [set immediate-return 1 set size 1 move-to one-of patches with [pcolor = [native-country] of myself]]]

   ask workers with [away = 1 and count myFamily = 1 and skills = 3][let x random-float 1
     if x < 0.05 [set immediate-return 1 set size 1  move-to one-of patches with [pcolor = [native-country] of myself]]]


   ask workers [if long-away = 1 and pcolor = native-country [set return 1 set long-away 0 set size 1 ]]

   ask workers with[away = 1 ] [set long-away 1 set away 0]



end


to update_familiar_salaries_and_costs

   ask workers [set familySalarySky (sum [salarySky] of myFamily) set familySalaryGray (sum [salaryGray] of myFamily) set familySalaryYellow (sum [salaryYellow] of myFamily)]

   ask workers[  set family-costs sum [personal-costs] of myFamily]

    ;each worker earns the salary of its category and the total salary of the family is computed

   ask workers[
    if skills = 1 [set actual-salary [salaryL] of patch-here]
    if skills = 2 [set actual-salary [salaryM] of patch-here]
    if skills = 3 [set actual-salary [salaryH] of patch-here]]

   ask workers [set actual-familyIncome (sum [actual-salary] of myFamily)]


   setup_famliar_salaries

end

to update_job_market

  ask patches [let deltaGDP GDP - GDPlag
               let deltaJob (GDP_job_multiplier * deltaGDP) / 1500000
               let x count workers with [skills = 1 and pcolor = [pcolor] of myself]
               let y count workers with [skills = 2 and pcolor = [pcolor] of myself]
               let z count workers with [skills = 3 and pcolor = [pcolor] of myself]

    ; as GDP increases, new jobs are created

    if deltaGDP > 0 [set jobL jobL + deltaJob set jobM jobM + deltaJob set jobH jobH + deltaJob

    ; and the effect is greater for the category in which the country is already specialized

    if x > y and x > z [set jobL jobL + deltaJob / 3]
    if y > x and y > z [set jobL jobM + deltaJob / 3]
    if z > x and z > y [set jobL jobH + deltaJob / 3]

    ; new jobs for highly skilled people are likely to create new jobs for low skilled ones

    set jobL jobL + deltaJob * snowball_effectLH]

    ; then the change in the number of jobs has an effect on salaries

    if x != jobL [set salaryL salaryL + [job_market_flex] of self * (jobL - x)]
    if y != jobM [set salaryM salaryM + [job_market_flex] of self * (jobM - y)]
    if z != jobH [set salaryH salaryH + [job_market_flex] of self * (jobH - z)]


    ]
     ask workers[

    if skills = 1 [set actual-salary [salaryL] of patch-here]
    if skills = 2 [set actual-salary [salaryM] of patch-here]
    if skills = 3 [set actual-salary [salaryH] of patch-here]
    ]


end

to update_GDP_GDPlag

  ask patches [set GDPlag GDP]
  ask patches [set GDP sum [actual-salary] of workers with [pcolor = [pcolor] of myself] ]

end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
619
440
16
16
12.1
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

PLOT
637
294
928
432
Salary Low Skilled
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -7500403 true "" "plot [salaryL] of one-of patches with [pcolor = gray]"
"pen-1" 1.0 0 -1184463 true "" "plot [salaryL] of one-of patches with [pcolor = yellow]"
"pen-2" 1.0 0 -13791810 true "" "plot [salaryL] of one-of patches with [pcolor = sky]"

PLOT
637
150
929
288
Salary Middle Skilled
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -7500403 true "" "plot [salaryM] of one-of patches with [pcolor = gray]"
"pen-1" 1.0 0 -1184463 true "" "plot [salaryM] of one-of patches with [pcolor = yellow]"
"pen-2" 1.0 0 -13791810 true "" "plot [salaryM] of one-of patches with [pcolor = sky]"

PLOT
637
11
930
144
Salary High Skilled
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -7500403 true "" "plot [salaryH] of one-of patches with [pcolor = gray]"
"pen-1" 1.0 0 -1184463 true "" "plot [salaryH] of one-of patches with [pcolor = yellow]"
"pen-2" 1.0 0 -13791810 true "" "plot [salaryH] of one-of patches with [pcolor = sky]"

BUTTON
115
10
178
43
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

BUTTON
21
10
94
43
NIL
setup\n
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
13
332
190
365
Distance_Gray_Sky
Distance_Gray_Sky
0
100
78
1
1
NIL
HORIZONTAL

SLIDER
14
371
188
404
Distance_Gray_Yellow
Distance_Gray_Yellow
0
100
95
1
1
NIL
HORIZONTAL

SLIDER
14
410
190
443
Distance_Yellow_Sky
Distance_Yellow_Sky
0
100
76
1
1
NIL
HORIZONTAL

SWITCH
533
449
677
482
AsymmetricSkills?
AsymmetricSkills?
0
1
-1000

SLIDER
13
129
163
162
BaseSalarySky
BaseSalarySky
0
100
78
1
1
NIL
HORIZONTAL

SLIDER
14
166
165
199
BaseSalaryYellow
BaseSalaryYellow
0
100
85
1
1
NIL
HORIZONTAL

SLIDER
14
91
164
124
BaseSalaryGray
BaseSalaryGray
0
100
82
1
1
NIL
HORIZONTAL

SLIDER
9
449
174
482
initial_unempl_rate_sky
initial_unempl_rate_sky
0
1
0.86
0.01
1
NIL
HORIZONTAL

SLIDER
180
449
352
482
initial_unempl_rate_yellow
initial_unempl_rate_yellow
0
1
0.79
0.01
1
NIL
HORIZONTAL

SLIDER
359
449
526
482
initial_unempl_rate_gray
initial_unempl_rate_gray
0
1
0.82
0.01
1
NIL
HORIZONTAL

SLIDER
11
248
180
281
job_market_flex_sky
job_market_flex_sky
0
5
4
1
1
NIL
HORIZONTAL

SLIDER
12
285
180
318
job_market_flex_yellow
job_market_flex_yellow
0
5
4
1
1
NIL
HORIZONTAL

SLIDER
12
210
178
243
job_market_flex_gray
job_market_flex_gray
0
5
4
1
1
NIL
HORIZONTAL

SLIDER
10
50
192
83
HowManyWorkers
HowManyWorkers
50
150
128
1
1
NIL
HORIZONTAL

SLIDER
683
448
823
481
Snowball_effectLH
Snowball_effectLH
0
10
4
1
1
NIL
HORIZONTAL

SLIDER
830
448
983
481
GDP_job_multiplier
GDP_job_multiplier
0
100
49
1
1
NIL
HORIZONTAL

PLOT
941
12
1249
214
Return
NIL
NIL
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"Immediate" 1.0 0 -11221820 true "" "plot (count workers with [immediate-return = 1])"
"Not imm" 1.0 0 -2674135 true "" "plot (count workers with [return = 1])"
"Migrants" 1.0 0 -7500403 true "" "plot (count workers with [away = 1] + count workers with [long-away = 1])"

PLOT
940
226
1248
432
Migrants' familiar status
Time
NIL
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"Singles" 1.0 0 -2674135 true "" "plot (count workers with [count myFamily = 1 and pcolor != native-country])"
"Families" 1.0 0 -7500403 true "" "plot (count workers with [count myFamily != 1 and pcolor != native-country])"

PLOT
28
496
642
695
Number of Immigrants per country
NIL
NIL
0.0
10.0
0.0
0.1
true
false
"" ""
PENS
"default" 1.0 0 -7500403 true "" "plot count workers with [pcolor != native-country and pcolor = gray]"
"pen-1" 1.0 0 -1184463 true "" "plot count workers with [pcolor != native-country and pcolor = yellow]"
"pen-2" 1.0 0 -13791810 true "" "plot count workers with [pcolor != native-country and pcolor = sky]"

PLOT
646
495
1253
696
Workforce composition per skill country Gray
NIL
NIL
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"Low " 1.0 0 -2064490 true "" "plot (count workers with [pcolor = gray and skills = 1] / (count workers with [pcolor = gray] + 1))"
"Middle" 1.0 0 -13840069 true "" "plot (count workers with [pcolor = gray and skills = 2] / (count workers with [pcolor = gray] + 1))"
"High" 1.0 0 -16777216 true "" "plot (count workers with [pcolor = gray and skills = 3] / (count workers with [pcolor = gray] + 1))"

PLOT
26
700
643
891
Workforce composition per skill country Yellow
NIL
NIL
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"Low" 1.0 0 -2064490 true "" "plot (count workers with [pcolor = yellow and skills = 1] / (count workers with [pcolor = yellow] + 1))"
"Middle" 1.0 0 -13840069 true "" "plot (count workers with [pcolor = yellow and skills = 2] / (count workers with [pcolor = yellow] + 1))"
"High" 1.0 0 -16777216 true "" "plot (count workers with [pcolor = yellow and skills = 3] / (count workers with [pcolor = yellow] + 1))"

PLOT
647
701
1254
892
Workforce composition per skill country Sky
NIL
NIL
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"Low" 1.0 0 -2064490 true "" "plot (count workers with [pcolor = sky and skills = 1] / (count workers with [pcolor = sky] + 1))"
"Middle" 1.0 0 -13840069 true "" "plot (count workers with [pcolor = sky and skills = 2] / (count workers with [pcolor = sky] + 1))"
"High" 1.0 0 -16777216 true "" "plot (count workers with [pcolor = sky and skills = 3] / (count workers with [pcolor = sky] + 1))"

TEXTBOX
1005
456
1249
493
Immigrants are denoted by a bigger size\n
13
0.0
1

TEXTBOX
1304
28
1498
113
MAQBOOL THOUFEEQ THARAYIL\nmaqboolthoufeeq.t@gmail.com\n1000023606\n
11
0.0
1

@#$#@#$#@
### MAQBOOL THOUFEEQ THARAYIL - 1000023606

## WHAT IS IT?

The aim of this work is to look for reactions of the agents to the simulated economic environment as far as the migration of families with more than one component vs singles, the return in the native country after being abroad and the skill composition of the migration flows are concerned. The main driving force of migration is the salary differential, but also material and psychological costs are taken into account.


## HOW IT WORKS

Workers are grouped into families that behaves as a unique individual, maximizing the joint wage. If the familiar salary abroad, after subtracting costs, is higher than the actual one, the family will migrate. Once the labour supply in a country changes, the salary in that country changes as well and the migration process starts again.


## HOW TO USE IT

The setup button creates the world: three countries and workers with their own features, such as the skill level.
The go button will perform the process described in the "How it works section"


## THINGS TO NOTICE

Notice that the variables of interest as the migration of families with more than one component vs singles, the return in the native country after being abroad and the skill composition of the migration flows are presented in charts.


## THINGS TO TRY

Different outputs of the go procedure can be obtained according to the values of the sliders: inital unemployment rate, base salary, distances among countries, job market flexibility, GDP-job multiplier and snowball effect. The user can try to reproduce an actual situation among some countries around the world.


## EXTENDING THE MODEL

To fit better the reality, it could be possible to introduce the age dimension as far as workers are concerned or the possibility of a change in the skill level during the simulation. Moreover, a more realistic modelling for the labour demand and supply could be performed.
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
NetLogo 5.3.1
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

#todo create several files for different instances?

NP = 3 # number of units
NC = 2 # number of contaminants
NT = 2 # number of treatment combinations
NDi = 11 # number of available standard diameters

NL = 3 # number of incremental levels


Q_min = 2
# Class of water quality


Q_P_123  = [
200	200	200
70	70	70
70	70	70
0	7	14
0	17	34
50	100	100
40	80	80
9	9	9
7	10.5	10.5
14	21	21    
]

Q_RT_1 = [
0.00	25.16	31.49	0.00	0.00	11.74	18.00	4.25	0.00
0.00	0.00	20.76	0.00	0.00	0.00	2.11	3.73	0.00
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
0.00	3.74	0.00	0.00	0.00	0.00	0.00	0.00	0.00
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
5.35	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
]

Q_RT_2 = [
0.00	25.16	31.49	0.00	7.93	11.74	18.00	4.25	0.00
0.00	0.00	20.76	2.13	2.18	0.00	2.11	3.73	0.00
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
0.00	0.00	0.00	0.00	0.00	2.47	0.00	0.00	0.00
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
0.00	3.74	0.00	0.00	0.00	0.00	0.00	0.00	0.00
0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
0.00	0.00	0.00	0.00	3.80	0.00	0.00	0.00	0.00
5.35	0.00	0.00	0.00	0.00	0.00	2.67	0.00	0.00
]


#flow rate each unit m3/hr
Q_P = Q_P_123[:,1:3] #1

#flow loss each unit %
xloss  = [
    10
5
5
5
20
10
10
5
10
30
40         
]



 # Concentration max to each unit (COD, TDS, TSS)
C_max = [
15	700 
75	1000
50	700
75	700
75	1200
15	700
25	700
75	1000
15	700
25	800
        
]

C_MP = [
    90	2000	50
    300	500	100
    3000	2000	500
    300	500	100
    2000	2000	500
    3000	2000	500
    4500	1200	100
    400	500	10
    300	2000	150
    300	490	100
    3000	15.3	3290               
]


C_FW = [10 500 10];   # fresh water contaminat concentration

C_max_E = [1000 2000 250]; # discharge limit to sewer


R_U = [
45   23   50# UF
70   97   98# UF + RO
98  99  99 # FO + LPRO
]

CoT = [  5  
         20
         17
]

RR =
        [85
        45
        30
]


CoFW_U = [1 2 4]




hoursperday = 8
daysperyear = 261

min_velocity = 0.8  #m/s
max_velocity = 1.2 #m/s

nu = 1e-6
g = 9.81
rho = 1000
pump_efficiency = 0.6
Cost_per_kWh = 0.12 #Dollars/kWh
pipe_roughness = 0.00015
ft = 0.02 #friction factor


DN = [
0	0	0	1	1	1	1	1	1	1
0	0	0	1	1	1	1	1	1	1
0	0	0	1	1	1	1	1	1	1
1	1	1	0	0	1	1	1	1	1
1	1	1	0	0	1	1	1	1	1
1	1	1	1	1	0	0	1	1	1
1	1	1	1	1	0	0	1	1	1
1	1	1	1	1	1	1	0	1	1
1	1	1	1	1	1	1	1	0	0
1	1	1	1	1	1	1	1	0	0
]

Q_P = Q_P[1:NP, 1:NL]
C_MP = C_MP[1:NP, 1:NC]
C_max = C_max[1:NP,1:NC]
R_U = R_U[1:NT,1:NC]
CoT = CoT[1:NT]
RR = RR[1:NT]

Q_PL = xloss[1:NP]/100 .* Q_P
Q_PO = Q_P .- Q_PL
Dis = Dis[1:NP, 1:NP]
DN = DN[1:NP, 1:NP]


#Annualized CAPEX parameters:
n = 15      # number of years
r = 0.10    # discount rate
Annuity = r * ( 1 + r)^n/(( 1 + r)^n - 1)

Di_standard = 1e-3*[
0
32
40
50
63
75
90
110
125
140
160
]

Price_per_Unit_pipe = [
0
1.58
2.52
3.91
6.18
8.63
12.50
18.54
24.05
29.98
39.35
]



Dis = [
0	0	0	6	6	8	8	8	9	9
0	0	0	6	6	8	8	8	9	9
0	0	0	6	6	8	8	8	9	9
6	6	6	0	0	12	12	12	13	13
6	6	6	0	0	12	12	12	13	13
8	8	8	12	12	0	0	2	5	5
8	8	8	12	12	0	0	2	5	5
8	8	8	12	12	2	2	0	5	5
9	9	9	13	13	5	5	5	0	0
9	9	9	13	13	5	5	5	0	0 
]


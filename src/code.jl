# todo get rid of commented out lines, introduce parameters instead
# todo would we want to separate model creating from solving?
#     (this would also help is, say, SCIP is not installed but one just wants to compile the model)

using JuMP
using SCIP
using JLD2

m = Model(with_optimizer(SCIP.Optimizer, numerics_feastol = 1e-03, limits_gap=0.05, randomization_permutationseed = 5))
#m = Model(with_optimizer(SCIP.Optimizer, limits_gap=0.05))


include("Input_Inc.jl")
#include("Example_Input_test.jl")

"Add problem variables"
function addVars()

    #todo also comment on these variables
    @variable(m, X[1:NP, 1:NP, 1:NL], Bin)
    @variable(m, Y_R[1:NP, 1:NP, 1:NT, 1:NL], Bin)
    #@variable(m, Y_E[1:NP, 1:NT, 1:NL], Bin)

    # flow
    @variable(m, 0 <= Q_R[1:NP, 1:NP, 1:NL])
    @variable(m, 0 <= Q_RT[1:NP, 1:NP, 1:NL])
    #@variable(m, 0 <= Q_TL[1:NP, 1:NP, 1:NL])
    @variable(m, 0 <= Q_FW[1:NP, 1:NL])
    @variable(m, 0 <= Q_E[1:NP, 1:NL])


    # concentreation
    @variable(m, 0 <= C_P[1:NP, 1:NC, 1:NL])
    @variable(m, 0 <= C_PO[1:NP, 1:NC, 1:NL])
    @variable(m, 0 <= C_RT[1:NP, 1:NP, 1:NC, 1:NL])
    #@variable(m, 0 <= C_E[1:NP, 1:NC, 1:NL])

    # treatment
    @variable(m, R[1:NP, 1:NP, 1:NC, 1:NL])   # no bounds, makes it slower!
    #@variable(m, R_E[1:NP, 1:NC, 1:NL])



    # Transport variables
    #@variable(m, 0 <= Di[1:NP, 1:NP])
    #@variable(m, 0 <= Di_idx[1:NP, 1:NP, 1:NDi], Bin)
    #@variable(m, 0 <= v[1:NP, 1:NP])
    #@variable(m, 0 <= hf[1:NP, 1:NP])


    @variable(m, 0 <= CoFW[1:NP, 1:NL])
    #@variable(m, 0 <= Cost_of_pumping[1:NP, 1:NP])
    @variable(m, 0 <= CoP[1:NP, 1:NP, 1:NL]) # treatment cost
    @variable(m, 0 <= CoT_R[1:NP, 1:NP, 1:NL] ) # piping cost
    @variable(m, 0 <= CM[1:NL]) #connectivity measure
end


### Create and solve the model ###

addVars()

# constraints
#@constraint(m, [l = 1:NL], sum(Q_FW[1:NP, l]) == sum(Q_TL[1:NP, 1:NP, l]) + sum(Q_PL[1:NP, l]) + sum(Q_E[1:NP, l])) # (3.2) redundant!
@constraint(m, [j = 1:NP, l = 1:NL], Q_P[j,l] == Q_FW[j,l] + sum(Q_RT[i,j,l] for i = 1:NP)) #(3.3)
@constraint(m, [i = 1:NP, l = 1:NL], Q_PO[i,l] == sum(Q_R[i,j,l] for j = 1:NP) + Q_E[i,l]) # (3.4)
#@constraint(m, [i = 1:NP], Q_PO[i] == Q_P[i] - Q_PL[i]) #(3.5)

@constraint(m, [i = 1:NP, k = 1:NC, l = 1:NL], C_PO[i,k,l] == C_P[i,k,l] + C_MP[i,k]) # (3.6)

@constraint(m, [i = 1:NP, k = 1:NC, l = 1:NL], C_P[i,k,l]*Q_P[i,l] == sum(Q_RT[j,i,l] * C_RT[j,i,k,l] for j = 1:NP) + C_FW[k]*Q_FW[i,l] ) #(3.7)
@constraint(m, [i = 1:NP, j = 1:NP, k = 1:NC, l = 1:NL], C_RT[i,j,k,l] == C_PO[i,k,l]*(1 - R[i,j,k,l]/100)) #(3.8)
@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL], Q_RT[i,j,l] == (sum(RR[m]*Y_R[i,j,m,l] for m = 1:NT)/100)*Q_R[i,j,l]) #(3.9)
#@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL], Q_TL[i,j,l] == Q_R[i,j,l] - Q_RT[i,j,l] ) #(3.10)

@constraint(m, [i = 1:NP, j = 1:NP, k = 1:NC, l = 1:NL],  R[i,j,k,l] == sum(R_U[m,k]*Y_R[i,j,m,l] for m = 1:NT)) #(3.11)
@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL], sum(Y_R[i,j,m,l] for m = 1:NT) <= X[i,j,l])
#@constraint(m, sum(Y_R, dims = 3) .==1)


# no recirculation 
@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL], X[i,j,l] + X[j,i,l] <= 1) #(3.13)


# Constraints
@constraint(m, [i = 1:NP, k = 1:NC, l = 1:NL], C_P[i,k,l] <= C_max[i,k]) #(3.14)
#@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL], (1-X[i,j,l]) <= sum(Y_R[i,j,1,l]) #(3.15)
@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL],  Q_RT[i,j,l] >= X[i,j,l]*Q_min) #(3.16)
@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL],  Q_R[i,j,l] <= minimum([Q_P[i,l],Q_P[j,l]])*X[i,j,l]) #(3.17)



# tighter bounds
@constraint(m, [i = 1:NP, l = 1:NL], Q_FW[i,l] <= Q_P[i,l])  #(3.18)
@constraint(m, [i = 1:NP, l = 1:NL], Q_E[i,l] <= Q_P[i,l])   # (3.19)
@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL], Q_R[i,j,l] <= minimum([Q_PO[i,l],Q_P[j,l]])) #(3.20)
@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL], Q_RT[i,j,l] <= minimum([Q_PO[i,l],Q_P[j,l]])) #(3.21)
@constraint(m, [i = 1:NP, j = 1:NP, k = 1:NC, l = 1:NL], C_RT[i,j,k,l] <= C_max[i,k] + C_MP[i,k]) #(3.22)


# costs
@constraint(m, [i = 1:NP, l = 1:NL], CoFW[i,l] ==  Q_FW[i,l]*CoFW_U[l]) #(3.27)
@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL], CoT_R[i,j,l] == sum(Y_R[i,j,m,l]*CoT[m] for m = 1:NT)*Q_R[i,j,l]) #(3.28)

@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL], CoP[i,j,l] == Dis[i,j]*Q_RT[i,j,l])

@constraint(m, [l = 1:NL], CM[l] == sum(DN[i,j]*X[i,j,l]/(NP*(NP-1)) for i = 1:NP, j = 1:NP))
@constraint(m, [l = 1:NL], CM[l] <= 1)




# Incremental flow constraints

@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL-1], X[i,j,l] <= X[i,j,l+1])  #(3.30)
@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL-1], Q_RT[i,j,l] == Q_RT[i,j,l+1]*X[i,j,l]) #(3.31)

#Incremental treatment constraints
#@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL-1], Y_R[i,j,1,l] <= Y_R[i,j,1,l+1] )
@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL-1], Y_R[i,j,1,l] <= Y_R[i,j,1,l+1] + Y_R[i,j,2,l+1] )
@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL-1], Y_R[i,j,2,l] <= Y_R[i,j,2,l+1] )
#@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL-1], Y_R[i,j,2,l] <= Y_R[i,j,2,l+1] + Y_R[i,j,3,l+1])
#@constraint(m, [i = 1:NP, j = 1:NP, l = 1:NL-1], Y_R[i,j,3,l] <= Y_R[i,j,3,l+1])


# Water saving constraint
#@constraint(m, sum(Q_FW) / sum(Q_P) <= 0.80)
#@constraint(m, sum(CoP) <= 0)
#@constraint(m, sum(CoT_R) <= 25000)
#@constraint(m, sum(CoT_R) + sum(CoP) <= 3500 )

# Network connectivity measure
#@constraint(m, sum(CM) == 0.5)

#@constraint(m, Q_RT[:,:,1] .== Q_RT_1)
#@constraint(m, Q_RT[:,:,2] .== Q_RT_2)


@objective(m, Min,
#sum(Q_FW)
sum(CoFW)  
#sum(Cost_of_pumping[i,j] for i = 1:NP, j = 1:NP) +
#sum(CoP) + 
#sum(CoT_R) 
#sum(CoT_E)

)   #(3.1)

#@objective(m, Max, sum(Q_RT))

JuMP.optimize!(m)

println("Objective value: ", JuMP.objective_value(m))
Q_RT = JuMP.value.(Q_RT)
Q_R = JuMP.value.(Q_R)
#Q_TL = JuMP.value.(Q_TL)
Q_FW = JuMP.value.(Q_FW)
Q_E = JuMP.value.(Q_E)
X = JuMP.value.(X)
C_P = JuMP.value.(C_P)
C_PO = JuMP.value.(C_PO)
C_RT = JuMP.value.(C_RT)

R = JuMP.value.(R)
Y_R = JuMP.value.(Y_R)
#Y_E = JuMP.value.(Y_E)

#Di = JuMP.value.(Di)
#Di_idx = JuMP.value.(Di_idx)
#v = JuMP.value.(v)
CoFW = JuMP.value.(CoFW)
CoT_R = JuMP.value.(CoT_R)
#CoT_E = JuMP.value.(CoT_E)
CoP = JuMP.value.(CoP)
CM = JuMP.value.(CM)
#Cost_of_pumping = JuMP.value.(Cost_of_pumping)
println("Water saving L1 : ", sum(Q_RT[:,:,1]))
println("Water saving L2 : ", sum(Q_RT[:,:,2]))
println("Water saving L3 : ", sum(Q_RT[:,:,3]))
println("Water saving total : ", sum(Q_RT))
#println("Water saving L1 %: ", (1 - sum(Q_FW[:,1])/sum(Q_P[:,1]))*100)
#println("Water saving L2 %: ", (1 - sum(Q_FW[:,2])/sum(Q_P[:,2]))*100)
#println("Water saving L3 %: ", (1 - sum(Q_FW[:,3])/sum(Q_P[:,3]))*100)
println("Water saving total %: ", (1 - sum(Q_FW)/sum(Q_P))*100)
println("Cost L1 : ", sum(CoT_R[:,:,1]) + sum(CoP[:,:,1]))
println("Cost L2 : ", sum(CoT_R[:,:,2]) + sum(CoP[:,:,2]))
println("Cost L3 : ", sum(CoT_R[:,:,3]) + sum(CoP[:,:,3]))
println("Cost total : ", sum(CoT_R) + sum(CoP))
println("CoP_total = ", sum(CoP))
println("CoT_R_Total = ", sum(CoT_R))
println("CM = ", CM)
#println("CoP = ", CoP)
#println("CoT_R = ", CoT_R)
println("Q_RT = ", Q_RT)
println("Y_R = ", Y_R)

using JuMP
using JLD2

#todo make the instance name a parameter

"specifies the objective function"
function addObjective(model)
    println("Here we set objective")
end

"adds variables to a model"
function addVars(model)
@variable(m, X[1:NP, 1:NP, 1:NL], Bin)
@variable(m, Y_R[1:NP, 1:NP, 1:NT, 1:NL], Bin)
#@variable(m, Y_E[1:NP, 1:NT, 1:NL], Bin)

# flow
@variable(m, 0 <= Q_R[1:NP, 1:NP, 1:NL], Int)
@variable(m, 0 <= Q_RT[1:NP, 1:NP, 1:NL], Int)
#@variable(m, 0 <= Q_TL[1:NP, 1:NP, 1:NL])
@variable(m, 0 <= Q_FW[1:NP, 1:NL], Int)
@variable(m, 0 <= Q_E[1:NP, 1:NL], Int)


# concentreation
@variable(m, 0 <= C_P[1:NP, 1:NC, 1:NL], Int)
@variable(m, 0 <= C_PO[1:NP, 1:NC, 1:NL], Int)
@variable(m, 0 <= C_RT[1:NP, 1:NP, 1:NC, 1:NL], Int)
#@variable(m, 0 <= C_E[1:NP, 1:NC, 1:NL])

# treatment
@variable(m, R[1:NP, 1:NP, 1:NC, 1:NL], Int)   # no bounds, makes it slower!
#@variable(m, R_E[1:NP, 1:NC, 1:NL])



# Transport variables
#@variable(m, 0 <= Di[1:NP, 1:NP])
#@variable(m, 0 <= Di_idx[1:NP, 1:NP, 1:NDi], Bin)
#@variable(m, 0 <= v[1:NP, 1:NP])
#@variable(m, 0 <= hf[1:NP, 1:NP])


@variable(m, 0 <= CoFW[1:NP, 1:NL], Int)
#@variable(m, 0 <= Cost_of_pumping[1:NP, 1:NP])
@variable(m, 0 <= CoP[1:NP, 1:NP, 1:NL], Int) # treatment cost
@variable(m, 0 <= CoT_R[1:NP, 1:NP, 1:NL], Int ) # piping cost
@variable(m, 0 <= CM[1:NL], Int) #connectivity measure

end

"adds constraints to a model"
function addConstraints(model)
    println("And here we add constraints")
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

end

function createModel(model, inst)
    include(inst)
    addObjective(model)
    addVars(model)
    addConstraints(model)
end

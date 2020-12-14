using JuMP
using JLD2

#todo make the instance name a parameter

"specifies the objective function"
function addObjective(model)
    println("Here we set objective")
end

"adds variables to a model"
function addVars(model)
    @variable(model, X[1:NP, 1:NP, 1:NL], Bin)
    @variable(model, Y_R[1:NP, 1:NP, 1:NT, 1:NL], Bin)
    println("Here we add vars")
    #@variable(m, 0 <= Q_R[1:NP, 1:NP, 1:NL])
    #@variable(m, 0 <= Q_RT[1:NP, 1:NP, 1:NL])
end

"adds constraints to a model"
function addConstraints(model)
    println("And here we add constraints")
end

function createModel(model, inst)
    include(inst)
    addObjective(model)
    addVars(model)
    addConstraints(model)
end

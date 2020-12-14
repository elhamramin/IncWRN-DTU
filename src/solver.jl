using JuMP
using JLD2

param_solver=""
if param_solver=="SCIP"
    using SCIP
end

function retrieveSolution(m)
    println("Here the values from solver are stored in the model")
end

function solve(m)
    if param_solver==""
        println("We have no solver, solve does nothing")
    else
        m.set_optimizer(SCIP.Optimizer)
    end
    retrieveSolution(m)
end

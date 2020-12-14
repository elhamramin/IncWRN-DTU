using JLD2

include("model.jl")
include("solver.jl")

instancename="../data/inst1.jl"
model = Model()

createModel(model, instancename)
solve(model)
#printSolution(model)

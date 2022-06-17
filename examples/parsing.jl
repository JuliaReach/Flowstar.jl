using Pkg; cd(@__DIR__); Pkg.activate("..")

using Flowstar, TaylorModels

# Read *.flow file
model = joinpath(@__DIR__, "simple.model")

# Read string and parse into FlowstarContinuousSolution
S = flowstar(model)
FS1 =  parse(FlowstarContinuousSolution, S)

# Direct Constructor
FS2 = FlowstarContinuousSolution(model)

fp = flowpipe(FS2)
tm = FP[end][1]  # final set, state 1

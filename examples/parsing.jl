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
tm = fp[end][1]  # final set, state 1

## parse string into TaylorModel1{TaylorN{Interval{Float64}}, Float64}
FS3 = parse(FlowstarContinuousSolution, S, Val(true))

tm1 = FS3[end][1]
eval_t = mid(domain(tm1))
tm1(eval_t)
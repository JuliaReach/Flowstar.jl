# using Pkg; cd(@__DIR__); Pkg.activate("..")

using ReachabilityAnalysis
using Flowstar, TaylorModels

# Read *.flow file
model = joinpath(@__DIR__, "simple.model")

# Read string and parse into FlowstarContinuousSolution
S = flowstar(model)

## TaylorModel1{TaylorN}
FS1 =  parse(FlowstarContinuousSolution, S)
typeof(FS1)

## TaylorModelN
FS2 = parse(FlowstarContinuousSolution, S, Val(false))
typeof(FS2)

# Direct Constructor
## TaylorModel1{TaylorN}
FS3 = FlowstarContinuousSolution(model)
typeof(FS3)

## TaylorModelN
FS4 = FlowstarContinuousSolution(model, Val(false))
typeof(FS4)
fp2 = Flowstar.flowpipe(FS4)
fp2[end][2]
FS3 # note, b/c TaylorN requires setting a global with numvars, FS3 isn't valid after calling Val(false)


## RA Experiments

FS3 = FlowstarContinuousSolution(model)
fp = Flowstar.flowpipe(FS3) 
dom_t = Flowstar.domain(FS3)
rs = TaylorModelReachSet(getindex.(fp,1), dom_t)


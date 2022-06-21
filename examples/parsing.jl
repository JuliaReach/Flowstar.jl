using Pkg; cd(@__DIR__); Pkg.activate("..")

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

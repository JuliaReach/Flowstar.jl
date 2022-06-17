using Pkg; cd(@__DIR__); Pkg.activate("..")

using Flowstar, TaylorModels, ReadableRegex

# Read *.flow file
model = joinpath(abspath("../test/models"),"lv.model")
model = joinpath(@__DIR__, "gerlach.model")
S = flowstar(model; outdir = pwd())
Sheader, Slocal, Sbody = split(S, "{", limit = 3)

fph = parse(FlowpipeHeader, Sheader)

local_vars = ["local_t"; split(Flowstar.match_between(Slocal, "tm var "), ",")]

P = Flowstar._parse3(Sbody, order(fph), nstates(fph)+1,states(fph), local_vars, 5);

P[end][1]  # time horizon, state

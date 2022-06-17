using Pkg; cd(@__DIR__); Pkg.activate("..")

using Flowstar, TaylorModels, ReadableRegex



# Read *.flow file
S = flowstar(joinpath(abspath("../test/models"),"lv.model"); outdir = pwd())
Sheader, Slocal, Sbody = split(S, "{", limit = 3)

fph = parse(FlowpipeHeader, Sheader)

local_vars = ["local_t"; split(Flowstar.match_between(Slocal, "tm var "), ",")]

# varmap = lvars .=> vars

ex =Flowstar._parse(Sbody, order(fph), nstates(fph)+1, local_vars)
Flowstar.x

P = Flowstar._parse2(Sbody, order(fph), nstates(fph)+1,states(fph), local_vars, 3)

P[end][1]([0.002, 1.0, 1.0])

# Parse Body
body = split(Sbody, "{")

res = map(body) do b
    s= split(b, "\n\n\n")[1]
    s = replace.(s, "}"=>"")
    s = strip.(s)
    s = replace.(s, "\n" => ";")
    s = replace.(s, "[" => "(")
    s = replace.(s, "]" => ")")
    s = replace.(s, "," => "..")
    for (idx,lv) in enumerate(local_vars)
        s = replace(s, "$lv" =>"ξ[$idx]")
    end
    "function _fp(ξ); $(s); return [$(join(states(fph), ","))]; end"
end

# body = replace.(body, "}"=>"")
# body = strip.(body)
# body = replace.(body, "\n" => ";")
# body = replace.(body, "[" => "(")
# body = replace.(body, "]" => ")")
# body = replace.(body, "," => "..")




# body = replace.(body, " in" =>"δ =")
# body = map(body[1:1]) do b
#     for (idx,lv) in enumerate(local_vars)
#         b = replace(b, "$lv" =>"X[$idx]")
#         b = replace(b, "X[$idx]δ" => "$")
#     end
#     b
# end

# body = replace.(body, "local_t" => "X[1]")


# pushfirst!(body[1], "function hello($path"



ξ = set_variables(join(["t"; states(fph)]," "), order=order(fph))

ex = Meta.parse(res[1])

eval(ex)

_fp(ξ)

# MAKE FLOWSTARSOLUTION STRUCT -> DISPATCH FOR TM CONSTRUCTOR????

using Symbolics

@variables r t

@variables local_var_1 local_var_2
local_t = TaylorModel1(6,0.0..3.0)

local_t*local_var_1

import Base.*
function *(a::Taylor1{S},b::Num) where S<:Union{Real, Complex}
a*b
end




f = 2*r + r*t + r^2*t + t^2
expand(f)
simplify(f)

[2:end-3]

re = r"\{([^{}]+)\}"

m=eachmatch(re, S) |> collect;

m|> length


# model = joinpath(@__DIR__, "gerlach.model")

# S = flowstar(model)
Sheader, Slocal, Sbody = split(S, "{", limit = 3)

split(Sbody, "{")


fph = parse(FlowpipeHeader, Sheader)

local_vars = ["local_t"; split(Flowstar.match_between(Slocal, "tm var "), ",")]
# P = Flowstar._parse2(Sbody, order(fph), nstates(fph)+1,states(fph), local_vars, 50)
P = Flowstar._parse3(Sbody, order(fph), nstates(fph)+1,states(fph), local_vars, 5);

P[1][2]  # time horizon 1, state 2

# model2 = joinpath(@__DIR__,"..","test","models","lv.model")
# S =flowstar(model2)
# Sheader, Slocal, Sbody = split(S, "{", limit = 3)
# fph = parse(FlowpipeHeader, Sheader)
# P = Flowstar._parse3(Sbody, order(fph), nstates(fph)+1,states(fph), local_vars, 5);

# P[1][2]  # time horizon 1, state 2

## ADD PARSE FUNCTIONS, NEEDS FlowstarSolution struct -> parse string into header and flowpipe???
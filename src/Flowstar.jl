module Flowstar

using Flowstar_jll, TaylorModels

import Flowstar_jll: flowstar
import TaylorModels: flowpipe
import Base: parse

include("string_utils.jl")

function flowstar(model)
    outdir = mktempdir()
    cmd = Cmd(`$(flowstar())`; dir = outdir)
    run(pipeline(model, cmd))

    @info "Flow* intermediate files saved to $outdir"
    flow = first(filter(x->endswith(x,".flow"), readdir(joinpath(outdir, "outputs"), join = true)))
    String(read(flow))
end

struct FlowstarContinuousSolution{ℕ}
    states::Vector{String}
    order::Int
    cutoff::Float64
    output::String
    local_vars::Vector{String}
    flow::Vector{Vector{TaylorModelN{ℕ, Interval{Float64}, Float64}}}
end

function FlowstarContinuousSolution(model)
    flowstr = flowstar(model)
    parse(FlowstarContinuousSolution, flowstr)
end

states(fs::FlowstarContinuousSolution) = fs.states
nstates(fs::FlowstarContinuousSolution) = length(states(fs))
order(fs::FlowstarContinuousSolution) = fs.order
cutoff(fs::FlowstarContinuousSolution) = fs.cutoff
local_vars(fs::FlowstarContinuousSolution) = fs.local_vars
flowpipe(fs::FlowstarContinuousSolution) = fs.flow


function parse(::Type{FlowstarContinuousSolution}, str; kwargs...)
    _valid_file(str)
    head_str, local_str, body_str = split(str, "{", limit = 3)

    vars, order, cutoff, output = _parse_header(head_str)
    local_vars = _parse_locals(local_str, )

    tstates = !any(vars.=="t") ? ["t"; vars] : vars
    names = join(tstates, " ")
    
    fp = _parse_flowpipe(body_str, order, vars, local_vars; names)
    FlowstarContinuousSolution(vars, order, cutoff, output, local_vars, fp)
end

function _parse_header(str)
    states = String.(split( _match_between(str, "state var "), ","))
    order = parse(Int, _match_between(str, "order "))
    cutoff = parse(Float64, _match_between(str, "cutoff "))
    output = String(_match_between(str, "output "))
    states, order, cutoff, output
end

function _parse_locals(str)
    local_vars = String.(split(_match_between(str, "tm var "), ","))
    !any(local_vars.=="local_t") ? ["local_t"; local_vars] : local_vars
end

function _parse_flowpipe(str, order, vars, lvars; names = "ξ")
    nvars = length(vars) + 1
    ξ = eval(:(ξ = set_variables($names; order= $order, numvars = $nvars)))

    body = split(str, "{")

    map(body) do b
        _tm, _dom = _cleantm(b, lvars)
        dom = eval(Meta.parse(_dom))
        states = _split_states(_tm)
        
        polrem = map(states) do state
             pol, rem = _split_poly_rem(state)
             pol = eval(Meta.parse(pol))
             rem = eval(Meta.parse(rem))

             TaylorModelN(pol, rem, IntervalBox(zeros(nvars)), dom)
        end
    end
end

function _valid_file(s)
    @assert occursin("continuous flowpipes", s) "Currently only continuous flowpipe solutions are supported"
end

export flowstar,  FlowstarContinuousSolution, states, nstates, order, cutoff, flowpipe, local_vars
end


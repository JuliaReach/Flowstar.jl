module Flowstar

using Flowstar_jll, TaylorModels, TypedPolynomials

import Flowstar_jll: flowstar
import TaylorModels: flowpipe, domain
import Base: parse

include("model.jl")
include("string_utils.jl")


function flowstar(model; outdir = mktempdir())
    output_name = _match_between(String(read(model)), "output ")*".flow"

    cmd = Cmd(`$(flowstar())`; dir = outdir)
    run(pipeline(model, cmd))

    @info "Flow* intermediate files saved to $outdir"
    flow = joinpath(outdir, "outputs", output_name)
    
    String(read(flow))
end

struct FlowstarContinuousSolution{𝕋}
    states::Vector{String}
    order::Int
    cutoff::Float64
    output::String
    flow::Vector{Vector{𝕋}}
end

function FlowstarContinuousSolution(model, tm1 = Val(true); kwargs...)
    flowstr = flowstar(model; kwargs...)
    parse(FlowstarContinuousSolution, flowstr, tm1;)
end

states(fs::FlowstarContinuousSolution) = fs.states
nstates(fs::FlowstarContinuousSolution) = length(states(fs))
order(fs::FlowstarContinuousSolution) = fs.order
cutoff(fs::FlowstarContinuousSolution) = fs.cutoff
flowpipe(fs::FlowstarContinuousSolution) = fs.flow
domain(fs::FlowstarContinuousSolution) = domain(flowpipe(fs)[1][1])

function parse(::Type{FlowstarContinuousSolution}, str, tm1 = Val(true))
    _valid_file(str)
    head_str, local_str, body_str = split(str, "{", limit = 3)

    vars, order, cutoff, output = _parse_header(head_str)
    local_vars = _parse_locals(local_str)
    
    fp = _parse_flowpipe(body_str, order, vars, local_vars, tm1)
    FlowstarContinuousSolution(vars, order, cutoff, output, fp)
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

function _parse_flowpipe(str, order, vars, lvars, ::Val{true})
    nvars = length(vars)
    nvars_t = nvars + 1

    # TypePolynomial symbols
    ξ = eval(:(@polyvar ξ[1:$nvars_t]))

    # TaylorN symbols
    ξtm = eval(:(set_variables($(join(vars, " ")); order= $order, numvars = $nvars)))

    body = split(str, "{")
    map(body) do b
        _tm, _dom = _cleantm(b, lvars)
        dom = eval(Meta.parse(_dom))
        states = split(_tm, ";", keepempty = false)
    
        polrem = map(states) do state
            pol, rem = _split_poly_rem(state)
            rem = eval(Meta.parse(rem))
            pol =  eval(Meta.parse(pol))
            coeffs = map(0:order) do n 
                coeff = TypedPolynomials.coefficient(pol, ξ[1]^n, [ξ[1]])
                coeff(ξ[1]=>0.0, ξ[2:end] => ξtm)  # coeff is independent of ξ[1], but required for type conversion
            end
            TaylorModel1(Taylor1(coeffs), rem, 0.0..0.0, dom[1])
        end
    end
end

function _parse_flowpipe(str, order, vars, lvars, ::Val{false})
    tstates = !any(vars.=="t") ? ["t"; vars] : vars
    names = join(tstates, " ")

    nvars = length(vars) + 1
    ξ = eval(:(ξ = set_variables($names; order= $order, numvars = $nvars)))

    body = split(str, "{")

    map(body) do b
        _tm, _dom = _cleantm(b, lvars)
        dom = eval(Meta.parse(_dom))
        states = split(_tm,";", keepempty = false)
        
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

export flowstar
export FlowstarContinuousSolution, states, nstates, order, cutoff, flowpipe, domain
end

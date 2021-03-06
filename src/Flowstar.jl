module Flowstar

using Flowstar_jll, TaylorModels, TypedPolynomials, ProgressLogging

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

function flowstar(m::AbstractFlowstarModel; outdir = mktempdir())
    fp = joinpath(outdir, "$(m.setting.name).model")
    open(fp,"w") do f
        print(f, string(m))
    end
    flowstar(fp; outdir)
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
domain(fs::FlowstarContinuousSolution) = domain.(first.(flowpipe(fs)))

function parse(::Type{FlowstarContinuousSolution}, str, tm1 = Val(true))
    _valid_file(str)
    split_str = split(str, "{", limit = 3)
    @assert length(split_str) == 3 "0 flowpipe(s) computed. Please try smaller step sizes or larger Taylor model orders"
    head_str, local_str, body_str = split_str

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
    @withprogress name="Parsing Flowpipes" begin
        lb = length(body)
        map(enumerate(body)) do (i, b)
            _tm, _dom = _cleantm(b, lvars)
            dom = eval(Meta.parse(_dom))
            states = split(_tm, ";", keepempty = false)
        
            tm = map(states) do state
                pol, rem = _split_poly_rem(state)
                rem = eval(Meta.parse(rem))
                pol =  eval(Meta.parse(pol * "+ Interval(0)*prod(ξ)")) # append polynomial term with zero coefficient to ensure is a polynomial type
                coeffs = map(0:order) do n 
                    coeff = TypedPolynomials.coefficient(pol, ξ[1]^n, [ξ[1]])
                    coeff(ξ[1]=>0.0, ξ[2:end] => ξtm)  # coeff is independent of ξ[1], but required for type conversion
                end
                TaylorModel1(Taylor1(coeffs), rem, 0.0..0.0, dom[1])
            end
            @logprogress i/lb

            tm
        end
    end
end

function _parse_flowpipe(str, order, vars, lvars, ::Val{false})
    tstates = !any(vars.=="t") ? ["t"; vars] : vars
    names = join(tstates, " ")

    nvars = length(vars) + 1
    ξ = eval(:(ξ = set_variables($names; order= $order, numvars = $nvars)))

    body = split(str, "{")
    @withprogress name="Parsing Flowpipes" begin
        lb = length(body)
        map(enumerate(body)) do (i, b)
            _tm, _dom = _cleantm(b, lvars)
            dom = eval(Meta.parse(_dom))
            states = split(_tm,";", keepempty = false)
            
            tm = map(states) do state
                pol, rem = _split_poly_rem(state)
                pol = eval(Meta.parse(pol * "+ Interval(0)*prod(ξ)")) # append TaylorModel term with zero coefficient to ensure is a TaylorModel type
                rem = eval(Meta.parse(rem))

                TaylorModelN(pol, rem, IntervalBox(zeros(nvars)), dom)
            end
            @logprogress i/lb

            tm
        end
    end
end


function _valid_file(s)
    @assert occursin("continuous flowpipes", s) "Currently only continuous flowpipe solutions are supported"
end

export flowstar
export FlowstarContinuousSolution, states, nstates, order, cutoff, flowpipe, domain
end

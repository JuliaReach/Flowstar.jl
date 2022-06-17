module Flowstar

using Flowstar_jll, TaylorModels, RuntimeGeneratedFunctions, ProgressLogging
RuntimeGeneratedFunctions.init(@__MODULE__)

import Flowstar_jll: flowstar
import Base: parse


function flowstar(model; outdir = mktempdir())
    cmd = Cmd(`$(flowstar())`; dir = outdir)
    run(pipeline(model, cmd))

    @info "Flow* intermediate files saved to $outdir"
    flow = first(filter(x->endswith(x,".flow"), readdir(joinpath(outdir, "outputs"), join = true)))
    String(read(flow))
end

function match_between(s::AbstractString, left, right = "\\n\\r")
    re= Regex("(?<=\\Q$left\\E)(.*?)(?=[$right])")
    m = match(re, s)

    @assert !isnothing(m) "No regex matches found between $left and $right"
    m.match
end

struct FlowpipeHeader{𝕊}
    states::Vector{𝕊}
    order::Int
    cutoff::Float64
    output::𝕊
    # locals::Vector{𝕊}
end

function parse(::Type{FlowpipeHeader}, str)
    states = split( match_between(str, "state var "), ",")
    order = parse(Int, match_between(str, "order "))
    cutoff = parse(Float64, match_between(str, "cutoff "))
    output = match_between(str, "output ")
    # locals = split(match_between(Slocal, "tm var "), ",")
    FlowpipeHeader(states, order, cutoff, output)
end

states(fp::FlowpipeHeader) = fp.states
nstates(fp::FlowpipeHeader) = length(states(fp))
order(fp::FlowpipeHeader) = fp.order
cutoff(fp::FlowpipeHeader) = fp.cutoff

<<<<<<< HEAD

function _split_states(str)
    split(str,";", keepempty = false)
end

function _intervalstr(str)
    str = replace(str, "[" => "(")
    str = replace(str, "]" => ")")
    str = replace(str, "," => "..")
    str
end

function _cleantm(str, lvars)
    tm_str, dom_str = split(str, "\n\n\n")

    tm_str = replace(tm_str, "}"=>"")
    tm_str = strip(tm_str)
    tm_str = replace.(tm_str, "\n" => ";")
    tm_str = _intervalstr(tm_str)
    for (idx,lv) in enumerate(lvars)
        tm_str = replace(tm_str, "$lv" =>"ξ[$idx]")
    end

    dom_str = replace(dom_str, "}"=>"")
    dom_str = strip(dom_str)
    dom_str = _intervalstr(dom_str)
    for lv in lvars[2:end]
        dom_str = replace(dom_str, "\n$lv in" =>",")
    end
    dom_str = replace(dom_str, "$(lvars[1]) in" => "IntervalBox(")
    dom_str = dom_str*")"

    tm_str, dom_str
end

function _split_poly_rem(str)
    idx = findlast('+', str)
    str[1:idx-1], str[idx+1:end]
end

function _parse3(str, order, numvars, vars, lvars, idx; names = "ξ")
    ξ = eval(:(ξ = set_variables($names; order= $order, numvars = $numvars)))

    body = split(str, "{")

    map(body) do b
        tm, dom = _cleantm(b, lvars)
        dom = eval(Meta.parse(dom))
        states = _split_states(tm)
        
        polrem = map(states) do state
             pol, rem = _split_poly_rem(state)
             pol = eval(Meta.parse(pol))
             rem = eval(Meta.parse(rem))

             TaylorModelN(pol, rem, IntervalBox(zeros(numvars)), dom)
        end
=======
function _parse(str, order, numvars, lvars; names = "ξ")
    body = split(str, "{")
    body = replace.(body, "}"=>"")
    body = strip.(body)
    body = replace.(body, "\n" => ";")
    body = replace.(body, "[" => "(")
    body = replace.(body, "]" => ")")
    body = replace.(body, "," => "..")
    body = replace.(body, " in" =>"δ =")


    # local_t, local_var_1, local_var_2 = set_variables(names; order, numvars)
    ex = Meta.parse(body[1])

    _build_and_inject_function(@__MODULE__, ex)
    # eval(ex)

    # @show local_t
end

function _parse2(str, order, numvars, vars, lvars, idx; names = "ξ")
    ξ = set_variables(names; order, numvars)

    body = split(str, "{")

    res = map(body) do b
        s= split(b, "\n\n\n")[1]
        s = replace.(s, "}"=>"")
        s = strip.(s)
        s = replace.(s, "\n" => ";")
        s = replace.(s, "[" => "(")
        s = replace.(s, "]" => ")")
        s = replace.(s, "," => "..")
        for (idx,lv) in enumerate(lvars)
            s = replace(s, "$lv" =>"ξ[$idx]")
        end
        "function _fp(ξ); $(s); return [$(join(vars, ","))]; end"
    end

    map(res, 1:length(res)) do r, idx
        @show idx
        ex = Meta.parse(r)
        _f = @RuntimeGeneratedFunction(ex)
        _f(ξ)
>>>>>>> 88f16b3 (initial parsing)
    end
end


function valid_file(s)
    @assert occursin("continuous flowpipes", s) "Currently only continuous flowpipe solutions are supported"
end


export flowstar, FlowpipeHeader, states, nstates, order, cutoff
end


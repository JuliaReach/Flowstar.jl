import Base: string, min, max

## Preconditioner
abstract type AbstractPreconditioner end
struct IdentityPreconditioner <: AbstractPreconditioner; end
struct QRPreconditioner <: AbstractPreconditioner; end

_precond_string(::IdentityPreconditioner) = "identity precondition"
_precond_string(::QRPreconditioner) = "QR precondition"

## TM Order
abstract type AbstractTMOrder end

struct FixedTMOrder <: AbstractTMOrder
    order::Int
end

struct AdaptiveTMOrder <: AbstractTMOrder
    min::Int
    max::Int
end

min(o::FixedTMOrder) = o.order
min(o::AdaptiveTMOrder) = o.min
max(o::FixedTMOrder) = o.order
max(o::AdaptiveTMOrder) = o.max

_order_string(o::FixedTMOrder) = "fixed orders $(min(o))"
_order_string(o::AdaptiveTMOrder) = "adaptive orders { min $(min(o)) , max $(max(o)) }"

## Scheme
abstract type AbstractODEScheme end
struct PolyODEScheme1 <: AbstractODEScheme; end
struct PolyODEScheme2 <: AbstractODEScheme; end
struct PolyODEScheme3 <: AbstractODEScheme; end
struct LinearODEScheme{𝕋𝕍} <: AbstractODEScheme;
    function LinearODEScheme(tv=false)
        @assert tv == false "Linear Time Varying Scheme Not Currently Supported"
        new{tv}()
    end
end
struct NonPolyODEScheme <: AbstractODEScheme; end

_scheme_string(::PolyODEScheme1) = "poly ode 1"
_scheme_string(::PolyODEScheme2) = "poly ode 2"
_scheme_string(::PolyODEScheme3) = "poly ode 3"
_scheme_string(::LinearODEScheme{true}) = "ltv ode"
_scheme_string(::LinearODEScheme{false}) = "lti ode"
_scheme_string(::NonPolyODEScheme) = "nonpoly ode"

## Setting
struct FlowstarSetting{𝕋, 𝕆<:AbstractTMOrder, ℙ<:AbstractPreconditioner}
    time_step::𝕋
    tf::Float64
    order::𝕆
    name::String
    rem_est::Float64
    precond::ℙ
    plot_states::String
    cutoff::Float64
    precision::Int
    verbose::Bool
    function FlowstarSetting(ts::𝕋, tf, order::𝕆, name, rem_est, precond::ℙ, plot_states, cutoff, precision, verbose) where {𝕋, 𝕆, ℙ}
        @assert !(order isa AdaptiveTMOrder && ts isa Interval) "Adaptive time step and adaptive order not supported together. Change to a fixed time step or fixed order"

        s = _join_states(plot_states)
        new{𝕋,𝕆,ℙ}(ts, tf, order, name, rem_est, precond, s, cutoff, precision, verbose)
    end
end

function FlowstarSetting(ts, tf, order, plot_states; name = "flowstar", rem_est = 1e-4, precond = QRPreconditioner(),
            cutoff = 1e-20, precision = 53, verbose = true)
    FlowstarSetting(ts, tf, order, name, rem_est, precond, plot_states, cutoff, precision, verbose)
end

## Models

abstract type AbstractFlowstarModel end

struct ContinuousReachModel{𝕊, ℙ, 𝔼<:FlowstarSetting, ℂ<:AbstractODEScheme,ℕ, 𝔽} <: AbstractFlowstarModel
    states::𝕊
    params::ℙ
    setting::𝔼
    scheme::ℂ
    eom::String
    dom::IntervalBox{ℕ,𝔽}

    function ContinuousReachModel(states, p::ℙ, sett::𝔼, scheme::ℂ, eom, dom::IntervalBox{ℕ,𝔽}) where {ℙ, 𝔼, ℂ, ℕ, 𝔽}
        s = _split_states(states)
        new{typeof(s),ℙ, 𝔼, ℂ, ℕ, 𝔽}(s, p, sett, scheme, eom, dom)
    end
end

function string(crm::ContinuousReachModel)
    """continuous reachability
    {
        $(_state_string(crm.states))
        $(_param_string(crm.params))
        $(_setting_string(crm.setting))
        $(_scheme_string(crm.scheme))
        {
            $(_eom_string(crm.eom))
        }

        $(_init_string(crm.states, crm.dom))
    }
    """
end

_timestep_string(ts::Real) = "fixed steps $(ts)"
_timestep_string(ts::Interval{𝕋}) where 𝕋 =  "adaptive steps { min $(inf(ts)) , max $(sup(ts)) }"
_tf_string(tf::Real) = "time $tf"
_rem_string(rem::Real) = "remainder estimation $(rem)"
_plot_string(vars) = "gnuplot interval $vars"
_cutoff_string(c::Real) = "cutoff $c"
_precision_string(p::Int) = "precision $p"
_output_string(s::String) = "output $s"
_print_string(b::Bool) = "print $(b ? "on" : "off")"
_state_string(s) = "state var $(join(s, ", "))"
_eom_string(s) = string(s)
_param_string(::Nothing) = ""

function _setting_string(fs::FlowstarSetting)
    """setting
     {
        $(_timestep_string(fs.time_step))
        $(_tf_string(fs.tf))
        $(_rem_string(fs.rem_est))
        $(_precond_string(fs.precond))
        $(_plot_string(fs.plot_states))
        $(_order_string(fs.order))
        $(_cutoff_string(fs.cutoff))
        $(_precision_string(fs.precision))
        $(_output_string(fs.name))
        $(_print_string(fs.verbose))
     }"""
end

function _init_string(states, ib)
    s = map(states, ib) do s, box
        "$s in $box"
    end

    """init
    {
    $(join(s, "\n"))
    }
    """
end

_split_states(states::String) = strip.(split(states, ","; keepempty = false))
_split_states(s) = s

_join_states(s::String) = s
_join_states(s) = join(s, ",")

# todo: move to flowstar.jl after rebase
function flowstar(m::AbstractFlowstarModel; outdir = mktempdir())
    @show outdir
    fp = joinpath(outdir, "$(m.setting.name).model")
    open(fp,"w") do f
        print(f, string(m))
    end
    flowstar(fp; outdir)
end


export FlowstarSetting
export ContinuousReachModel
export FixedTimeStep, AdaptiveTimeStep
export IdentityPreconditioner, QRPreconditioner
export FixedTMOrder, AdaptiveTMOrder
export PolyODEScheme1, PolyODEScheme2, PolyODEScheme3, LinearODEScheme, NonPolyODEScheme
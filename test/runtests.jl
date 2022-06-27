using Flowstar
using Test, IntervalArithmetic, TaylorModels
import Base.≈

≈(a::Interval, b::Interval) = inf(a) ≈ inf(b) && sup(a) ≈ sup(b)
function ≈(a::IntervalBox, b::IntervalBox) 
    dims = map(a,b) do _a, _b
        _a ≈ _b
    end
    all(dims)
end


model = joinpath(abspath("models"), "Lotka_Volterra.model")
S = flowstar(model; outdir = pwd())

@testset "Flow* Call" begin
    outdir = mktempdir(;cleanup = false)
    outfile = joinpath(outdir,"outputs","Lotka_Volterra.flow")
    S = flowstar(model; outdir)
    @test isfile(outfile)
    @test S == String(read(outfile)) 
end

@testset "TaylorModelN vs TaylorModel1{TaylorN} parsing" begin
    fcs_tmN = FlowstarContinuousSolution(model, Val(false))
    @test length(flowpipe(fcs_tmN)[end]) == 2   # test num vars
    @test all(domain(fcs_tmN) .≈ Ref(IntervalBox(0..0.02, -1..1, -1..1))) # test domain

    eval_pt = mid(first(domain(fcs_tmN)))
    tmN = flowpipe(fcs_tmN)[end][1](eval_pt)
   
    fcs_tm1 = FlowstarContinuousSolution(model, Val(true))
    @test length(flowpipe(fcs_tm1)[end]) == 2 # test num vars
    @test all(domain(fcs_tm1) .≈ 0..0.02) # test domain

    tm1 = flowpipe(fcs_tm1)[end][1](eval_pt[1])(eval_pt[2:end])
    @test tmN == tm1
end

@testset "Model Strings" begin
    @test Flowstar._order_string(FixedTMOrder(5)) == "fixed orders 5"
    @test Flowstar._order_string(AdaptiveTMOrder(3,4)) == "adaptive orders { min 3 , max 4 }"
    @test Flowstar._order_string(AdaptiveTMOrder( ("x"=>2, "y" =>3, "z" => 4), ("x"=>20, "y" =>30, "z" => 40))) == 
            Flowstar._order_string(AdaptiveTMOrder( ["x"=>2, "y" =>3, "z" => 4], ["x"=>20, "y" =>30, "z" => 40])) ==
            Flowstar._order_string(AdaptiveTMOrder( ("x" => (2,20), "y" => (3,30), "z" => (4,40)) )) == 
            Flowstar._order_string(AdaptiveTMOrder( ["x" => (2,20), "y" => (3,30), "z" => (4,40)] )) == 
            Flowstar._order_string(AdaptiveTMOrder( [:x => (2,20), :y => (3,30), :z => (4,40)] ))
            "adaptive orders { min {x :2 , y :3 , z :4} , max {x :20 , y :30 , z :40}}"

    @test Flowstar._precond_string(IdentityPreconditioner()) == "identity precondition"
    @test Flowstar._precond_string(QRPreconditioner()) == "QR precondition"

    @test Flowstar._scheme_string(PolyODEScheme1()) == "poly ode 1"
    @test Flowstar._scheme_string(PolyODEScheme2()) == "poly ode 2"
    @test Flowstar._scheme_string(PolyODEScheme3()) == "poly ode 3"
    @test_throws AssertionError Flowstar._scheme_string(LinearODEScheme(true)) == "ltv ode"
    @test Flowstar._scheme_string(LinearODEScheme(false)) == "lti ode"
    @test Flowstar._scheme_string(NonPolyODEScheme()) == "nonpoly ode"

    @test Flowstar._timestep_string(3.1) == "fixed steps 3.1"
    @test Flowstar._timestep_string(1.0..2.1) == "adaptive steps { min 1.0 , max 2.1 }"

    @test Flowstar._tf_string(2.1) == "time 2.1"
    @test Flowstar._rem_string(0.001) == "remainder estimation 0.001"
    @test Flowstar._plot_string("a,b") == "gnuplot interval a,b"
    @test Flowstar._cutoff_string(0.1) == "cutoff 0.1"
    @test Flowstar._output_string("name", true) == "output name"
    @test Flowstar._output_string("name", false) == "tm output name" 
    @test Flowstar._print_string(true) == "print on"
    @test Flowstar._print_string(false) == "print off"
    @test Flowstar._state_string(("x", "y", "z")) == "state var x, y, z"
    @test Flowstar._eom_string("x'=x\n y'=3") == "x'=x\n y'=3"
    @test Flowstar._param_string(nothing) == ""

    @test Flowstar._init_string(("x", "y"), IntervalBox(0.0..1.0, -0.2..(-0.1))) == "init\n{\nx in [0, 1]\ny in [-0.200001, -0.0999999]\n}\n"
 
end

@testset "Model Writing" begin
    for ts in (0.1, 0.1..0.2)
        for o in (FixedTMOrder(5), AdaptiveTMOrder(2,5), AdaptiveTMOrder(("x"=>(1,2), "y"=>(2,3))))
            for p in ( IdentityPreconditioner(), QRPreconditioner())
                for scheme in (PolyODEScheme1(), PolyODEScheme2(), PolyODEScheme3(), NonPolyODEScheme(), LinearODEScheme(false))
                    if ts isa Interval && o isa AdaptiveTMOrder
                        @test_throws AssertionError FlowstarSetting(ts, 5.0, o, "x,y"; verbose = false, precond = p)
                    else
                        if scheme isa LinearODEScheme{false}
                            eom = "x' = .5*x\n y'=.3*y"
                        else
                            eom = " x' = 1.5*x - x*y\n y' = -3*y + x*y"
                        end
                        sett = FlowstarSetting(ts, 5.0, o, "x,y"; verbose = false, precond = p)
                        crm = ContinuousReachModel("x, y", nothing, sett, scheme, eom, IntervalBox(-1..1, -0.5..0.5))
                        @info sett.time_step, sett.order, sett.precond, crm.scheme
                        flowstar(crm; outdir=pwd())
                        fp = joinpath(pwd(), "outputs","$(crm.setting.name)"*".flow")
                        @test isfile(fp)
                        rm(fp)
                    end
                end
            end
        end
    end
end

@testset "Zero Flowpipes" begin
        sett = FlowstarSetting(0.1, 5.0, FixedTMOrder(5), "x,y"; verbose = false)
        crm = ContinuousReachModel("x, y", nothing, sett, PolyODEScheme3(), " x' = 1.5*x - x*y\n y' = -3*y + x*y", IntervalBox(-1..1, -0.5..0.5))
        @test_throws AssertionError FlowstarContinuousSolution(crm)
end

@testset "Time Independeny Flowpipe Solution" begin
    model = joinpath(abspath("models"), "t_independent_flowpipe.model")
    
    fcs = FlowstarContinuousSolution(model, Val(true); outdir = pwd())
    @test flowpipe(fcs)[1][2] isa TaylorModel1{TaylorSeries.TaylorN{Interval{Float64}}, Float64}

    fcs = FlowstarContinuousSolution(model, Val(false); outdir = pwd())
    @test flowpipe(fcs)[1][2] isa TaylorModelN{3, Interval{Float64}, Float64}
end

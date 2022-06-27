using Flowstar
using Test, IntervalArithmetic
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
using Flowstar
using Test, IntervalArithmetic

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
    eval_pt = mid(domain(fcs_tmN))

    tmN = flowpipe(fcs_tmN)[end][1](eval_pt)
    @test length(flowpipe(fcs_tmN)[end]) == 2

    fcs_tm1 = FlowstarContinuousSolution(model, Val(true))
    tm1 = flowpipe(fcs_tm1)[end][1](eval_pt[1])(eval_pt[2:end])
    @test length(flowpipe(fcs_tm1)[end]) == 2

    @test tmN == tm1
end

@testset "Model Writing" begin
    for ts in (0.1, 0.1..0.2)
        for o in (FixedTMOrder(5), AdaptiveTMOrder(2,5))
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

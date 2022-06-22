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

    fcs_tm1 = FlowstarContinuousSolution(model, Val(true))
    tm1 = flowpipe(fcs_tm1)[end][1](eval_pt[1])(eval_pt[2:end])

    @test tmN == tm1
end

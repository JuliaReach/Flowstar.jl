using Flowstar
using Test


@testset "Flowstar.jl" begin
    model = joinpath(abspath("models"), "Lotka_Volterra.model")
    # output = String(read(joinpath(abspath("models"),"lv.flow")))
    S = flowstar(model; outdir = pwd())
    @test S ==  String(read(joinpath(pwd(),"outputs","Lotka_Volterra.flow")))
end

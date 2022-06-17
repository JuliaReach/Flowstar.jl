using Flowstar
using Test


@testset "Flowstar.jl" begin
    model = joinpath(abspath("models"), "Lotka_Volterra.model")
    S = flowstar(model; outdir = pwd())
    @test S ==  String(read(joinpath(pwd(),"outputs","Lotka_Volterra.flow")))
end

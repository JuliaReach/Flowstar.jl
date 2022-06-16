using Flowstar
using Test

models = filter(x->endswith(x, ".model"), readdir(abspath("models"); join = true))

@testset "Flowstar.jl" begin
    model = joinpath(abspath("models"), "lv.model")
    output = String(read(joinpath(abspath("models"),"lv.flow")))
    @test output == flowstar(model)
end

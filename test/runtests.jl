using Flowstar
using Test

models = filter(x->endswith(x, ".model"), readdir(abspath("models"); join = true))

@testset "Flowstar.jl" begin
    for m in models
        joinpath(pwd(), m)
       flowstar(joinpath(pwd(), m))
    end
end

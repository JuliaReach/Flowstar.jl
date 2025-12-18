# Flowstar.jl

**Status** | **Community** | **License** |
|:----------:|:-------------:|:-----------:|
| [![CI][ci-img]][ci-url] [![codecov][cov-img]][cov-url] [![PkgEval][pkgeval-img]][pkgeval-url] [![aqua][aqua-img]][aqua-url] [![dev-commits][dev-commits-url]][dev-commits-target] | [![zulip][chat-img]][chat-url] [![JuliaHub][juliahub-img]][juliahub-url] | [![license][lic-img]][lic-url] |

[ci-img]: https://github.com/JuliaReach/Flowstar.jl/actions/workflows/CI.yml/badge.svg
[ci-url]: https://github.com/JuliaReach/Flowstar.jl/actions/workflows/CI.yml
[cov-img]: https://codecov.io/github/JuliaReach/Flowstar.jl/coverage.svg
[cov-url]: https://app.codecov.io/github/JuliaReach/Flowstar.jl
[pkgeval-img]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/F/Flowstar.svg
[pkgeval-url]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/F/Flowstar.html
[aqua-img]: https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg
[aqua-url]: https://github.com/JuliaTesting/Aqua.jl
[dev-commits-url]: https://img.shields.io/github/commits-since/JuliaReach/Flowstar.jl/latest.svg
[dev-commits-target]: https://github.com/JuliaReach/Flowstar.jl
[chat-img]: https://img.shields.io/badge/zulip-join_chat-brightgreen.svg
[chat-url]: https://julialang.zulipchat.com/#narrow/stream/278609-juliareach
[juliahub-img]: https://juliahub.com/docs/General/Flowstar/stable/version.svg
[juliahub-url]: https://juliahub.com/ui/Packages/General/Flowstar
[lic-img]: https://img.shields.io/github/license/mashape/apistatus.svg
[lic-url]: https://github.com/JuliaReach/Flowstar.jl/blob/master/LICENSE

This package is a wrapper to [Flow*](https://flowstar.org), a verification tool for cyber-physical systems. Currently only continuous reachability is supported.

## Direct Usage

Pass an absolute path to the *.model file to `flowstar`. This returns a string of the contents of the resulting `*.flow` file.

```julia
using Flowstar

model = download("https://home.cs.colorado.edu/~xich8622/benchmarks/laub_loomis_small.model")
flow_str = flowstar(model)
```

## Parsed Usage
Flowstar.jl can also be used to parse the string produced by Flow* via

```julia
model = download("https://home.cs.colorado.edu/~xich8622/benchmarks/laub_loomis_small.model")
fcs = FlowstarContinuousSolution(model)
```

See examples/parsing.jl for additional usage.

## Modeling
Instead of specifying a model file directly, you can create one programatically as shown in [examples/modeling.jl](examples/modeling.jl).

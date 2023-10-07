# Flowstar.jl

[![Build Status](https://github.com/agerlach/Flowstar.jl/workflows/CI/badge.svg)](https://github.com/agerlach/Flowstar.jl/actions?query=workflow%3ACI)

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
Instead of specifying a model file directly, you can create one programatically as shown in examples/modeling.jl

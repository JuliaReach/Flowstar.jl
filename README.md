# Flowstar.jl

[![Build Status](https://github.com/agerlach/Flowstar.jl/workflows/CI/badge.svg)](https://github.com/agerlach/Flowstar.jl/actions?query=workflow%3ACI)

This package is a wrapper to [Flow*](flowstar.org), a verification tool for cyber-physical systems.

It is a WIP. 

## Usage

Pass an absolute path to the *.model file to `flowstar`. This returns a string of the contents of the resulting `*.flow` file.

```julia
using Flowstar

model = download("https://home.cs.colorado.edu/~xich8622/benchmarks/laub_loomis_small.model")
flow_str = flowstar(model)
```
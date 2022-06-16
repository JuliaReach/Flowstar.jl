module Flowstar

using Flowstar_jll
import Flowstar_jll: flowstar

function flowstar(model; outdir = mktempdir())
    cmd = Cmd(`$(flowstar())`; dir = outdir)
    run(pipeline(model, cmd))

    flow = first(filter(x->endswith(x,".flow"), readdir(joinpath(outdir, "outputs"), join = true)))
    String(read(flow))
end

export flowstar
end


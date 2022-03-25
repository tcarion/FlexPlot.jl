module FlexPlot

using Rasters
using Makie
using Flexpart
using JSServe
using Dates

export
    MixingRatio,
    GeoTiff,
    sliderplot

include("mixingratio.jl")
include("recipes.jl")
include("geotiff.jl")
include("serve.jl")

end

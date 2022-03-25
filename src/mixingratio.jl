function Rasters.RasterStack(output::DeterministicOutput)
    Rasters.RasterStack(output.name)
end

abstract type AbstractMixingRatio end
struct MixingRatio{T, N} <: AbstractMixingRatio
    raster::AbstractRaster{T, N}
    relpoints::AbstractArray
end
# MixingRatio(path::String) = MixingRatio(Raster(path, name= :spec001_mr))
function MixingRatio(output::AbstractOutputFile)
    rasterstack = RasterStack(output)
    rellat, rellon = rasterstack[:RELLAT1], rasterstack[:RELLNG1]
    [[lon, lat] for (lon, lat) in zip(rellon, rellat)]
    MixingRatio(rasterstack[:spec001_mr], [[lon, lat] for (lon, lat) in zip(rellat, rellon)])
end
Base.show(io::IO, mime::MIME"text/plain", mr::AbstractMixingRatio) = show(io, mime, mr.raster)

struct CubicMixingRatio
    raster::AbstractRaster
    relpoints::AbstractArray
end

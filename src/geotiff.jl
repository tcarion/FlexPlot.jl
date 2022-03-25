struct GeoTiff
    raster::AbstractRaster
end
GeoTiff(path::AbstractString) = GeoTiff(_to_rgb(path))
Base.parent(geotiff::GeoTiff) = geotiff.raster

function _to_rgb(fn)
    rast = Raster(fn)
    rast = reverse(rast, dims = 2)
    red = view(rast, Rasters.Band(1)) |> read
    green = view(rast, Rasters.Band(2)) |> read
    blue = view(rast, Rasters.Band(3)) |> read

    replace!.(x -> isnan(x) ? 0.0 : x, [red, green, blue])

    rgb = fill(RGBf(0,0,0), dims(rast, :X), dims(rast, :Y));

    for i in eachindex(red)
        rgb[i] = RGBf(red[i], green[i], blue[i])
    end
    eltype(rast) == UInt8 ? rgb./255 : rgb
end
@recipe(FlexpartPlot) do scene
    Attributes(
        time = Ti(1),
        height = Dim{:height}(1),
        nageclass = Dim{:nageclass}(1),
        pointspec = Dim{:pointspec}(1),
        lons = X(:),
        lats = Y(:),
        scale = :lin,
        title = ""
    )
end

@recipe(SliderPlot) do scene
    Attributes(
        lons = X(:),
        lats = Y(:),
        scale = :lin,
        title = ""
    )
end

Makie.convert_arguments(P::Union{Type{<:Heatmap}, Type{<:Contourf}, Type{<:Contour}}, r::AbstractRaster) = convert_arguments(P, dims(r, :X) |> collect, dims(r, :Y) |> collect, Matrix(r))
# Makie.convert_single_argument(r::AbstractRaster) = dims(r, :X) |> collect, dims(r, :Y) |> collect, Matrix(r)
# Makie.convert_arguments(P::Type{<:Contourf}, r::AbstractRaster) = convert_arguments(P, dims(r, :X) |> collect, dims(r, :Y) |> collect, Matrix(r))

# _convert(r::AbstractRaster) = Vector(dims(r, :X) |> collect), Vector(dims(r, :Y) |> collect), Matrix(r)

# function Makie.plot!(ensplot::EnsemblePlot{<:Tuple{AbstractVector{<:EnsembleOutput}}})
function Makie.plot!(fpplot::FlexpartPlot{<:Tuple{<:MixingRatio}})
    # ax = Axis(ensplot)
    # global access = ensplot
    mr = fpplot[1].val
    raster = mr.raster
    # filename = convert(String, fpoutput)
    # raster = Raster(filename, name= :spec001_mr)
    scale =  fpplot.scale.val
    filtrast = view(raster, 
        fpplot.time.val, 
        fpplot.height.val, 
        fpplot.nageclass.val, 
        fpplot.pointspec.val,
        fpplot.lons.val,
        fpplot.lats.val,
        )
    lons = dims(filtrast, :X) |> collect
    lats = dims(filtrast, :Y) |> collect
    cmap = cgrad(:viridis, scale = scale)

    matrix = replace!(x -> isapprox(x, 0) ? NaN : x, Matrix(filtrast))
    scale == :log10 && replace!(x -> log10(x), matrix)
    heatmap!(fpplot, lons, lats, 
        matrix, 
        colormap = cmap,
        axis = (aspect = DataAspect(), title = fpplot.title, titlegap = 0),
        # cscale = log10
        )
    # Colorbar(ax[1, 2], heat)
end

# function Makie.plot!(sp::SliderPlot{<:Tuple{<:AbstractRaster}})
#     # ax = Axis(ensplot)
#     # global access = ensplot
#     rasterobs = sp[1]
#     raster = rasterobs[]
#     times = dims(raster, Ti) |> collect

#     mr = fpplot[1].val
#     raster = mr.raster
#     # filename = convert(String, fpoutput)
#     # raster = Raster(filename, name= :spec001_mr)
#     scale =  fpplot.scale.val
#     filtrast = view(raster, 
#         fpplot.time.val, 
#         fpplot.height.val, 
#         fpplot.nageclass.val, 
#         fpplot.pointspec.val,
#         fpplot.lons.val,
#         fpplot.lats.val,
#         )
#     lons = dims(filtrast, :X) |> collect
#     lats = dims(filtrast, :Y) |> collect
#     cmap = cgrad(:viridis, scale = scale)

#     matrix = replace!(x -> isapprox(x, 0) ? NaN : x, Matrix(filtrast))
#     scale == :log10 && replace!(x -> log10(x), matrix)
#     heatmap!(fpplot, lons, lats, 
#         matrix, 
#         colormap = cmap,
#         axis = (aspect = DataAspect(), title = fpplot.title, titlegap = 0),
#         # cscale = log10
#         )
#     # Colorbar(ax[1, 2], heat)
# end 

function sliderplot(raster::AbstractRaster)
    fig = Figure()
    # ax = Axis(fig[1, 1])
    times = dims(raster, Ti) |> collect
    heights = dims(raster, Dim{:height}) |> collect
    lsgrid = labelslidergrid!(
        fig,
        ["Time", "Height"],
        [1:length(times), 1:length(heights)];
        # formats = "{:.1f}" .* ["V", "A", "Ω"],
        formats = [i -> Dates.format(times[i], "yyyy-mm-ddTHH:MM:SS"), i -> "$(heights[i])m"],
        # formats = [x->"$x"],
        width = 600,
        height = 100)
    
    fig[1, 1] = lsgrid.layout

    sliderobs = [s.value for s in lsgrid.sliders]
    viewed = map(sliderobs...) do t, h
        view(raster, 
            Ti(t),
            Dim{:height}(h),
            )
    end

    ax, hm = heatmap(fig[2, 1], viewed, colormap = (:Spectral, 0.3))
    Colorbar(fig[2, 2], hm)
    fig
end

function sliderplot(raster::AbstractRaster, tiff::GeoTiff)
    fig = Figure()
    # ax = Axis(fig[1, 1])
    times = dims(raster, Ti) |> collect
    heights = dims(raster, Dim{:height}) |> collect
    lsgrid = labelslidergrid!(
        fig,
        ["Time", "Height"],
        [1:length(times), 1:length(heights)];
        # formats = "{:.1f}" .* ["V", "A", "Ω"],
        formats = [i -> Dates.format(times[i], "yyyy-mm-ddTHH:MM:SS"), i -> "$(heights[i])m"],
        # formats = [x->"$x"],
        width = 600,
        height = 100)
    
    fig[1, 1] = lsgrid.layout

    sliderobs = [s.value for s in lsgrid.sliders]
    viewed = map(sliderobs...) do t, h
        view(raster, 
            Ti(t),
            Dim{:height}(h),
            )
    end

    ax = Axis(fig[2, 1])
    hmtiff = heatmap!(ax, tiff.raster)
    hm = heatmap!(ax, viewed, colormap = (:viridis, 0.8))
    Colorbar(fig[2, 2], hm)
    # translate!(hm, 0, 0, -1)
    fig
end

struct LogMinorTicks end
	
function MakieLayout.get_minor_tickvalues(
        ::LogMinorTicks, scale, tickvalues, vmin, vmax
)
    vals = Float64[]
    extended_tickvalues = [
        tickvalues[1] - (tickvalues[2] - tickvalues[1]);
        tickvalues;
        tickvalues[end] + (tickvalues[end] - tickvalues[end-1]);
    ]
    # @show extended_tickvalues
    # @show tickvalues
    for (lo, hi) in zip(
            @view(extended_tickvalues[1:end-1]),
            @view(extended_tickvalues[2:end])
        )
        interval = hi-lo
        steps = log10.(LinRange(10^lo, 10^hi, 11))
        append!(vals, steps[2:end-1])
    end
    return filter(x -> vmin < x < vmax, vals)
end

custom_formatter(values) = map(
    v -> "10" * Makie.UnicodeFun.to_superscript(round(Int64, v)),
    values
)
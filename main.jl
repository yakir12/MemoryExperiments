# setup
import Pkg
Pkg.Registry.update() 
Pkg.activate(@__DIR__)
Pkg.instantiate()

# packages we're using
using Arrow, DataFrames, GLMakie, CairoMakie, Statistics, LinearAlgebra, Measurements, OnlineStats, CSV, Dates, Chain, Rotations, CoordinateTransformations
import Colors: Gray, RGB, N0f8
import GLMakie.AbstractPlotting.data_text_boundingbox
CairoMakie.activate!()
# CairoMakie.AbstractPlotting.inline!(true)

include("stats.jl")
include("plots.jl")

# the folder where all the results are saved
const path = "MemoryExperiments results"
# create the plots, one plot per group
mkpath(path)


# the link to the data
link = "https://s3.eu-central-1.amazonaws.com/vision-group-file-sharing/Data%20backup%20and%20storage/Ayse/db.arrow"

df = @chain link begin
  download # download the data
  Arrow.Table # transform to an arrow table
  DataFrame # transform to a dataframe
  filter(:tp => >(1), _) # we can't use any tracks with too-few coordinates
  sort("holding time") # sort by holding time
  transform( # transform to coordinate types
            :coords => ByRow(xy -> Point2f0.(xy)) => :coords,
            [:dropoff, :fictive_nest] .=> ByRow(Point2f0) .=> [:dropoff, :fictive_nest]
           )
  # center everything on the dropoff point
  transform([:coords, :dropoff] => ByRow(.-) => :coords,
            [:fictive_nest, :dropoff] => ByRow(-) => :fictive_nest,
            :dropoff => ByRow(zero) => :dropoff,
           )
  # apply a couple of convenient transformations
  transform([:coords, :tp] => ByRow((xy, i) -> xy[1:i]) => :homing, # keep only the homing part of the track
            [:coords, :tp] => ByRow((xy, i) -> xy[i]) => :turning_point, # add the turning point
            :date => ByRow(x -> Date(string(x), dateformat"yyyymmdd")) => :date, # change the date to a real date type
            ["feeder to nest", "holding condition"] => ByRow(categorize4figure) => :figure # add a categorization for the figure
           )
  # some stats
  transform([:homing, :t] => ByRow(speedstats) => "speed μ±σ", 
            [:dropoff, :turning_point] => ByRow(norm ∘ -) => "vector length",
            :homing => ByRow(xy -> sum(norm, diff(xy))) => "path length",
            [:nest2feeder, :turning_point] => ByRow((n2f, tp) -> -n2f - last(tp)) => "nest corrected vector",
            [:dropoff, :turning_point] => ByRow((a,b) -> rad2deg(abs(angular_diff_from_pos_y_axis(b - a)))) => "angular difference",
           )
  @aside @chain _ begin
    select(:runid,
           "beetle ID",
           :date,
           "feeder to nest", 
           "holding condition",
           "holding time",
           "speed μ±σ", 
           "vector length",
           "path length",
           "nest corrected vector",
           "angular difference",
          )
    CSV.write(joinpath(path, "stats.csv"), _)
  end
  groupby(["holding condition", "feeder to nest", "holding time"])
  transform(["holding condition", "feeder to nest"] => tocolors => :color)
end


# @chain df begin
#   groupby(:figure)
#   ym, yM = find_extrema(:homing, last, M = maximum(last, gd.fictive_nest))
# end

height = 600
for (k,gd) in pairs(groupby(df, :figure))
  ym, yM = find_extrema(last, gd.homing, M = maximum(last, gd.fictive_nest))
  scene, layout = layoutscene(resolution = (2000, height + 50), figure_padding = 0)
  for (i, (k, g)) in enumerate(pairs(groupby(gd, ["holding condition", "feeder to nest", "holding time"])))
    title = join(k, " ")
    xm, xM = find_extrema(first, g.homing)
    i == 1 && (xm -= 10)
    ax = layout[1, i] = Axis(scene, aspect = DataAspect(), limits = (xm, xM, ym, yM), xticks = [0], xgridcolor = :grey70, ygridcolor = :grey70, yticks = [0], title = title)
    colsize!(layout, i, Auto((xM - xm)/(yM - ym)))
    nest2feeder = getproperty(k, Symbol("feeder to nest"))
    plotgrid!(ax, nest2feeder, i == 1 ? xm + (nest2feeder == 130 ? 9 : 14) : nothing)
    gcolor = g.color[1]
    lines!(ax, Circle(zero(Point2f0), nest2feeder), color = gcolor)
    for (xy, tp, color) in zip(g.homing, g.turning_point, g.color)
      lines!(ax, Point2f0.(xy); linestyle = nothing, linewidth = 1, color = color)
      poly!(ax, dropmarker(xy[end-1], xy[end], (yM - ym)/100); strokecolor = :transparent, markersize = 10px, color = color)
    end
    scatter!(ax, Point2f0(first(g.fictive_nest)), color = gcolor, strokecolor = GLMakie.AbstractPlotting.PlotUtils.darken(gcolor, 0.25), marker = :star5, markersize = 20px)
    scatter!(ax, Point2f0(first(g.dropoff)), color = gcolor, marker = :rect, strokecolor = GLMakie.AbstractPlotting.PlotUtils.darken(gcolor, 0.25), markersize = 20px)
  end
  hidedecorations!.(contents(layout[1,:]), grid = false, minorgrid = false, minorticks = false)
  save(joinpath(path, string(k..., ".pdf")), scene)
end

#
# #### Length distributions figure ####
# gd = groupby(stats, ["holding condition", "feeder to nest", "holding time"])
# n = length(gd)
# n += 10
# f = Figure(resolution = (700, 1500), figure_padding = 0)
# for (j,l) in enumerate(("vector length", "path length", "nest corrected vector"))
#   ax = Axis(f[j, 1], aspect = AxisAspect(1))
#   ys = []
#   ysl = []
#   for (i, (k, g)) in enumerate(pairs(gd))
#     vector = abs.(g[:, l])
#     y = (i - 1)/(n - 1)
#     density!(ax, vector, offset = y, color = (:slategray, 0.4), bandwidth = 5, boundary = (0, 300))
#     push!(ys, y)
#     push!(ysl, join(k, " "))
#   end
#   ax.xticks = [0, 130, 260]
#   ax.xlabel = l
#   ax.yticks = (ys, ysl)
#   xlims!(ax, 0, 300)
#   hideydecorations!(ax, label = false, ticklabels = false, ticks = false, grid = true, minorgrid = true, minorticks = true)
# end
# save(joinpath(path, "lengths.png"), f)
#
#
#
# #### ayse figure ####
# using StatsBase
# absmean(x) = mean(abs, x)
# gd = groupby(stats, ["holding condition", "feeder to nest", "holding time"])
# a = combine(gd, "vector length" => length => "n",
#             ["vector length", "path length", "nest corrected vector"] .=> median,
#             ["vector length", "path length", "nest corrected vector"] .=> absmean,
#             ["vector length", "path length", "nest corrected vector"] .=> std,
#            )
# μ = stack(a, r"mean", ["holding condition", "holding time", "feeder to nest"])
# dict = levelsmap(μ.variable)
# transform!(μ, :variable => ByRow(v -> dict[v]) => :grpi)
# dict = levelsmap(μ[!, "holding time"])
# transform!(μ, "holding time" => ByRow(v -> dict[v]) => :x)
# gd = groupby(μ, ["holding condition", "feeder to nest"])
# g = gd[1]
# h = barplot(g.x, g.value, dodge = g.grpi, color = g.grpi)
# ylims!(h.axis, (0, 255))
# h.axis.xticks = (collect(values(dict)), string.(keys(dict)))
# h
# save(joinpath(path, "ayse figure.png"), h)
#
#
# #### summary table for the lengths ####
# gd = groupby(stats, ["holding condition", "feeder to nest", "holding time"])
# a = combine(gd, "vector length difference" => length => "n",
#             ["vector length difference", "angular difference"] .=> median,
#             ["vector length difference", "angular difference"] .=> x -> mean(x) ± std(x),
#            )
# CSV.write(joinpath(path, "length summary.csv"), a)
#
#
# data = filter("holding condition" => !=("postice"), stats)
# gd = groupby(data, ["holding condition", "feeder to nest"])
# fig = Figure()
# axs = fig[1:2,1:3] = [Axis(fig) for i in 1:2, j in 1:3]
# for (i, (k, g)) in enumerate(pairs(gd))
#   for (j, (f, u)) in enumerate(zip(("vector length", "angular difference"), (" (cm)", " (°)")))
#     boxplot!(axs[j,i], g[!, "holding time"], g[!, f], width = 3)
#     axs[j,i].xticks = unique(g[!, "holding time"])
#     axs[j,i].ylabel = uppercasefirst(f*u)
#     if j == 1
#       axs[j,i].title = join(k, " ")
#       abline!(axs[j,i], getproperty(k, "feeder to nest"), 0, color = :gray, linestyle = :dash)
#       axs[j,i].yticks = 0:65:260
#       ylims!(axs[j,i], (0, 270))
#     end
#   end
# end
# linkxaxes!(axs...)
# for i in 1:2
#   linkyaxes!(axs[i, :]...)
# end
# hidexdecorations!.(axs[1,:], grid = false, minorgrid = false, minorticks = false)
# hideydecorations!.(axs[:,2:end], grid = false, minorgrid = false, minorticks = false)
# Label(fig[3,:], "Holding time (min)")
# fig
# save(joinpath(path, "length time.png"), fig)
#

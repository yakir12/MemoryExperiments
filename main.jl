# setup
import Pkg
Pkg.Registry.update() 
Pkg.activate(@__DIR__)
Pkg.instantiate()

# packages we're using
using Arrow, DataFrames, CairoMakie, Statistics, LinearAlgebra, OnlineStats, CSV, Dates, Chain, Rotations, CoordinateTransformations, StatsBase
import Colors: Gray, RGB, N0f8

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
           # "angular difference",
          )
    CSV.write(joinpath(path, "stats.csv"), _)
  end
  groupby(["holding condition", "feeder to nest", "holding time"])
  transform(["holding condition", "feeder to nest"] => tocolors => :color)
end

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
    scatter!(ax, Point2f0(first(g.fictive_nest)), color = gcolor, strokecolor = CairoMakie.Makie.PlotUtils.darken(gcolor, 0.25), marker = :star5, markersize = 20px)
    scatter!(ax, Point2f0(first(g.dropoff)), color = gcolor, marker = :rect, strokecolor = CairoMakie.Makie.PlotUtils.darken(gcolor, 0.25), markersize = 20px)
  end
  hidedecorations!.(contents(layout[1,:]), grid = false, minorgrid = false, minorticks = false)
  save(joinpath(path, string(k..., ".pdf")), scene)
end

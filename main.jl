# results for Short range navigation in ants
# setup
# import Pkg
# Pkg.Registry.update() 
# Pkg.activate(@__DIR__)
# Pkg.instantiate()

# packages we're using
using Arrow, DataFrames, GLMakie, Statistics, LinearAlgebra, OnlineStats, CSV, Dates, Chain, Rotations, CoordinateTransformations, StatsBase, Colors, StaticArrays, Missings, StructArrays, IntervalSets, Interpolations, CategoricalArrays
import IterTools:partition

include("plots.jl")
include("utils.jl")
#
link = "/home/yakir/downloads/db.arrow"
df = @chain link begin
  # download # download the data
  Arrow.Table # transform to an arrow table
  DataFrame # transform to a dataframe
  transform(
            [:dropoff, :fictive_nest, :nest] .=> ByRow(passmissing(Point2f0)) .=> [:dropoff, :fictive_nest, :nest],
            [:t, :tp] => ByRow((t, tp) -> ceil(Int, t[tp])) => :tp,
            :rawcoords => ByRow(filter_jump) => :coords,
            [:Experiment, :treatment] => ByRow(to_figure) => :figure, # what figure
            :treatment => ByRow(x -> get(treatments, x, x)) => :treatment
           )
  transform(
            [:coords, :tp] => ByRow((xy, i) -> xy[1:i]) => :homing, # the homing part of the track
            [:coords, :tp] => ByRow((xy, i) -> xy[i:end]) => :searching, # the homing part of the track
            [:coords, :tp] => ByRow((xy, i) -> xy[i]) => :turning_point # add the turning point
           )
end
delete!(df, 16) # turning point is missing
#

# the folder where all the results are saved
path = "Short range navigation in ants"
# create the plots, one plot per group
mkpath(path)
colors = distinguishable_colors(length(unique(df.figure)), [colorant"white", colorant"black"], dropseed = true)
for ((k, gd), color) in zip(pairs(groupby(df, :figure, sort = true)), colors)
  fig = plottracks(gd; color)
  save(joinpath(path, string("track ", k..., ".png")), fig)
end


ds = select(df, [:homing, :turning_point, :searching] => ByRow(get_speed) => ["$i" for i in [-reverse(speed_mid); speed_mid]], :figure, :treatment)
dd = stack(ds, Not(Cols(:figure, :treatment)))
rm2small!(dd)
dropmissing!(dd)
transform!(dd, :variable => x -> parse.(Int, x); renamecols = false)

<<<<<<< HEAD
M = maximum(abs, dd.variable) + speed_interval
for ((k, gd), color) in zip(pairs(groupby(dd, :figure, sort = true)), colors)
  fig = plotspeeds(gd, M; color)
  save(joinpath(path, string("speed ", k..., ".png")), fig)
=======
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
>>>>>>> 89b091e29a08681b4512a6d0b7bef2a77ca00097
end


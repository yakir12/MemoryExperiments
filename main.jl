# results for Short range navigation in ants
# setup
# import Pkg
# Pkg.Registry.update() 
# Pkg.activate(@__DIR__)
# Pkg.instantiate()

# packages we're using
using Arrow, DataFrames, CairoMakie, Statistics, LinearAlgebra, OnlineStats, CSV, Dates, Chain, Rotations, CoordinateTransformations, StatsBase, Colors, StaticArrays, Missings, StructArrays, IntervalSets, Interpolations, CategoricalArrays
import IterTools:partition

include("plots.jl")
include("utils.jl")

link = "/home/yakir/downloads/db.arrow"
df = @chain link begin
  # download # download the data
  Arrow.Table # transform to an arrow table
  DataFrame # transform to a dataframe
  transform(
            [:dropoff, :fictive_nest, :nest] .=> ByRow(passmissing(Point2f0)) .=> [:dropoff, :fictive_nest, :nest],
            # [:t, :tp] => ByRow((t, tp) -> ceil(Int, t[tp])) => :tp,
            # :rawcoords => ByRow(filter_jump) => :coords,
            :coords => ByRow(x -> Point2f0.(x)) => :coords,
            [:Experiment, :treatment] => ByRow(to_figure) => :figure, # what figure
            :treatment => ByRow(treatments) => :treatment
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
  save(joinpath(path, string("track ", k..., ".pdf")), fig)
end


ds = select(df, [:homing, :turning_point, :searching] => ByRow(get_speed) => ["$i" for i in [-reverse(speed_mid); speed_mid]], :figure, :treatment)
dd = stack(ds, Not(Cols(:figure, :treatment)), variable_name=:distance, value_name=:speed)
rm2small!(dd)
dropmissing!(dd)
transform!(dd, :distance => x -> parse.(Int, x); renamecols = false)

Mx = maximum(abs, dd.distance) + speed_interval
My = maximum(dd.speed)
for ((k, gd), color) in zip(pairs(groupby(dd, :figure, sort = true)), colors)
  fig = plotspeeds(gd, Mx, My; color)
  save(joinpath(path, string("speed ", k..., ".pdf")), fig)
end


import Pkg
Pkg.activate(".")
Pkg.instantiate()

using Arrow, DataFrames, GLMakie, Statistics, LinearAlgebra, Measurements, OnlineStats, CSV
import IterTools
import GLMakie: Gray, RGB, N0f8

const intervals = sort([5, 10, 30, 60, 90, 120])

include("stats.jl")
const path = "figures"
include("plots.jl")

link = "https://s3.eu-central-1.amazonaws.com/vision-group-file-sharing/Data%20backup%20and%20storage/Ayse/db.arrow"
df = link |> download |> Arrow.Table |> DataFrame |> copy


transform!(df, [:coords, :tp] => ByRow((xy, i) -> xy[1:i]) => :homing)
transform!(df, :coords => ByRow(last) => :turning_point)

filter!(:homing => xy -> length(xy) > 3, df)

function tocolors(holding_condition, nest2feeder)::RGB{N0f8} 
  if holding_condition == "nonice"
    if nest2feeder == 130 
      RGB(255/255, 51/255, 13/255) 
    else
      RGB(64/255,255/255,64/255)
    end
  elseif holding_condition == "ice"
    RGB(77/255, 217/255, 255/255)
  else
    Gray(0.8)
  end
end

mkpath(path)
for (k, g) in pairs(groupby(df, ["holding condition", "feeder to nest", "holding time"]))
  plotsave(g.homing, k, true)
end



include("stats.jl")
txt_intervals = [string("direction ", i1, "-", i2) for (i1,i2) in zip([0; intervals], [intervals; "∞"])]

stats = select(df, 
               :runid,
               [:homing, :t] => ByRow(speedstats) => "speed μ±σ", 
               [:homing, :dropoff] => ByRow(directionstats) => txt_intervals, 
               [:dropoff, :turning_point] => ByRow(norm ∘ -) => "vector length",
               :homing => ByRow(xy -> sum(norm, diff(xy))) => "path length",
               [:nest2feeder, :turning_point] => ByRow((n2f, tp) -> -n2f - last(tp)) => "nest corrected vector",
              )

CSV.write("stats.csv", stats)

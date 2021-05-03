# setup
import Pkg
Pkg.Registry.update() 
Pkg.activate(@__DIR__)
Pkg.instantiate()

# packages we're using
using Arrow, DataFrames, GLMakie, Statistics, LinearAlgebra, Measurements, OnlineStats, CSV, Dates
import IterTools
import GLMakie: Gray, RGB, N0f8

# the intervals for the Statistics
const intervals = sort([5, 10, 30, 60, 90, 120, 150])

include("stats.jl")

# the folder where all the results are saved
const path = "MemoryExperiments results"

include("plots.jl")

# get the tracks from the cloud
link = "https://s3.eu-central-1.amazonaws.com/vision-group-file-sharing/Data%20backup%20and%20storage/Ayse/db.arrow"
df = link |> download |> Arrow.Table |> DataFrame |> copy

# apply a couple of convenient transformations
transform!(df, [:coords, :tp] => ByRow((xy, i) -> xy[1:i]) => :homing, # keep only the homing part of the track
           :coords => ByRow(last) => :turning_point, # add the turning point
           :date => ByRow(x -> Date(string(x), dateformat"yyyymmdd")) => :date # change the date to a real date type
          )

# we can't use any tracks with too-few coordinates
filter!(:homing => xy -> length(xy) > 3, df)

# coloring scheme
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

# create the plots, one plot per group
mkpath(path)
for (k, g) in pairs(groupby(df, ["holding condition", "feeder to nest", "holding time"]))
  plotsave(g.homing, k, true)
end


include("stats.jl")

# the interval labels
txt_intervals = [string("direction ", i1, "-", i2) for (i1,i2) in zip([0; intervals], [intervals; "∞"])]

# all the stats we're interested in

stats = select(df, 
               :runid,
               "beetle ID",
               :date,
               "feeder to nest", 
               "holding condition",
               "holding time",
               [:homing, :t] => ByRow(speedstats) => "speed μ±σ", 
               [:homing, :dropoff] => ByRow(directionstats) => txt_intervals, 
               [:dropoff, :turning_point] => ByRow(norm ∘ -) => "vector length",
               :homing => ByRow(xy -> sum(norm, diff(xy))) => "path length",
               [:nest2feeder, :turning_point] => ByRow((n2f, tp) -> -n2f - last(tp)) => "nest corrected vector",
              )

# save the table
CSV.write(joinpath(path, "stats.csv"), stats)

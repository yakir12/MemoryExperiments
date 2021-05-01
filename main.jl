import Pkg
Pkg.activate(".")
Pkg.instantiate()

using Arrow, DataFrames, GLMakie
import IterTools
import GLMakie: Gray, RGB, N0f8

include("plots.jl")

link = "https://s3.eu-central-1.amazonaws.com/vision-group-file-sharing/Data%20backup%20and%20storage/Ayse/db.arrow"
df = link |> download |> Arrow.Table |> DataFrame

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

transform!(df, ["holding condition", "feeder to nest"] => ByRow(tocolors) => :color)

gd = groupby(df, ["holding condition", "feeder to nest", "holding time"])
ks = keys(gd)
for (k, g) in zip(ks, gd)
  plotsave(g.coords, g.tp, g.nest2feeder[1], g.color[1], string(NamedTuple(k))[2:end-1], false)
end

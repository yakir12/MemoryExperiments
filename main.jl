import Pkg
Pkg.activate(".")
Pkg.instantiate()

using Arrow, DataFrames, GLMakie
import IterTools
import GLMakie: Gray, RGB, N0f8

include("plots.jl")

link = "https://vision-group-temporary.s3.eu-central-1.amazonaws.com/db.arrow"
df = link |> download |> Arrow.Table |> DataFrame

transform!(df, [:coords, :tp] => ByRow((x, i) -> Point2f0.(x[1:i])) => :homing)

colors = Dict{Tuple{String, Int64}, RGB{N0f8}}(
                                               ("nonice", 130) => RGB(255/255, 51/255, 13/255), 
                                               ("nonice", 260) => RGB(64/255,255/255,64/255), 
                                               ("ice", 130) => RGB(77/255, 217/255, 255/255), 
                                               ("postice", 130) => Gray(0.9))

gd1 = groupby(df, ["holding condition", "feeder to nest"])
ks1 = keys(gd1)
for (k1, g1) in zip(ks1, gd1)
  gd2 = groupby(g1, "holding time")
  ks2 = keys(gd2)
  for (k2, g2) in zip(ks2, gd2)
    title = string(merge(NamedTuple(k1), NamedTuple(k2)))[2:end-1]
    fig = plotruns(g2.homing, g2.nest2feeder[1], colors[Tuple(k1)], title, show_circles = true)
    save("$title.png", fig)
  end
end

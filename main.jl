# setup
import Pkg
Pkg.Registry.update() 
Pkg.activate(@__DIR__)
Pkg.instantiate()

# packages we're using
using Arrow, DataFrames, GLMakie, CairoMakie, Statistics, LinearAlgebra, Measurements, OnlineStats, CSV, Dates
import IterTools
import Colors: Gray, RGB, N0f8
import GLMakie.AbstractPlotting.data_text_boundingbox
CairoMakie.activate!()
# CairoMakie.AbstractPlotting.inline!(true)

# get the tracks from the cloud
link = "https://s3.eu-central-1.amazonaws.com/vision-group-file-sharing/Data%20backup%20and%20storage/Ayse/db.arrow"
df = link |> download |> Arrow.Table |> DataFrame |> copy

# we can't use any tracks with too-few coordinates
filter!(:tp => >(1), df)

# center everything on the dropoff point
transform!(df, [:coords, :dropoff] => ByRow((xys, xy) -> xys .- Ref(xy)) => :coords,
           [:fictive_nest, :dropoff] => ByRow(-) => :fictive_nest,
           :dropoff => ByRow(zero) => :dropoff,
          )

# apply a couple of convenient transformations
transform!(df, [:coords, :tp] => ByRow((xy, i) -> xy[1:i]) => :homing, # keep only the homing part of the track
           [:coords, :tp] => ByRow((xy, i) -> xy[i]) => :turning_point, # add the turning point
           :date => ByRow(x -> Date(string(x), dateformat"yyyymmdd")) => :date # change the date to a real date type
          )

# the intervals for the Statistics
const intervals = sort([30, 60, 90, 120, 150])

# the folder where all the results are saved
const path = "MemoryExperiments results"

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
               [:dropoff, :turning_point, :nest2feeder] => ByRow((a,b,c) -> abs(norm(a - b) - c)) => "vector length difference",
               [:dropoff, :turning_point] => ByRow((a,b) -> rad2deg(abs(angular_diff_from_pos_y_axis(b - a)))) => "angular difference",
              )


# save the table
CSV.write(joinpath(path, "stats.csv"), stats)


# a convinience function 
function find_extrema(f, xyss; m = Inf, M = -Inf)
  for xys in xyss
    _m, _M = extrema(f, xys)
    m = min(m, _m)
    M = max(M, _M)
  end
  return m, M
end

### main track figures ###
transform!(df, ["feeder to nest", "holding condition"] => ByRow((n2f, hc) -> n2f == 130 ? hc == "postice" ? "postice" : "130" : "260") => :figure)
sort!(df, "holding time")
height = 600
for (k,gd) in pairs(groupby(df, :figure))
  # k, gd = first(pairs(groupby(df, :figure)))
  ym, yM = find_extrema(last, gd.homing, M = maximum(last, gd.fictive_nest))
  buf = (yM - ym)*2/100
  ym -= buf
  yM += buf
  scene, layout = layoutscene(resolution = (2000, 650), figure_padding = 0)
  for (i, (k, g)) in enumerate(pairs(groupby(gd, ["holding condition", "feeder to nest", "holding time"])))
    hc, n2f, ht = k
    title = join(k, " ")#string(NamedTuple(k))[2:end-1]
    xm, xM = find_extrema(first, g.homing)
    xm -= buf
    xM += buf
    ax = layout[1, i] = Axis(scene, width = height/(yM - ym)*(xM - xm),  height = height, limits = (xm, xM, ym, yM), xticks = [0], yticks = [0], title = title)
    color = tocolors(hc, n2f)
    lines!(ax, Circle(zero(Point2f0), getproperty(k, Symbol("feeder to nest"))), color = color)
    _intervals = filter(<(getproperty(k, Symbol("feeder to nest"))), intervals)
    for radius in _intervals
      lines!(ax, Circle(zero(Point2f0), radius), color = :grey)
      scatter!(ax, Point2f0(0, radius), color = :white, markersize = round(Int, length(string(radius))*45/3)*1px, strokewidth = 0)
    end
    positions = Point2f0.(0, _intervals)
    textplot = text!(ax, [(string(r), p) for (r, p) in zip(_intervals, positions)], align=(:center, :center), color = :grey)
    # layouts = textplot._glyphlayout[]
    # strings = textplot[1][]
    # bbs = map(strings, layouts) do str, l 
    #   data_text_boundingbox(str[1], l, Quaternionf0(0,0,0,1), Point3f0(0))
    # end
    # scatter!(ax, positions, markersize=widths.(bbs), marker=Rect, color = :white)
    # ax.scene.plots[end-1:end] .= ax.scene.plots[[end, end-1]]
    colors = range(color, stop=RGB{N0f8}(Gray(0)), length=nrow(g) + 1)[1:end-1]
    for (isfirst, (xy, tp, color)) in IterTools.flagfirst(zip(g.homing, g.turning_point, colors))
      l = lines!(ax, Point2f0.(xy); linestyle = nothing, linewidth = 1, color = color)
      isfirst && (l.label = "Tracks")
      l = scatter!(ax, Point2f0(tp); marker = '•', strokecolor = :transparent, markersize = 50px, color = color)
      isfirst && (l.label = "Turning points")
    end
    scatter!(ax, Point2f0(first(g.fictive_nest)), color = color, marker = '⋆', markersize = 50px)
    scatter!(ax, Point2f0(first(g.dropoff)), color = color, marker = '↓', markersize = 40px)
  end
  hidedecorations!.(contents(layout[1,:]), grid = false, minorgrid = false, minorticks = false)
  save(joinpath(path, string(k..., ".pdf")), scene)
end


#### Length distributions figure ####
gd = groupby(stats, ["holding condition", "feeder to nest", "holding time"])
n = length(gd)
n += 10
f = Figure(resolution = (700, 1500), figure_padding = 0)
for (j,l) in enumerate(("vector length", "path length", "nest corrected vector"))
  ax = Axis(f[j, 1], aspect = AxisAspect(1))
  ys = []
  ysl = []
  for (i, (k, g)) in enumerate(pairs(gd))
    vector = abs.(g[:, l])
    y = (i - 1)/(n - 1)
    density!(ax, vector, offset = y, color = (:slategray, 0.4), bandwidth = 5, boundary = (0, 300))
    push!(ys, y)
    push!(ysl, join(k, " "))
  end
  ax.xticks = [0, 130, 260]
  ax.xlabel = l
  ax.yticks = (ys, ysl)
  xlims!(ax, 0, 300)
  hideydecorations!(ax, label = false, ticklabels = false, ticks = false, grid = true, minorgrid = true, minorticks = true)
end
save(joinpath(path, "lengths.png"), f)



#### ayse figure ####
using StatsBase
absmean(x) = mean(abs, x)
gd = groupby(stats, ["holding condition", "feeder to nest", "holding time"])
a = combine(gd, "vector length" => length => "n",
            ["vector length", "path length", "nest corrected vector"] .=> median,
            ["vector length", "path length", "nest corrected vector"] .=> absmean,
            ["vector length", "path length", "nest corrected vector"] .=> std,
           )
μ = stack(a, r"mean", ["holding condition", "holding time", "feeder to nest"])
dict = levelsmap(μ.variable)
transform!(μ, :variable => ByRow(v -> dict[v]) => :grpi)
dict = levelsmap(μ[!, "holding time"])
transform!(μ, "holding time" => ByRow(v -> dict[v]) => :x)
gd = groupby(μ, ["holding condition", "feeder to nest"])
g = gd[1]
h = barplot(g.x, g.value, dodge = g.grpi, color = g.grpi)
ylims!(h.axis, (0, 255))
h.axis.xticks = (collect(values(dict)), string.(keys(dict)))
h
save(joinpath(path, "ayse figure.png"), h)


#### summary table for the lengths ####
gd = groupby(stats, ["holding condition", "feeder to nest", "holding time"])
a = combine(gd, "vector length difference" => length => "n",
            ["vector length difference", "angular difference"] .=> median,
            ["vector length difference", "angular difference"] .=> x -> mean(x) ± std(x),
           )
CSV.write(joinpath(path, "length summary.csv"), a)


data = filter("holding condition" => !=("postice"), stats)
gd = groupby(data, ["holding condition", "feeder to nest"])
fig = Figure()
axs = fig[1:2,1:3] = [Axis(fig) for i in 1:2, j in 1:3]
for (i, (k, g)) in enumerate(pairs(gd))
  for (j, (f, u)) in enumerate(zip(("vector length", "angular difference"), (" (cm)", " (°)")))
    boxplot!(axs[j,i], g[!, "holding time"], g[!, f], width = 3)
    axs[j,i].xticks = unique(g[!, "holding time"])
    axs[j,i].ylabel = uppercasefirst(f*u)
    if j == 1
      axs[j,i].title = join(k, " ")
      abline!(axs[j,i], getproperty(k, "feeder to nest"), 0, color = :gray, linestyle = :dash)
      axs[j,i].yticks = 0:65:260
      ylims!(axs[j,i], (0, 270))
    end
  end
end
linkxaxes!(axs...)
for i in 1:2
  linkyaxes!(axs[i, :]...)
end
hidexdecorations!.(axs[1,:], grid = false, minorgrid = false, minorticks = false)
hideydecorations!.(axs[:,2:end], grid = false, minorgrid = false, minorticks = false)
Label(fig[3,:], "Holding time (min)")
fig
save(joinpath(path, "length time.png"), fig)


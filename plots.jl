ntentries = Dict(:homing => (linestyle = nothing, linewidth = 1, color = :black),
                 :fictive_nest => (color = :white, marker = '⋆', strokecolor = :black, markerstrokewidth = 1, strokewidth = 1, markersize = 15px), 
                 :dropoff => (color = :black, marker = '↓', markersize = 15px),
                 :turning_point => (color = :black, marker = '•', strokecolor = :transparent, markersize = 15px),
                )
labels = Dict(:homing => "Tracks",
              :fictive_nest => "Fictive nest",
              :dropoff => "Dropoff",
              :turning_point => "Turning points",
             )

function plotruns(xys, nest2feeder, color, title; show_circles = false)

  fig = Figure(resolution = (1000,1000))
  ax = fig[1, 1] = Axis(fig, aspect = DataAspect(), xlabel = "X (cm)", ylabel = "Y (cm)", title = title)

  colors = range(color, stop=colorant"black", length=length(xys) + 1)[1:end-1]

  for (isfirst, (xy, color)) in IterTools.flagfirst(zip(xys, colors))
    s = :homing
    l = lines!(ax, xy; ntentries[s]..., color = color)
    isfirst && (l.label = labels[s])
    s = :turning_point
    l = scatter!(ax, xy[end]; ntentries[s]..., color = color)
    isfirst && (l.label = labels[s])
  end
  l = scatter!(ax, zero(Point2f0); ntentries[:fictive_nest]...)
  l.label = labels[:fictive_nest]
  dropoff = Point2f0(0, -nest2feeder)
  l = scatter!(ax, dropoff; ntentries[:dropoff]...)
  l.label = labels[:dropoff]

  if show_circles
    limits!(ax.finallimits[])
    for radius in (5, 10, 30, 60, 90, 120)
      lines!(ax, Circle(dropoff, radius), color = :grey)
      text!(ax, string(radius), position = Point2f0(0, radius - nest2feeder), align = (:left, :baseline))
    end
  end

  Legend(fig[0,1], ax, orientation = :vertical, nbanks = 2, tellheight = true, height = Auto(), groupgap = 30);

  fig
end



styles = (
          homing        = (label = "homing", linewidth = 2,),
          searching     = (label = "searching", linewidth = 1,),
          turning_point = (label = "turning point", marker    = '◎', color = :red),
          dropoff       = (label = "drop-off", marker    = '•', color = :white, strokewidth = 1),
          nest          = (label = "nest", marker    = :star5,),
          fictive_nest  = (label = "fictive nest", marker = :star5, color = :white, strokewidth = 1),
         )

function plottrack(ax, dropoff, homing, turning_point, searching, fictive_nest, figure, color)
  lines!(ax, homing; color, styles.homing...)
  if figure ≠ :conflict
    lines!(ax, searching; color, styles.searching...)
  end
  if figure == :displacement
    scatter!(ax, dropoff; strokecolor = color, styles.dropoff...)
  end
  scatter!(ax, turning_point; color, styles.turning_point...)
end

function plottracks(ax, dropoff, homing, turning_point, searching, fictive_nest, nest, figure, color)
  plottrack.(ax, dropoff, homing, turning_point, searching, fictive_nest, figure, color)
  if figure[1] ≠ :displacement
    scatter!(ax, dropoff[1]; strokecolor = color, styles.dropoff...)
    scatter!(ax, fictive_nest[1]; strokecolor = color, styles.fictive_nest...)
  else
    scatter!(ax, nest[1]; color, styles.nest...)
  end
end

function plottracks(df; color = :black)
  fig = Figure()
  for (i, (k, gd)) in enumerate(pairs(groupby(df, :treatment)))
    ax = Axis(fig[1,i], aspect = DataAspect(), title = string(k...), ylabel = "Y (cm)")
    plottracks(ax, gd.dropoff, gd.homing, gd.turning_point, gd.searching, gd.fictive_nest, gd.nest, gd.figure, color)
  end
  axs = contents(fig[1, :])
  linkaxes!(axs...)
  hideydecorations!.(axs[2:end], grid = false)
  Label(fig[2,:], "X (cm)", tellwidth = false, tellheight = true)
  Legend(fig[3, :], axs[1], orientation = :horizontal, tellwidth = false, tellheight = true, merge = true, unique = true)
  fig
end

function plotspeeds(df, Mx, My; color = :black)
  fig = Figure()
  for (i, (k, gd)) in enumerate(pairs(groupby(df, :treatment)))
    ax = Axis(fig[1,i], aspect = 1, title = string(k...), ylabel = "Speed (cm/sec)")
    boxplot!(ax, gd.distance, color = color, gd.speed, width=speed_interval/2, show_median=true, show_outliers = false)
    vlines!(ax, 0, color = :gray)
  end
  axs = contents(fig[1, :])
  linkaxes!(axs...)
  xlims!(axs[1], -Mx, Mx)
  ylims!(axs[1], nothing, My)
  hideydecorations!.(axs[2:end], grid = false)
  Label(fig[2,:], "Radial distance from the turning point (cm)", tellwidth = false, tellheight = true)
  fig
end

function ploteach()
  fig = Figure()
  sl = Slider(fig[2, 1], range = 1:nrow(df))
  homing = lift(sl.value) do i
    Vector{Union{Missing, Point2f0}}(df.homing[i])
  end
  turning_point = lift(sl.value) do i
    df.turning_point[i]
  end
  searching = lift(sl.value) do i
    Vector{Union{Missing, Point2f0}}(df.searching[i])
  end
  ax = Axis(fig[1,1], aspect = DataAspect())
  lines!(ax, homing; styles.homing...)
  scatter!(ax, turning_point; styles.turning_point...)
  lines!(ax, searching; styles.searching...)
  fig
end
using GLMakie
GLMakie.activate!()
ploteach()

styles = (
          homing        = (label = "homing", linewidth = 2,),
          searching     = (label = "searching", linewidth = 1,),
          turning_point = (label = "turning point", marker    = '◎',),
          dropoff       = (label = "drop-off", marker    = '•', color = :white, strokewidth = 1),
          nest          = (label = "nest", marker    = :star5,),
          fictive_nest  = (label = "fictive nest", marker = :star5, color = :white, strokewidth = 1),
         )

function plottrack(ax, dropoff, homing, turning_point, searching, fictive_nest, figure, color)
  # lines!(ax, collect(Missings.replace(homing, Point2f(NaN, NaN))); color, styles.homing...)
  lines!(ax, homing; color, styles.homing...)
  if figure ≠ :conflict
    # lines!(ax, collect(Missings.replace(searching, Point2f(NaN, NaN))); color, styles.searching...)
    lines!(ax, searching; color, styles.searching...)
  end
  if figure == :displacement
    scatter!(ax, dropoff; strokecolor = color, styles.dropoff...)
  end
  scatter!(ax, turning_point; color, styles.turning_point...)
  # if figure == :transfer
  #   scatter!(ax, fictive_nest; color, styles.fictive_nest...)
  # end
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

function plotspeeds(df, M; color = :black)
  fig = Figure()
  for (i, (k, gd)) in enumerate(pairs(groupby(df, :treatment)))
    ax = Axis(fig[1,i], aspect = 1, title = string(k...), ylabel = "Speed (cm/sec)")
    boxplot!(ax, gd.variable, color = color, gd.value, width=5, show_median=true, show_outliers = false)
    vlines!(ax, 0, color = :gray)
  end
  axs = contents(fig[1, :])
  linkaxes!(axs...)
  xlims!(axs[1], -M, M)
  hideydecorations!.(axs[2:end], grid = false)
  Label(fig[2,:], "Radial distance from the turning point (cm)", tellwidth = false, tellheight = true)
  fig
end

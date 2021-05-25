function speedstats(xy, t)
  Δt = mean(diff(t))
  l = norm.(diff(xy))
  s = l/Δt
  mean_and_std(s)
end

function angular_diff_from_pos_y_axis(u)
  α = π/2 - atan(reverse(u)...)
  return α > π ? α - 2π : α
end

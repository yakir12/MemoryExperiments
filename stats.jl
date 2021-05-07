function speedstats(xy, t)
  Δt = mean(diff(t))
  l = norm.(diff(xy))
  s = l/Δt
  μ = mean(s)
  σ = std(s, mean = μ)
  μ ± σ
end

function angular_diff_from_pos_y_axis(u)
  α = π/2 - atan(reverse(u)...)
  return α > π ? α - 2π : α
end

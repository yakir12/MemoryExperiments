function speedstats(xy, t)
  Δt = mean(diff(t))
  l = norm.(diff(xy))
  s = l/Δt
  μ = mean(s)
  σ = std(s, mean = μ)
  μ ± σ
end

const nintervals = length(intervals) + 1

function coordinate2group(xy)
  l = norm(xy)
  for (i, L) in pairs(intervals)
    if l ≤ L
      return i
    end
  end
  return nintervals
end

function directionstats(xy, dropoff)
  ss = [[Mean(), Mean()] for _ in 1:nintervals]
  for i in 2:length(xy)
    g = coordinate2group(xy[i] - dropoff)
    fit!.(ss[g], LinearAlgebra.normalize(xy[i] - xy[i-1]))
  end
  [OnlineStats.nobs(s[1]) > 0 ? rad2deg(angular_diff_from_pos_y_axis(value.(s))) : missing for s in ss]
end

function angular_diff_from_pos_y_axis(u)
  α = π/2 - atan(reverse(u)...)
  return α > π ? α - 2π : α
end

function to_figure(e, t)
  e == "transfer" && return :transfer
  occursin(r"OP", t) && return :conflict
  :displacement
end
#
function filter_jump(rawcoords)
  xyts = StructArray(rawcoords)
  Δs = diff(xyts.t)
  i = findall(Δs .> 60) # minimum of 20
  bad = [xyts.t[j]..xyts.t[j+1] for j in i]
  itp = interpolate((xyts.t, ), xyts.xy, Gridded(Linear()))
  ts = range(0, xyts.t[end], step = 1)
  xy = Vector{Union{Missing, Point2f0}}(undef, length(ts))
  for (i, t) in enumerate(ts)
    if any(x -> t ∈ x, bad)
      xy[i] = missing
    else
      xy[i] = Point2f0(itp(t))
    end
  end
  xy
end
#
treatments = Dict(
                  "FV"      => "Full vector",
                  "ZV"      => "Zero vector",
                  "FV_R"    => "Full vector (right)",
                  "FV_L"    => "Full vector (left)",
                  "ZV_R"    => "Zero vector (right)",
                  "ZV_L"    => "Zero vector (left)",
                  "OP-FV_R" => "Conflict full vector (right)",
                  "OP-FV_L" => "Conflict full vector (left)",
                  "HV"      => "Half vector",
                 )

speed_interval = 10
speed_breaks = 0:speed_interval:200
speed_mid = Int.(midpoints(speed_breaks))
#
function _getspeed(xy, c)
  o = [Mean() for _ in speed_mid]
  for (a1, a2) in partition(xy, 2, 1)
    if !ismissing(a1) && !ismissing(a2)
      L = norm(a2 - c)
      i = Int(L ÷ speed_interval) + 1
      Δ = norm(a2 - a1)
      fit!(o[i], Δ)
    end
  end
  [nobs(i) > 0 ? mean(i) : missing for i in o]
end
#
function get_speed(homing, turning_point, searching)
  y1 = reverse(_getspeed(reverse(homing), turning_point))
  y2 = _getspeed(searching, turning_point)
  return [y1; y2]
end
#
function rm2small!(df, cutoff = 5)
  for g in groupby(df, [:figure, :treatment, :variable])
    if sum(completecases(g)) < cutoff
      g.value .= missing
    end
  end
end

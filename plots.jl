categorize4figure(n2f, hc) = n2f == 130 ? hc == "postice" ? "postice" : "130" : "260"

# coloring scheme
function tocolors(holding_condition::String, nest2feeder::Int)::RGB{N0f8} 
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

function tocolors(hc, n2f) 
  color = tocolors(hc[1], n2f[1])
  n = length(hc)
  range(color, stop=RGB{N0f8}(Gray(0)), length = n + 1)[1:end-1]
end

function plotgrid!(ax, nest2feeder, xm = nothing)
  radii = 30:30:(nest2feeder - 1)
  for radius in radii
    lines!(ax, Circle(zero(Point2f0), radius), color = :grey70, linewidth = 1)
  end
  if !isnothing(xm)
    positions = similar(radii, Point2f0)
    radii = reverse(radii)
    positions[1] = Point2f0(xm, sqrt(radii[1]^2 - xm^2))
    for i in 2:length(positions)
      if radii[i] > abs(xm)
        positions[i] = Point2f0(xm, sqrt(radii[i]^2 - xm^2))
      else
        α = atan(reverse(positions[i-1])...)
        positions[i] = Point2f0(radii[i]*cos(α), radii[i]*sin(α))
      end
    end
    # positions = [r > abs(xm) ? Point2f0(xm, sqrt(r^2 - xm^2)) : Point2f0(
    # _radii = filter(>(abs(xm)), radii)
    # ys = [sqrt(r^2 - xm^2) for r in _radii]
    # positions = Point2f0.(xm, ys)
    labels = [string(r, " cm") for r in radii]
    scatter!(ax, positions, color = :white, markersize = round.(Int, length.(labels)*30/3), strokewidth = 0)
    textplot = text!(ax, Tuple.(zip(labels, positions)), align=(:center, :center), color = :grey70, rotation = [atan(reverse(p)...) - pi/2 for p in positions], textsize = 12)
    # layouts = textplot._glyphlayout[]
    # strings = textplot[1][]
    # bbs = map(strings, layouts) do str, l 
    #   data_text_boundingbox(str[1], l, Quaternionf0(0,0,0,1), Point3f0(0))
    # end
    # scatter!(ax, positions, markersize=widths.(bbs), marker=Rect, color = :white)
    # ax.scene.plots[end-1:end] .= ax.scene.plots[[end, end-1]]
    # colors = range(color, stop=RGB{N0f8}(Gray(0)), length=nrow(g) + 1)[1:end-1]
  end
end
# a convinience function 
function find_extrema(f, xyss; m = Inf, M = -Inf, b = 5/100)
  for xys in xyss
    _m, _M = extrema(f, xys)
    m = min(m, _m)
    M = max(M, _M)
  end
  buff = (M - m)*b
  return m - buff, M + buff
end
function dropmarker(p1, p2, factor)
  tra1 = Translation(Point2f0(-1.,0))
  v = p1 - p2
  α = atan(reverse(v)...)
  rot = LinearMap(Angle2d(α))
  tra2 = Translation(p2)
  f = tra2 ∘ rot ∘ tra1
  t = 0:0.01:2pi
  ps = [f(factor*Point2f0(cos(t),sin(t)*sin(t/2)^2)) for t in t]
  # GLMakie.AbstractPlotting.GeometryBasics.Polygon(ps)
end

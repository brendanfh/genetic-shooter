function math.lerp(a, b, t)
	return a + (b - a) * t
end

function math.sqrDist(x1, y1, x2, y2)
	return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)
end

function math.genuuid()
	return ("xxxxxxxx-xxxx-4yxx-xxxxxxxx"):gsub('[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

function math.rectcontains(r, x, y)
	return r[1] <= x and r[2] <= y and r[1] + r[3] >= x and r[2] + r[4] >= y
end

function math.rectintersects(r1, r2)
	return r1[1] <= r2[1] + r2[3] and r1[2] <= r2[2] + r2[4] and r1[1] + r1[3] >= r2[1] and r1[2] + r1[4] >= r2[2]
end

local function ripairsiter(t, i)
	i = i - 1
	if i ~= 0 then
		return i, t[i]
	end
end

function reversedipairs(t)
	return ripairsiter, t, #t + 1
end

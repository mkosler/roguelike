return {
    foreach = function (t, f, ...)
        for _,v in ipairs(t) do
            if type(f) == 'string' then
                v[f](v, ...)
            else
                f(v, ...)
            end
        end
    end,

    map = function (t, f, ...)
        local nt = {}

        for _,v in ipairs(t) do
            table.insert(nt, f(v, ...))
        end

        return nt
    end,

    dist = function (x1, y1, x2, y2)
        return math.sqrt(((x1 - x2) * (x1 - x2)) + ((y1 - y2) * (y1 - y2)))
    end,
}
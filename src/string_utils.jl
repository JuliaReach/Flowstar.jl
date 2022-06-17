function _match_between(s::AbstractString, left, right = "\\n\\r")
    re= Regex("(?<=\\Q$left\\E)(.*?)(?=[$right])")
    m = match(re, s)

    @assert !isnothing(m) "No regex matches found between $left and $right"
    m.match
end

function _split_states(str)
    split(str,";", keepempty = false)
end

function _intervalstr(str)
    str = replace(str, "[" => "(")
    str = replace(str, "]" => ")")
    str = replace(str, "," => "..")
    str
end

function _cleantm(str, lvars)
    tm_str, dom_str = split(str, "\n\n\n")

    tm_str = replace(tm_str, "}"=>"")
    tm_str = strip(tm_str)
    tm_str = replace.(tm_str, "\n" => ";")
    tm_str = _intervalstr(tm_str)
    for (idx,lv) in enumerate(lvars)
        tm_str = replace(tm_str, "$lv" =>"ξ[$idx]")
    end

    dom_str = replace(dom_str, "}"=>"")
    dom_str = strip(dom_str)
    dom_str = _intervalstr(dom_str)
    for lv in lvars[2:end]
        dom_str = replace(dom_str, "\n$lv in" =>",")
    end
    dom_str = replace(dom_str, "$(lvars[1]) in" => "IntervalBox(")
    dom_str = dom_str*")"

    tm_str, dom_str
end

function _split_poly_rem(str)
    idx = findlast('+', str)
    str[1:idx-1], str[idx+1:end]
end
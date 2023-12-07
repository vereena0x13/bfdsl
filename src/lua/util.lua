function is_int(n) return n == math.floor(n) end

function assert_is_int(n)
    if type(n) ~= "number" then error("expected number, got " .. type(n)) end
    if not is_int(n) then error("expected integer, got " .. tostring(n)) end
end
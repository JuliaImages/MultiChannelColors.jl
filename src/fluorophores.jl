# Data in the data/ directory were harvested from https://en.wikipedia.org/wiki/Fluorophore
# with "complicated" cases commented out (e.g., two excitation peaks)

# Parse the csv files without using the CSV package (for reasons of latency)
function csvparse(io::IO)
    lookup = Dict{String,RGB{N0f8}}()
    for (i, line) in enumerate(eachline(io))
        startswith(line, '#') && continue
        name, ex, em, _ = split(line, ',')
        lookup[name] = colormatch(parse(Float32, em))
    end
    return lookup
end
function csvparse(filename::AbstractString)
    return open(filename) do io
        csvparse(io)
    end
end

"""
    rgb = fluorophore_rgb[name]

Look up the RGB color associated with a fluorophore named `name`.
"""
const fluorophore_rgb = merge(
    csvparse(joinpath(dirname(@__DIR__), "data", "organics.csv")),
    csvparse(joinpath(dirname(@__DIR__), "data", "proteins.csv")),
)

"""
    rgb = fluorophore_rgb"NAME"

Look up the RGB color associated with a fluorophore hard-coded in the string that follows.
This lookup is performed at compile-time, and hence the *value* of `rgb` is visible to
the compiler and may be constant-propagated.

If the fluorophore name cannot be hard-coded, use the dictionary form `fluorophore_rgb[name]`.
"""
macro fluorophore_rgb_str(str::String)
    return fluorophore_rgb[str]
end

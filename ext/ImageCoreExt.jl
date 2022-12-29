module ImageCoreExt

@static if isdefined(Base, :get_extension)
    using ImageCore
else
    using ..ImageCore
end

using MultiChannelColors: ColorMixture

# clamp01 is designed to work on RGB colors (a major usage is for display), so convert first
ImageCore.clamp01(c::ColorMixture{T}) where T = convert(RGB{T}, ImageCore.clamp01(convert(RGB{floattype(T)}, c)))
ImageCore.clamp01nan(c::ColorMixture{T}) where T = convert(RGB{T}, ImageCore.clamp01nan(convert(RGB{floattype(T)}, c)))

function __init__()
    @debug "ImageCoreExt loaded"
    return nothing
end

end

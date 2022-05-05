# clamp01 is designed to work on RGB colors (a major usage is for display), so convert first
ImageCore.clamp01(c::ColorMixture) = ImageCore.clamp01(convert(RGB, c))
ImageCore.clamp01nan(c::ColorMixture) = ImageCore.clamp01nan(convert(RGB, c))

# FAQ

## Why are the RGB colors encoded in the `ColorMixture` *type*? Why not a value field?

In many places, JuliaImages assumes that you can convert from one color space to another purely from knowing the type you want to convert to. This would not be possible if the RGB colors were encoded as a second field of the color.

## I wrote some code and got lousy performance. How can I fix it?

To achieve good performance, in some cases the RGB *values* must be aggressively constant-propagated, a feature available only on Julia 1.7 and higher. So if you're experiencing this problem on Julia 1.6, try a newer version.

If you're using fluorophore colors with `fluorophore_rgb`, where possible make sure you're using the compile-time constant syntax `fluorophore_rgb"EGFP"` rather than the runtime syntax `fluorophore_rgb["EGFP"]`.

When you can't get good performance otherwise, your best option is to use a [function barrier](https://docs.julialang.org/en/v1/manual/performance-tips/#kernel-functions):

```julia
ctemplate = ColorMixture((rgb1, rgb2))

@noinline function make_image_and_do_something(ctemplate, sz)
    img = [ctemplate(rand(), rand()) for i = 1:sz[1], j = 1:sz[2]]
    ...
end
```

In this case `ctemplate` encodes the type and code in `make_image_and_do_something` will be inferrable even if the type of the created `ctemplate` is not inferrable in the calling scope.

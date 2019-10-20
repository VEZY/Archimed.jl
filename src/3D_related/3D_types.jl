"""
Data structure for a mesh material that is used to desribe the light components of a [Phong reflection](https://en.wikipedia.org/wiki/Phong_reflection_model)
type model. All data is stored as RGBα for Red, Green, Blue and transparency.

# Exemples
> a= Component_light(0.5,0.2,0.1,0.0)
> mat= material(a,a,a,a,0.5)
> mat.shininess
0.5
"""
struct material
    emission::Array{AbstractFloat,1}
    ambiant::Array{AbstractFloat,1}
    diffuse::Array{AbstractFloat,1}
    specular::Array{AbstractFloat,1}
    shininess::AbstractFloat
end


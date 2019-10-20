"""
Component_light is a data structure for the Red, Blue, Green and α (transparency)
values of a light component (e.g. material for the Phong model). 

# Exemples
> a= Component_light(0.5,0.2,0.1,0.0)
> a.R
0.5
"""
struct Component_light{T<:AbstractFloat}
    R::T
    G::T
    B::T
    α::T
end

"""
Data structure for a mesh material that is used to desribe the light components of a [Phong reflection](https://en.wikipedia.org/wiki/Phong_reflection_model)
type model.

# Exemples
> a= Component_light(0.5,0.2,0.1,0.0)
> mat= material(a,a,a,a,0.5)
> mat.shininess
0.5
"""
struct material{T<:Component_light}
    emission::T
    ambiant::T
    diffuse::T
    specular::T
    shininess::AbstractFloat
end

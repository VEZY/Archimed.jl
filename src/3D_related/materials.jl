"""
Extract all materials from the opf file, format them to [`material`] type and return a `Dict`
out of them. The keys of the `Dict` are named after the `id` (as for the meshes).
"""
function extract_opf_materials(opf)
    materials = Dict{Int32, Any}()
    for i in opf["materialBDD"]["material"]
        push!(materials, i[:Id] => extract_opf_material(i))
    end
    return materials
end

"""
Parse a material in opf format to [`material`]
"""
function extract_opf_material(opf_material)
    material(Component_light(opf_material["emission"]...),
            Component_light(opf_material["ambient"]...),
            Component_light(opf_material["diffuse"]...),
            Component_light(opf_material["specular"]...),
            opf_material["shininess"])
end
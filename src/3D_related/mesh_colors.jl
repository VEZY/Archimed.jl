"""
Find each mesh color.

# Notes
`meshes` is typically the output from [`meshes_from_topology`].

# Exemples
opf= read_opf("simple_OPF_shapes.opf")
mesh_data= meshes_from_topology(opf)
shapes= extract_opf_shapes(opf)
materials= extract_opf_materials(opf)
cols= meshes_color(opf,mesh_data)
mesh(merge_meshes(mesh_data["mesh"]), color= cols)
"""
function meshes_color(opf,meshes::Dict{String,Dict}= meshes_from_topology(opf))

    mesh_ids= collect(keys(meshes["mesh"]))
    materials= extract_opf_materials(opf)

    # n_triangles= sum([length(i.second.faces) for i in meshes["mesh"]])
    n_triangles= Dict{Int32,Int32}()
    for i in meshes["mesh"]
        push!(n_triangles, i.first => length(i.second.vertices))
    end
    n_triangles_tot= sum(values(n_triangles))
    prev_max= [0]
    # mesh_color= Dict{Int32, RGBA{Float64}}() # To get only the color per mesh ID
    triangle_color= Array{RGBA{Float64}}(undef, n_triangles_tot)

    for i in 1:length(mesh_ids)
        material_id= meshes["attributes"][mesh_ids[i]]["materialIndex"]
        col= RGBA(materials[material_id].diffuse...)
        # push!(mesh_color, mesh_ids[i] => col)
        for j in ((1:n_triangles[mesh_ids[i]]) .+ prev_max[1])
            triangle_color[j]= col
        end
        prev_max[1] += n_triangles[mesh_ids[i]]
    end

    return triangle_color
end

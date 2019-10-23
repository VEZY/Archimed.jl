"""
Extract all meshes from the opf file, format them to [`HomogenousMesh`] and return a `Dict`
out of them. The keys of the `Dict` are named after the mesh `id`.
"""
function extract_opf_meshes(opf, MeshType::Type{MT} = GLNormalMesh) where {MT <: AbstractMesh}
    meshes = Dict{Int32, Any}()
    for i in opf["meshBDD"]["mesh"]
        push!(meshes, parse(Int32,i[:Id]) => extract_opf_mesh(i))
    end
    return meshes
end

"""
Parse a mesh in opf format to [`HomogenousMesh`]
"""
function extract_opf_mesh(opf_mesh, MeshType::Type{MT} = GLNormalMesh) where {MT <: AbstractMesh}
    # Tv,Tn,Tuv,Tf = vertextype(MeshType), normaltype(MeshType), TextureCoordinate(MeshType), facetype(MeshType)
    Tv,Tn,Tuv,Tf = vertextype(MeshType), normaltype(MeshType), UV{Float32}, facetype(MeshType)
    v,n,uv,f     = Tv[], Tn[], Tuv[], Tf[]
    attr = Dict{Symbol, Any}()
    id= Int32[]
    # Faces:
    mesh_faces= [a[""] for a in opf_mesh["faces"]["face"]]
    for opf_mesh in mesh_faces
        append!(f, decompose(Tf, Face{3, UInt32}(opf_mesh .+ 1)))
    end
    # NB: +1 because decompose tries to transform 1-based to 0-based index, but
    # the faces already are 0-based indices.

    # vertices:
    for p in 1:3:length(opf_mesh["points"])
        push!(v, Point{3, Float32}(opf_mesh["points"][p:(p+2)]))
    end

    # normals:
    for p in 1:3:length(opf_mesh["normals"])
        push!(n, Point{3, Float32}(opf_mesh["normals"][p:(p+2)]))
    end

    # textures coordinates:
    for p in 1:2:length(opf_mesh["textureCoords"])
        push!(uv, UV{Float32}(opf_mesh["textureCoords"][p:(p+1)]))
    end

    # attribute_id
    push!(id, parse(Int32,opf_mesh[:Id]))

    attr[:faces]= f
    attr[:vertices]= v
    attr[:normals]= n
    attr[:texturecoordinates]= uv
    attr[:attributes]= id

    return MT(GeometryTypes.homogenousmesh(attr))::MT
end

"""
Make a Dict of meshes from the reference meshes (from `[extract_opf_meshes]`) and the topology (using transformation matrices).
These meshes can then be used for 3D graphics purposes. 
"""
function meshes_from_topology(opf)
    meshes = Dict{Int32,HomogenousMesh}() # A dict with the meshes
    attr = Dict() # A dict with the attributes (change Dict() to  Dict{Type, Any}())
    ref_meshes= extract_opf_meshes(opf)
    shapes= opf["shapeBDD"]["shape"]
    attrTypes= attr_type(opf["attributeBDD"])
    mesh_from_topology!(opf,meshes,ref_meshes,shapes,attr,attrTypes)

    return Dict("mesh" => meshes, "attributes" => attr) # The whole item (mesh + attributes)
end

"""
Compute meshes from topology and reference mesh iteratively for the whole topology. This function is called 
    by [`meshes_from_topology`].
"""
function mesh_from_topology!(node,meshes,ref_meshes,shapes,attr,attrType,child= "topology")

    attr_mesh= Dict{String,Any}()
    # Getting the attributes:
    for i in intersect(collect(keys(attrType)), collect(keys(node[child])))
        push!(attr_mesh, i => node[child][i])
    end
    # Add the scale as an attribute:
    push!(attr_mesh, "scale" => node[child][:scale])

    id= node[child][:id]
    # Add the resultting attributes to the main attr object:
    push!(attr, id => attr_mesh)

    # Get the geometry (transformation matrix and dUp and dDwn):
    try
        node[child]["geometry"]["mat"]
        geom= node[child]["geometry"]
        shapeIndex= parse(Int32,geom["shapeIndex"])
        shape= shapes[shapeIndex]
        m= vcat(geom["mat"], [0 0 0 1])
        transformed_vertices= map(x -> Point{3,Float32}((reshape(vcat(x, 1), 1, 4) * m)[1:3]),
                                    ref_meshes[shape["meshIndex"]].vertices)

        mesh_1= HomogenousMesh(faces= ref_meshes[shape["meshIndex"]].faces,
                                vertices= transformed_vertices,
                                normals= ref_meshes[shape["meshIndex"]].normals)
        push!(meshes, id => mesh_1)
    catch
        nothing
    end

    # Make the function recursive for each component:
    for i in intersect(collect(keys(node[child])), ["decomp", "branch","follow"])
        mesh_from_topology!(node[child],meshes,ref_meshes,shapes,attr,attrType,i)
    end
end

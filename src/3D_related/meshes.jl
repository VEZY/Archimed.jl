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


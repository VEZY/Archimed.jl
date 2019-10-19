"""
Make a standard mesh from the opf file.
"""
function opf_to_mesh(opf, MeshType::Type{MT} = GLNormalMesh) where {MT <: AbstractMesh}
    # Tv,Tn,Tuv,Tf = vertextype(MeshType), normaltype(MeshType), TextureCoordinate(MeshType), facetype(MeshType)
    Tv,Tn,Tuv,Tf = vertextype(MeshType), normaltype(MeshType), UV{Float32}, facetype(MeshType)
    v,n,uv,f     = Tv[], Tn[], Tuv[], Tf[]
    attr = Dict{Symbol, Any}()
    id= Int32[]

    for i in opf["meshBDD"]["mesh"]
        # Faces:
        mesh_faces= [a[""] for a in i["faces"]["face"]]
        for i in mesh_faces
            append!(f, decompose(Tf, Face{3, UInt32}(i .+ 1)))
        end
        # NB: +1 because decompose tries to transform 1-based to 0-based index, but
        # the faces already are 0-based indices.

        # vertices:
        for p in 1:3:length(i["points"])
            push!(v, Point{3, Float32}(i["points"][p:(p+2)]))
        end

        # normals:
        for p in 1:3:length(i["normals"])
            push!(n, Point{3, Float32}(i["normals"][p:(p+2)]))
        end

        # textures coordinates:
        for p in 1:2:length(i["textureCoords"])
            push!(uv, UV{Float32}(i["textureCoords"][p:(p+1)]))
        end

        # attribute_id
        push!(id, parse(Int32,i[:Id]))
    end

    attr[:faces]= f
    attr[:vertices]= v
    attr[:normals]= n
    attr[:texturecoordinates]= uv
    attr[:attributes]= id

    return MT(GeometryTypes.homogenousmesh(attr))::MT
end

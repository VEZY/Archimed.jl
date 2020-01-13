"""
Extract all the reference meshes from the opf file, format them to [`HomogenousMesh`] and return a `Dict`
out of them. The keys of the `Dict` are named after the mesh `id`.

# Notes
In OPF files, the reference meshes are used as a basis to build each component, and then transformed (scaled, rotated...)
using a transformation matrix located in the topology to fit the dimensions and spatial positionning of the component.

# Exemples
> opf= read_opf("simple_OPF_shapes.opf")
> extract_opf_ref_meshes(opf)
"""
function extract_opf_ref_meshes(opf, MeshType::Type{MT} = GLNormalMesh) where {MT <: AbstractMesh}
    meshes = Dict{Int32, Any}()
    for i in opf["meshBDD"]["mesh"]
        push!(meshes, parse(Int32,i[:Id]) => extract_opf_ref_mesh(i))
    end
    return meshes
end

"""
Parse a mesh in opf format to [`HomogenousMesh`]
"""
function extract_opf_ref_mesh(opf_mesh, MeshType::Type{MT} = GLNormalMesh) where {MT <: AbstractMesh}
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
Make a Dict of meshes from the reference meshes (from `[extract_opf_ref_meshes]`) and the topology (using transformation matrices).
These meshes can then be used for 3D graphics purposes.
"""
function meshes_from_topology(opf)
    meshes = Dict{Int32,HomogenousMesh}() # A dict with the meshes
    attr = Dict() # A dict with the attributes (change Dict() to  Dict{Type, Any}())
    ref_meshes= extract_opf_ref_meshes(opf)
    shapes= extract_opf_shapes(opf)
    attrTypes= attr_type(opf["attributeBDD"])
    mesh_from_topology!(opf,meshes,ref_meshes,shapes,attr,attrTypes)

    return Dict("mesh" => meshes, "attributes" => attr) # The whole item (mesh + attributes)
end

"""
Compute meshes from topology and reference mesh iteratively for the whole topology. This function is called
    by [`meshes_from_topology`].

# Arguments
* node: parent node with all its childs (e.g. opf).
* meshes: a Dict with the previously computed meshes (Dict{Int32,HomogenousMesh}()). The function will recursively push to it.
* ref_meshes: the meshes used as a reference. A transformation matrix is used on them to build the object's meshes.
* shapes: shapes from the opf, i.e. the mesh index, the material index and its name.
* attr: an empty Dict that is filled recursively with the attributes of each node.
* attrType: the attributes type, read from the opf.
* child: the name of the node of interest.

# Returns
Increments `meshes` and `attr` in-place recursively for all childs in the node.
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

    # Get the geometry (transformation matrix and dUp and dDwn):
    geom= try node[child]["geometry"] catch nothing end
    # Try to get the shape index if any:
    shapeIndex= try parse(Int32,geom["shapeIndex"]) catch nothing end

    if geom != nothing
        # Add w to the transformation matrix:
        m= vcat(geom["mat"], [0 0 0 1])
    else
        m= I # identity matrix from LinearAlgebra package (lazy)
    end

    if shapeIndex != nothing
        shape= shapes[shapeIndex]
        # Add the material index as an attribute:
        push!(attr_mesh, "materialIndex" => shape["materialIndex"])

        # Get the reference mesh and taper it in z and y (the principal axis is following x already):
        ref_mesh_scaled= taper( ref_meshes[shape["meshIndex"]].vertices,geom["dUp"],geom["dDwn"])

        # Transform the vertices:
        transformed_vertices= map(x -> Point{3,Float32}((m*vcat(x, 1.0))[1:3]),ref_mesh_scaled)
        # NB: using vcat to add w (1) on the vector.
        # NB2: the order for the matrices products is important.

        mesh_1= HomogenousMesh(faces= ref_meshes[shape["meshIndex"]].faces,
                                vertices= transformed_vertices,
                                normals= ref_meshes[shape["meshIndex"]].normals)
        push!(meshes, id => mesh_1)
    end

    # Add the resulting attributes to the main attr object:
    push!(attr, id => attr_mesh)
    # Make the function recursive for each component:
    for i in intersect(collect(keys(node[child])), ["decomp", "branch","follow"])
        mesh_from_topology!(node[child],meshes,ref_meshes,shapes,attr,attrType,i)
    end
end

"""
Merge the meshes returned from [`meshes_from_topology`] into one [`HomogenousMesh`] for plotting purposes.
"""
function merge_meshes(meshes::Dict{Int32,HomogenousMesh})
    mesh_ids= collect(keys(meshes))
    all_meshes= [(meshes[mesh_ids[1]])]

    for i in mesh_ids[2:end]
        all_meshes[1]= merge(all_meshes[1], meshes[i])
    end

    return all_meshes[1]
end

"""
Transform a reference mesh using dDwn and dUp from the geometry of a mesh. The tapering
helps to transform the reference mesh into a more tapered (i.e. pointy) or enlarged object, e.g.
make a cone from a cylinder.
"""
function taper(mesh,dUp,dDwn)
    delta = dDwn - dUp
    Xs= map(x -> x[1], mesh)
    xmin= minimum(Xs) ; xmax= maximum(Xs)
    deltaX = xmax - xmin

    scaled_mesh= Array{Point{3,Float32}}(undef, length(mesh))
    for i in 1:length(mesh)
        dX = (mesh[i][1] - xmin)
        factor = dDwn - delta * (dX / deltaX)
        scaled_mesh[i]= Point{3,Float32}(mesh[i][1],mesh[i][2] * factor,mesh[i][3] * factor)
    end

    return scaled_mesh
end

"""
Read an OPF file, parse its values and return the result as an OrderedDict.
"""
function read_opf(file)
    xdoc2 = readxml(file);
    xroot= root(xdoc2)
    if xroot.name != "opf"
        error("The file is not an OPF")
    end

    d = xml_dict(xdoc2)
    opf= d["opf"]

    if opf[:version] != "2.0"
        error("Cannot reaf OPF files version other than V2.0")
    end

    editable= parse(Bool,opf[:editable])
    parse_meshBDD!(opf)
    parse_opf_elements!(opf,"materialBDD","material", [Int64, Float64,Float64,Float64,Float64,Float64])
    parse_opf_elements!(opf,"shapeBDD","shape", [Int64, String,Int64, Int64])
    parse_opf_attributeBDD!(opf)
    parse_opf_topology!(opf,attr_type(opf["attributeBDD"]))

    return opf
end


"""
Parse an array of values from the OPF into a Julia array (Arrays in OPFs
are not following XML recommendations)
"""
function parse_opf_array(elem,type= Float64)
    if type==String
        strip(elem)
    else
        parsed= map(x -> parse(type,x), split(elem))
        if length(parsed)==1
            return parsed[1]
        else
            return parsed
        end
    end
end


"""
Parse the mesh_BDD using [parse_opf_array]
"""
function parse_meshBDD!(opf)
    # MeshBDD:
    for m in 1:length(opf["meshBDD"]["mesh"])
        for i in intersect(keys(opf["meshBDD"]["mesh"][m]),["points", "normals", "textureCoords"])
            opf["meshBDD"]["mesh"][m][i]= parse_opf_array(opf["meshBDD"]["mesh"][m][i])
        end
        for i in 1:length(opf["meshBDD"]["mesh"][m]["faces"]["face"])
            face_val_key= collect(keys(opf["meshBDD"]["mesh"][m]["faces"]["face"][i]))[2]
            opf["meshBDD"]["mesh"][m]["faces"]["face"][i][face_val_key]=
            parse_opf_array(opf["meshBDD"]["mesh"][m]["faces"]["face"][i][face_val_key], Int64)
        end
    end
end


"""
Generic parser for OPF elements.

# Arguments

- `opf::OrderedDict`: the opf Dict (using [XMLDict.xml_dict])
- `child::String`: the child name (e.g. "materialBDD")
- `subchild::String`: the sub-child name (e.g. "material")
- `elem_types::Array`: the target types of the element (e.g. "[String, Int64]")

# Details

`elem_types` should be of the same length as the number of elements found in each
item of the subchild.

"""
function parse_opf_elements!(opf,child,subchild,elem_types)
    for m in 1:length(opf[child][subchild])
        elem_keys= collect(keys(opf[child][subchild][m]))
        for i in 1:length(elem_keys)
            if !isa(opf[child][subchild][m][elem_keys[i]], Array)
                opf[child][subchild][m][elem_keys[i]]=
                    parse_opf_array(opf[child][subchild][m][elem_keys[i]],elem_types[i])
            end
        end
    end
end

"""
 Parse the opf attributes as a Dict.
"""
function parse_opf_attributeBDD!(opf)
    opf["attributeBDD"]= Dict([a[:name] => a[:class] for a in opf["attributeBDD"]["attribute"]])
end

"""
Get the attributes types in Julia `DataType`.
"""
attr_type= function(attr)
    attr_Type= Dict{String,DataType}()
    for i in keys(attr)
        if attr[i] in ["Object", "String", "Color","Image"]
            push!(attr_Type, i => String)
        elseif attr[i] == "Integer"
            push!(attr_Type, i => Int32)
        elseif attr[i] in ["Double", "Metre", "Centimetre", "Millimetre", "10E-5 Metre"]
            push!(attr_Type, i => Float32)
        elseif attr[i] == "Boolean"
            push!(attr_Type, i => Bool)
        end
    end
    return attr_Type
end


"""
Parse the geometry element of the OPF.

# Note
The transformation matrix is 3*4.
"""
function parse_geometry(elem)
    elem["mat"]= SMatrix{3, 4}(transpose(reshape(parse_opf_array(elem["mat"]),4,3)))
    elem["dUp"]= parse_opf_array(elem["dUp"])
    elem["dDwn"]= parse_opf_array(elem["dDwn"])
end


"""
Parser for OPF topology.

# Note

The transformation matrices in `geometry` are 3*4.
"""
function parse_opf_topology!(node,attrType,child= "topology")
    node[child][:scale]= parse_opf_array(node[child][:scale],Int32)
    node[child][:id]= parse_opf_array(node[child][:id],Int32)

    # Parsing the attributes to their true type:
    for i in intersect(collect(keys(attrType)), collect(keys(node[child])))
       node[child][i]= parse_opf_array(node[child][i],attrType[i])
    end

    # Parse the geometry (transformation matrix and dUp and dDwn):
    try
        parse_geometry(node[child]["geometry"])
    catch
        nothing
    end

    # Make the function recursive for each component:
    for i in intersect(collect(keys(node[child])), ["decomp", "branch","follow"])
        # If it is an Array (several "follow" are represented as an Array under only
        # one "follow" to avoid several same key names in a Dict), then do it for each:
        if isa(node[child][i], Array)
            for j in 1:length(node[child][i])
                parse_opf_topology!(node[child][i],attrType,j)
            end
        else
            parse_opf_topology!(node[child],attrType,i)
        end
    end
end

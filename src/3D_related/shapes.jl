
"""
Format the shapes from the opf and return a [`Dict`] with the id as key and the shape data as values.

# Exemples
> opf= read_opf("simple_OPF_shapes.opf")
> extract_opf_shapes(opf)
"""
function extract_opf_shapes(opf)
    shapes_Dict= Dict{Int32,Any}()
    shapes= opf["shapeBDD"]["shape"]
    for i in shapes
        push!(shapes_Dict, i[:Id] => i)
    end
    return shapes_Dict
end
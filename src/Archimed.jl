module Archimed

import XMLDict.xml_dict
import EzXML.readxml
import EzXML.root
using MeshIO
using GeometryTypes

# 3D: 
export read_opf,extract_opf_ref_meshes,extract_opf_materials
export meshes_from_topology,merge_meshes
export material,extract_opf_shapes,find_meshes_color

include("3D_related/read_opf.jl")
include("3D_related/meshes.jl")
include("3D_related/materials.jl")
include("3D_related/shapes.jl")
include("3D_related/mesh_colors.jl")
include("3D_related/3D_types.jl")

end # module

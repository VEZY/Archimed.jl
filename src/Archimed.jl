module Archimed

import XMLDict.xml_dict
import EzXML.readxml
import EzXML.root
using MeshIO
using GeometryTypes

# 3D: 
export read_opf,extract_opf_meshes,extract_opf_materials
export meshes_from_topology

include("3D_related/read_opf.jl")
include("3D_related/meshes.jl")
include("3D_related/materials.jl")
include("3D_related/3D_types.jl")

end # module

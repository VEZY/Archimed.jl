module Archimed

import XMLDict.xml_dict
import EzXML.readxml
import EzXML.root
using MeshIO
using GeometryTypes

export read_opf,opf_to_mesh

include("read_opf.jl")
include("opf_to_mesh.jl")

end # module

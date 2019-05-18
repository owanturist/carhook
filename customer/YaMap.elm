port module YaMap exposing (destroy, init, onAddress, setAddress)


port ya_map__init :
    { nodeId : String
    , interactive : Bool
    }
    -> Cmd msg


init : String -> Bool -> Cmd msg
init nodeId interactive =
    ya_map__init
        { nodeId = nodeId
        , interactive = interactive
        }


port ya_map__set_address : String -> Cmd msg


setAddress : String -> Cmd msg
setAddress =
    ya_map__set_address


port ya_map__destroy : () -> Cmd msg


destroy : Cmd msg
destroy =
    ya_map__destroy ()


port ya_map__on_address : (String -> msg) -> Sub msg


onAddress : Sub String
onAddress =
    ya_map__on_address identity

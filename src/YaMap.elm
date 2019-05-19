port module YaMap exposing (destroy, init, onAddress, onReport, setAddress, setAddresses)

import ID exposing (ID)


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


port ya_map__set_addresses :
    List
        { id : String
        , address : String
        }
    -> Cmd msg


setAddresses : List ( ID { report : () }, String ) -> Cmd msg
setAddresses list =
    List.map
        (\( id, address ) ->
            { id = ID.toString id
            , address = address
            }
        )
        list
        |> ya_map__set_addresses


port ya_map__destroy : () -> Cmd msg


destroy : Cmd msg
destroy =
    ya_map__destroy ()


port ya_map__on_address : (String -> msg) -> Sub msg


onAddress : Sub String
onAddress =
    ya_map__on_address identity


port ya_map__on_report : (String -> msg) -> Sub msg


onReport : Sub (ID { report : () })
onReport =
    ya_map__on_report ID.fromString

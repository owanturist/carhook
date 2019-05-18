port module YaMap exposing (destroy, init, onAddress)


port ya_map__init : String -> Cmd msg


init : String -> Cmd msg
init =
    ya_map__init


port ya_map__destroy : () -> Cmd msg


destroy : Cmd msg
destroy =
    ya_map__destroy ()


port ya_map__on_address : (String -> msg) -> Sub msg


onAddress : Sub String
onAddress =
    ya_map__on_address identity

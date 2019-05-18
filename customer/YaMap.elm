port module YaMap exposing (destroy, init)


port ya_map__init : String -> Cmd msg


init : String -> Cmd msg
init =
    ya_map__init


port ya_map__destroy : () -> Cmd msg


destroy : Cmd msg
destroy =
    ya_map__destroy ()

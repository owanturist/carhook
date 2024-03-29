module Status exposing (Reason(..), Status(..), decoder)

import Http
import Json.Decode as Decode exposing (Decoder)
import Time


posixDecoder : Decoder Time.Posix
posixDecoder =
    Decode.map Time.millisToPosix Decode.int


type Reason
    = RulesFollowed
    | PhotosUnclear


reasonDecoder : Decoder Reason
reasonDecoder =
    Decode.andThen
        (\res ->
            case res of
                0 ->
                    Decode.succeed RulesFollowed

                1 ->
                    Decode.succeed PhotosUnclear

                _ ->
                    Decode.fail "Reason is invalid"
        )
        Decode.int


type Status
    = Ready
    | Accepted Time.Posix
    | Declined Time.Posix Reason
    | InProgress Time.Posix
    | Done Time.Posix


decoder : String -> Decoder Status
decoder field =
    Decode.andThen
        (\stat ->
            case stat of
                0 ->
                    Decode.succeed Ready

                1 ->
                    Decode.map Accepted
                        (Decode.field "update_time" posixDecoder)

                2 ->
                    Decode.map InProgress
                        (Decode.field "update_time" posixDecoder)

                3 ->
                    Decode.map Done
                        (Decode.field "update_time" posixDecoder)

                4 ->
                    Decode.map2 Declined
                        (Decode.field "update_time" posixDecoder)
                        (Decode.succeed PhotosUnclear)

                _ ->
                    Decode.fail ("Status " ++ String.fromInt stat ++ " is invalid")
        )
        (Decode.field field Decode.int)

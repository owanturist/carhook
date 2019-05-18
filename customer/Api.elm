module Api exposing (Reason(..), Report, Status(..), getListOfReports)

import Http
import ID exposing (ID)
import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)
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


statusDecoder : Decoder Status
statusDecoder =
    Decode.andThen
        (\type_ ->
            case type_ of
                "READY" ->
                    Decode.succeed Ready

                "ACCEPTED" ->
                    Decode.map Accepted
                        (Decode.field "date" posixDecoder)

                "DECLINED" ->
                    Decode.map2 Declined
                        (Decode.field "date" posixDecoder)
                        (Decode.field "reason" reasonDecoder)

                "IN_PROGRESS" ->
                    Decode.map InProgress
                        (Decode.field "date" posixDecoder)

                "DONE" ->
                    Decode.map Done
                        (Decode.field "date" posixDecoder)

                _ ->
                    Decode.fail "Status is invalid"
        )
        (Decode.field "type" Decode.string)


type alias Report =
    { id : ID { report : () }
    , date : Time.Posix
    , status : Status
    , number : Maybe String
    , comment : Maybe String
    , photos : List String
    }


reportDecoder : Decoder Report
reportDecoder =
    Decode.map6 Report
        (Decode.field "id" ID.decoder)
        (Decode.field "date" posixDecoder)
        (Decode.field "status" statusDecoder)
        (Decode.field "number" (Decode.nullable Decode.string))
        (Decode.field "comment" (Decode.nullable Decode.string))
        (Decode.field "photos" (Decode.list Decode.string))


getListOfReports : (Result Http.Error (List Report) -> msg) -> Cmd msg
getListOfReports tagger =
    [ Report
        (ID.fromInt 0)
        (Time.millisToPosix 100)
        Ready
        Nothing
        Nothing
        [ "http://lorempixel.com/400/300/transport/1"
        ]
    , Report
        (ID.fromInt 1)
        (Time.millisToPosix 200)
        (Accepted (Time.millisToPosix 500))
        Nothing
        (Just (String.repeat 10 "long comment "))
        [ "http://lorempixel.com/400/300/transport/2"
        ]
    , Report
        (ID.fromInt 2)
        (Time.millisToPosix 300)
        (Declined (Time.millisToPosix 400) PhotosUnclear)
        (Just "c800pa 54")
        Nothing
        [ "http://lorempixel.com/400/300/transport/3"
        ]
    , Report
        (ID.fromInt 2)
        (Time.millisToPosix 300)
        (InProgress (Time.millisToPosix 800))
        (Just "x123pp")
        (Just (String.repeat 5 "comment "))
        [ "http://lorempixel.com/400/300/transport/4"
        ]
    , Report
        (ID.fromInt 2)
        (Time.millisToPosix 300)
        (Done (Time.millisToPosix 1000))
        Nothing
        Nothing
        [ "http://lorempixel.com/400/300/transport/5"
        ]
    ]
        |> Ok
        |> tagger
        |> Task.succeed
        |> Task.perform identity

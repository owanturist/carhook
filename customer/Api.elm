module Api exposing (Reason(..), Report, Status(..), createRequest, getListOfReports, getReport)

import File exposing (File)
import Http
import ID exposing (ID)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Task exposing (Task)
import Time
import Url.Builder exposing (crossOrigin)


endpoint : String
endpoint =
    "http://carhook.ru/api"


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
        (\stat ->
            case stat of
                0 ->
                    Decode.succeed Ready

                1 ->
                    Decode.map Accepted
                        (Decode.field "date" posixDecoder)

                2 ->
                    Decode.map InProgress
                        (Decode.field "date" posixDecoder)

                3 ->
                    Decode.map Done
                        (Decode.field "date" posixDecoder)

                4 ->
                    Decode.map2 Declined
                        (Decode.field "date" posixDecoder)
                        (Decode.field "reason" reasonDecoder)

                _ ->
                    Decode.fail ("Status " ++ String.fromInt stat ++ " is invalid")
        )
        Decode.int


type alias Report =
    { id : ID { report : () }
    , date : Time.Posix
    , address : String
    , status : Status
    , number : Maybe String
    , comment : Maybe String
    , photos : List String
    }


reportDecoder : Decoder Report
reportDecoder =
    Decode.map7 Report
        (Decode.field "_id" ID.decoder)
        (Decode.field "create_time" posixDecoder)
        (Decode.field "address" Decode.string)
        (Decode.field "status" statusDecoder)
        (Decode.field "car_code" (Decode.nullable Decode.string))
        (Decode.field "comment" (Decode.nullable Decode.string))
        (Decode.field "photos" (Decode.list (Decode.map ((++) "http://carhook.ru") Decode.string)))


getReport : ID { report : () } -> Cmd (Result Http.Error Report)
getReport reportId =
    Http.request
        { method = "POST"
        , headers = []
        , url = crossOrigin endpoint [ "get_order" ] []
        , body =
            [ ( "id", ID.encoder reportId )
            ]
                |> Encode.object
                |> Http.jsonBody
        , expect = Http.expectJson identity reportDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


getListOfReports : Cmd (Result Http.Error (List Report))
getListOfReports =
    Http.request
        { method = "GET"
        , headers = []
        , url = crossOrigin endpoint [ "get_orders" ] []
        , body = Http.emptyBody
        , expect = Http.expectJson identity (Decode.list reportDecoder)
        , timeout = Nothing
        , tracker = Nothing
        }


createRequest :
    { address : String
    , number : String
    , comment : Maybe String
    , photos : List File
    }
    -> Cmd (Result Http.Error (ID { report : () }))
createRequest payload =
    Http.request
        { method = "POST"
        , headers = []
        , url = crossOrigin endpoint [ "create_order" ] []
        , body =
            [ case payload.comment of
                Nothing ->
                    []

                Just comment ->
                    [ Http.stringPart "comment" comment
                    ]
            , [ Http.stringPart "address" payload.address
              , Http.stringPart "car_code" payload.number
              , Http.stringPart "lat" "0"
              , Http.stringPart "lon" "0"
              ]
            , List.map (Http.filePart "photos[]") payload.photos
            ]
                |> List.concatMap identity
                |> Http.multipartBody
        , expect = Http.expectJson identity (Decode.field "id" ID.decoder)
        , timeout = Nothing
        , tracker = Nothing
        }

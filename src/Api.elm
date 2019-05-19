port module Api exposing
    ( Report
    , changeReportStatus
    , createRequest
    , getListOfReports
    , getReport
    , onChangeReport
    )

import File exposing (File)
import Http
import ID exposing (ID)
import Json.Decode as Decode exposing (Decoder, decodeValue)
import Json.Encode as Encode exposing (Value)
import Status exposing (Status)
import Task exposing (Task)
import Time
import Url.Builder exposing (crossOrigin)


endpoint : String
endpoint =
    "//carhook.ru/api"


posixDecoder : Decoder Time.Posix
posixDecoder =
    Decode.map Time.millisToPosix Decode.int


type alias Report =
    { id : ID { report : () }
    , date : Time.Posix
    , address : String
    , status : Status
    , number : String
    , comment : Maybe String
    , photos : List String
    }


reportDecoder : Decoder Report
reportDecoder =
    Decode.map7 Report
        (Decode.field "_id" ID.decoder)
        (Decode.field "create_time" posixDecoder)
        (Decode.field "address" Decode.string)
        (Status.decoder "status")
        (Decode.field "car_code" Decode.string)
        (Decode.maybe (Decode.field "comment" Decode.string))
        (Decode.field "photos" (Decode.list Decode.string))


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
        , tracker = Just "create"
        }


changeReportStatus : Int -> ID { report : () } -> Cmd (Result Http.Error Report)
changeReportStatus stat reportId =
    Http.request
        { method = "POST"
        , headers = []
        , url = crossOrigin endpoint [ "set_order_status" ] []
        , body =
            [ ( "id", ID.encoder reportId )
            , ( "status", Encode.int stat )
            ]
                |> Encode.object
                |> Http.jsonBody
        , expect = Http.expectJson identity reportDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


port api__on_change_report : (Value -> msg) -> Sub msg


onChangeReport : Sub (Result Decode.Error Report)
onChangeReport =
    api__on_change_report (decodeValue reportDecoder)

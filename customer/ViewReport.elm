module ViewReport exposing (Model, Msg, destroy, init, update, view)

import Api
import Error
import Html exposing (Html, div, text)
import Html.Attributes
import Http
import ID exposing (ID)
import RemoteData exposing (RemoteData(..))
import YaMap



-- M O D E L


type alias Model =
    { report : RemoteData Http.Error Api.Report
    }


init : ID { report : () } -> ( Model, Cmd Msg )
init reportId =
    ( Model Loading
    , Cmd.batch
        [ Cmd.map GetReportDone (Api.getReport reportId)
        , YaMap.init "ya-map" False
        ]
    )


destroy : Cmd Msg
destroy =
    YaMap.destroy



-- U P D A T E


type Msg
    = GetReportDone (Result Http.Error Api.Report)


update : Msg -> ID { report : () } -> Model -> ( Model, Cmd Msg )
update msg reportId model =
    case msg of
        GetReportDone (Err err) ->
            ( { model | report = Failure err }
            , Cmd.none
            )

        GetReportDone (Ok report) ->
            ( { model | report = Success report }
            , YaMap.setAddress report.address
            )



-- V I E W


view : Model -> Html Msg
view model =
    case model.report of
        Failure error ->
            div [ Html.Attributes.class "container-fluid my-3" ] [ Error.view error ]

        Success report ->
            div
                []
                [ div
                    [ Html.Attributes.class "bg-light"
                    , Html.Attributes.id "ya-map"
                    , Html.Attributes.style "width" "100%"
                    , Html.Attributes.style "height" "300px"
                    ]
                    []
                , div
                    [ Html.Attributes.class "container-fluid my-3"
                    ]
                    [ text (ID.toString report.id)
                    ]
                ]

        _ ->
            div [] []

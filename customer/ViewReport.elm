module ViewReport exposing (Model, Msg, init, subscriptions, update, view)

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
    , Cmd.map GetReportDone (Api.getReport reportId)
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
        GetReportDone result ->
            ( { model | report = RemoteData.fromResult result }
            , Cmd.none
            )



-- S U B S C R I P T O N


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- V I E W


view : Model -> Html Msg
view model =
    case model.report of
        Failure error ->
            div [ Html.Attributes.class "container-fluid" ] [ Error.view error ]

        Success report ->
            div [] [ text (ID.toString report.id) ]

        _ ->
            div [] []

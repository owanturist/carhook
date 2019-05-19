module ViewReport exposing (Model, Msg, destroy, init, update, view, subscriptions)

import Api
import Error
import Html exposing (Html, button, div, form, i, img, label, q, span, text)
import Html.Attributes
import Http
import ID exposing (ID)
import Json.Decode as Decode
import RemoteData exposing (RemoteData(..))
import StatusPanel
import YaMap



-- M O D E L


type alias Model =
    { report : RemoteData Http.Error Api.Report
    , statusPanel : StatusPanel.Model
    }


init : ID { report : () } -> ( Model, Cmd Msg )
init reportId =
    ( Model Loading StatusPanel.initial
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
    | StatusPanelMsg StatusPanel.Msg
    | OnReportChanged (Result Decode.Error Api.Report)


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

        StatusPanelMsg msgOfStatusPanel ->
            let
                updateStatusPanel mod cmd stage =
                    case stage of
                        StatusPanel.Updated ( nextStatusPanel, cmdOfStatusPanel ) ->
                            ( { mod | statusPanel = nextStatusPanel }
                            , Cmd.batch
                                [ Cmd.map StatusPanelMsg cmdOfStatusPanel
                                , cmd
                                ]
                            )

                        StatusPanel.StatusChanged updatedReport subStage ->
                            updateStatusPanel { mod | report = Success updatedReport } cmd subStage
            in
            updateStatusPanel model Cmd.none (StatusPanel.update msgOfStatusPanel reportId model.statusPanel)

        OnReportChanged (Err err) ->
            ( { model | report = Failure (Http.BadBody (Decode.errorToString err)) }
            , Cmd.none
            )

        OnReportChanged (Ok report) ->
            ( { model | report = Success report }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map OnReportChanged Api.onChangeReport



-- V I E W


viewPhoto : String -> Html msg
viewPhoto uri =
    div
        [ Html.Attributes.class "col-sm-3 col-4"
        ]
        [ img
            [ Html.Attributes.class "img-thumbnail"
            , Html.Attributes.src uri
            ]
            []
        ]


view : Bool -> Model -> Html Msg
view isCustomer model =
    case model.report of
        Failure error ->
            div [ Html.Attributes.class "view-report container-fluid my-3" ] [ Error.view error ]

        Success report ->
            div
                [ Html.Attributes.class "view-report" ]
                [ div
                    [ Html.Attributes.class "bg-light"
                    , Html.Attributes.id "ya-map"
                    , Html.Attributes.style "width" "100%"
                    , Html.Attributes.style "height" "300px"
                    ]
                    []
                , form
                    [ Html.Attributes.class "container-fluid my-3"
                    , Html.Attributes.novalidate True
                    ]
                    [ div
                        [ Html.Attributes.class "form-group"
                        ]
                        [ Html.map StatusPanelMsg (StatusPanel.view isCustomer report.status model.statusPanel)
                        ]
                    , div
                        [ Html.Attributes.class "form-group"
                        ]
                        [ label [ Html.Attributes.class "small" ] [ text "Адрес:" ]
                        , span
                            [ Html.Attributes.class "form-control-plaintext"
                            ]
                            [ text report.address ]
                        ]
                    , div
                        [ Html.Attributes.class "form-group"
                        ]
                        [ label [ Html.Attributes.class "small" ] [ text "Фото транспортного средства:" ]
                        , div
                            [ Html.Attributes.class "form-group row mb-0"
                            ]
                            (List.map viewPhoto report.photos)
                        ]
                    , div
                        [ Html.Attributes.class "form-group"
                        ]
                        [ label [ Html.Attributes.class "small" ] [ text "Гос номер:" ]
                        , span
                            [ Html.Attributes.class "form-control-plaintext"
                            ]
                            [ text report.number ]
                        ]
                    , case report.comment of
                        Nothing ->
                            text ""

                        Just comment ->
                            div
                                [ Html.Attributes.class "form-group"
                                ]
                                [ label [ Html.Attributes.class "small" ] [ text "Комментарий:" ]
                                , span
                                    [ Html.Attributes.class "form-control-plaintext"
                                    ]
                                    [ text comment ]
                                ]
                    ]
                ]

        _ ->
            div [] []

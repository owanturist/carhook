module Home exposing (Model, Msg, init, update, view)

import Api
import Dict exposing (Dict)
import Error
import Html exposing (Html, a, button, div, h5, i, img, p, q, small, span, text)
import Html.Attributes
import Http
import ID exposing (ID)
import RemoteData exposing (RemoteData(..))
import Router
import StatusPanel
import Time
import Time.Format
import Time.Format.Config.Config_ru_ru



-- M O D E L


type alias Model =
    { reports : RemoteData Http.Error (List (ID { report : () }))
    , reportsDict : Dict String Api.Report
    , statusPanels : Dict String StatusPanel.Model
    }


init : ( Model, Cmd Msg )
init =
    ( Model Loading Dict.empty Dict.empty
    , Cmd.map GetListOfReportsDone Api.getListOfReports
    )



-- U P D A T E


type Msg
    = GetListOfReportsDone (Result Http.Error (List Api.Report))
    | StatusPanelMsg (ID { report : () }) StatusPanel.Msg


insertToDict : { entity | id : ID supported } -> Dict String { entity | id : ID supported } -> Dict String { entity | id : ID supported }
insertToDict entity dict =
    Dict.insert (ID.toString entity.id) entity dict


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetListOfReportsDone (Err error) ->
            ( { model | reports = Failure error }
            , Cmd.none
            )

        GetListOfReportsDone (Ok reports) ->
            let
                reportsDict =
                    List.foldr insertToDict Dict.empty reports
            in
            ( { model
                | reports = Success (List.map .id reports)
                , reportsDict = reportsDict
              }
            , Cmd.none
            )

        StatusPanelMsg reportId msgOfStatusPanel ->
            let
                updateStatusPanel mod cmd stage =
                    case stage of
                        StatusPanel.Updated ( nextStatusPanel, cmdOfStatusPanel ) ->
                            ( { mod | statusPanels = Dict.insert (ID.toString reportId) nextStatusPanel mod.statusPanels }
                            , Cmd.batch
                                [ Cmd.map (StatusPanelMsg reportId) cmdOfStatusPanel
                                , cmd
                                ]
                            )

                        StatusPanel.StatusChanged updatedReport subStage ->
                            updateStatusPanel
                                { mod | reportsDict = insertToDict updatedReport mod.reportsDict }
                                cmd
                                subStage
            in
            Dict.get (ID.toString reportId) model.statusPanels
                |> Maybe.withDefault StatusPanel.initial
                |> StatusPanel.update msgOfStatusPanel reportId
                |> updateStatusPanel model Cmd.none



-- V I E W


posixToFullDate : Time.Posix -> String
posixToFullDate posix =
    Time.Format.format Time.Format.Config.Config_ru_ru.config
        "%-@d %B %Y, %A, %H:%M"
        Time.utc
        posix


viewReportCard : StatusPanel.Model -> Api.Report -> Html Msg
viewReportCard statusPanel report =
    div
        [ Html.Attributes.class "card bg-light my-3"
        ]
        [ a
            [ Html.Attributes.class "home__card-link"
            , Html.Attributes.href (Router.toString (Router.ToViewReport report.id))
            , Html.Attributes.tabindex 1
            ]
            []
        , div
            [ Html.Attributes.class "row no-gutters"
            ]
            [ div
                [ Html.Attributes.class "col-sm-4"
                ]
                [ case List.head report.photos of
                    Nothing ->
                        text ""

                    Just photo ->
                        div
                            [ Html.Attributes.class "home__card-photo"
                            , Html.Attributes.style "background-image" ("url(" ++ photo ++ ")")
                            ]
                            []
                ]
            , div
                [ Html.Attributes.class "col-sm-8"
                ]
                [ div
                    [ Html.Attributes.class "card-header"
                    ]
                    [ Html.map (StatusPanelMsg report.id) (StatusPanel.view True report.status statusPanel)
                    ]
                , case report.comment of
                    Nothing ->
                        div
                            [ Html.Attributes.class "card-body"
                            ]
                            [ h5 [ Html.Attributes.class "card-title m-0" ] [ text report.number ]
                            ]

                    Just comment ->
                        div
                            [ Html.Attributes.class "card-body"
                            ]
                            [ h5 [ Html.Attributes.class "card-title" ] [ text report.number ]
                            , p [ Html.Attributes.class "cart-text mb-0" ] [ text comment ]
                            ]
                , div
                    [ Html.Attributes.class "card-footer"
                    ]
                    [ small [ Html.Attributes.class "text-muted" ] [ text (posixToFullDate report.date) ]
                    ]
                ]
            ]
        ]


view : Model -> Html Msg
view model =
    case model.reports of
        Failure error ->
            div
                [ Html.Attributes.class "home container-fluid my-3"
                ]
                [ Error.view error
                ]

        Success reports ->
            div
                [ Html.Attributes.class "home container-fluid"
                ]
                (List.filterMap
                    (\reportId ->
                        Maybe.map
                            (viewReportCard
                                (Maybe.withDefault StatusPanel.initial (Dict.get (ID.toString reportId) model.statusPanels))
                            )
                            (Dict.get (ID.toString reportId) model.reportsDict)
                    )
                    reports
                )

        _ ->
            div [] []

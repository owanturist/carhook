module StatusPanel exposing (Model, Msg, Stage(..), initial, update, view)

import Api
import Error
import Html exposing (Html, button, div, form, i, img, label, q, span, text)
import Html.Attributes
import Html.Events
import Http
import ID exposing (ID)
import RemoteData exposing (RemoteData(..))
import Status exposing (Reason(..), Status(..))
import Time
import Time.Format
import Time.Format.Config.Config_ru_ru



-- M O D E L


type alias Model =
    { aborting : RemoteData Http.Error Never
    }


initial : Model
initial =
    Model NotAsked



-- U P D A T E


type Msg
    = ChangeStatus Int
    | ChangeStatusDone (Result Http.Error Api.Report)


type Stage
    = Updated ( Model, Cmd Msg )
    | StatusChanged Api.Report Stage


update : Msg -> ID { report : () } -> Model -> Stage
update msg reportId model =
    case msg of
        ChangeStatus nextStatus ->
            Updated
                ( { model | aborting = Loading }
                , Cmd.map ChangeStatusDone (Api.changeReportStatus nextStatus reportId)
                )

        ChangeStatusDone (Err error) ->
            Updated
                ( { model | aborting = Failure error }
                , Cmd.none
                )

        ChangeStatusDone (Ok report) ->
            Updated ( initial, Cmd.none )
                |> StatusChanged report



-- V I E W


posixToShortDate : Time.Posix -> String
posixToShortDate posix =
    Time.Format.format Time.Format.Config.Config_ru_ru.config
        "%H:%M"
        Time.utc
        posix


view : Bool -> Status -> Model -> Html Msg
view isCustomer status model =
    case status of
        Ready ->
            case model.aborting of
                Failure error ->
                    Error.view error

                _ ->
                    div
                        [ Html.Attributes.class "status-panel_justify"
                        ]
                        [ span
                            []
                            [ i [ Html.Attributes.class "fa fa-lg fa-map mr-2" ] []
                            , text "Ожидает транспортировки"
                            ]
                        , span
                            []
                            [ if isCustomer then
                                text ""

                              else
                                button
                                    [ Html.Attributes.class "status-panel__el-over btn btn-sm btn-success ml-2"
                                    , Html.Attributes.type_ "button"
                                    , Html.Attributes.disabled (RemoteData.isLoading model.aborting)
                                    , Html.Attributes.tabindex 1
                                    , Html.Events.onClick (ChangeStatus 1)
                                    ]
                                    [ i [ Html.Attributes.class "fa fa-fw fa-clipboard-check" ] []
                                    ]
                            , button
                                [ Html.Attributes.class "status-panel__el-over btn btn-sm btn-danger ml-2"
                                , Html.Attributes.type_ "button"
                                , Html.Attributes.disabled (RemoteData.isLoading model.aborting)
                                , Html.Attributes.tabindex 1
                                , Html.Events.onClick (ChangeStatus 4)
                                ]
                                [ i [ Html.Attributes.class "fa fa-fw fa-ban" ] []
                                ]
                            ]
                        ]

        Accepted startDate ->
            div
                [ Html.Attributes.class "status-panel_justify"
                ]
                [ span []
                    [ i [ Html.Attributes.class "fa fa-lg fa-shipping-fast mr-2" ] []
                    , text ("Эвакуатор в пути c " ++ posixToShortDate startDate)
                    ]
                , span
                    []
                    [ if isCustomer then
                        text ""

                      else
                        button
                            [ Html.Attributes.class "status-panel__el-over btn btn-sm btn-success ml-2"
                            , Html.Attributes.type_ "button"
                            , Html.Attributes.disabled (RemoteData.isLoading model.aborting)
                            , Html.Attributes.tabindex 1
                            , Html.Events.onClick (ChangeStatus 2)
                            ]
                            [ i [ Html.Attributes.class "fa fa-fw fa-truck-loading" ] []
                            ]
                    , button
                        [ Html.Attributes.class "status-panel__el-over btn btn-sm btn-danger ml-2"
                        , Html.Attributes.type_ "button"
                        , Html.Attributes.disabled (RemoteData.isLoading model.aborting)
                        , Html.Attributes.tabindex 1
                        , Html.Events.onClick (ChangeStatus 4)
                        ]
                        [ i [ Html.Attributes.class "fa fa-fw fa-ban" ] []
                        ]
                    ]
                ]

        Declined stopDate reason ->
            div []
                [ div
                    []
                    [ i [ Html.Attributes.class "fa fa-lg fa-ban mr-2 text-danger" ] []
                    , text ("Запрос отклонён в " ++ posixToShortDate stopDate)
                    ]
                , q
                    [ Html.Attributes.class "blockquote-footer"
                    ]
                    [ case reason of
                        RulesFollowed ->
                            text "Правила не нарушены"

                        PhotosUnclear ->
                            text "Фото не исчерпывающие"
                    ]
                ]

        InProgress startDate ->
            div
                [ Html.Attributes.class "status-panel_justify"
                ]
                [ span []
                    [ i [ Html.Attributes.class "fa fa-lg fa-truck-loading mr-2" ] []
                    , text ("Эвакуация началась в " ++ posixToShortDate startDate)
                    ]
                , if isCustomer then
                    text ""

                  else
                    span
                        []
                        [ button
                            [ Html.Attributes.class "status-panel__el-over btn btn-sm btn-success ml-2"
                            , Html.Attributes.type_ "button"
                            , Html.Attributes.disabled (RemoteData.isLoading model.aborting)
                            , Html.Attributes.tabindex 1
                            , Html.Events.onClick (ChangeStatus 3)
                            ]
                            [ i [ Html.Attributes.class "fa fa-fw fa-clipboard-check" ] []
                            ]
                        , button
                            [ Html.Attributes.class "status-panel__el-over btn btn-sm btn-danger ml-2"
                            , Html.Attributes.type_ "button"
                            , Html.Attributes.disabled (RemoteData.isLoading model.aborting)
                            , Html.Attributes.tabindex 1
                            , Html.Events.onClick (ChangeStatus 4)
                            ]
                            [ i [ Html.Attributes.class "fa fa-fw fa-ban" ] []
                            ]
                        ]
                ]

        Done endDate ->
            span []
                [ i [ Html.Attributes.class "fa fa-lg fa-clipboard-check mr-2 text-success" ] []
                , text ("Эвакуирован в " ++ posixToShortDate endDate)
                ]

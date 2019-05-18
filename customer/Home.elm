module Home exposing (Model, Msg, init, update, view)

import Api
import Html exposing (Html, a, div, h5, i, img, p, q, small, span, text)
import Html.Attributes
import Http
import RemoteData exposing (RemoteData(..))
import Router
import Time
import Time.Format
import Time.Format.Config.Config_ru_ru



-- M O D E L


type alias Model =
    { reports : RemoteData Http.Error (List Api.Report)
    }


init : ( Model, Cmd Msg )
init =
    ( Model Loading
    , Api.getListOfReports GetListOfReportsDone
    )



-- U P D A T E


type Msg
    = GetListOfReportsDone (Result Http.Error (List Api.Report))


update : Msg -> Model -> Model
update msg model =
    case msg of
        GetListOfReportsDone result ->
            { model | reports = RemoteData.fromResult result }



-- V I E W


posixToFullDate : Time.Posix -> String
posixToFullDate posix =
    Time.Format.format Time.Format.Config.Config_ru_ru.config
        "%H:%M, %-@d %B %Y %A"
        Time.utc
        posix


posixToShortDate : Time.Posix -> String
posixToShortDate posix =
    Time.Format.format Time.Format.Config.Config_ru_ru.config
        "%H:%M"
        Time.utc
        posix


viewReportStatus : Api.Status -> Html Msg
viewReportStatus status =
    case status of
        Api.Ready ->
            span []
                [ i [ Html.Attributes.class "fa fa-lg fa-map mr-2" ] []
                , text "Ожидает транспортировки"
                ]

        Api.Accepted startDate ->
            span []
                [ i [ Html.Attributes.class "fa fa-lg fa-shipping-fast mr-2" ] []
                , text ("Эвакуатор в пути c " ++ posixToShortDate startDate)
                ]

        Api.Declined stopDate reason ->
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
                        Api.RulesFollowed ->
                            text "Правила не нарушены"

                        Api.PhotosUnclear ->
                            text "Фото не исчерпывающие"
                    ]
                ]

        Api.InProgress startDate ->
            span []
                [ i [ Html.Attributes.class "fa fa-lg fa-truck-loading mr-2" ] []
                , text ("Эвакуация началась в " ++ posixToShortDate startDate)
                ]

        Api.Done endDate ->
            span []
                [ i [ Html.Attributes.class "fa fa-lg fa-clipboard-check mr-2" ] []
                , text ("Эвакуирован в " ++ posixToShortDate endDate)
                ]


viewReportCard : Api.Report -> Html Msg
viewReportCard report =
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
                    [ viewReportStatus report.status
                    ]
                , case ( report.number, report.comment ) of
                    ( Nothing, Nothing ) ->
                        text ""

                    ( Nothing, Just comment ) ->
                        div
                            [ Html.Attributes.class "card-body"
                            ]
                            [ p [ Html.Attributes.class "cart-text mb-0" ] [ text comment ]
                            ]

                    ( Just number, Nothing ) ->
                        div
                            [ Html.Attributes.class "card-body"
                            ]
                            [ h5 [ Html.Attributes.class "card-title m-0" ] [ text number ]
                            ]

                    ( Just number, Just comment ) ->
                        div
                            [ Html.Attributes.class "card-body"
                            ]
                            [ h5 [ Html.Attributes.class "card-title" ] [ text "title" ]
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
        Success reports ->
            div
                [ Html.Attributes.class "home container-fluid"
                ]
                (List.map viewReportCard reports)

        _ ->
            div [] []

module Main exposing (main)

import Browser
import Browser.Navigation
import CreateReport
import Glob exposing (Glob)
import Home
import Html exposing (Html, a, div, form, i, nav, text)
import Html.Attributes
import ID exposing (ID)
import Router
import Url exposing (Url)
import ViewReport



-- F L A G S


type alias Flags =
    {}



-- M O D E L


type Page
    = Void
    | HomePage Home.Model
    | CreateReportPage CreateReport.Model
    | ViewReportPage (ID { report : () }) ViewReport.Model


initPage : Glob -> Router.Route -> ( Page, Cmd Msg )
initPage glob route =
    case route of
        Router.ToHome ->
            Tuple.mapBoth HomePage (Cmd.map HomeMsg) Home.init

        Router.ToCreateReport ->
            Tuple.mapBoth CreateReportPage (Cmd.map CreateReportMsg) CreateReport.init

        Router.ToViewReport reportId ->
            Tuple.mapBoth (ViewReportPage reportId) (Cmd.map ViewReportMsg) (ViewReport.init reportId)

        Router.ToNotFound ->
            ( Void, Router.replace glob.key Router.ToHome )


type Model
    = Model Glob Page


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags initialUrl key =
    let
        glob =
            Glob key
    in
    Tuple.mapFirst (Model glob) (initPage glob (Router.parse initialUrl))



-- M S G


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url
    | HomeMsg Home.Msg
    | CreateReportMsg CreateReport.Msg
    | ViewReportMsg ViewReport.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( UrlRequested (Browser.Internal url), Model glob page ) ->
            ( model
            , Cmd.batch
                [ case page of
                    CreateReportPage _ ->
                        Cmd.map CreateReportMsg CreateReport.destroy

                    ViewReportPage _ _ ->
                        Cmd.map ViewReportMsg ViewReport.destroy

                    _ ->
                        Cmd.none
                , Browser.Navigation.pushUrl glob.key (Url.toString url)
                ]
            )

        ( UrlRequested (Browser.External uri), _ ) ->
            ( model
            , Browser.Navigation.load uri
            )

        ( UrlChanged url, Model glob page ) ->
            Tuple.mapFirst (Model glob) (initPage glob (Router.parse url))

        ( HomeMsg msgOfHome, Model glob (HomePage homePage) ) ->
            Tuple.mapBoth (Model glob << HomePage) (Cmd.map HomeMsg) (Home.update msgOfHome homePage)

        ( HomeMsg _, _ ) ->
            ( model, Cmd.none )

        ( CreateReportMsg msgOfCreateReport, Model glob (CreateReportPage createReportPage) ) ->
            let
                ( nextCreateReport, cmdOfCreateReport ) =
                    CreateReport.update msgOfCreateReport glob createReportPage
            in
            ( Model glob (CreateReportPage nextCreateReport)
            , Cmd.map CreateReportMsg cmdOfCreateReport
            )

        ( CreateReportMsg _, _ ) ->
            ( model, Cmd.none )

        ( ViewReportMsg msgOfViewReport, Model glob (ViewReportPage viewReportId viewReportPage) ) ->
            let
                ( nextViewReportPage, cmdOfViewReport ) =
                    ViewReport.update msgOfViewReport viewReportId viewReportPage
            in
            ( Model glob (ViewReportPage viewReportId nextViewReportPage)
            , Cmd.map ViewReportMsg cmdOfViewReport
            )

        ( ViewReportMsg _, _ ) ->
            ( model, Cmd.none )



-- S U B S C R I P T I O N S


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.map CreateReportMsg CreateReport.subscriptions



-- V I E W


viewNav : Html msg
viewNav =
    nav
        [ Html.Attributes.class "main__nav navbar navbar-light bg-light"
        ]
        [ a
            [ Html.Attributes.class "main__logo navbar-brand"
            , Html.Attributes.href (Router.toString Router.ToHome)
            , Html.Attributes.tabindex 1
            ]
            [ text "c a r "
            , i [ Html.Attributes.class "fa fa-car" ] []
            , text " h o o k"
            ]
        , a
            [ Html.Attributes.class "btn btn-warning text-light"
            , Html.Attributes.href (Router.toString Router.ToCreateReport)
            , Html.Attributes.tabindex 1
            ]
            [ i [ Html.Attributes.class "fa fa-shipping-fast" ] []
            ]
        ]


view : Model -> Browser.Document Msg
view (Model glob page) =
    Browser.Document "Car Hook"
        [ div
            [ Html.Attributes.class "main"
            ]
            [ viewNav
            , case page of
                Void ->
                    text ""

                HomePage homePage ->
                    Html.map HomeMsg (Home.view homePage)

                CreateReportPage createReportPage ->
                    Html.map CreateReportMsg (CreateReport.view createReportPage)

                ViewReportPage reportId viewReportPage ->
                    Html.map ViewReportMsg (ViewReport.view True viewReportPage)
            ]
        ]



-- M A I N


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = UrlRequested
        }

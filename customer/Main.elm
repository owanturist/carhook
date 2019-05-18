module Main exposing (main)

import Browser
import Browser.Navigation
import Glob exposing (Glob)
import Home
import Html exposing (Html, a, div, form, i, nav, text)
import Html.Attributes
import ID exposing (ID)
import Router
import Url exposing (Url)



-- F L A G S


type alias Flags =
    {}



-- M O D E L


type Page
    = HomePage Home.Model
    | CreateReportPage
    | ViewReportPage (ID { report : () })


initPage : Router.Route -> ( Page, Cmd Msg )
initPage route =
    case route of
        Router.ToHome ->
            Tuple.mapBoth HomePage (Cmd.map HomeMsg) Home.init

        _ ->
            Debug.todo "initPage "


type Model
    = Model Glob Page


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags initialUrl key =
    let
        ( initialPage, initialCmdOfPage ) =
            initPage (Router.parse initialUrl)
    in
    ( Model (Glob key) initialPage, initialCmdOfPage )



-- M S G


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url
    | HomeMsg Home.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( UrlRequested (Browser.Internal url), Model glob _ ) ->
            ( model
            , Browser.Navigation.pushUrl glob.key (Url.toString url)
            )

        ( UrlRequested (Browser.External uri), _ ) ->
            ( model
            , Browser.Navigation.load uri
            )

        ( UrlChanged url, Model _ _ ) ->
            ( model, Cmd.none )

        ( HomeMsg msgOfHome, Model glob (HomePage homePage) ) ->
            ( Model glob (HomePage (Home.update msgOfHome homePage))
            , Cmd.none
            )

        ( HomeMsg _, _ ) ->
            ( model, Cmd.none )



-- S U B S C R I P T I O N S


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- V I E W


viewNav : Html msg
viewNav =
    nav
        [ Html.Attributes.class "main__nav navbar navbar-dark bg-dark"
        ]
        [ a
            [ Html.Attributes.class "navbar-brand"
            , Html.Attributes.href (Router.toString Router.ToHome)
            , Html.Attributes.tabindex 1
            ]
            [ i [ Html.Attributes.class "fa fa-car" ] []
            , text " h o o k"
            ]
        , a
            [ Html.Attributes.class "btn btn-warning text-dark"
            , Html.Attributes.href (Router.toString Router.ToCreateReport)
            , Html.Attributes.tabindex 1
            ]
            [ i [ Html.Attributes.class "fa fa-plus" ] []
            ]
        ]


view : Model -> Browser.Document Msg
view (Model glob page) =
    Browser.Document "Car Hook"
        [ div
            [ Html.Attributes.class "main bg-secondary"
            ]
            [ viewNav
            , case page of
                HomePage homePage ->
                    Html.map HomeMsg (Home.view homePage)

                _ ->
                    Debug.todo "view"

            -- , div
            --     [ Html.Attributes.class "main__content"
            --     ]
            --     []
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

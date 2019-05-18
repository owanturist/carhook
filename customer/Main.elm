module Main exposing (main)

import Browser
import Browser.Navigation
import Html exposing (Html, div, text)
import ID exposing (ID)
import Router
import Url exposing (Url)



-- F L A G S


type alias Flags =
    {}



-- M O D E L


type Page
    = HomePage
    | CreateReportPage
    | ViewReportPage (ID { report : () })


initPage : Router.Route -> ( Page, Cmd Msg )
initPage route =
    ( HomePage, Cmd.none )


type alias Model =
    { key : Browser.Navigation.Key
    , page : Page
    }


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags initialUrl key =
    let
        ( initialPage, initialCmdOfPage ) =
            initPage (Router.parse initialUrl)
    in
    ( Model key initialPage, initialCmdOfPage )



-- M S G


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlRequested (Browser.Internal url) ->
            ( model
            , Browser.Navigation.pushUrl model.key (Url.toString url)
            )

        UrlRequested (Browser.External uri) ->
            ( model
            , Browser.Navigation.load uri
            )

        UrlChanged url ->
            ( model, Cmd.none )



-- S U B S C R I P T I O N S


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- V I E W


view : Model -> Browser.Document Msg
view model =
    Browser.Document "Car Hook"
        [ text "hi!"
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

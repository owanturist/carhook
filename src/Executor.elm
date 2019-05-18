module Executor exposing (main)

import Browser
import Browser.Navigation
import Glob exposing (Glob)
import Html exposing (Html, a, div, form, i, nav, text)
import Html.Attributes
import ID exposing (ID)
import Url exposing (Url)



-- M O D E L


type Page
    = Page


type Model
    = Model Glob Page


init : () -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags initialUrl key =
    let
        glob =
            Glob key
    in
    ( Model glob Page, Cmd.none )



-- U P D A T E


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg (Model glob page) =
    case ( msg, page ) of
        ( UrlRequested (Browser.Internal url), _ ) ->
            ( Model glob page
            , Browser.Navigation.pushUrl glob.key (Url.toString url)
            )

        ( UrlRequested (Browser.External uri), _ ) ->
            ( Model glob page
            , Browser.Navigation.load uri
            )

        ( UrlChanged url, _ ) ->
            ( Model glob page
            , Cmd.none
            )



-- S U B S C R I P T I O N


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- V I E W


view : Model -> Browser.Document Msg
view model =
    Browser.Document "Car Hook | Executor"
        [text "hi"]



-- M A I N


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = UrlRequested
        }

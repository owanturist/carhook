module Customer exposing (main)

import Browser
import Browser.Navigation
import Html exposing (Html, div, text)
import Url exposing (Url)



-- F L A G S


type alias Flags =
    {}



-- M O D E L


type alias Model =
    {}


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags initialUrl key =
    ( {}, Cmd.none )



-- M S G


type Msg
    = OnUrlRequest Browser.UrlRequest
    | OnUrlChange Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
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
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        }

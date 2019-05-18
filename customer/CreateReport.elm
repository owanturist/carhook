module CreateReport exposing (Model, Msg, init, update, view, destroy)

import Html exposing (Html, div, text)
import Html.Attributes
import YaMap



-- M O D E L


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}
    , YaMap.init
    )


destroy : Cmd Msg
destroy =
    YaMap.destroy



-- U P D A T E


type Msg
    = NoOp


update : Msg -> Model -> Model
update msg model =
    model



-- V I E W


view : Model -> Html Msg
view model =
    div
        []
        [ div
            [ Html.Attributes.id "ya-map"
            , Html.Attributes.style "width" "100%"
            , Html.Attributes.style "height" "300px"
            ]
            []
        ]

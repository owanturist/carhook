module CreateReport exposing (Model, Msg, init, update, view)

import Html exposing (Html, div, text)



-- M O D E L


type alias Model =
    {}


init : Model
init =
    {}



-- U P D A T E


type Msg
    = NoOp


update : Msg -> Model -> Model
update msg model =
    model



-- V I E W


view : Model -> Html Msg
view model =
    div [] [text "Create"]

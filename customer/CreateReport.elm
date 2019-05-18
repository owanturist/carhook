module CreateReport exposing (Model, Msg, destroy, init, update, view)

import File exposing (File)
import Html exposing (Html, button, div, form, i, img, input, label, text, textarea)
import Html.Attributes
import Html.Events
import Json.Decode as Decode
import Task
import YaMap



-- M O D E L


type alias Model =
    { number : String
    , comment : String
    , photos : List ( File, String )
    }


init : ( Model, Cmd Msg )
init =
    ( Model "" "" []
    , YaMap.init "ya-map"
    )


destroy : Cmd Msg
destroy =
    YaMap.destroy



-- U P D A T E


type Msg
    = ChangeNumber String
    | ChangeComment String
    | UploadFiles (List File)
    | PreviewFiles (List ( File, String ))
    | DeleteFile Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeNumber nextNumber ->
            ( { model | number = nextNumber }
            , Cmd.none
            )

        ChangeComment nextComment ->
            ( { model | comment = nextComment }
            , Cmd.none
            )

        UploadFiles files ->
            ( model
            , List.map (\file -> Task.map (Tuple.pair file) (File.toUrl file))
                files
                |> Task.sequence
                |> Task.perform PreviewFiles
            )

        PreviewFiles pairs ->
            ( { model | photos = List.take 6 (model.photos ++ pairs) }
            , Cmd.none
            )

        DeleteFile index ->
            ( { model | photos = List.take index model.photos ++ List.drop (index + 1) model.photos }
            , Cmd.none
            )



-- V I E W


viewPhoto : Int -> ( File, String ) -> Html Msg
viewPhoto index ( file, base64 ) =
    div
        [ Html.Attributes.class "col-sm-3 col-4 mt-3"
        ]
        [ img
            [ Html.Attributes.class "img-thumbnail"
            , Html.Attributes.src base64
            , Html.Events.onClick (DeleteFile index)
            ]
            []
        ]


viewAddPhoto : Html Msg
viewAddPhoto =
    div
        [ Html.Attributes.class "col-sm-3 col-4 mt-3"
        ]
        [ label
            [ Html.Attributes.class "card"
            ]
            [ i [ Html.Attributes.class "fa fa-plus fa-3x p-3 text-center text-primary" ] []
            , input
                [ Html.Attributes.class "create-report__file-input"
                , Html.Attributes.type_ "file"
                , Html.Attributes.multiple True
                , Html.Events.on "change"
                    (Decode.list File.decoder
                        |> Decode.at [ "target", "files" ]
                        |> Decode.map UploadFiles
                    )
                ]
                []
            ]
        ]


view : Model -> Html Msg
view model =
    div
        [ Html.Attributes.class "create-report"
        ]
        [ div
            [ Html.Attributes.class "bg-secondary"
            , Html.Attributes.id "ya-map"
            , Html.Attributes.style "width" "100%"
            , Html.Attributes.style "height" "300px"
            ]
            []
        , form
            [ Html.Attributes.class "container-fluid mb-3"
            , Html.Attributes.novalidate True
            ]
            [ if List.length model.photos < 6 then
                div
                    [ Html.Attributes.class "form-group row"
                    ]
                    (viewAddPhoto :: List.indexedMap viewPhoto model.photos)

              else
                div
                    [ Html.Attributes.class "form-group row"
                    ]
                    (List.indexedMap viewPhoto model.photos)
            , div
                [ Html.Attributes.class "form-group"
                ]
                [ label [] [ text "Гос номер" ]
                , input
                    [ Html.Attributes.class "form-control"
                    , Html.Attributes.type_ "text"
                    , Html.Attributes.value model.number
                    , Html.Attributes.placeholder "е777кх 154"
                    , Html.Attributes.required True
                    , Html.Events.onInput ChangeNumber
                    ]
                    []
                ]
            , div
                [ Html.Attributes.class "form-group"
                ]
                [ label [] [ text "Комментарий" ]
                , textarea
                    [ Html.Attributes.class "form-control"
                    , Html.Attributes.value model.comment
                    , Html.Attributes.rows 4
                    , Html.Attributes.placeholder "Любые детали и уточенения"
                    , Html.Events.onInput ChangeComment
                    ]
                    []
                ]
            , button
                [ Html.Attributes.class "btn btn-block btn-success"
                ]
                [ i [ Html.Attributes.class "fa fa-paper-plane mr-2" ] []
                , text "Отправить"
                ]
            ]
        ]

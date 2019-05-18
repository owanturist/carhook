module CreateReport exposing (Model, Msg, destroy, init, subscriptions, update, view)

import Api
import File exposing (File)
import Glob exposing (Glob)
import Html exposing (Html, br, button, code, div, form, i, img, input, label, text, textarea)
import Html.Attributes
import Html.Events
import Http
import ID exposing (ID)
import Json.Decode as Decode
import RemoteData exposing (RemoteData(..))
import Router
import Task
import YaMap



-- M O D E L


type alias Model =
    { creation : RemoteData Http.Error ()
    , address : String
    , number : String
    , comment : String
    , photos : List ( File, String )
    }


init : ( Model, Cmd Msg )
init =
    ( Model NotAsked "" "" "" []
    , YaMap.init "ya-map"
    )


destroy : Cmd Msg
destroy =
    YaMap.destroy


isValid : Model -> Bool
isValid model =
    String.isEmpty (String.trim model.address)
        || String.isEmpty (String.trim model.number)
        || List.isEmpty model.photos
        |> not



-- U P D A T E


type Msg
    = ChangeAddress String
    | ChangeNumber String
    | ChangeComment String
    | UploadFiles (List File)
    | PreviewFiles (List ( File, String ))
    | DeleteFile Int
    | SubmitCreation
    | SubmitCreationDone (Result Http.Error (ID { report : () }))


update : Msg -> Glob -> Model -> ( Model, Cmd Msg )
update msg glob model =
    case msg of
        ChangeAddress nextAddress ->
            ( { model | address = nextAddress }
            , Cmd.none
            )

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
            ( if RemoteData.isLoading model.creation then
                model

              else
                { model | photos = List.take index model.photos ++ List.drop (index + 1) model.photos }
            , Cmd.none
            )

        SubmitCreation ->
            ( { model | creation = Loading }
            , Api.createRequest
                { address = String.trim model.address
                , number = String.trim model.number
                , comment =
                    case String.trim model.comment of
                        "" ->
                            Nothing

                        comment ->
                            Just comment
                , photos = List.map Tuple.first model.photos
                }
                |> Cmd.map SubmitCreationDone
            )

        SubmitCreationDone (Err err) ->
            ( { model | creation = Failure err }
            , Cmd.none
            )

        SubmitCreationDone (Ok reportId) ->
            ( model
            , Router.push glob.key (Router.ToViewReport reportId)
            )



-- S U B S C R I P T I O N


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map ChangeAddress YaMap.onAddress



-- V I E W


viewPhoto : Int -> ( File, String ) -> Html Msg
viewPhoto index ( file, base64 ) =
    div
        [ Html.Attributes.class "col-sm-3 col-4"
        ]
        [ img
            [ Html.Attributes.class "img-thumbnail"
            , Html.Attributes.src base64
            , Html.Events.onClick (DeleteFile index)
            ]
            []
        ]


viewAddPhoto : Bool -> Html Msg
viewAddPhoto busy =
    div
        [ Html.Attributes.class "col-sm-3 col-4"
        ]
        [ label
            [ Html.Attributes.class "card"
            ]
            [ i [ Html.Attributes.class "fa fa-camera fa-3x p-3 text-center text-primary" ] []
            , input
                [ Html.Attributes.class "create-report__file-input"
                , Html.Attributes.type_ "file"
                , Html.Attributes.accept "image/*"
                , Html.Attributes.attribute "capture" "camera"
                , Html.Attributes.multiple True
                , Html.Attributes.disabled busy
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
    let
        busy =
            RemoteData.isLoading model.creation
    in
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
            [ Html.Attributes.class "container-fluid my-3"
            , Html.Attributes.novalidate True
            , Html.Events.onSubmit SubmitCreation
            ]
            [ div
                [ Html.Attributes.class "form-group"
                ]
                [ label [] [ text "Адрес" ]
                , input
                    [ Html.Attributes.class "form-control"
                    , Html.Attributes.type_ "text"
                    , Html.Attributes.value model.address
                    , Html.Attributes.placeholder "Выберите на карте"
                    , Html.Attributes.required True
                    , Html.Attributes.disabled busy
                    , Html.Events.onInput ChangeAddress
                    ]
                    []
                ]
            , div
                [ Html.Attributes.class "form-group"
                ]
                [ label [] [ text "Фото транспортного средства" ]
                , if List.length model.photos < 6 then
                    div
                        [ Html.Attributes.class "form-group row mb-0"
                        ]
                        (viewAddPhoto busy :: List.indexedMap viewPhoto model.photos)

                  else
                    div
                        [ Html.Attributes.class "form-group row mb-0"
                        ]
                        (List.indexedMap viewPhoto model.photos)
                ]
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
                    , Html.Attributes.disabled busy
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
                    , Html.Attributes.disabled busy
                    , Html.Events.onInput ChangeComment
                    ]
                    []
                ]
            , case model.creation of
                Failure (Http.BadUrl _) ->
                    div
                        [ Html.Attributes.class "alert alert-danger" ]
                        [ text "Разработчики наговнокодили" ]

                Failure Http.Timeout ->
                    div
                        [ Html.Attributes.class "alert alert-danger" ]
                        [ text "Медленное интернет соединение" ]

                Failure Http.NetworkError ->
                    div
                        [ Html.Attributes.class "alert alert-danger" ]
                        [ text "Проверьте подключение к интернету" ]

                Failure (Http.BadStatus status) ->
                    div
                        [ Html.Attributes.class "alert alert-danger" ]
                        [ text ("Запрос упал (STATUS: " ++ String.fromInt status ++ ")") ]

                Failure (Http.BadBody error) ->
                    div
                        [ Html.Attributes.class "alert alert-danger" ]
                        [ text "Плохой ответ от сервера:"
                        , br [] []
                        , code [] [ text error ]
                        ]

                _ ->
                    text ""
            , button
                [ Html.Attributes.class "btn btn-block btn-success"
                , Html.Attributes.disabled (not (isValid model))
                , Html.Attributes.type_ "submit"
                , Html.Attributes.disabled (busy || not (isValid model))
                ]
                [ i [ Html.Attributes.class "fa fa-paper-plane mr-2" ] []
                , text "Отправить"
                ]
            ]
        ]

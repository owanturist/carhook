module Error exposing (view)

import Html exposing (Html, br, code, div, text)
import Html.Attributes
import Http


view : Http.Error -> Html msg
view error =
    case error of
        Http.BadUrl _ ->
            div
                [ Html.Attributes.class "alert alert-danger" ]
                [ text "Разработчики наговнокодили" ]

        Http.Timeout ->
            div
                [ Html.Attributes.class "alert alert-danger" ]
                [ text "Медленное интернет соединение" ]

        Http.NetworkError ->
            div
                [ Html.Attributes.class "alert alert-danger" ]
                [ text "Проверьте подключение к интернету" ]

        Http.BadStatus status ->
            div
                [ Html.Attributes.class "alert alert-danger" ]
                [ text ("Запрос упал (STATUS: " ++ String.fromInt status ++ ")") ]

        Http.BadBody decodeError ->
            div
                [ Html.Attributes.class "alert alert-danger" ]
                [ text "Плохой ответ от сервера:"
                , br [] []
                , code [ Html.Attributes.class "small" ] [ text decodeError ]
                ]

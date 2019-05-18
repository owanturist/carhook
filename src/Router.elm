module Router exposing (Route(..), parse, push, replace, toString)

import Browser.Navigation
import ID exposing (ID)
import Url exposing (Url)
import Url.Builder exposing (absolute)
import Url.Parser exposing ((</>), Parser, s)


type Route
    = ToHome
    | ToCreateReport
    | ToViewReport (ID { report : () })
    | ToNotFound


toString : Route -> String
toString route =
    case route of
        ToHome ->
            absolute [] []

        ToCreateReport ->
            absolute [ "report" ] []

        ToViewReport reportId ->
            absolute [ "report", ID.toString reportId ] []

        ToNotFound ->
            absolute [] []


parser : Parser (Route -> a) a
parser =
    Url.Parser.oneOf
        [ Url.Parser.map ToHome Url.Parser.top
        , Url.Parser.map ToCreateReport (s "report")
        , Url.Parser.map ToViewReport (s "report" </> ID.parser)
        ]


parse : Url -> Route
parse =
    Maybe.withDefault ToNotFound << Url.Parser.parse parser


push : Browser.Navigation.Key -> Route -> Cmd msg
push key route =
    Browser.Navigation.pushUrl key (toString route)


replace : Browser.Navigation.Key -> Route -> Cmd msg
replace key route =
    Browser.Navigation.replaceUrl key (toString route)

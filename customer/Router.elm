module Router exposing (Route(..), parse, toString)

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

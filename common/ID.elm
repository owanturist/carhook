module ID exposing (ID, compare, parser, decoder, encoder, fromFloat, fromInt, fromString, toString)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Url.Parser exposing (Parser)


type ID supported
    = ID String


fromString : String -> ID supported
fromString =
    ID


fromInt : Int -> ID supported
fromInt =
    ID << String.fromInt


fromFloat : Float -> ID supported
fromFloat =
    ID << String.fromFloat


toString : ID supported -> String
toString (ID id) =
    id


compare : ID supported -> ID supported -> Order
compare (ID left) (ID right) =
    Basics.compare left right


parser : Parser (ID supported -> a) a
parser =
    Url.Parser.oneOf
        [ Url.Parser.map fromString Url.Parser.string
        , Url.Parser.map fromInt Url.Parser.int
        ]


decoder : Decoder (ID supported)
decoder =
    Decode.oneOf
        [ Decode.map fromString Decode.string
        , Decode.map fromInt Decode.int
        , Decode.map fromFloat Decode.float
        ]


encoder : ID supported -> Value
encoder (ID id) =
    case String.toFloat id of
        Nothing ->
            Encode.string id

        Just float ->
            case String.toInt id of
                Nothing ->
                    Encode.float float

                Just int ->
                    Encode.int int

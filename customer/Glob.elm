module Glob exposing (Glob, Key)

import Browser.Navigation


type alias Key =
    Browser.Navigation.Key


type alias Glob =
    { key : Key
    }

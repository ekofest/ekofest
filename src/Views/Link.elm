module Views.Link exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


baseClass : String
baseClass =
    "link hover:underline hover:text-accent"


external : List (Attribute msg) -> List (Html msg) -> Html msg
external attrs =
    a (attrs ++ [ target "_blank", class baseClass, rel "noopener noreferrer" ])


internal : List (Attribute msg) -> List (Html msg) -> Html msg
internal attrs =
    a (class baseClass :: attrs)

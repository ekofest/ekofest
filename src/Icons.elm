module Icons exposing (..)

import Html exposing (Html)
import Html.Attributes exposing (src)
import Svg exposing (svg)
import Svg.Attributes exposing (..)


logo : Html msg
logo =
    svg []
        [ Svg.image
            [ src "./assets/mimosa-svgrepo-com.svg"
            ]
            []
        ]


zap : Html msg
zap =
    svg
        [ fill "none"
        , viewBox "0 0 24 24"
        , class "inline-block w-8 h-8 stroke-current"
        ]
        [ Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , d "M13 10V3L4 14h7v7l9-11h-7z"
            ]
            []
        ]

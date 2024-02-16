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


error : Html msg
error =
    svg
        [ fill "none"
        , viewBox "0 0 24 24"
        , class "stroke-current shrink-0 h-6 w-6"
        ]
        [ Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , d "M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
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


chevronUp : Html msg
chevronUp =
    svg
        [ viewBox "0 0 24 24"
        , fill "none"
        , class "inline-block w-5 h-5 stroke-current"
        ]
        [ Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , d "m18 15-6-6-6 6"
            ]
            []
        ]


chevronDown : Html msg
chevronDown =
    svg
        [ viewBox "0 0 24 24"
        , fill "none"
        , class "inline-block w-5 h-5 stroke-current"
        ]
        [ Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , d "m6 9 6 6 6-6"
            ]
            []
        ]

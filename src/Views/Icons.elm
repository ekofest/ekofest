module Views.Icons exposing (..)

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


rotateCcw : Html msg
rotateCcw =
    svg
        [ viewBox "0 0 24 24"
        , fill "none"
        , class "inline-block w-4 h-4 stroke-current"
        ]
        [ Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , d "M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"
            ]
            []
        , Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , d "M3 3v5h5"
            ]
            []
        ]


{-| <svg xmlns="<http://www.w3.org/2000/svg"> width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-refresh-ccw"><path d="M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16"/><path d="M16 16h5v5"/></svg>
-}
refresh : Html msg
refresh =
    svg
        [ viewBox "0 0 24 24"
        , fill "none"
        , class "inline-block w-4 h-4 stroke-current"
        ]
        [ Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , d "M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"
            ]
            []
        , Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , d "M3 3v5h5"
            ]
            []
        , Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , d "M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16"
            ]
            []
        , Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , d "M16 16h5v5"
            ]
            []
        ]


download : Html msg
download =
    svg
        [ viewBox "0 0 24 24"
        , fill "none"
        , class "inline-block w-5 h-5 stroke-current"
        ]
        [ Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "1.75"
            , d "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"
            ]
            []
        , Svg.polyline
            [ strokeWidth "2"
            , points "7 10 12 15 17 10"
            ]
            []
        , Svg.line
            [ strokeWidth "2"
            , x1 "12"
            , x2 "12"
            , y1 "15"
            , y2 "3"
            ]
            []
        ]


{-| <svg xmlns="<http://www.w3.org/2000/svg"> width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-upload"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" x2="12" y1="3" y2="15"/></svg>
-}
upload : Html msg
upload =
    svg
        [ viewBox "0 0 24 24"
        , fill "none"
        , class "inline-block w-5 h-5 stroke-current"
        ]
        [ Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "1.75"
            , d "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"
            ]
            []
        , Svg.polyline
            [ strokeWidth "2"
            , points "17 8 12 3 7 8"
            ]
            []
        , Svg.line
            [ strokeWidth "2"
            , x1 "12"
            , x2 "12"
            , y1 "3"
            , y2 "15"
            ]
            []
        ]


{-| <svg xmlns="<http://www.w3.org/2000/svg"> width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-heart-handshake"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/><path d="M12 5 9.04 7.96a2.17 2.17 0 0 0 0 3.08v0c.82.82 2.13.85 3 .07l2.07-1.9a2.82 2.82 0 0 1 3.79 0l2.96 2.66"/><path d="m18 15-2-2"/><path d="m15 18-2-2"/></svg>
-}
heartHandshake : Html msg
heartHandshake =
    svg
        [ viewBox "0 0 24 24"
        , fill "none"
        , class "inline-block w-5 h-5 stroke-current"
        ]
        [ Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "1.75"
            , d "M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"
            ]
            []
        , Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "1.75"
            , d "M12 5 9.04 7.96a2.17 2.17 0 0 0 0 3.08v0c.82.82 2.13.85 3 .07l2.07-1.9a2.82 2.82 0 0 1 3.79 0l2.96 2.66"
            ]
            []
        , Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "1.75"
            , d "m18 15-2-2"
            ]
            []
        , Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "1.75"
            , d "m15 18-2-2"
            ]
            []
        ]


{-| <svg xmlns="<http://www.w3.org/2000/svg"> width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-chevron-right"><path d="m9 18 6-6-6-6"/></svg>
-}
chevronRight : Html msg
chevronRight =
    svg
        [ viewBox "0 0 24 24"
        , fill "none"
        , class "inline-block w-5 h-5 stroke-current"
        ]
        [ Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , d "m9 18 6-6-6-6"
            ]
            []
        ]


{-| <svg xmlns="<http://www.w3.org/2000/svg"> width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-chevron-left"><path d="m15 18-6-6 6-6"/></svg>
-}
chevronLeft : Html msg
chevronLeft =
    svg
        [ viewBox "0 0 24 24"
        , fill "none"
        , class "inline-block w-5 h-5 stroke-current"
        ]
        [ Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , d "m15 18-6-6 6-6"
            ]
            []
        ]


{-| <svg xmlns="<http://www.w3.org/2000/svg"> width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-ban"><circle cx="12" cy="12" r="10"/><path d="m4.9 4.9 14.2 14.2"/></svg>
-}
ban : Html msg
ban =
    svg
        [ viewBox "0 0 24 24"
        , fill "none"
        , class "inline-block w-5 h-5 stroke-current"
        ]
        [ Svg.circle
            [ cx "12"
            , cy "12"
            , r "10"
            , strokeWidth "2"
            ]
            []
        , Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , d "m4.9 4.9 14.2 14.2"
            ]
            []
        ]


{-| <svg xmlns="<http://www.w3.org/2000/svg"> width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-circle-slash-2"><circle cx="12" cy="12" r="10"/><path d="M22 2 2 22"/></svg>
-}
circleSlash2 : Html msg
circleSlash2 =
    svg
        [ viewBox "0 0 24 24"
        , fill "none"
        , class "inline-block w-5 h-5 stroke-current"
        ]
        [ Svg.circle
            [ cx "12"
            , cy "12"
            , r "10"
            , strokeWidth "2"
            ]
            []
        , Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , d "M22 2 2 22"
            ]
            []
        ]


{-| <svg xmlns="<http://www.w3.org/2000/svg"> width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-home"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
-}
home : Html msg
home =
    svg
        [ viewBox "0 0 24 24"
        , fill "none"
        , class "inline-block w-5 h-5 stroke-current"
        ]
        [ Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , d "m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"
            ]
            []
        , Svg.polyline
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , strokeWidth "2"
            , points "9 22 9 12 15 12 15 22"
            ]
            []
        ]


{-| <svg xmlns="<http://www.w3.org/2000/svg"> width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-external-link"><path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/></svg>
-}
externalLink : Html msg
externalLink =
    svg [ viewBox "0 0 24 24", fill "none", class "inline-block w-3 h-3 stroke-current" ]
        [ Svg.path [ strokeLinecap "round", strokeLinejoin "round", strokeWidth "2", d "M15 3h6v6" ] []
        , Svg.path [ strokeLinecap "round", strokeLinejoin "round", strokeWidth "2", d "M10 14 21 3" ] []
        , Svg.path [ strokeLinecap "round", strokeLinejoin "round", strokeWidth "2", d "M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" ] []
        ]


{-| <svg xmlns="<http://www.w3.org/2000/svg"> width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-book-open-text"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/><path d="M6 8h2"/><path d="M6 12h2"/><path d="M16 8h2"/><path d="M16 12h2"/></svg>
-}
bookOpenText : Html msg
bookOpenText =
    svg [ viewBox "0 0 24 24", fill "none", class "inline-block w-5 h-5 stroke-current" ]
        [ Svg.path [ strokeLinecap "round", strokeLinejoin "round", strokeWidth "2", d "M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z" ] []
        , Svg.path [ strokeLinecap "round", strokeLinejoin "round", strokeWidth "2", d "M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z" ] []
        , Svg.path [ strokeLinecap "round", strokeLinejoin "round", strokeWidth "2", d "M6 8h2" ] []
        , Svg.path [ strokeLinecap "round", strokeLinejoin "round", strokeWidth "2", d "M6 12h2" ] []
        , Svg.path [ strokeLinecap "round", strokeLinejoin "round", strokeWidth "2", d "M16 8h2" ] []
        , Svg.path [ strokeLinecap "round", strokeLinejoin "round", strokeWidth "2", d "M16 12h2" ] []
        ]

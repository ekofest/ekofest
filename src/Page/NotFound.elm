module Page.NotFound exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Views.Icons as Icons


view : Html msg
view =
    div [ class "flex flex-col justify-center items-center w-full" ]
        [ div [ class "flex flex-col gap-4 justify-center items-center w-fit min-h-[75vh]" ]
            [ h1 [ class "text-5xl" ] [ text "404 - Page not found" ]
            , p [] [ text "La page que vous cherchez n'existe pas ou a été déplacée." ]
            , a [ class "btn btn-primary text-white mt-8", href "/" ]
                [ Icons.home, text "Retourner à l'accueil" ]
            ]
        ]

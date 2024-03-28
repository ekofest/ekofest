module Page.Template exposing (Config, view)

import Browser exposing (Document)
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Session as S
import Views.Icons as Icons
import Views.Link as Link


type alias Config msg =
    { title : String
    , content : Html msg
    , session : S.Data
    , resetSituation : msg
    , exportSituation : msg
    , importSituation : msg
    }


view : Config msg -> Document msg
view config =
    { title = config.title ++ " | Ekofest"
    , body =
        [ viewHeader config
        , main_ []
            [ if Dict.isEmpty config.session.rawRules then
                div [ class "flex flex-col w-full h-full items-center" ]
                    [ S.viewError config.session.currentErr
                    , div [ class "loading loading-lg text-primary mt-4" ] []
                    ]

              else
                config.content
            ]
        , viewFooter
        ]
    }


viewHeader : Config msg -> Html msg
viewHeader { resetSituation, exportSituation, importSituation } =
    let
        btnClass =
            "join-item btn-sm bg-base-100 border border-base-200 hover:bg-base-200"
    in
    header []
        [ div [ class "flex md:items-center sm:flex-row justify-between flex-col w-full px-4 lg:px-8 border-b border-base-200 bg-neutral" ]
            [ div [ class "flex items-center" ]
                [ a [ href "/" ]
                    [ img [ src "/assets/logo.svg", class "w-32 m-4", width 128, alt "ekofest logo" ] []
                    ]
                , span [ class "badge badge-accent badge-outline" ] [ text "beta" ]
                ]
            , div [ class "join p-2 mb-4 sm:mb-0" ]
                [ button [ class btnClass, onClick resetSituation ]
                    [ span [ class "mr-2" ] [ Icons.refresh ], span [ class "invisible xsm:visible" ] [ text "Recommencer" ] ]
                , button [ class btnClass, onClick exportSituation ]
                    [ span [ class "mr-2" ] [ Icons.download ]
                    , span [ class "invisible xsm:visible" ] [ text "Télécharger" ]
                    ]
                , button
                    [ class btnClass
                    , type_ "file"
                    , multiple False
                    , accept ".json"
                    , onClick importSituation
                    ]
                    [ span [ class "mr-2" ] [ Icons.upload ]
                    , span [ class "invisible xsm:visible" ] [ text "Importer" ]
                    ]
                ]
            ]
        ]


viewFooter : Html msg
viewFooter =
    div []
        [ footer [ class "footer p-8 mt-8 md:mt-20 bg-neutral text-base-content border-t border-base-200" ]
            [ aside [ class "text-md max-w-4xl" ]
                [ div []
                    [ text """
                    Ekofest a pour objectif de faciliter l'organisation d'événements festifs et culturels éco-responsables.
                    L'outil permet de rapidement estimer l'impact carbone (en équivalent CO2) d'un événement
                    afin de repérer les postes les plus émetteurs et anticiper les actions à mettre en place.
                    """
                    ]
                , div [ class "" ]
                    [ text """
                    Ce simulateur a été développé dans une démarche de transparence et de partage.
                    Ainsi, le code du simulateur est libre et ouvert, de la même manière que le modèle de calcul.
                    """
                    ]
                , div []
                    [ text "Fait avec "
                    , Icons.heartHandshake
                    , text " par "
                    , Link.external [ href "https://github.com/EmileRolley" ] [ text "Milou" ]
                    , text " et "
                    , Link.external [ href "https://github.com/clemog" ] [ text "Clemog" ]
                    , text " au Moulin Bonne Vie en février 2024."
                    ]
                ]
            , nav []
                [ h6 [ class "footer-title" ] [ text "Liens utiles" ]
                , Link.internal [ href "/documentation" ]
                    [ text "Documentation du modèle" ]
                , Link.external [ href "https://github.com/ekofest/publicodes-evenements" ]
                    [ text "Code source du modèle" ]
                , Link.external [ href "https://github.com/ekofest/ekofest" ]
                    [ text "Code source du site" ]
                ]
            , a [ href "https://bff.ecoindex.fr/redirect/?url=https://ekofest.fr", target "_blank" ]
                [ img
                    [ src "https://bff.ecoindex.fr/badge/?theme=light&url=https://ekofest.fr"
                    , alt "Ecoindex Badge"
                    , class "w-24"
                    , width 96
                    ]
                    []
                ]
            ]
        , footer [ class "footer p-4 bg-red-50 text-base-content border-t border-base-200" ]
            [ div []
                [ div [ class "text-sm" ]
                    [ text """Ce simulateur étant en cours de développement, les résultats obtenus
                sont donc à prendre avec précaution et ne peuvent se substituer à un bilan carbone.
                Pour toute question ou suggestion, n'hésitez pas """
                    , a [ class "link", href "mailto:emile.rolley@tuta.io" ] [ text "à nous contacter" ]
                    , text "."
                    ]
                ]
            ]
        ]

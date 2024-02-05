module Main exposing (..)

import Browser
import Dict exposing (Dict)
import Effect
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (lazy2)
import Json.Decode as Decode exposing (string)
import Json.Decode.Pipeline as Decode
import Json.Encode
import Platform.Cmd as Cmd
import Publicodes as P exposing (Mecanism(..), rootNodeName)



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type alias Evaluation =
    { nodeValue : P.NodeValue
    , missingVariables : List P.RuleName
    , isNullable : Bool
    }


evaluationDecoder : Decode.Decoder Evaluation
evaluationDecoder =
    Decode.succeed Evaluation
        |> Decode.required "nodeValue" P.nodeValueDecoder
        |> Decode.required "missingVariables" (Decode.list string)
        |> Decode.required "isNullable" Decode.bool


type alias Model =
    { rawRules : P.RawRules
    , evaluations : Dict P.RuleName Evaluation
    , questions : List P.RuleName
    , situation : P.Situation
    }


emptyModel : Model
emptyModel =
    { rawRules = Dict.empty
    , evaluations = Dict.empty
    , questions = []
    , situation = Dict.empty
    }


type alias Flags =
    Decode.Value


init : Flags -> ( Model, Cmd Msg )
init rules =
    case rules |> Decode.decodeValue P.rawRulesDecoder of
        Ok rawRules ->
            ( { emptyModel
                | rawRules = rawRules
                , questions =
                    Dict.toList rawRules
                        |> List.filterMap
                            (\( name, rule ) ->
                                Maybe.map (\_ -> name) rule.question
                            )
              }
            , -- TODO: should be [Effect.evaluateAll]j
              Dict.toList rawRules
                |> List.map (\( name, _ ) -> name)
                |> Effect.evaluateAll
            )

        Err e ->
            let
                _ =
                    Debug.log "init" e
            in
            -- TODO: prints an error
            ( emptyModel, Cmd.none )



-- UPDATE


type Msg
    = NewAnswer ( P.RuleName, P.NodeValue )
    | UpdateEvaluation ( P.RuleName, Json.Encode.Value )
    | UpdateAllEvaluation (List ( P.RuleName, Json.Encode.Value ))
    | Evaluate ()
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewAnswer ( name, value ) ->
            let
                newSituation =
                    case value of
                        _ ->
                            Dict.insert name value model.situation
            in
            ( { model | situation = newSituation }
            , newSituation
                |> P.encodeSituation
                |> Effect.setSituation
            )

        UpdateEvaluation ( name, encodedEvaluation ) ->
            ( updateEvaluation ( name, encodedEvaluation ) model, Cmd.none )

        UpdateAllEvaluation encodedEvaluations ->
            ( List.foldl updateEvaluation model encodedEvaluations, Cmd.none )

        Evaluate () ->
            ( model
            , -- TODO: could it be clever to only evaluate the rules that have been updated?
              Dict.toList model.rawRules
                |> List.map (\( name, _ ) -> name)
                |> Effect.evaluateAll
            )

        NoOp ->
            ( model, Cmd.none )


updateEvaluation : ( P.RuleName, Json.Encode.Value ) -> Model -> Model
updateEvaluation ( name, encodedEvaluation ) model =
    case Decode.decodeValue evaluationDecoder encodedEvaluation of
        Ok eval ->
            { model | evaluations = Dict.insert name eval model.evaluations }

        Err e ->
            let
                _ =
                    Debug.log "updateEvaluation: decode error:" e
            in
            let
                _ =
                    Debug.log "updateEvaluation: decode error:" name
            in
            model



-- VIEW


getTitle : Model -> P.RuleName -> String
getTitle model name =
    case Dict.get name model.rawRules of
        Just rule ->
            let
                _ =
                    Debug.log "getTitle" rule.title
            in
            Maybe.withDefault name rule.title

        Nothing ->
            name


view : Model -> Html Msg
view model =
    div []
        [ viewHeader
        , case Dict.toList model.rawRules of
            [] ->
                div [] [ text "Désolé, une erreur est survenue lors du chargement des règles." ]

            rules ->
                div [ class "flex p-2" ]
                    [ div [ class "basis-3/4" ]
                        [ h2 [ class "text-2xl font-bold" ] [ text "Questions" ]
                        , lazy2 viewRules model rules
                        ]
                    , div [ class "border-r-2 border-green-600 mx-4" ] []
                    , div [ class "basis-1/4" ]
                        [ h2 [ class "text-2xl font-bold" ] [ text "Total" ]
                        , p [ class "font-semi" ] [ text (getTitle model rootNodeName ++ " = ") ]
                        , viewResult (Dict.get rootNodeName model.evaluations)
                        , viewUnit (Dict.get rootNodeName model.rawRules)
                        ]
                    ]
        ]


viewHeader : Html Msg
viewHeader =
    header []
        [ div [ class "flex items-center justify-between w-full bg-green-800 p-2" ]
            [ p [ class "text-xl font-bold text-white" ] [ text "EcoFest" ]
            , a
                [ class "text-green-100"
                , href "https://github.com/ecofest/publicodes-evenements"
                , target "_blank"
                ]
                [ text "Modèle de calcul ⧉" ]
            ]
        ]


viewUnit : Maybe P.RawRule -> Html Msg
viewUnit maybeRawRule =
    case maybeRawRule of
        Just rawRule ->
            text (" " ++ Maybe.withDefault "" rawRule.unit)

        Nothing ->
            text ""


viewRules : Model -> List ( P.RuleName, P.RawRule ) -> Html Msg
viewRules model rules =
    ul [ class "grid grid-rows-5 grid-flow-col gap-4" ]
        (rules
            |> List.filterMap
                (\( name, rule ) ->
                    case ( rule.question, Dict.get name model.evaluations ) of
                        ( Just _, Just evaluation ) ->
                            if not evaluation.isNullable then
                                Just [ viewQuestion model ( name, rule ) ]

                            else
                                Nothing

                        _ ->
                            Nothing
                )
            |> List.concat
        )



-- Questions


viewQuestion : Model -> ( P.RuleName, P.RawRule ) -> Html Msg
viewQuestion model ( name, rule ) =
    rule.question
        |> Maybe.map
            (\question ->
                li [ class "w-100 p-2 bg-green-100" ]
                    [ div [ class "pb-2" ] [ text question ]
                    , viewInput model ( name, rule )
                    ]
            )
        |> Maybe.withDefault (text "")


viewInput : Model -> ( P.RuleName, P.RawRule ) -> Html Msg
viewInput model ( name, rule ) =
    let
        newAnswer val =
            case String.toFloat val of
                Just value ->
                    NewAnswer ( name, P.Num value )

                Nothing ->
                    if String.isEmpty val then
                        NewAnswer ( name, P.Empty )

                    else
                        NewAnswer ( name, P.Str val )
    in
    case ( rule.formula, Dict.get name model.situation, rule.default ) of
        ( Just (UnePossibilite { possibilites }), Just situationValue, _ ) ->
            select
                [ onInput newAnswer ]
                (possibilites
                    |> List.map
                        (\possibilite ->
                            option
                                [ value possibilite
                                , selected
                                    (P.nodeValueToString situationValue
                                        == P.toConstantString possibilite
                                    )
                                ]
                                [ text possibilite ]
                        )
                )

        ( Just (UnePossibilite { possibilites }), Nothing, Just defaultValue ) ->
            select
                [ onInput newAnswer ]
                (possibilites
                    |> List.map
                        (\possibilite ->
                            option
                                [ value possibilite
                                , selected
                                    (P.nodeValueToString defaultValue
                                        == P.toConstantString possibilite
                                    )
                                ]
                                [ text possibilite ]
                        )
                )

        ( _, Just (P.Num num), _ ) ->
            input
                [ type_ "number"
                , value (String.fromFloat num)
                , onInput newAnswer
                ]
                []

        ( _, Just (P.Str str), _ ) ->
            input
                [ type_ "text"
                , value str
                , onInput newAnswer
                ]
                []

        ( _, Just (P.Boolean bool), _ ) ->
            input
                [ type_ "checkbox"
                , checked bool
                , onCheck (\b -> NewAnswer ( name, P.Boolean b ))
                ]
                []

        -- We have a default value
        ( _, Nothing, Just (P.Num num) ) ->
            input
                [ type_ "number"
                , placeholder (String.fromFloat num)
                , onInput newAnswer
                ]
                []

        ( _, Nothing, Just (P.Str str) ) ->
            input
                [ type_ "text"
                , placeholder str
                , onInput newAnswer
                ]
                []

        ( _, Nothing, Just (P.Boolean bool) ) ->
            input
                [ type_ "checkbox"
                , checked bool
                , onCheck (\b -> NewAnswer ( name, P.Boolean b ))
                ]
                []

        _ ->
            -- TODO: should print an error
            input [ type_ "number", onInput newAnswer ] []


viewResult : Maybe Evaluation -> Html Msg
viewResult eval =
    case eval of
        Just { nodeValue } ->
            strong [] [ text (P.nodeValueToString nodeValue) ]

        Nothing ->
            text "Calcul en cours"



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Effect.evaluatedRule UpdateEvaluation
        , Effect.evaluatedRules UpdateAllEvaluation
        , Effect.situationUpdated Evaluate
        ]

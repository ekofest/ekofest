module Main exposing (..)

import Browser
import Dict exposing (Dict)
import Effect
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
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
            , -- TODO: should be [Effect.evaluateAll]
              Cmd.batch
                (Dict.toList rawRules
                    |> List.map (\( name, _ ) -> Effect.evaluate name)
                )
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
            case Decode.decodeValue evaluationDecoder encodedEvaluation of
                Ok eval ->
                    ( { model | evaluations = Dict.insert name eval model.evaluations }
                    , Cmd.none
                    )

                Err e ->
                    let
                        _ =
                            Debug.log "update evaluation" e
                    in
                    -- TODO: should print an error
                    ( model, Cmd.none )

        Evaluate () ->
            ( model
            , Cmd.batch
                (Dict.toList model.rawRules
                    |> List.map (\( name, _ ) -> Effect.evaluate name)
                )
            )

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    case Dict.toList model.rawRules of
        [] ->
            div [] [ text "Désolé, une erreur est survenue lors du chargement des règles." ]

        rules ->
            div []
                [ h3 [ class "flex" ] [ text "Questions" ]
                , viewRules model rules
                , h3 [] [ text "Total" ]
                , i []
                    [ text ("[" ++ rootNodeName ++ "]: ")
                    , viewResult (Dict.get rootNodeName model.evaluations)
                    , viewUnit (Dict.get rootNodeName model.rawRules)
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
    ul []
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
                li []
                    [ div [] [ text question ]
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
                , onInput newAnswer
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
                , onInput newAnswer
                ]
                []

        _ ->
            -- TODO: should print an error
            input [ type_ "number", onInput newAnswer ] []


viewResult : Maybe Evaluation -> Html Msg
viewResult eval =
    case eval of
        Just { nodeValue } ->
            strong []
                [ case nodeValue of
                    P.Num n ->
                        text (String.fromFloat n)

                    P.Str s ->
                        text s

                    P.Boolean b ->
                        text
                            (if b then
                                "oui"

                             else
                                "non"
                            )

                    P.Empty ->
                        text ""
                ]

        Nothing ->
            text "Calcul en cours"



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Effect.evaluatedRule UpdateEvaluation
        , Effect.situationUpdated Evaluate
        ]

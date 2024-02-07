module Main exposing (..)

import Browser
import Chart as C
import Chart.Attributes as CA
import Dict exposing (Dict)
import Effect
import Helpers as H
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (lazy)
import Icons
import Json.Decode as Decode exposing (string)
import Json.Decode.Pipeline as Decode
import Json.Encode
import Platform.Cmd as Cmd
import Publicodes as P exposing (Mecanism(..))



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
    , questions : Dict String (List P.RuleName)
    , situation : P.Situation
    , categories : List P.RuleName
    , currentError : Maybe AppError
    }


type AppError
    = DecodeError Decode.Error


emptyModel : Model
emptyModel =
    { rawRules = Dict.empty
    , evaluations = Dict.empty
    , questions = Dict.empty
    , situation = Dict.empty
    , categories = []
    , currentError = Nothing
    }


type alias Flags =
    Decode.Value


init : Flags -> ( Model, Cmd Msg )
init rules =
    case rules |> Decode.decodeValue P.rawRulesDecoder of
        Ok rawRules ->
            let
                categories =
                    H.getCategories rawRules
            in
            ( { emptyModel
                | rawRules = rawRules
                , questions = H.getQuestions rawRules categories
                , categories = categories
              }
            , Dict.toList rawRules
                |> List.map (\( name, _ ) -> name)
                |> Effect.evaluateAll
            )

        Err e ->
            ( { emptyModel | currentError = Just (DecodeError e) }, Cmd.none )



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
            { model | currentError = Just (DecodeError e) }



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ viewHeader
        , if Dict.isEmpty model.rawRules then
            div [ class "p-4" ]
                [ viewError model.currentError
                , div [ class "prose" ] [ text "Chargement..." ]
                ]

          else
            div [ class "flex flex-col-reverse lg:grid lg:grid-cols-3" ]
                [ div [ class "p-4 lg:pl-8 lg:pr-4 lg:col-span-2" ]
                    [ ul [ class "flex flex-wrap bg-neutral rounded-t-lg border-t border-x border-base-200 p-2 sticky top-0" ]
                        (viewCategoriesAnchors model.categories)
                    , lazy viewCategories model
                    ]
                , lazy viewError model.currentError
                , div [ class "flex flex-col p-4 lg:pl-4 lg:col-span-1 lg:pr-8 " ]
                    [ lazy viewResult model
                    , lazy viewGraph model
                    ]
                ]
        ]


viewHeader : Html Msg
viewHeader =
    header []
        [ div [ class "flex items-center justify-between w-full py-2 px-8 mb-4 border-b border-base-200 bg-neutral" ]
            [ div [ class "flex items-center" ]
                [ div [ class "text-3xl font-bold text-primary m-2" ] [ text "EkoFest" ]
                , span [ class "badge badge-secondary badge-outline italic" ] [ text "beta" ]
                ]
            , a
                [ class "hover:text-primary cursor-pointer"
                , href "https://ekofest.github.io/publicodes-evenements"
                , target "_blank"
                ]
                [ text "Consulter le modèle de calcul ⧉" ]
            ]
        ]


viewError : Maybe AppError -> Html Msg
viewError maybeError =
    case maybeError of
        Just (DecodeError e) ->
            div [ class "alert alert-error" ]
                [ Icons.error
                , span [] [ text (Decode.errorToString e) ]
                ]

        Nothing ->
            text ""


viewCategoriesAnchors : List P.RuleName -> List (Html Msg)
viewCategoriesAnchors categories =
    categories
        |> List.map
            (\category ->
                li [ class "p-1 hover:bg-base-100 rounded-lg" ]
                    [ a
                        [ class "tab cursor-pointer text-xs hover:text-accent"
                        , href ("#" ++ category)
                        ]
                        [ text (String.toUpper category) ]
                    ]
            )


viewCategories : Model -> Html Msg
viewCategories model =
    div [ class "bg-neutral border-x border-b border-base-200 overflow-y-auto rounded-b-md h-[87vh]" ]
        (model.questions
            |> Dict.toList
            |> List.map
                (\( category, questions ) ->
                    div [ class "mb-8" ]
                        [ div [ class "bg-base-100 p-4 mb-4 border-y border-base-200 sticky top-0", id category ]
                            [ text (String.toUpper category)
                            ]
                        , div [ class "grid grid-cols-1 lg:grid-cols-2 gap-6 px-6" ]
                            (questions
                                |> List.filterMap
                                    (\name ->
                                        case ( Dict.get name model.rawRules, Dict.get name model.evaluations ) of
                                            ( Just rule, Just eval ) ->
                                                Just
                                                    (viewQuestion model ( name, rule ) eval.isNullable)

                                            _ ->
                                                Nothing
                                    )
                            )
                        ]
                )
        )



-- Questions


viewQuestion : Model -> ( P.RuleName, P.RawRule ) -> Bool -> Html Msg
viewQuestion model ( name, rule ) isDisabled =
    rule.title
        |> Maybe.map
            (\title ->
                div []
                    [ label [ class "form-control" ]
                        [ div [ class "label" ]
                            [ span [ class "label-text text-md font-semibold" ] [ text title ]
                            , span [ class "label-text-alt text-md" ] [ viewUnit rule ]
                            ]
                        , viewInput model ( name, rule ) isDisabled
                        ]
                    ]
            )
        |> Maybe.withDefault (text "")


viewInput : Model -> ( P.RuleName, P.RawRule ) -> Bool -> Html Msg
viewInput model ( name, rule ) isDisabled =
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
    let
        maybeNodeValue =
            Dict.get name model.evaluations
                |> Maybe.map (\{ nodeValue } -> nodeValue)
    in
    case ( rule.formula, Dict.get name model.situation, maybeNodeValue ) of
        ( Just (UnePossibilite { possibilites }), Just situationValue, _ ) ->
            viewSelectInput model.rawRules name possibilites situationValue isDisabled

        ( Just (UnePossibilite { possibilites }), Nothing, Just nodeValue ) ->
            viewSelectInput model.rawRules name possibilites nodeValue isDisabled

        ( _, Just (P.Num num), _ ) ->
            input
                [ type_ "number"
                , disabled isDisabled
                , class "input input-bordered"
                , value (String.fromFloat num)
                , onInput newAnswer
                ]
                []

        ( _, Just (P.Str str), _ ) ->
            input
                [ type_ "text"
                , disabled isDisabled
                , class "input input-bordered"
                , value str
                , onInput newAnswer
                ]
                []

        ( _, Just (P.Boolean bool), _ ) ->
            viewBooleanRadioInput name bool

        -- We have a default value
        ( _, Nothing, Just (P.Num num) ) ->
            input
                [ type_ "number"
                , disabled isDisabled
                , class "input input-bordered"
                , placeholder (String.fromFloat num)
                , onInput newAnswer
                ]
                []

        ( _, Nothing, Just (P.Str str) ) ->
            input
                [ type_ "text"
                , disabled isDisabled
                , class "input input-bordered"
                , placeholder str
                , onInput newAnswer
                ]
                []

        ( _, Nothing, Just (P.Boolean bool) ) ->
            viewBooleanRadioInput name bool

        _ ->
            -- TODO: should print an error
            input [ type_ "number", onInput newAnswer ] []


viewSelectInput : P.RawRules -> P.RuleName -> List String -> P.NodeValue -> Bool -> Html Msg
viewSelectInput rules ruleName possibilites nodeValue isDisabled =
    select
        [ onInput (\v -> NewAnswer ( ruleName, P.Str v ))
        , class "select select-bordered"
        , disabled isDisabled
        ]
        (possibilites
            |> List.map
                (\possibilite ->
                    option
                        [ value possibilite
                        , selected (P.nodeValueToString nodeValue == possibilite)
                        ]
                        [ text (H.getOptionTitle rules ruleName possibilite) ]
                )
        )


viewBooleanRadioInput : P.RuleName -> Bool -> Html Msg
viewBooleanRadioInput name bool =
    div [ class "form-control" ]
        [ label [ class "label cursor-pointer" ]
            [ span [ class "label-text" ] [ text "Oui" ]
            , input
                [ class "radio"
                , type_ "radio"
                , checked bool
                , onCheck (\b -> NewAnswer ( name, P.Boolean b ))
                ]
                []
            ]
        , label [ class "label cursor-pointer" ]
            [ span [ class "label-text" ] [ text "Non" ]
            , input
                [ class "radio"
                , type_ "radio"
                , checked (not bool)
                , onCheck (\b -> NewAnswer ( name, P.Boolean (not b) ))
                ]
                []
            ]
        ]


viewResult : Model -> Html Msg
viewResult model =
    let
        resultRules =
            Dict.toList model.rawRules
                |> List.filterMap
                    (\( name, rule ) ->
                        case P.splitRuleName name of
                            [ namespace, _ ] ->
                                if namespace == H.resultNamespace then
                                    Just ( name, rule )

                                else
                                    Nothing

                            _ ->
                                Nothing
                    )
    in
    div [ class "stats stats-vertical border w-full rounded-md bg-neutral" ]
        (resultRules
            |> List.map
                (\( name, rule ) ->
                    div [ class "stat" ]
                        [ div [ class "stat-title" ]
                            [ text (H.getTitle model.rawRules name) ]
                        , div [ class "stat-value text-primary" ]
                            [ viewEvaluation (Dict.get name model.evaluations) ]
                        , div [ class "stat-desc text-primary" ] [ viewUnit rule ]
                        ]
                )
        )


viewEvaluation : Maybe Evaluation -> Html Msg
viewEvaluation eval =
    case eval of
        Just { nodeValue } ->
            text (P.nodeValueToString nodeValue)

        Nothing ->
            text "Calcul en cours"


viewUnit : P.RawRule -> Html Msg
viewUnit rawRule =
    text (" " ++ Maybe.withDefault "" rawRule.unit)


viewGraph : Model -> Html Msg
viewGraph model =
    let
        total =
            Dict.get H.totalRuleName model.evaluations
                |> Maybe.andThen (\{ nodeValue } -> P.nodeValueToFloat nodeValue)
                |> Maybe.withDefault 0
    in
    let
        data =
            model.categories
                |> List.filterMap
                    (\category ->
                        Dict.get category model.evaluations
                            |> Maybe.andThen
                                (\{ nodeValue } ->
                                    case nodeValue of
                                        P.Num value ->
                                            Just
                                                { category = category
                                                , nodeValue = (value / total) * 100
                                                }

                                        _ ->
                                            Nothing
                                )
                    )
    in
    div [ class "hidden lg:block bg-neutral border border-base-200 rounded-md mt-8" ]
        [ h2 [ class "bg-base-100 p-4 border-b border-base-200" ] [ text "DÉTAILS" ]
        , div [ class "p-4" ]
            [ C.chart
                [ CA.width 800
                , CA.height 800
                , CA.margin { top = 40, right = 40, bottom = 40, left = 40 }
                , CA.domain
                    [ CA.lowest 0 CA.exactly
                    , CA.highest 100 CA.exactly
                    ]
                ]
                [ C.yLabels
                    [ CA.withGrid
                    , CA.format (\v -> String.fromFloat v ++ " %")
                    ]
                , C.binLabels .category [ CA.moveDown 30 ]
                , C.bars [ CA.roundTop 0.25, CA.margin 0.25 ]
                    [ C.bar .nodeValue [ CA.color CA.brown, CA.opacity 0.8 ]
                    ]
                    data
                ]
            ]
        ]



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Effect.evaluatedRule UpdateEvaluation
        , Effect.evaluatedRules UpdateAllEvaluation
        , Effect.situationUpdated Evaluate
        ]

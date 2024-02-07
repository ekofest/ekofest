module Main exposing (..)

import Browser
import Chart as C
import Chart.Attributes as CA
import Dict exposing (Dict)
import Effect
import Helpers as H exposing (resultNamespace)
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
    }


emptyModel : Model
emptyModel =
    { rawRules = Dict.empty
    , evaluations = Dict.empty
    , questions = Dict.empty
    , situation = Dict.empty
    , categories = []
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

        Err _ ->
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

        Err _ ->
            model



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ viewHeader
        , if Dict.isEmpty model.rawRules then
            div [ class "prose" ] [ text "Chargement..." ]

          else
            div [ class "grid grid-cols-3" ]
                [ div [ class "pl-8 pr-4 pb-4 col-span-2 overflow-y-auto h-[96vh]" ]
                    [ -- [ div [ class "tabs tabs-bordered" ]
                      --     [ a [ class "tab", href "#alimentation" ] [ text "Alimentation" ]
                      --     , a [ class "tab tab-active", href "#transport" ] [ text "Transport" ]
                      --     , a [ class "tab", href "#infrascture" ] [ text "Infrastructure" ]
                      --     , a [ class "tab" ] [ text "Hébergement" ]
                      --     ]
                      lazy viewCategories model
                    ]
                , div [ class "flex flex-col pr-8 pl-4 col-span-1" ]
                    [ lazy viewResult model
                    , lazy viewGraph model
                    ]
                ]
        ]


viewHeader : Html Msg
viewHeader =
    header []
        [ div [ class "flex items-center justify-between w-full p-2 mb-4 border-b-2 border-primary" ]
            [ div [ class "flex items-center" ]
                [ img [ src "/src/assets/mimosa-svgrepo-com.svg", class "w-10 h-10" ] []
                , p [ class "text-3xl font-bold text-black ml-2" ] [ text "Mimozo" ]
                ]
            , a
                [ class "text-neutral"
                , href "https://github.com/ecofest/publicodes-evenements"
                , target "_blank"
                ]
                [ text "Consulter le modèle de calcul ⧉" ]
            ]
        ]


viewCategories : Model -> Html Msg
viewCategories model =
    div [ class "" ]
        (model.questions
            |> Dict.toList
            |> List.map
                (\( category, questions ) ->
                    div [ class "card shadow p-4 mb-8 bg-base-100" ]
                        [ h2 [ class "text-2xl font-bold text-accent" ] [ text (String.toUpper category) ]
                        , div [ class "divider" ] []
                        , div [ class "grid grid-cols-2 gap-4" ]
                            (questions
                                |> List.filterMap
                                    (\name ->
                                        case ( Dict.get name model.rawRules, Dict.get name model.evaluations ) of
                                            ( Just rule, Just eval ) ->
                                                if eval.isNullable then
                                                    Nothing

                                                else
                                                    Just
                                                        (viewQuestion model ( name, rule ))

                                            _ ->
                                                Nothing
                                    )
                            )
                        ]
                )
        )



-- Questions


viewQuestion : Model -> ( P.RuleName, P.RawRule ) -> Html Msg
viewQuestion model ( name, rule ) =
    rule.question
        |> Maybe.map
            (\question ->
                div []
                    [ label [ class "form-control" ]
                        [ div [ class "label" ]
                            [ span [ class "label-text text-xl" ] [ text question ] ]
                        , viewInput model ( name, rule )
                        ]
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
    let
        maybeNodeValue =
            Dict.get name model.evaluations
                |> Maybe.map (\{ nodeValue } -> nodeValue)
    in
    case ( rule.formula, Dict.get name model.situation, maybeNodeValue ) of
        ( Just (UnePossibilite { possibilites }), Just situationValue, _ ) ->
            select
                [ onInput newAnswer, class "select select-bordered select-lg" ]
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

        ( Just (UnePossibilite { possibilites }), Nothing, Just nodeValue ) ->
            select
                [ onInput newAnswer, class "select select-bordered select-lg" ]
                (possibilites
                    |> List.map
                        (\possibilite ->
                            option
                                [ value possibilite
                                , selected
                                    (P.nodeValueToString nodeValue == possibilite)
                                ]
                                [ text possibilite ]
                        )
                )

        ( _, Just (P.Num num), _ ) ->
            input
                [ type_ "number"
                , class "input input-bordered input-lg"
                , value (String.fromFloat num)
                , onInput newAnswer
                ]
                []

        ( _, Just (P.Str str), _ ) ->
            input
                [ type_ "text"
                , class "input input-bordered input-lg"
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
                , class "input input-bordered input-lg"
                , placeholder (String.fromFloat num)
                , onInput newAnswer
                ]
                []

        ( _, Nothing, Just (P.Str str) ) ->
            input
                [ type_ "text"
                , class "input input-bordered input-lg"
                , placeholder str
                , onInput newAnswer
                ]
                []

        ( _, Nothing, Just (P.Boolean bool) ) ->
            viewBooleanRadioInput name bool

        _ ->
            -- TODO: should print an error
            input [ type_ "number", onInput newAnswer ] []


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
    div [ class "stats stats-vertical shadow border-1 w-full" ]
        (resultRules
            |> List.map
                (\( name, rule ) ->
                    div [ class "stat" ]
                        [ div [ class "stat-figure text-primary" ]
                            [ Icons.zap ]
                        , div [ class "stat-title" ]
                            [ text (getTitle model name) ]
                        , div [ class "stat-value text-primary" ]
                            [ viewEvaluation (Dict.get name model.evaluations) ]
                        , div [ class "stat-desc text-secondary" ] [ viewUnit rule ]
                        ]
                )
        )


getTitle : Model -> P.RuleName -> String
getTitle model name =
    case Dict.get name model.rawRules of
        Just rule ->
            Maybe.withDefault name rule.title

        Nothing ->
            name


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
    div [ class "card shadow p-4 mt-8 bg-base-100" ]
        [ h2 [ class "text-2xl font-bold" ] [ text "Graphique" ]
        , div [ class "divider" ] []
        , C.chart
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
                [ C.bar .nodeValue [ CA.color CA.yellow, CA.opacity 0.8 ]
                ]
                data
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

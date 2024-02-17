module Main exposing (..)

import Browser
import Dict exposing (Dict)
import Effect
import File exposing (File)
import File.Download
import File.Select
import FormatNumber.Locales exposing (Decimals(..))
import Helpers as H
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (lazy, lazy2)
import Icons
import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import Json.Encode
import Markdown
import Platform.Cmd as Cmd
import Publicodes as P exposing (Mecanism(..), NodeValue(..))
import Simple.Animation as Animation exposing (Animation)
import Simple.Animation.Animated as Animated
import Simple.Animation.Property as AnimProp
import Task
import UI



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
    , isApplicable : Bool
    }


evaluationDecoder : Decode.Decoder Evaluation
evaluationDecoder =
    Decode.succeed Evaluation
        |> Decode.required "nodeValue" P.nodeValueDecoder
        |> Decode.required "isApplicable" Decode.bool


type alias Model =
    { rawRules : P.RawRules
    , evaluations : Dict P.RuleName Evaluation
    , situation : P.Situation
    , questions : UI.Questions
    , resultRules : List ( P.RuleName, P.RawRule )
    , categories : UI.Categories
    , orderedCategories : List UI.Category
    , allCategorieAndSubcategorieNames : List P.RuleName
    , openedCategories : Dict P.RuleName Bool
    , currentError : Maybe AppError
    , currentTab : Maybe UI.Category
    }


type AppError
    = DecodeError Decode.Error
    | UnvalidSituationFile


emptyModel : Model
emptyModel =
    { rawRules = Dict.empty
    , evaluations = Dict.empty
    , questions = Dict.empty
    , situation = Dict.empty
    , categories = Dict.empty
    , resultRules = []
    , orderedCategories = []
    , allCategorieAndSubcategorieNames = []
    , currentError = Nothing
    , currentTab = Nothing
    , openedCategories = Dict.empty
    }


type alias Flags =
    { rules : Json.Encode.Value
    , ui : Json.Encode.Value
    , situation : Json.Encode.Value
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    case
        ( Decode.decodeValue P.rawRulesDecoder flags.rules
        , Decode.decodeValue UI.uiDecoder flags.ui
        , Decode.decodeValue P.situationDecoder flags.situation
        )
    of
        ( Ok rawRules, Ok ui, Ok situation ) ->
            let
                orderedCategories =
                    UI.getOrderedCategories ui.categories
            in
            evaluate
                { emptyModel
                    | rawRules = rawRules
                    , questions = ui.questions
                    , resultRules = H.getResultRules rawRules
                    , categories = ui.categories
                    , situation = situation
                    , orderedCategories = orderedCategories
                    , allCategorieAndSubcategorieNames =
                        UI.getAllCategoryAndSubCategoryNames ui.categories
                    , currentTab = List.head orderedCategories
                }

        ( Err e, _, _ ) ->
            ( { emptyModel | currentError = Just (DecodeError e) }, Cmd.none )

        ( _, Err e, _ ) ->
            ( { emptyModel | currentError = Just (DecodeError e) }, Cmd.none )

        ( _, _, Err e ) ->
            ( { emptyModel | currentError = Just (DecodeError e) }, Cmd.none )


{-| We try to evaluate only the rules that need to be updated:

  - all the questions and subquestions of the current category
  - all the result rules
  - all the categories (as they are always displayed)
  - all the subcategories if displayed (for now they all are evaluated each time
    the situation changes)

-}
evaluate : Model -> ( Model, Cmd Msg )
evaluate model =
    let
        currentCategory =
            -- NOTE: we always have a currentTab
            Maybe.withDefault "" model.currentTab
    in
    let
        currentCategoryQuestions =
            Dict.get currentCategory model.questions
                |> Maybe.withDefault []
                |> List.concat
    in
    ( model
    , model.resultRules
        |> List.map Tuple.first
        |> List.append currentCategoryQuestions
        |> List.append model.orderedCategories
        |> List.append model.allCategorieAndSubcategorieNames
        |> Effect.evaluateAll
    )



-- UPDATE


type Msg
    = NewAnswer ( P.RuleName, P.NodeValue )
    | UpdateEvaluation ( P.RuleName, Json.Encode.Value )
    | UpdateAllEvaluation (List ( P.RuleName, Json.Encode.Value ))
    | Evaluate
    | ChangeTab P.RuleName
    | SetSubCategoryGraphStatus P.RuleName Bool
    | SelectFile
    | UploadedFile File
    | NewEncodedSituation String
    | ExportSituation
    | ResetSituation
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewAnswer ( name, value ) ->
            ( { model | situation = Dict.insert name value model.situation }
            , Effect.updateSituation ( name, P.nodeValueEncoder value )
            )

        UpdateEvaluation ( name, encodedEvaluation ) ->
            ( updateEvaluation ( name, encodedEvaluation ) model, Cmd.none )

        UpdateAllEvaluation encodedEvaluations ->
            ( List.foldl updateEvaluation model encodedEvaluations, Cmd.none )

        Evaluate ->
            evaluate model

        ChangeTab category ->
            evaluate { model | currentTab = Just category }

        SetSubCategoryGraphStatus category status ->
            let
                newOpenedCategories =
                    Dict.insert category status model.openedCategories
            in
            ( { model | openedCategories = newOpenedCategories }, Cmd.none )

        ExportSituation ->
            ( model
            , P.encodeSituation model.situation
                |> Json.Encode.encode 0
                |> File.Download.string "simulation-ekofest.json" "json"
            )

        UploadedFile file ->
            ( model, Task.perform NewEncodedSituation (File.toString file) )

        SelectFile ->
            ( model, File.Select.file [ "json" ] UploadedFile )

        ResetSituation ->
            ( { model | situation = Dict.empty }
            , Dict.empty
                |> P.encodeSituation
                |> Effect.setSituation
            )

        NewEncodedSituation encodedSituation ->
            case Decode.decodeString P.situationDecoder encodedSituation of
                Ok situation ->
                    ( { model | situation = situation }
                    , P.encodeSituation situation
                        |> Effect.setSituation
                    )

                Err _ ->
                    ( { model | currentError = Just UnvalidSituationFile }, Cmd.none )

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
    div [ class "flex flex-col min-h-screen justify-between" ]
        [ div []
            [ viewHeader
            , if Dict.isEmpty model.rawRules || Dict.isEmpty model.evaluations then
                div [ class "flex flex-col w-full items-center" ]
                    [ viewError model.currentError
                    , div [ class "loading loading-lg text-primary mt-4" ] []
                    ]

              else
                div
                    [ class "flex flex-col-reverse lg:grid lg:grid-cols-3" ]
                    [ div [ class "p-4 lg:pl-8 lg:pr-4 lg:col-span-2" ]
                        [ lazy2 viewCategoriesTabs model.orderedCategories model.currentTab
                        , lazy viewCategoryQuestions model
                        ]
                    , lazy viewError model.currentError
                    , div [ class "flex flex-col p-4 lg:pl-4 lg:col-span-1 lg:pr-8" ]
                        [ lazy viewResult model
                        , lazy viewGraph model
                        ]
                    ]
            ]
        , viewFooter
        ]


viewHeader : Html Msg
viewHeader =
    let
        btnClass =
            "join-item btn-sm bg-base-100 font-semibold border border-base-200 hover:bg-base-200"
    in
    header []
        [ div [ class "flex items-center justify-between w-full px-8 mb-4 border-b border-base-200 text-primary bg-neutral" ]
            [ div [ class "flex items-center" ]
                [ div [ class "text-3xl font-bold text-dark m-2" ] [ text "EkoFest" ]
                , span [ class "badge badge-accent badge-outline" ] [ text "beta" ]
                ]
            , div [ class "join join-vertical p-2 sm:join-horizontal" ]
                [ button [ class (btnClass ++ " btn-primary"), onClick ResetSituation ] [ text "Recommencer ↺ " ]
                , button [ class btnClass, onClick ExportSituation ] [ text "Exporter ↑" ]
                , button
                    [ class btnClass
                    , type_ "file"
                    , multiple False
                    , accept ".json"
                    , onClick SelectFile
                    ]
                    [ text "Importer ↓" ]
                ]
            ]
        ]


viewFooter : Html Msg
viewFooter =
    footer []
        [ div [ class "flex flex-col gap-y-2 items-center justify-center w-full px-4 py-4 mt-4 border-t border-base-200 text-primary bg-neutral" ]
            [ div [ class "flex gap-x-4" ]
                [ a
                    [ class "hover:text-primary cursor-pointer"
                    , href "https://ekofest.github.io/publicodes-evenements"
                    , target "_blank"
                    ]
                    [ text "Consulter le modèle de calcul" ]
                , div [ class "text-base-200" ]
                    [ text " | " ]
                , a
                    [ class "hover:text-primary cursor-pointer"
                    , href "https://github.com/ekofest/ekofest"
                    , target "_blank"
                    ]
                    [ text "Consulter le code source" ]
                ]
            , div [ class "text-accent text-sm" ] [ text "Fait avec amour par Milou et Clemog au Moulin Bonne Vie 🏡" ]
            ]
        ]


viewError : Maybe AppError -> Html Msg
viewError maybeError =
    case maybeError of
        Just (DecodeError e) ->
            div [ class "alert alert-error flex" ]
                [ Icons.error
                , span [] [ text (Decode.errorToString e) ]
                ]

        Just UnvalidSituationFile ->
            div [ class "alert alert-error flex" ]
                [ Icons.error
                , span [] [ text "Le fichier renseigné ne contient pas de situation valide." ]
                ]

        Nothing ->
            text ""


viewCategoriesTabs : List UI.Category -> Maybe P.RuleName -> Html Msg
viewCategoriesTabs categories currentTab =
    div [ class "flex flex-wrap md:justify-center bg-neutral rounded-md border border-base-200 p-2 mb-4" ]
        [ ul [ class "menu menu-horizontal gap-2" ]
            (categories
                |> List.map
                    (\category ->
                        let
                            activeClass =
                                currentTab
                                    |> Maybe.andThen
                                        (\tab ->
                                            if tab == category then
                                                Just " bg-primary text-white border-transparent"

                                            else
                                                Nothing
                                        )
                                    |> Maybe.withDefault ""
                        in
                        li []
                            [ a
                                [ class
                                    ("bg-base-100 rounded-md border border-base-200 cursor-pointer px-4 py-2 text-xs font-semibold hover:bg-primary hover:text-white hover:border-transparent"
                                        ++ activeClass
                                    )
                                , onClick (ChangeTab category)
                                ]
                                [ text (String.toUpper category) ]
                            ]
                    )
            )
        ]


viewCategoryQuestions : Model -> Html Msg
viewCategoryQuestions model =
    let
        currentCategory =
            Maybe.withDefault "" model.currentTab
    in
    div [ class "bg-neutral border-x border-b border-base-200 rounded-md " ]
        (model.categories
            |> Dict.toList
            |> List.map
                (\( category, _ ) ->
                    let
                        toShow =
                            currentCategory == category
                    in
                    Animated.div showCategoryContent
                        [ class "mb-8"
                        , style "display"
                            (if toShow then
                                "block"

                             else
                                "none"
                            )
                        ]
                        [ div [ class "pl-6 bg-base-200 font-semibold p-2 border border-base-300 rounded-t-md" ]
                            [ text (String.toUpper category)
                            ]
                        , viewMarkdownCategoryDescription model category
                        , viewQuestions model (Dict.get category model.questions)
                        ]
                )
        )


showCategoryContent : Animation
showCategoryContent =
    Animation.fromTo
        { duration = 250
        , options = [ Animation.easeIn ]
        }
        [ AnimProp.opacity 0.5 ]
        [ AnimProp.opacity 1 ]


viewMarkdownCategoryDescription : Model -> String -> Html Msg
viewMarkdownCategoryDescription model currentCategory =
    let
        categoryDescription =
            Dict.get currentCategory model.rawRules
                |> Maybe.andThen (\ruleCategory -> ruleCategory.description)
    in
    case categoryDescription of
        Nothing ->
            text ""

        Just desc ->
            div [ class "px-6 py-3 mb-4 border-b bg-orange-50" ]
                [ div [ class "prose max-w-full" ] <|
                    Markdown.toHtml Nothing desc
                ]


viewQuestions : Model -> Maybe (List (List P.RuleName)) -> Html Msg
viewQuestions model maybeQuestions =
    case maybeQuestions of
        Just questions ->
            div [ class "grid grid-cols-1 lg:grid-cols-2 gap-6 px-6" ]
                (List.map (viewSubQuestions model) questions)

        Nothing ->
            text ""


viewSubQuestions : Model -> List P.RuleName -> Html Msg
viewSubQuestions model subquestions =
    div [ class "bg-neutral rounded-md p-4 border border-base-200" ]
        (subquestions
            |> List.map
                (\name ->
                    case ( Dict.get name model.rawRules, Dict.get name model.evaluations ) of
                        ( Just rule, Just eval ) ->
                            viewQuestion model ( name, rule ) eval.isApplicable

                        _ ->
                            text ""
                )
        )


viewQuestion : Model -> ( P.RuleName, P.RawRule ) -> Bool -> Html Msg
viewQuestion model ( name, rule ) isApplicable =
    rule.title
        |> Maybe.map
            (\title ->
                div []
                    [ label [ class "form-control mb-1" ]
                        [ div [ class "label" ]
                            [ span [ class "label-text text-md font-semibold" ] [ text title ]
                            , span [ class "label-text-alt text-md" ] [ viewUnit rule ]
                            ]
                        , if name == "transport . public . parts totales" then
                            viewCustomTransportTotal model name

                          else
                            viewInput model ( name, rule ) isApplicable
                        ]
                    ]
            )
        |> Maybe.withDefault (text "")


viewCustomTransportTotal : Model -> P.RuleName -> Html Msg
viewCustomTransportTotal model name =
    let
        maybeNodeValue =
            Dict.get name model.evaluations
                |> Maybe.map (\{ nodeValue } -> nodeValue)
    in
    case maybeNodeValue of
        Just (P.Num num) ->
            if num == 100 then
                div [ class "text-end text-success" ] [ text "100 % ✅" ]

            else
                div [ class "text-end text-error" ] [ text (H.formatFloatToFrenchLocale 1 num ++ " %") ]

        _ ->
            text ""


viewInput : Model -> ( P.RuleName, P.RawRule ) -> Bool -> Html Msg
viewInput model ( name, rule ) isApplicable =
    let
        newAnswer val =
            case String.toFloat val of
                Just value ->
                    NewAnswer ( name, P.Num value )

                Nothing ->
                    if String.isEmpty val then
                        NoOp

                    else
                        NewAnswer ( name, P.Str val )
    in
    let
        maybeNodeValue =
            Dict.get name model.evaluations
                |> Maybe.map .nodeValue
    in
    if not isApplicable then
        viewDisabledInput

    else
        case ( ( rule.formula, rule.unit ), maybeNodeValue ) of
            ( ( Just (UnePossibilite { possibilites }), _ ), Just nodeValue ) ->
                viewSelectInput model.rawRules name possibilites nodeValue

            ( ( _, Just "%" ), Just (P.Num num) ) ->
                viewRangeInput num newAnswer

            ( _, Just (P.Num num) ) ->
                viewNumberInputOnlyPlaceHolder num newAnswer

            ( _, Just (P.Boolean bool) ) ->
                viewBooleanRadioInput name bool

            ( _, Just (P.Str _) ) ->
                -- Should not happen
                viewDisabledInput

            _ ->
                viewDisabledInput


viewNumberInput : Float -> (String -> Msg) -> Bool -> Html Msg
viewNumberInput num newAnswer isDisabled =
    div [ class "flex flex-row-reverse" ]
        [ input
            [ type_ "number"
            , disabled isDisabled
            , class "input input-bordered"
            , value (String.fromFloat num)
            , onInput newAnswer
            ]
            []
        ]


viewNumberInputOnlyPlaceHolder : Float -> (String -> Msg) -> Html Msg
viewNumberInputOnlyPlaceHolder num newAnswer =
    input
        [ type_ "number"
        , class "input input-bordered"
        , placeholder (String.fromFloat num)
        , onInput newAnswer
        ]
        []


viewSelectInput : P.RawRules -> P.RuleName -> List String -> P.NodeValue -> Html Msg
viewSelectInput rules ruleName possibilites nodeValue =
    select
        [ onInput (\v -> NewAnswer ( ruleName, P.Str v ))
        , class "select select-bordered"
        ]
        (possibilites
            |> List.map
                (\possibilite ->
                    option
                        [ value possibilite
                        , selected (H.getStringFromSituation nodeValue == possibilite)
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
                [ class "radio radio-sm"
                , type_ "radio"
                , checked bool
                , onCheck (\b -> NewAnswer ( name, P.Boolean b ))
                ]
                []
            ]
        , label [ class "label cursor-pointer" ]
            [ span [ class "label-text" ] [ text "Non" ]
            , input
                [ class "radio radio-sm"
                , type_ "radio"
                , checked (not bool)
                , onCheck (\b -> NewAnswer ( name, P.Boolean (not b) ))
                ]
                []
            ]
        ]


viewRangeInput : Float -> (String -> Msg) -> Html Msg
viewRangeInput num newAnswer =
    div [ class "flex flex-row" ]
        [ input
            [ type_ "range"
            , class "range range-accent range-xs my-2"
            , value (String.fromFloat num)
            , onInput newAnswer
            , Html.Attributes.min "0"
            , Html.Attributes.max "100"

            -- Should use `plancher` and `plafond` attributes
            ]
            []
        , span
            [ class "ml-4" ]
            [ text (String.fromFloat num) ]
        ]


viewDisabledInput : Html Msg
viewDisabledInput =
    input [ class "input", disabled True ] []



-- Results


viewResult : Model -> Html Msg
viewResult model =
    div [ class "stats stats-vertical border w-full rounded-md bg-neutral border-base-200" ]
        (model.resultRules
            |> List.map
                (\( name, rule ) ->
                    div [ class "stat" ]
                        [ div [ class "stat-title" ]
                            [ text (H.getTitle model.rawRules name) ]
                        , div [ class "flex items-baseline" ]
                            [ div [ class "stat-value text-primary" ]
                                [ viewEvaluation (Dict.get name model.evaluations) ]
                            , div [ class "stat-desc text-primary ml-2 text-base" ] [ viewUnit rule ]
                            ]
                        ]
                )
        )


viewEvaluation : Maybe Evaluation -> Html Msg
viewEvaluation eval =
    case eval of
        Just { nodeValue } ->
            text (P.nodeValueToString nodeValue)

        Nothing ->
            text ""


viewUnit : P.RawRule -> Html Msg
viewUnit rawRule =
    case rawRule.unit of
        Just "l" ->
            text " litre"

        Just unit ->
            text (" " ++ unit)

        Nothing ->
            text ""


getInfos : Model -> P.RuleName -> Float -> Maybe { title : String, percent : Float, result : Float }
getInfos model rule total =
    Dict.get rule model.evaluations
        |> Maybe.andThen
            (\{ nodeValue } ->
                case nodeValue of
                    P.Num value ->
                        Just
                            { title = H.getTitle model.rawRules rule
                            , percent = (value / total) * 100
                            , result = value
                            }

                    _ ->
                        Nothing
            )


viewGraph : Model -> Html Msg
viewGraph model =
    let
        total =
            Dict.get H.totalRuleName model.evaluations
                |> Maybe.andThen (\{ nodeValue } -> P.nodeValueToFloat nodeValue)
                |> Maybe.withDefault 0
    in
    let
        categoryInfos =
            model.categories
                |> Dict.toList
                |> List.filterMap
                    (\( category, { subs } ) ->
                        getInfos model category total
                            |> Maybe.andThen
                                (\{ title, percent, result } ->
                                    Just
                                        { category = title
                                        , percent = percent
                                        , result = result
                                        , subCatInfos =
                                            List.filterMap
                                                (\sub -> getInfos model sub result)
                                                subs
                                        }
                                )
                    )
    in
    div [ class "border border-base-200 w-full rounded-md bg-neutral mt-4" ]
        (categoryInfos
            |> List.sortBy .percent
            |> List.reverse
            |> List.indexedMap
                (\i { category, percent, result, subCatInfos } ->
                    let
                        containerClass =
                            if i == 0 then
                                " rounded-t-md"

                            else
                                " border-t border-base-200"
                    in
                    let
                        isHidden =
                            Dict.get category model.openedCategories
                                |> Maybe.withDefault True
                    in
                    details [ class ("collapse rounded-none" ++ containerClass) ]
                        [ summary
                            [ class "collapse-title cursor-pointer hover:bg-base-200 rounded-none pr-4"

                            -- TODO: learn about local state component in elm
                            , onClick (SetSubCategoryGraphStatus category (not isHidden))
                            ]
                            [ viewGraphStat category percent result (Just isHidden) ]
                        , div [ class "collapse-content p-0 m-0 bg-base-100" ]
                            [ viewSubCategoryGraph subCatInfos
                            ]
                        ]
                )
        )


viewGraphStat : String -> Float -> Float -> Maybe Bool -> Html Msg
viewGraphStat title percent result isHidden =
    div []
        [ div [ class "stat-title flex w-full justify-between" ]
            [ span []
                [ text (String.toUpper title)
                , span [ class "ml-2 font-bold" ] [ text (H.formatFloatToFrenchLocale 0 (result / 1000) ++ " tCO2e") ]
                ]
            , viewCategoryArrow isHidden
            ]
        , div [ class "flex items-center" ]
            [ div
                [ class "stat-value text-primary text-2xl text-right w-20 mr-4" ]
                [ text
                    (H.formatFloatToFrenchLocale 1 percent
                        ++ " %"
                    )
                ]
            , progress [ class "progress progress-primary h-3", value (String.fromFloat percent), Html.Attributes.max "100" ] []
            ]
        ]


viewCategoryArrow : Maybe Bool -> Html Msg
viewCategoryArrow isHidable =
    case isHidable of
        Nothing ->
            text ""

        Just isHidden ->
            span [ class "mr-2 text-xs" ]
                [ if isHidden then
                    Icons.chevronUp

                  else
                    Icons.chevronDown
                ]


showSubCat : Animation
showSubCat =
    Animation.fromTo
        { duration = 250
        , options = []
        }
        [ AnimProp.opacity 0.6, AnimProp.y -50 ]
        [ AnimProp.opacity 1, AnimProp.y 0 ]



-- viewSubCategoryGraph : Bool -> List { subCat : P.RuleName, percent : Float, totalSubCat : Float } -> Html Msg


viewSubCategoryGraph : List { title : String, percent : Float, result : Float } -> Html Msg
viewSubCategoryGraph subCatInfos =
    div [ class "p-4 border-t border-base-200 bg-base-100" ]
        (subCatInfos
            |> List.sortBy .percent
            |> List.reverse
            |> List.map
                (\{ title, percent, result } ->
                    viewSubCatGraphStat title percent result
                )
        )


viewSubCatGraphStat : String -> Float -> Float -> Html Msg
viewSubCatGraphStat title percent result =
    div [ class "mb-0" ]
        [ div [ class "stat-title text-sm flex w-full justify-between" ]
            [ span [] [ text (String.toUpper title) ]
            , span [] [ text (H.formatFloatToFrenchLocale 0 (result / 1000) ++ " tCO2e") ]
            ]
        , div [ class "flex items-center" ]
            [ div
                [ class "stat-value text-accent text-lg  w-16 mr-4" ]
                [ text
                    (H.formatFloatToFrenchLocale 1 percent
                        ++ " %"
                    )
                ]
            , progress [ class "progress progress-accent h-2", value (String.fromFloat percent), Html.Attributes.max "100" ] []
            ]
        ]



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Effect.evaluatedRule UpdateEvaluation
        , Effect.evaluatedRules UpdateAllEvaluation
        , Effect.situationUpdated (\_ -> Evaluate)
        ]

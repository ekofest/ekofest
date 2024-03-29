module Page.Home exposing (Model, Msg(..), init, subscriptions, update, view)

import Dict exposing (Dict)
import Effect
import FormatNumber.Locales exposing (Decimals(..))
import Helpers as H
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (lazy, lazy2)
import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import Json.Encode
import Markdown
import Platform.Cmd as Cmd
import Publicodes as P exposing (Mecanism(..), NodeValue(..))
import Session as S
import UI
import Views.Icons as Icons



-- MODEL


type alias Model =
    { session : S.Data
    , resultRules : List ( P.RuleName, P.RawRule )
    , orderedCategories : List UI.Category
    , allCategorieAndSubcategorieNames : List P.RuleName
    , openedCategories : Dict P.RuleName Bool
    , evaluations : Dict P.RuleName Evaluation
    , currentTab : Maybe UI.Category
    }


{-| TODO: should it be moved in Publicodes module?
-}
type alias Evaluation =
    { nodeValue : P.NodeValue
    , isApplicable : Bool
    }


evaluationDecoder : Decode.Decoder Evaluation
evaluationDecoder =
    Decode.succeed Evaluation
        |> Decode.required "nodeValue" P.nodeValueDecoder
        |> Decode.required "isApplicable" Decode.bool


emptyModel : Model
emptyModel =
    { session = S.empty
    , evaluations = Dict.empty
    , resultRules = []
    , orderedCategories = []
    , allCategorieAndSubcategorieNames = []
    , currentTab = Nothing
    , openedCategories = Dict.empty
    }


init : S.Data -> ( Model, Cmd Msg )
init session =
    let
        orderedCategories =
            UI.getOrderedCategories session.ui.categories
    in
    evaluate
        { emptyModel
            | session = session
            , resultRules = H.getResultRules session.rawRules
            , orderedCategories = orderedCategories
            , allCategorieAndSubcategorieNames =
                UI.getAllCategoryAndSubCategoryNames session.ui.categories
            , currentTab = List.head orderedCategories
        }


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
        session =
            model.session
    in
    if session.engineInitialized then
        let
            currentCategory =
                -- NOTE: we always have a currentTab
                Maybe.withDefault "" model.currentTab

            currentCategoryQuestions =
                Dict.get currentCategory session.ui.questions
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

    else
        ( model, Cmd.none )



-- UPDATE


type Msg
    = NewAnswer ( P.RuleName, P.NodeValue )
    | ChangeTab P.RuleName
    | SetSubCategoryGraphStatus P.RuleName Bool
    | Evaluate
    | UpdateEvaluation ( P.RuleName, Json.Encode.Value )
    | UpdateAllEvaluation (List ( P.RuleName, Json.Encode.Value ))
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewAnswer ( name, value ) ->
            ( S.updateSituation (Dict.insert name value) model
            , Effect.updateSituation ( name, P.nodeValueEncoder value )
            )

        ChangeTab category ->
            let
                ( newModel, cmd ) =
                    evaluate { model | currentTab = Just category }
            in
            ( newModel, Cmd.batch [ Effect.scrollTo ( 0, 0 ), cmd ] )

        SetSubCategoryGraphStatus category status ->
            let
                newOpenedCategories =
                    Dict.insert category status model.openedCategories
            in
            ( { model | openedCategories = newOpenedCategories }, Cmd.none )

        Evaluate ->
            evaluate model

        UpdateEvaluation ( name, encodedEvaluation ) ->
            ( updateEvaluation ( name, encodedEvaluation ) model, Cmd.none )

        UpdateAllEvaluation encodedEvaluations ->
            ( List.foldl updateEvaluation model encodedEvaluations, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


updateEvaluation : ( P.RuleName, Json.Encode.Value ) -> Model -> Model
updateEvaluation ( name, encodedEvaluation ) model =
    case Decode.decodeValue evaluationDecoder encodedEvaluation of
        Ok eval ->
            { model | evaluations = Dict.insert name eval model.evaluations }

        Err e ->
            S.updateError (\_ -> Just (S.DecodeError e)) model



-- VIEW


view : Model -> Html Msg
view model =
    let
        session =
            model.session
    in
    div []
        [ if Dict.isEmpty model.evaluations then
            div [ class "flex flex-col w-full h-full items-center" ]
                [ div [ class "loading loading-lg text-primary mt-4" ] []
                ]

          else
            div []
                [ lazy2 viewCategoriesTabs model.orderedCategories model.currentTab
                , div
                    [ class "flex flex-col-reverse lg:grid lg:grid-cols-3" ]
                    [ div [ class "p-4 lg:pl-8 lg:pr-4 lg:col-span-2" ]
                        [ lazy viewCategoryQuestions model
                        ]
                    , if not session.engineInitialized then
                        div [ class "flex flex-col w-full h-full items-center" ]
                            [ div [ class "loading loading-lg text-primary mt-4" ] []
                            ]

                      else
                        div [ class "flex flex-col p-4 lg:pl-4 lg:col-span-1 lg:pr-8" ]
                            [ div [ class "lg:sticky lg:top-4" ]
                                [ lazy viewResults model
                                , lazy viewGraph model
                                ]
                            ]
                    ]
                ]
        ]


viewCategoriesTabs : List UI.Category -> Maybe P.RuleName -> Html Msg
viewCategoriesTabs categories currentTab =
    div [ class "flex bg-neutral rounded-md border-b border-base-200 mb-4 px-6 overflow-x-auto" ]
        (categories
            |> List.indexedMap
                (\i category ->
                    let
                        isActive =
                            currentTab == Just category
                    in
                    button
                        [ class
                            ("flex items-center rounded-none cursor-pointer border-b p-4 tracking-wide text-xs hover:bg-base-100 "
                                ++ (if isActive then
                                        " border-primary font-semibold"

                                    else
                                        " border-transparent font-medium"
                                   )
                            )
                        , onClick (ChangeTab category)
                        ]
                        [ span
                            [ class
                                ("rounded-full inline-flex justify-center items-center w-5 h-5 mr-2 font-normal"
                                    ++ (if isActive then
                                            " text-white bg-primary"

                                        else
                                            " bg-gray-300"
                                       )
                                )
                            ]
                            [ text (String.fromInt (i + 1)) ]
                        , text (String.toUpper category)
                        ]
                )
        )


viewCategoryQuestions : Model -> Html Msg
viewCategoryQuestions model =
    let
        session =
            model.session

        currentCategory =
            Maybe.withDefault "" model.currentTab
    in
    div [ class "bg-neutral border border-base-200 rounded-md mb-4" ]
        (session.ui.categories
            |> Dict.toList
            |> List.map
                (\( category, _ ) ->
                    let
                        isVisible =
                            currentCategory == category
                    in
                    div
                        [ class
                            -- Add duration to trigger transition
                            -- TODO: better transition
                            ("flex flex-col transition-opacity ease-in duration-0"
                                ++ (if isVisible then
                                        "  mb-6 opacity-100"

                                    else
                                        " opacity-50"
                                   )
                            )
                        ]
                        (if isVisible then
                            [ viewMarkdownCategoryDescription session.rawRules category
                            , viewQuestions model (Dict.get category session.ui.questions)
                            , viewCategoriesNavigation model.orderedCategories category
                            ]

                         else
                            []
                        )
                )
        )


viewCategoriesNavigation : List UI.Category -> String -> Html Msg
viewCategoriesNavigation orderedCategories category =
    let
        nextList =
            H.dropUntilNext ((==) category) ("empty" :: orderedCategories)

        maybePrevCategory =
            if List.head nextList == Just "empty" then
                Nothing

            else
                List.head nextList

        maybeNextCategory =
            nextList
                |> List.drop 2
                |> List.head
    in
    div [ class "flex justify-between mt-6 mx-6" ]
        [ case maybePrevCategory of
            Just prevCategory ->
                button
                    [ class "btn btn-sm btn-primary btn-outline self-end"
                    , onClick (ChangeTab prevCategory)
                    ]
                    [ Icons.chevronLeft, text (String.toUpper prevCategory) ]

            _ ->
                div [] []
        , case maybeNextCategory of
            Just nextCategory ->
                button
                    [ class "btn btn-sm btn-primary self-end text-white"
                    , onClick (ChangeTab nextCategory)
                    ]
                    [ text (String.toUpper nextCategory), Icons.chevronRight ]

            _ ->
                div [] []
        ]


viewMarkdownCategoryDescription : P.RawRules -> String -> Html Msg
viewMarkdownCategoryDescription rawRules currentCategory =
    let
        categoryDescription =
            Dict.get currentCategory rawRules
                |> Maybe.andThen (\ruleCategory -> ruleCategory.description)
    in
    case categoryDescription of
        Nothing ->
            text ""

        Just desc ->
            div [ class "px-6 py-3 mb-6 border-b rounded-t-md bg-orange-50" ]
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
    div [ class "bg-neutral rounded p-4 border border-base-200" ]
        (subquestions
            |> List.map
                (\name ->
                    case ( Dict.get name model.session.rawRules, Dict.get name model.evaluations ) of
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
                div [ class "text-end text-error" ] [ text (H.formatPercent num) ]

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
                        -- FIXME: there is a little delay when updatin an empty input
                        NoOp

                    else
                        NewAnswer ( name, P.Str val )

        maybeNodeValue =
            Dict.get name model.evaluations
                |> Maybe.map .nodeValue
    in
    if not isApplicable then
        viewDisabledInput

    else
        case ( ( rule.formula, rule.unit ), maybeNodeValue ) of
            ( ( Just (UnePossibilite { possibilites }), _ ), Just nodeValue ) ->
                viewSelectInput model.session.rawRules name possibilites nodeValue

            ( ( _, Just "%" ), Just (P.Num num) ) ->
                viewRangeInput num newAnswer

            ( _, Just (P.Num num) ) ->
                case Dict.get name model.session.situation of
                    Just _ ->
                        viewNumberInput num newAnswer

                    Nothing ->
                        viewNumberInputOnlyPlaceHolder num newAnswer

            ( _, Just (P.Boolean bool) ) ->
                viewBooleanRadioInput name bool

            ( _, Just (P.Str _) ) ->
                -- Should not happen
                viewDisabledInput

            _ ->
                viewDisabledInput


viewNumberInput : Float -> (String -> Msg) -> Html Msg
viewNumberInput num newAnswer =
    input
        [ type_ "number"
        , class "input input-bordered"
        , value (String.fromFloat num)
        , onInput newAnswer
        ]
        []


viewNumberInputOnlyPlaceHolder : Float -> (String -> Msg) -> Html Msg
viewNumberInputOnlyPlaceHolder num newAnswer =
    input
        [ type_ "number"
        , class "input input-bordered"
        , placeholder (H.formatFloatToFrenchLocale (Max 1) num)
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


viewResults : Model -> Html Msg
viewResults model =
    div [ class "stats stats-vertical border w-full rounded-md bg-neutral border-base-200" ]
        (model.resultRules
            |> List.map
                (\( name, { unit } ) ->
                    let
                        title =
                            H.getTitle model.session.rawRules name
                    in
                    case Dict.get name model.evaluations of
                        Just { nodeValue } ->
                            case nodeValue of
                                P.Num value ->
                                    if unit == Just "kgCO2e" || unit == Nothing then
                                        viewResult title value

                                    else
                                        viewResultError title

                                _ ->
                                    viewResultError title

                        _ ->
                            viewResultError title
                )
        )


viewResultError : String -> Html Msg
viewResultError title =
    div [ class "stat" ]
        [ div [ class "stat-title" ]
            [ text title ]
        , div [ class "flex items-baseline" ]
            [ div [ class "stat-value text-error" ]
                [ Icons.circleSlash2 ]
            , div [ class "stat-desc text-error text-xl ml-2" ]
                [ text "une erreur est survenue" ]
            ]
        ]


viewResult : String -> Float -> Html Msg
viewResult title value =
    let
        ( formatedValue, formatedUnit ) =
            H.formatCarbonResult value
    in
    div [ class "stat" ]
        [ div [ class "stat-title" ]
            [ text title ]
        , div [ class "flex items-baseline" ]
            [ div [ class "stat-value text-primary" ]
                [ text formatedValue ]
            , div [ class "stat-desc text-primary ml-2 text-lg font-semibold" ]
                [ text formatedUnit ]
            ]
        ]


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
                            { title = H.getTitle model.session.rawRules rule
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

        categoryInfos =
            model.session.ui.categories
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
                [ span [] [ text (String.toUpper title) ]
                , span [ class "ml-2 font-bold text-primary" ]
                    [ text (H.formatPercent percent)
                    ]
                ]
            , viewCategoryArrow isHidden
            ]
        , div [ class "flex items-center" ]
            [ div [ class "flex justify-start min-w-24 items-baseline text-accent mr-2" ]
                [ div [ class "stat-value text-2xl" ] [ text (H.formatFloatToFrenchLocale (Exact 0) (result / 1000)) ]
                , div [ class "stats-desc ml-2" ] [ text " tCO2e" ]
                ]
            , div [ class "flex-1" ]
                [ progress
                    [ class "progress progress-primary h-3"
                    , value (String.fromFloat percent)
                    , Html.Attributes.max "100"
                    ]
                    []
                ]
            ]
        ]


viewCategoryArrow : Maybe Bool -> Html Msg
viewCategoryArrow isHidable =
    span [ class "mr-2 text-xs" ]
        [ if isHidable == Just True then
            Icons.chevronDown

          else
            Icons.chevronUp
        ]


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
        [ div [ class "flex justify-between stat-title text-md" ]
            [ span [] [ text (String.toUpper title) ]
            , span [ class "ml-2 font-bold" ]
                [ text (H.formatPercent percent)
                ]
            ]
        , div [ class "flex items-center" ]
            [ div
                [ class "flex justify-start min-w-20 items-baseline text-accent mr-2" ]
                [ div [ class "stat-value text-lg" ] [ text (H.formatFloatToFrenchLocale (Exact 0) (result / 1000)) ]
                , div [ class "stats-desc text-sm ml-1" ] [ text " tCO2e" ]
                ]
            , progress [ class "progress progress-accent h-2", value (String.fromFloat percent), Html.Attributes.max "100" ] []
            ]
        ]



-- Subscriptions


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ Effect.evaluatedRule UpdateEvaluation
        , Effect.evaluatedRules UpdateAllEvaluation
        , Effect.situationUpdated (\_ -> Evaluate)
        ]

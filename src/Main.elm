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
                div []
                    [ lazy2 viewCategoriesTabs model.orderedCategories model.currentTab
                    , div
                        [ class "flex flex-col-reverse lg:grid lg:grid-cols-3" ]
                        [ div [ class "p-4 lg:pl-8 lg:pr-4 lg:col-span-2" ]
                            [ lazy viewCategoryQuestions model
                            ]
                        , lazy viewError model.currentError
                        , div [ class "flex flex-col p-4 lg:pl-4 lg:col-span-1 lg:pr-8" ]
                            [ lazy viewResult model
                            , lazy viewGraph model
                            ]
                        ]
                    ]
            ]
        , viewFooter
        ]


viewHeader : Html Msg
viewHeader =
    let
        btnClass =
            "join-item btn-sm bg-base-100 border border-base-200 hover:bg-base-200"
    in
    header []
        [ div [ class "flex items-center justify-between w-full px-4 lg:px-8 border-b border-base-200 bg-neutral" ]
            [ div [ class "flex items-center" ]
                [ -- div [ class "text-3xl font-semibold text-dark m-2 text-primary" ] [ text "ekofest" ]
                  img [ src "/assets/logo.svg", class "w-32" ] []
                , span [ class "badge badge-accent badge-outline" ] [ text "beta" ]
                ]
            , div [ class "join join-vertical p-2 sm:join-horizontal" ]
                [ button [ class btnClass, onClick ResetSituation ]
                    [ span [ class "mr-2" ] [ Icons.refresh ], text "Recommencer" ]
                , button [ class btnClass, onClick ExportSituation ]
                    [ span [ class "mr-2" ] [ Icons.download ]
                    , text "Télécharger"
                    ]
                , button
                    [ class btnClass
                    , type_ "file"
                    , multiple False
                    , accept ".json"
                    , onClick SelectFile
                    ]
                    [ span [ class "mr-2" ] [ Icons.upload ]
                    , text "Importer"
                    ]
                ]
            ]
        ]


viewFooter : Html Msg
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
                    , a [ class "link", href "https://github.com/EmileRolley", target "_blank" ] [ text "Milou" ]
                    , text " et "
                    , a [ class "link", href "https://github.com/clemog", target "_blank" ] [ text "Clemog" ]
                    , text " au Moulin Bonne Vie"
                    ]
                ]
            , nav []
                [ h6 [ class "footer-title" ] [ text "Liens utiles" ]
                , a
                    [ class "link link-hover"
                    , href "https://ekofest.github.io/publicodes-evenements"
                    , target "_blank"
                    ]
                    [ text "Documentation du modèle" ]
                , a
                    [ class "link link-hover"
                    , href "https://github.com/ekofest/publicodes-evenements"
                    , target "_blank"
                    ]
                    [ text "Code source du modèle" ]
                , a
                    [ class "link link-hover"
                    , href "https://github.com/ekofest/ekofest"
                    , target "_blank"
                    ]
                    [ text "Code source du site" ]
                ]
            , a [ class "w-24", href "https://bff.ecoindex.fr/redirect/?url=https://ekofest.fr", target "_blank" ]
                [ img [ src "https://bff.ecoindex.fr/badge/?theme=light&url=https://ekofest.fr", alt "Ecoindex Badge" ] []
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
        currentCategory =
            Maybe.withDefault "" model.currentTab
    in
    div [ class "bg-neutral border border-base-200 rounded-md mb-4" ]
        (model.categories
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
                            [ viewMarkdownCategoryDescription model.rawRules category
                            , viewQuestions model (Dict.get category model.questions)
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


viewNumberInputOnlyPlaceHolder : Float -> (String -> Msg) -> Html Msg
viewNumberInputOnlyPlaceHolder num newAnswer =
    input
        [ type_ "number"
        , class "input input-bordered"
        , placeholder (H.formatFloatToFrenchLocale 1 num)
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
                            [ div [ class "stat-value text-primary font-bold" ]
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
                , span [ class "ml-2 font-semibold text-primary" ]
                    [ text
                        (H.formatFloatToFrenchLocale 1 percent
                            ++ " %"
                        )
                    ]
                ]
            , viewCategoryArrow isHidden
            ]
        , div [ class "flex items-center" ]
            [ div [ class "flex justify-start min-w-24 items-baseline text-accent mr-2" ]
                [ div [ class "stat-value font-semibold text-2xl" ] [ text (H.formatFloatToFrenchLocale 0 (result / 1000)) ]
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
                [ text
                    (H.formatFloatToFrenchLocale 1 percent
                        ++ " %"
                    )
                ]
            ]
        , div [ class "flex items-center" ]
            [ div
                [ class "flex justify-start min-w-20 items-baseline text-accent mr-2" ]
                [ div [ class "stat-value font-semibold text-lg" ] [ text (H.formatFloatToFrenchLocale 0 (result / 1000)) ]
                , div [ class "stats-desc text-sm ml-1" ] [ text " tCO2e" ]
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

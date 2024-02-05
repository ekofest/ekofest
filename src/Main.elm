module Main exposing (..)

import Browser
import Dict
import Effect
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Json.Encode
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


type alias Model =
    { rawRules : P.RawRules
    , total : Maybe P.NodeValue -- TODO: we need to store all sub nodes values
    , situation : P.Situation
    }


emptyModel : Model
emptyModel =
    { rawRules = Dict.empty
    , total = Nothing
    , situation = Dict.empty
    }


type alias Flags =
    Decode.Value


init : Flags -> ( Model, Cmd Msg )
init rules =
    case rules |> Decode.decodeValue P.rawRulesDecoder of
        Ok rawRules ->
            ( { emptyModel | rawRules = rawRules }, Effect.evaluate P.rootNodeName )

        Err e ->
            let
                _ =
                    Debug.log "Error" e
            in
            -- TODO: prints an error
            ( emptyModel, Effect.evaluate P.rootNodeName )



-- UPDATE


type Msg
    = NewAnswer ( P.RuleName, P.NodeValue )
    | UpdateNodeValue ( P.RuleName, Json.Encode.Value )
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

        UpdateNodeValue ( name, encodedValue ) ->
            if name == P.rootNodeName then
                case Decode.decodeValue P.nodeValueDecoder encodedValue of
                    Ok value ->
                        ( { model | total = Just value }, Cmd.none )

                    Err _ ->
                        -- TODO: should print an error
                        ( model, Cmd.none )

            else
                ( model, Cmd.none )

        Evaluate () ->
            ( model, Effect.evaluate P.rootNodeName )

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    case Dict.toList model.rawRules of
        [] ->
            div [] [ text "Il n'y a pas de règles" ]

        rules ->
            div []
                [ h3 [ class "flex" ] [ text "Questions" ]
                , viewRules rules model
                , h3 [] [ text "Total" ]
                , i []
                    [ text ("[" ++ rootNodeName ++ "]: ")
                    , viewTotal model.total
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


viewRules : List ( P.RuleName, P.RawRule ) -> Model -> Html Msg
viewRules rules model =
    ol []
        (rules
            |> List.filterMap
                (\( name, rule ) ->
                    rule.question
                        |> Maybe.map
                            (\question ->
                                li []
                                    [ div [] [ text question ]
                                    , viewQuestion model ( name, rule )
                                    ]
                            )
                )
        )



-- Questions


viewQuestion : Model -> ( P.RuleName, P.RawRule ) -> Html Msg
viewQuestion model ( name, rule ) =
    let
        newAnswer val =
            case String.toFloat val of
                Just value ->
                    NewAnswer ( name, P.Num value )

                Nothing ->
                    if String.isEmpty val then
                        NewAnswer ( name, P.Empty )

                    else
                        let
                            _ =
                                Debug.log "newAnswer" val
                        in
                        NewAnswer ( name, P.Str val )
    in
    let
        viewDefaultValue defaultValue =
            case defaultValue of
                P.Num num ->
                    input
                        [ type_ "number"
                        , value (String.fromFloat num)
                        , onInput newAnswer
                        ]
                        []

                P.Str str ->
                    input
                        [ type_ "text"
                        , value str
                        , onInput newAnswer
                        ]
                        []

                P.Boolean bool ->
                    input
                        [ type_ "checkbox"
                        , value
                            (if bool then
                                "true"

                             else
                                "false"
                            )
                        , onInput newAnswer
                        ]
                        []

                P.Empty ->
                    input [ type_ "number" ] []
    in
    case rule.formula of
        Just (UnePossibilite { possibilites }) ->
            select
                [ onInput newAnswer ]
                (possibilites
                    |> List.map
                        (\possibilite ->
                            option
                                [ value possibilite
                                ]
                                [ text possibilite ]
                        )
                )

        _ ->
            case ( Dict.get name model.situation, rule.default ) of
                ( Just situationValue, _ ) ->
                    input
                        [ value (P.nodeValueToString situationValue)
                        , onInput newAnswer
                        ]
                        []

                ( Nothing, Just defaultValue ) ->
                    viewDefaultValue defaultValue

                ( Nothing, Nothing ) ->
                    input [ type_ "number", onInput newAnswer ] []


viewTotal : Maybe P.NodeValue -> Html Msg
viewTotal total =
    strong []
        [ case total of
            Just (P.Num value) ->
                text (String.fromFloat value)

            Just (P.Str value) ->
                text value

            Just P.Empty ->
                text "empty"

            Just (P.Boolean value) ->
                text
                    (if value then
                        "oui"

                     else
                        "non"
                    )

            Nothing ->
                text "_"
        ]



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Effect.evaluatedNodeValue UpdateNodeValue
        , Effect.situationUpdated Evaluate
        ]

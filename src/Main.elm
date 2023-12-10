module Main exposing (..)

-- Press buttons to increment and decrement a counter.
--
-- Read how it works:
--   https://guide.elm-lang.org/architecture/buttons.html
--

import Browser
import Dict
import Effect
import Html exposing (Html, div, input, li, ol, text)
import Html.Attributes exposing (type_, value)
import Html.Events exposing (onInput)
import Json.Decode as Decode exposing (Value)
import Json.Encode
import Publicodes as P



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element { init = init, update = update, view = view, subscriptions = subscriptions }



-- MODEL


type alias Model =
    { rawRules : P.RawRules
    , total : Maybe P.NodeValue -- TODO: we need to store all sub nodes values
    , situation : P.Situation
    }


emptyModel : Model
emptyModel =
    { rawRules = Dict.empty, total = Nothing, situation = Dict.empty }


type alias Flags =
    Value


init : Flags -> ( Model, Cmd Msg )
init rules =
    case rules |> Decode.decodeValue P.rawRulesDecoder of
        Ok rawRules ->
            ( { emptyModel | rawRules = rawRules }, Effect.evaluate P.rootNodeName )

        Err _ ->
            -- TODO: prints an error
            ( emptyModel, Effect.evaluate P.rootNodeName )



-- UPDATE


type Msg
    = NewNumberAnswer ( P.RuleName, P.NodeValue )
    | UpdateNodeValue ( P.RuleName, Json.Encode.Value )
    | Evaluate ()
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewNumberAnswer ( name, value ) ->
            let
                newSituation =
                    case value of
                        P.Str _ ->
                            Dict.insert name value model.situation

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
                [ text "Règles disponibles :"
                , viewRules rules model
                , text "Total (a x 10) = "
                , viewTotal model.total
                ]


viewRules : List ( P.RuleName, P.RawRule ) -> Model -> Html Msg
viewRules rules model =
    ol []
        (List.map (viewQuestion model) rules)


viewQuestion : Model -> ( P.RuleName, P.RawRule ) -> Html Msg
viewQuestion model ( name, rule ) =
    let
        newNumberAnswer =
            \val ->
                case String.toFloat val of
                    Just value ->
                        NewNumberAnswer ( name, P.Num value )

                    Nothing ->
                        NewNumberAnswer ( name, P.Empty )
    in
    case rule.question of
        Just question ->
            li []
                [ div [] [ text name, text " : ", text question ]
                , case Dict.get name model.situation of
                    Just situationValue ->
                        input
                            [ type_ "number"
                            , value (P.nodeValueToString situationValue)
                            , onInput newNumberAnswer
                            ]
                            []

                    Nothing ->
                        let
                            _ =
                                Debug.log "Test"
                        in
                        Dict.get name model.rawRules
                            |> Maybe.andThen (\rawRule -> rawRule.default)
                            |> Maybe.andThen
                                (\defaultValue ->
                                    Just
                                        (input
                                            [ type_ "number"
                                            , value defaultValue
                                            , onInput newNumberAnswer
                                            ]
                                            []
                                        )
                                )
                            |> Maybe.withDefault
                                (input [ type_ "number", onInput newNumberAnswer ] [])
                ]

        Nothing ->
            li [] [ text name ]


viewTotal : Maybe P.NodeValue -> Html Msg
viewTotal total =
    case total of
        Just (P.Num value) ->
            text (String.fromFloat value)

        Just (P.Str value) ->
            text value

        Just P.Empty ->
            text "empty"

        Nothing ->
            text "..."



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Effect.evaluatedNodeValue UpdateNodeValue
        , Effect.situationUpdated Evaluate
        ]

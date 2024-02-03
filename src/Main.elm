module Main exposing (..)

import Browser
import Dict
import Effect
import Html as H exposing (Html)
import Html.Attributes exposing (class, type_, value)
import Html.Events exposing (onInput)
import Json.Decode as Decode
import Json.Encode
import Publicodes as P exposing (rootNodeName)



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
            H.div [] [ H.text "Il n'y a pas de règles" ]

        rules ->
            H.div []
                [ H.h3 [ class "flex" ] [ H.text "Questions" ]
                , viewRules rules model
                , H.h3 [] [ H.text "Total" ]
                , H.i []
                    [ H.text ("[" ++ rootNodeName ++ "]: ")
                    , viewTotal model.total
                    , viewUnit (Dict.get rootNodeName model.rawRules)
                    ]
                ]


viewUnit : Maybe P.RawRule -> Html Msg
viewUnit maybeRawRule =
    case maybeRawRule of
        Just rawRule ->
            H.text (" " ++ Maybe.withDefault "" rawRule.unit)

        Nothing ->
            H.text ""


viewRules : List ( P.RuleName, P.RawRule ) -> Model -> Html Msg
viewRules rules model =
    H.ol []
        (rules
            |> List.filterMap
                (\( name, rule ) ->
                    rule.question |> Maybe.map (\_ -> viewQuestion model ( name, rule ))
                )
        )


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
                        NewAnswer ( name, P.Str val )
    in
    let
        viewDefaultValue defaultValue =
            case defaultValue of
                P.Num num ->
                    H.input
                        [ type_ "number"
                        , value (String.fromFloat num)
                        , onInput newAnswer
                        ]
                        []

                P.Str str ->
                    H.input
                        [ type_ "text"
                        , value str
                        , onInput newAnswer
                        ]
                        []

                P.Empty ->
                    H.input [ type_ "number" ] []
    in
    case rule.question of
        Just question ->
            H.li []
                [ H.div [] [ H.text name, H.text " : ", H.text question ]
                , case ( Dict.get name model.situation, rule.default ) of
                    ( Just situationValue, _ ) ->
                        let
                            _ =
                                Debug.log "situationValue" situationValue
                        in
                        H.input
                            [ value (P.nodeValueToString situationValue)
                            , onInput newAnswer
                            ]
                            []

                    ( Nothing, Just defaultValue ) ->
                        let
                            _ =
                                Debug.log "defaultValue" defaultValue
                        in
                        viewDefaultValue defaultValue

                    ( Nothing, Nothing ) ->
                        H.input [ type_ "number", onInput newAnswer ] []
                ]

        Nothing ->
            H.li [] [ H.text name ]


viewTotal : Maybe P.NodeValue -> Html Msg
viewTotal total =
    H.strong []
        [ case total of
            Just (P.Num value) ->
                H.text (String.fromFloat value)

            Just (P.Str value) ->
                H.text value

            Just P.Empty ->
                H.text "empty"

            Nothing ->
                H.text "_"
        ]



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Effect.evaluatedNodeValue UpdateNodeValue
        , Effect.situationUpdated Evaluate
        ]

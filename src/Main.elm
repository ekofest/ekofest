port module Main exposing (..)

-- Press buttons to increment and decrement a counter.
--
-- Read how it works:
--   https://guide.elm-lang.org/architecture/buttons.html
--

import Browser
import Dict
import Html exposing (Html, div, input, li, ol, text)
import Html.Attributes exposing (type_)
import Html.Events exposing (onInput)
import Json.Decode as Decode
import Publicodes exposing (RawRules)


type Rules
    = Value


type alias Flags =
    { rules : String
    , total : Float
    }



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element { init = init, update = update, view = view, subscriptions = subscriptions }



-- MODEL


type alias Model =
    { rawRules : RawRules
    , total : Float
    }


init : Flags -> ( Model, Cmd Msg )
init { rules, total } =
    case rules |> Decode.decodeString Publicodes.rawRulesDecoder of
        Ok rawRules ->
            ( { rawRules = rawRules, total = total }, Cmd.none )

        Err _ ->
            ( { rawRules = Dict.fromList [], total = total }, Cmd.none )



-- Ports


port evaluateWith : Int -> Cmd msg


port totalUpdated : (Float -> msg) -> Sub msg



-- UPDATE


type Msg
    = NewAnswer String
    | UpdateTotal Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewAnswer value ->
            case String.toInt value of
                Nothing ->
                    ( model, Cmd.none )

                Just intValue ->
                    ( model, evaluateWith intValue )

        UpdateTotal total ->
            ( { model | total = total }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    case Dict.toList model.rawRules of
        [] ->
            div [] [ text "Il n'y a pas de règles" ]

        rules ->
            div []
                [ text "Règles disponibles :"
                , ol []
                    (rules
                        |> List.map
                            (\( key, rule ) ->
                                case rule.question of
                                    Nothing ->
                                        li [] [ text key ]

                                    Just question ->
                                        li []
                                            [ div [] [ text key, text " : ", text question ]
                                            , input [ type_ "number", onInput NewAnswer ] []
                                            ]
                            )
                    )
                , text "Total (a x 10): "
                , text (String.fromFloat model.total)
                ]



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions _ =
    totalUpdated UpdateTotal

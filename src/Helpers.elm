module Helpers exposing (..)

import Dict exposing (Dict)
import File exposing (File)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), frenchLocale)
import Json.Decode as Decode exposing (Decoder)
import Publicodes as P


resultNamespace : P.RuleName
resultNamespace =
    "resultats"


totalRuleName : P.RuleName
totalRuleName =
    "resultats . bilan total"


getQuestions : P.RawRules -> List String -> Dict String (List P.RuleName)
getQuestions rules categories =
    Dict.toList rules
        |> List.filterMap
            (\( name, rule ) ->
                Maybe.map (\_ -> name) rule.question
            )
        |> List.foldl
            (\name dict ->
                let
                    category =
                        P.namespace name
                in
                if List.member category categories then
                    Dict.update category
                        (\maybeList ->
                            case maybeList of
                                Just list ->
                                    Just (name :: list)

                                Nothing ->
                                    Just [ name ]
                        )
                        dict

                else
                    dict
            )
            Dict.empty


isInCategory : P.RuleName -> P.RuleName -> Bool
isInCategory category ruleName =
    P.splitRuleName ruleName
        |> List.head
        |> Maybe.withDefault ""
        |> (\namespace -> namespace == category)


getTitle : P.RawRules -> P.RuleName -> String
getTitle rules name =
    case Dict.get name rules of
        Just rule ->
            Maybe.withDefault name rule.title

        Nothing ->
            name


{-| TODO: should find a way to use the [disambiguateReference] function from
[publicodes]
-}
getOptionTitle : P.RawRules -> P.RuleName -> P.RuleName -> String
getOptionTitle rules contexte optionVal =
    rules
        |> Dict.get (contexte ++ " . " ++ optionVal)
        |> Maybe.andThen (\r -> r.title)
        |> Maybe.withDefault optionVal


formatFloatToFrenchLocale : Int -> Float -> String
formatFloatToFrenchLocale n =
    format { frenchLocale | decimals = Max n }


filesDecoder : Decoder (List File)
filesDecoder =
    Decode.at [ "target", "files" ] (Decode.list File.decoder)

module Publicodes exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, nullable, string)
import Json.Decode.Pipeline exposing (optional)


type alias RawRules =
    Dict RuleName RawRule


type alias RuleName =
    String


type alias RawRule =
    { question : Maybe String
    , résumé : Maybe String
    , unité : Maybe String
    }


rawRuleDecoder : Decoder RawRule
rawRuleDecoder =
    Decode.succeed RawRule
        |> optional "question" (nullable string) Nothing
        |> optional "résumé" (nullable string) Nothing
        |> optional "unité" (nullable string) Nothing


rawRulesDecoder : Decoder RawRules
rawRulesDecoder =
    Decode.dict rawRuleDecoder

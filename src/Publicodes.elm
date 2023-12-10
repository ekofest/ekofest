module Publicodes exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, nullable, string)
import Json.Decode.Pipeline exposing (optional)
import Json.Encode as Encode


type alias RuleName =
    String


rootNodeName : RuleName
rootNodeName =
    "root"


type NodeValue
    = Str String
    | Num Float
    | Empty


nodeValueDecoder : Decoder NodeValue
nodeValueDecoder =
    Decode.oneOf
        [ Decode.map Str Decode.string
        , Decode.map Num Decode.float
        ]


nodeValueEncoder : NodeValue -> Encode.Value
nodeValueEncoder nodeValue =
    case nodeValue of
        Str str ->
            Encode.string str

        Num num ->
            Encode.float num

        Empty ->
            Encode.null


nodeValueToString : NodeValue -> String
nodeValueToString nodeValue =
    case nodeValue of
        Str str ->
            str

        Num num ->
            String.fromFloat num

        Empty ->
            ""


type alias RawRules =
    Dict RuleName RawRule


type alias Situation =
    Dict RuleName NodeValue


situationDecoder : Decoder Situation
situationDecoder =
    Decode.dict nodeValueDecoder


encodeSituation : Situation -> Encode.Value
encodeSituation situation =
    Encode.dict identity nodeValueEncoder situation


type alias RawRule =
    { question : Maybe String
    , summary : Maybe String
    , unit : Maybe String
    , default : Maybe String
    , formula : Maybe String
    }


rawRuleDecoder : Decoder RawRule
rawRuleDecoder =
    Decode.succeed RawRule
        |> optional "question" (nullable string) Nothing
        |> optional "résumé" (nullable string) Nothing
        |> optional "unité" (nullable string) Nothing
        |> optional "par défaut" (nullable string) Nothing
        |> optional "formule" (nullable string) Nothing


rawRulesDecoder : Decoder RawRules
rawRulesDecoder =
    Decode.dict rawRuleDecoder

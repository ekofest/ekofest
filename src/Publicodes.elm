module Publicodes exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, field, list, map, nullable, string)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode


type alias RuleName =
    String


rootNodeName : RuleName
rootNodeName =
    "bilan"


type NodeValue
    = Str String
    | Num Float
      -- TODO: what to do with empty values?
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
    , default : Maybe NodeValue
    , formula : Maybe Mecanism
    }



-- TODO: could be more precise


type alias Clause =
    { si : Maybe String
    , alors : Maybe String
    , sinon : Maybe String
    }


clauseDecoder : Decoder Clause
clauseDecoder =
    Decode.succeed Clause
        |> optional "si" (nullable string) Nothing
        |> optional "alors" (nullable string) Nothing
        |> optional "sinon" (nullable string) Nothing


type alias Possibilite =
    { choix_obligatoire : Maybe String
    , possibilites : List String
    }


possibiliteDecoder : Decoder Possibilite
possibiliteDecoder =
    Decode.succeed Possibilite
        |> optional "choix obligatoire" (nullable string) Nothing
        |> required "possibilités" (list string)


type Mecanism
    = Ref RuleName
    | Val NodeValue
    | Expr String
    | Somme (List String)
    | Moyenne (List String)
    | Variations (List Clause)
    | UnePossibilite Possibilite


mecansismDecoder : Decoder Mecanism
mecansismDecoder =
    Decode.oneOf
        [ map Ref (field "ref" string)
        , map Val nodeValueDecoder
        , map Expr string
        , map Somme (field "somme" (list string))
        , map Moyenne (field "moyenne" (list string))
        , map Variations (field "variations" (list clauseDecoder))
        , map UnePossibilite (field "une possibilité" possibiliteDecoder)
        ]


rawRuleDecoder : Decoder RawRule
rawRuleDecoder =
    Decode.succeed RawRule
        |> optional "question" (nullable string) Nothing
        |> optional "résumé" (nullable string) Nothing
        |> optional "unité" (nullable string) Nothing
        |> optional "par défaut" (nullable nodeValueDecoder) Nothing
        |> optional "formule" (nullable mecansismDecoder) Nothing


rawRulesDecoder : Decoder RawRules
rawRulesDecoder =
    Decode.dict rawRuleDecoder

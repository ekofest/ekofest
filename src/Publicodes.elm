module Publicodes exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, field, list, map, nullable, string)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode


type alias RuleName =
    String


rootNodeName : RuleName
rootNodeName =
    "resultats . bilan total"


type NodeValue
    = Str String
    | Num Float
    | Boolean Bool
    | Empty


decodeBool : Decoder Bool
decodeBool =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "oui" ->
                        Decode.succeed True

                    "non" ->
                        Decode.succeed False

                    _ ->
                        Decode.fail "expected 'oui' or 'non'"
            )


nodeValueDecoder : Decoder NodeValue
nodeValueDecoder =
    Decode.oneOf
        [ Decode.map Str Decode.string
        , Decode.map Num Decode.float
        , Decode.map Boolean decodeBool
        , Decode.null Empty
        ]


nodeValueEncoder : NodeValue -> Encode.Value
nodeValueEncoder nodeValue =
    case nodeValue of
        Str str ->
            Encode.string (toConstantString str)

        Num num ->
            Encode.float num

        Boolean bool ->
            if bool then
                Encode.string "oui"

            else
                Encode.string "non"

        Empty ->
            Encode.null


nodeValueToString : NodeValue -> String
nodeValueToString nodeValue =
    case nodeValue of
        Str str ->
            str

        Num num ->
            String.fromFloat num

        Boolean bool ->
            if bool then
                "oui"

            else
                "non"

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
    { si : Maybe NodeValue
    , alors : Maybe NodeValue
    , sinon : Maybe NodeValue
    }


clauseDecoder : Decoder Clause
clauseDecoder =
    Decode.succeed Clause
        |> optional "si" (nullable nodeValueDecoder) Nothing
        |> optional "alors" (nullable nodeValueDecoder) Nothing
        |> optional "sinon" (nullable nodeValueDecoder) Nothing


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
    = Expr NodeValue
    | Somme (List String)
    | Moyenne (List String)
    | Variations (List Clause)
    | UnePossibilite Possibilite


mecanismDecoder : Decoder Mecanism
mecanismDecoder =
    Decode.oneOf
        [ map Expr nodeValueDecoder
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
        |> optional "formule" (nullable mecanismDecoder) Nothing


rawRulesDecoder : Decoder RawRules
rawRulesDecoder =
    Decode.dict rawRuleDecoder



-- Helpers


{-| Publicodes enums needs to be single quoted

TODO: express constant strings in a more type-safe way

-}
toConstantString : String -> String
toConstantString str =
    "'" ++ str ++ "'"

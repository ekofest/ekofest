module Publicodes exposing (..)

import Dict exposing (Dict)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), frenchLocale)
import Json.Decode as Decode exposing (Decoder, field, lazy, list, map, nullable, string)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode


type alias RuleName =
    String


type alias SplitedRuleName =
    List RuleName


type NodeValue
    = Str String
    | Num Float
    | Boolean Bool
    | Empty


nodeValueDecoder : Decoder NodeValue
nodeValueDecoder =
    Decode.oneOf
        [ Decode.map
            (\str ->
                case str of
                    "oui" ->
                        Boolean True

                    "non" ->
                        Boolean False

                    _ ->
                        Str str
            )
            Decode.string
        , Decode.map Num Decode.float
        , Decode.map Boolean Decode.bool
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
            format { frenchLocale | decimals = Exact 1 } num

        Boolean bool ->
            if bool then
                "oui"

            else
                "non"

        Empty ->
            ""


nodeValueToFloat : NodeValue -> Maybe Float
nodeValueToFloat nodeValue =
    case nodeValue of
        Num num ->
            Just num

        _ ->
            Nothing


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
    , default : Maybe Mecanism
    , formula : Maybe Mecanism
    , title : Maybe String
    , note : Maybe String
    }



-- TODO: could be more precise


type alias Clause =
    { si : Maybe Mecanism
    , alors : Maybe Mecanism
    , sinon : Maybe Mecanism
    }


clauseDecoder : Decoder Clause
clauseDecoder =
    Decode.succeed Clause
        |> optional "si" (nullable mecanismDecoder) Nothing
        |> optional "alors" (nullable mecanismDecoder) Nothing
        |> optional "sinon" (nullable mecanismDecoder) Nothing


type alias PossibiliteNode =
    { choix_obligatoire : Maybe String
    , possibilites : List String
    }


possibiliteNodeDecoder : Decoder PossibiliteNode
possibiliteNodeDecoder =
    Decode.succeed PossibiliteNode
        |> optional "choix obligatoire" (nullable string) Nothing
        |> required "possibilités" (list string)


type alias RecalculNode =
    { regle : RuleName
    , avec : Situation
    }


recalculNodeDecoder : Decoder RecalculNode
recalculNodeDecoder =
    Decode.succeed RecalculNode
        |> required "règle" string
        |> required "avec" situationDecoder


type Mecanism
    = Expr NodeValue
    | Somme (List String)
    | Moyenne (List String)
    | Variations (List Clause)
    | UnePossibilite PossibiliteNode
    | ToutesCesConditions (List Clause)
    | UneDeCesConditions (List Clause)
    | Recalcul RecalculNode


mecanismDecoder : Decoder Mecanism
mecanismDecoder =
    Decode.oneOf
        [ map Expr nodeValueDecoder
        , map Somme (field "somme" (list string))
        , map Moyenne (field "moyenne" (list string))
        , map Variations (field "variations" (list (lazy (\_ -> clauseDecoder))))
        , map UnePossibilite (field "une possibilité" possibiliteNodeDecoder)
        , map ToutesCesConditions (field "toutes ces conditions" (list (lazy (\_ -> clauseDecoder))))
        , map UneDeCesConditions (field "une de ces conditions" (list (lazy (\_ -> clauseDecoder))))
        , map Recalcul (field "recalcul" recalculNodeDecoder)
        ]


rawRuleDecoder : Decoder RawRule
rawRuleDecoder =
    Decode.succeed RawRule
        |> optional "question" (nullable string) Nothing
        |> optional "résumé" (nullable string) Nothing
        |> optional "unité" (nullable string) Nothing
        |> optional "par défaut" (nullable mecanismDecoder) Nothing
        |> optional "formule" (nullable mecanismDecoder) Nothing
        |> optional "titre" (nullable string) Nothing
        |> optional "note" (nullable string) Nothing


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


splitRuleName : RuleName -> SplitedRuleName
splitRuleName ruleName =
    String.split " . " ruleName


namespace : RuleName -> RuleName
namespace ruleName =
    splitRuleName ruleName
        |> List.head
        |> Maybe.withDefault ruleName

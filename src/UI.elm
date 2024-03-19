module UI exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Publicodes as P


type alias Category =
    P.RuleName


type alias CategoryInfos =
    { index : Int
    , subs : List P.RuleName
    }


decodeCategoryInfos : Decoder CategoryInfos
decodeCategoryInfos =
    Decode.succeed CategoryInfos
        |> required "index" int
        |> required "sub" (list string)


{-| Contains the list of categories and the list of sub-categories
-}
type alias Categories =
    Dict Category CategoryInfos


{-| Contains the list of questions and the list of sub-questions for each category
-}
type alias Questions =
    Dict Category (List (List P.RuleName))


type alias Data =
    { categories : Categories
    , questions : Questions
    }


empty : Data
empty =
    { categories = Dict.empty
    , questions = Dict.empty
    }


uiDecoder : Decoder Data
uiDecoder =
    Decode.succeed Data
        |> required "categories" (dict decodeCategoryInfos)
        |> required "questions" (dict (list (list string)))



-- Helpers


getOrderedCategories : Categories -> List Category
getOrderedCategories categories =
    Dict.toList categories
        |> List.sortBy (\( _, { index } ) -> index)
        |> List.map Tuple.first


getAllCategoryAndSubCategoryNames : Categories -> List Category
getAllCategoryAndSubCategoryNames categories =
    categories
        |> Dict.toList
        |> List.concatMap (\( category, { subs } ) -> category :: subs)

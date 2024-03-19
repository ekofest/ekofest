module Personas exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Publicodes as P


type alias Personas =
    Dict String Persona


personasDecoder : Decoder Personas
personasDecoder =
    Decode.dict personaDecoder


type alias Persona =
    { titre : String
    , description : String
    , situation : P.Situation
    }


personaDecoder : Decoder Persona
personaDecoder =
    Decode.succeed Persona
        |> required "titre" string
        |> required "description" string
        |> required "situation" P.situationDecoder



-- Helpers

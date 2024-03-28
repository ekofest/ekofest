module Session exposing (..)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import Publicodes as P
import UI
import Views.Icons


{-| TODO: should [rawRules] and [ui] stored here?
-}
type alias Data =
    { engineInitialized : Bool
    , situation : P.Situation
    , currentErr : Maybe AppError
    , rawRules : P.RawRules
    , ui : UI.Data
    }


{-| Extensible record type alias for models that include a [Data] session.
-}
type alias WithSession a =
    { a | session : Data }


type AppError
    = DecodeError Decode.Error
    | UnvalidSituationFile


empty : Data
empty =
    { engineInitialized = False
    , rawRules = Dict.empty
    , situation = Dict.empty
    , ui = UI.empty
    , currentErr = Nothing
    }


init : P.RawRules -> P.Situation -> UI.Data -> Data
init rawRules situation ui =
    { empty
        | rawRules = rawRules
        , situation = situation
        , ui = ui
    }



-- UPDATE SITUATION HELPERS


updateEngineInitialized : Bool -> WithSession model -> WithSession model
updateEngineInitialized b model =
    let
        session =
            model.session

        newSession =
            { session | engineInitialized = b }
    in
    { model | session = newSession }


{-| NOTE: this could only accept a [P.Situation] as argument, but it's more flexible this way.
-}
updateSituation : (P.Situation -> P.Situation) -> WithSession model -> WithSession model
updateSituation f model =
    let
        session =
            model.session

        newSession =
            { session | situation = f session.situation }
    in
    { model | session = newSession }


updateError : (Maybe AppError -> Maybe AppError) -> WithSession model -> WithSession model
updateError f model =
    let
        session =
            model.session

        newSession =
            { session | currentErr = f session.currentErr }
    in
    { model | session = newSession }



-- VIEW HELPERS


viewError : Maybe AppError -> Html msg
viewError maybeError =
    case maybeError of
        Just (DecodeError e) ->
            div [ class "alert alert-error flex" ]
                [ Views.Icons.error
                , span [] [ text (Decode.errorToString e) ]
                ]

        Just UnvalidSituationFile ->
            div [ class "alert alert-error flex" ]
                [ Views.Icons.error
                , span [] [ text "Le fichier renseigné ne contient pas de situation valide." ]
                ]

        Nothing ->
            text ""

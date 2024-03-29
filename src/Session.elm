module Session exposing (..)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import Personas exposing (Personas)
import Publicodes as P
import UI
import Views.Icons



-- FLAGS
--
-- NOTE: Flags are used to pass data from outside the Elm runtime into the Elm
-- program (i.e. from the main.ts file to the Elm app).
--


type alias Flags =
    { rules : P.RawRules
    , ui : UI.Data
    , personas : Personas
    , situation : P.Situation
    }


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Decode.succeed Flags
        |> Decode.required "rules" P.rawRulesDecoder
        |> Decode.required "ui" UI.uiDecoder
        |> Decode.required "personas" Personas.personasDecoder
        |> Decode.required "situation" P.situationDecoder


{-| TODO: should [rawRules] and [ui] stored here?
-}
type alias Data =
    { engineInitialized : Bool
    , situation : P.Situation
    , currentErr : Maybe AppError
    , rawRules : P.RawRules
    , ui : UI.Data
    , personas : Personas
    , -- Used to show little ping on the personas button until the user opens the modal
      alreadyOpenedPersonasModal : Bool
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
    , personas = Dict.empty
    , alreadyOpenedPersonasModal = False
    , currentErr = Nothing
    }


init : Flags -> Data
init { rules, situation, ui, personas } =
    { empty
        | rawRules = rules
        , situation = situation
        , ui = ui
        , personas = personas
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


openPersonasModal : WithSession model -> WithSession model
openPersonasModal model =
    let
        session =
            model.session

        newSession =
            { session | alreadyOpenedPersonasModal = True }
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

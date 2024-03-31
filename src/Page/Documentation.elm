module Page.Documentation exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Encode
import Publicodes as P
import Session


type alias Model =
    { session : Session.Data
    , rule : P.RuleName
    }


init : Session.Data -> P.RuleName -> ( Model, Cmd Msg )
init session rule =
    ( { session = session
      , rule = rule
      }
    , Cmd.none
    )


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


view : Model -> Html Msg
view { session, rule } =
    let
        serializedSituation =
            Json.Encode.encode 0 (P.encodeSituation session.situation)
    in
    node "publicodes-rule-page"
        [ attribute "rule" rule
        , attribute "documentationPath" "/documentation"
        , attribute "situation" serializedSituation
        ]
        []

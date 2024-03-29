module Page.Documentation exposing (Model, Msg, init, update, view)

import Effect
import Helpers as H
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Encode
import Publicodes as P
import Session
import Views.Icons as Icons


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
view model =
    div []
        [ div [ id "publicodes-rule-page-container" ] []
        , viewRulePage model.rule model.session.situation
        ]


viewRulePage : P.RuleName -> P.Situation -> Html msg
viewRulePage rule situation =
    let
        serializedSituation =
            Json.Encode.encode 0 (P.encodeSituation situation)
    in
    node "publicodes-rule-page"
        [ attribute "rule" rule
        , attribute "documentationPath" "/documentation"
        , attribute "situation" serializedSituation
        ]
        []

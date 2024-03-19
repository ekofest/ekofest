module Page.Documentation exposing (Model, Msg, init, update, view)

import Html exposing (Html, div, text)
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


{-| TODO: could it be removed?
-}
type Msg
    = NoOp


update : Msg -> Model -> Model
update msg model =
    case msg of
        NoOp ->
            model


view : Model -> Html Msg
view model =
    div []
        [ div [] [ text "Documentation" ]
        , div [] [ text model.rule ]
        ]

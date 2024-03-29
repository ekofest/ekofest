module Page.Documentation exposing (Model, Msg, init, update, view)

import Helpers as H
import Html exposing (..)
import Html.Attributes exposing (..)
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
    div [ class "flex flex-col justify-center items-center w-full" ]
        [ div [ class "flex flex-col gap-4 justify-center items-center w-fit min-h-[75vh]" ]
            [ h1 [ class "text-5xl" ]
                [ text ("Documentation - " ++ H.getTitle model.session.rawRules model.rule) ]
            , p [] [ text "Cette page est en cours de construction." ]
            , a [ target "_blank", class "btn btn-primary text-white mt-8", href "https://ekofest.github.io/publicodes-evenements" ]
                [ Icons.bookOpenText
                , text "Visiter la documentation générale des règles"
                ]
            ]
        ]

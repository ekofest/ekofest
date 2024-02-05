port module Effect exposing (..)

import Json.Encode
import Publicodes



-- COMMANDS


port evaluate : Publicodes.RuleName -> Cmd msg


{-|

    The Situation needs to be encoded as a Json.Value

-}
port setSituation : Json.Encode.Value -> Cmd msg



-- SUBSCRIPTIONS


{-| Receives the result of the evaluation of a rule in the form of a tuple (ruleName, {nodeValue, missingsVariables}).
-}
port evaluatedRule : (( Publicodes.RuleName, Json.Encode.Value ) -> msg) -> Sub msg


port situationUpdated : (() -> msg) -> Sub msg

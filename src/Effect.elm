port module Effect exposing (..)

import Json.Encode
import Publicodes as P



-- COMMANDS


port evaluate : P.RuleName -> Cmd msg


port evaluateAll : List P.RuleName -> Cmd msg


port setSituation : Json.Encode.Value -> Cmd msg


port updateSituation : ( P.RuleName, Json.Encode.Value ) -> Cmd msg



-- SUBSCRIPTIONS


{-| Receives the result of the evaluation of a rule in the form of a tuple (ruleName, {nodeValue, missingsVariables}).
-}
port evaluatedRule : (( P.RuleName, Json.Encode.Value ) -> msg) -> Sub msg


port evaluatedRules : (List ( P.RuleName, Json.Encode.Value ) -> msg) -> Sub msg


port situationUpdated : (() -> msg) -> Sub msg

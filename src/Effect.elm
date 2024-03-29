port module Effect exposing (..)

import Json.Encode
import Publicodes as P



-- COMMANDS


port evaluate : P.RuleName -> Cmd msg


port evaluateAll : List P.RuleName -> Cmd msg


port setSituation : Json.Encode.Value -> Cmd msg


port updateSituation : ( P.RuleName, Json.Encode.Value ) -> Cmd msg


{-| window.scrollTo
-}
port scrollTo : ( Int, Int ) -> Cmd msg


{-| Calls the native function to show a modal with the given id.

```js
document.getElementById(id)?.showModal()
```

-}
port showModal : String -> Cmd msg


{-| Calls the native function to close a modal with the given id.

```js
document.getElementById(id)?.close()
```

-}
port closeModal : String -> Cmd msg



-- SUBSCRIPTIONS


{-| Receives the result of the evaluation of a rule in the form of a tuple (ruleName, {nodeValue, missingsVariables}).
-}
port evaluatedRule : (( P.RuleName, Json.Encode.Value ) -> msg) -> Sub msg


port evaluatedRules : (List ( P.RuleName, Json.Encode.Value ) -> msg) -> Sub msg


port situationUpdated : (() -> msg) -> Sub msg


port engineInitialized : (() -> msg) -> Sub msg


{-| A link was clicked in a react component
-}
port reactLinkClicked : (String -> msg) -> Sub msg

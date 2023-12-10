import Engine, { Rule } from "publicodes"
import { Elm } from "./Main.elm"
import EcoFestEngine, { RuleName, Situation } from "./EcoFestEngine"

const rules = JSON.parse(`{
  "root": {
    "formule": "a * 10"
  },
  "a": {
    "question": "Combien ?",
    "par défaut": "10"
  }
}`)

let app = Elm.Main.init({
    flags: rules,
    node: document.getElementById("elm-app"),
})

const engine = new EcoFestEngine(rules, app)

app.ports.setSituation.subscribe((newSituation: Situation) => {
    engine.setSituation(newSituation)
})

app.ports.evaluate.subscribe((rule: RuleName) => {
    engine.evaluate(rule)
})

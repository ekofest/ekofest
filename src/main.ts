// @ts-ignore
import { Elm } from "./Main.elm"
import EcoFestEngine, { RuleName, Situation } from "./EcoFestEngine"

const rules = JSON.parse(`{
  "root": {
    "formule": "a * (10 - b)"
  },
  "a": {
    "question": "Combien ?",
    "par défaut": "10"
  },
  "b": {
    "question": "Combien ?",
    "par défaut": "5"
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

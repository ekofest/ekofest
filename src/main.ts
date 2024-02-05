// @ts-ignore
import { Elm } from "./Main.elm"
import EcoFestEngine, { RuleName, Situation } from "./EcoFestEngine"
import rules from "publicodes-evenements"

let app = Elm.Main.init({
    flags: rules,
    node: document.getElementById("elm-app"),
})

const engine = new EcoFestEngine(rules, app)

console.log("app", engine.getParsedRules())

app.ports.setSituation.subscribe((newSituation: Situation) => {
    engine.setSituation(newSituation)
})

// app.ports.evaluate.subscribe((rule: RuleName) => {
//     engine.evaluate(rule)
// })
//
app.ports.evaluateAll.subscribe((rules: RuleName[]) => {
    engine.evaluateAll(rules)
})

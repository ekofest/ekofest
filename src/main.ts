// @ts-ignore
import { Elm } from "./Main.elm"
import EcoFestEngine, { RuleName, Situation } from "./EcoFestEngine"
import rules from "publicodes-evenements"
import { utils } from "publicodes"

console.log("rules", rules)

let app = Elm.Main.init({
    flags: rules,
    node: document.getElementById("elm-app"),
})

const engine = new EcoFestEngine(rules, app)

app.ports.setSituation.subscribe((newSituation: Situation) => {
    engine.setSituation(newSituation)
})

app.ports.evaluateAll.subscribe((rules: RuleName[]) => {
    engine.evaluateAll(rules)
})

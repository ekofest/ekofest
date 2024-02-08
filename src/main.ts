// @ts-ignore
import { Elm } from "./Main.elm"
import EcoFestEngine, { RuleName, Situation } from "./EcoFestEngine"
import rules, { ui } from "publicodes-evenements"

let app = Elm.Main.init({
    flags: { rules, ui },
    node: document.getElementById("elm-app"),
})

const engine = new EcoFestEngine(rules, app)

app.ports.setSituation.subscribe((newSituation: Situation) => {
    engine.setSituation(newSituation)
})

app.ports.evaluateAll.subscribe((rules: RuleName[]) => {
    engine.evaluateAll(rules)
})

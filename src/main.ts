// @ts-ignore
import { Elm } from "./Main.elm"
import EcoFestEngine, { RuleName, Situation } from "./EcoFestEngine"
import rules, { ui } from "publicodes-evenements"

const situation = JSON.parse(localStorage.getItem("situation") ?? "{}")

let app = Elm.Main.init({
    flags: { rules, ui, situation },
    node: document.getElementById("elm-app"),
})

const engine = new EcoFestEngine(rules, app)

app.ports.setSituation.subscribe((newSituation: Situation) => {
    engine.setSituation(newSituation)

    localStorage.setItem("situation", JSON.stringify(newSituation))
})

app.ports.evaluateAll.subscribe((rules: RuleName[]) => {
    engine.evaluateAll(rules)
})

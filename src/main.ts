// @ts-ignore
import { Elm } from "./Main.elm"
import EcoFestEngine, {
    PublicodeValue,
    RuleName,
    Situation,
} from "./EcoFestEngine"
import rules, { ui } from "publicodes-evenements"

let situation = JSON.parse(localStorage.getItem("situation") ?? "{}")

let app = Elm.Main.init({
    flags: { rules, ui, situation },
    node: document.getElementById("elm-app"),
})

const engine = new EcoFestEngine(rules, app).setSituation(situation)

app.ports.setSituation.subscribe((newSituation: Situation) => {
    engine.setSituation(newSituation)
    localStorage.setItem("situation", JSON.stringify(newSituation))
})

app.ports.updateSituation.subscribe(
    ([name, value]: [RuleName, PublicodeValue]) => {
        const newSituation = { ...engine.getSituation(), [name]: value }
        engine.setSituation(newSituation)
        localStorage.setItem("situation", JSON.stringify(newSituation))
    }
)

app.ports.evaluateAll.subscribe((rules: RuleName[]) => {
    engine.evaluateAll(rules)
})

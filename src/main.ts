// @ts-ignore
import { Elm } from "./Main.elm"
import EkofestEngine, {
    PublicodeValue,
    RuleName,
    Situation,
} from "./EkofestEngine"
import rules, { ui } from "publicodes-evenements"

let situation = JSON.parse(localStorage.getItem("situation") ?? "{}")

let app = Elm.Main.init({
    flags: { rules, ui, situation },
    node: document.getElementById("elm-app"),
})

// NOTE(@EmileRolley): I encapsulate the engine in a promise to be able to
// initialize it asynchronously. This is useful to avoid blocking the UI while
// the engine is being initialized.
const engine = await EkofestEngine.createAsync(rules, situation, app)

app.ports.engineInitialized.send(null)

app.ports.scrollTo.subscribe((x: number, y: number) => {
    window.scrollTo(x, y)
})

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

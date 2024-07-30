// @ts-ignore
import { Elm } from "./Main.elm"
import EkofestEngine, { PublicodeValue, RuleName } from "./EkofestEngine"

import rules, { ui, personas } from "publicodes-evenements"
import { defineCustomElementWith } from "./RulePageCustomElement"
import { Situation } from "publicodes"

const situation = JSON.parse(localStorage.getItem("situation") ?? "{}")

const app = Elm.Main.init({
    flags: { rules, ui, personas, situation },
    node: document.getElementById("elm-app"),
})

// NOTE(@EmileRolley): I encapsulate the engine in a promise to be able to
// initialize it asynchronously. This is useful to avoid blocking the UI while
// the engine is being initialized.
const engine = await EkofestEngine.createAsync(rules, situation, app)

// NOTE(@EmileRolley): I define the custom element that will be used to render
// the rule page.
//
// This must be done after the elm app is initialized because the custom element
// needs to access to a DOM element to render the rule page.
defineCustomElementWith(engine)

/// Basic ports

app.ports.scrollTo.subscribe((x: number, y: number) => {
    window.scrollTo(x, y)
})

app.ports.showModal.subscribe((id: string) => {
    const modal = document.getElementById(id)
    // @ts-ignore
    modal?.showModal()
})

app.ports.closeModal.subscribe((id: string) => {
    const modal = document.getElementById(id)
    // @ts-ignore
    modal?.close()
})

/// Publicodes

app.ports.engineInitialized.send(null)

app.ports.setSituation.subscribe((newSituation: Situation<RuleName>) => {
    // TODO: check if the situation is valid
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

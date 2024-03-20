import { RulePage } from "@publicodes/react-ui"
import React from "react"
import { Root, createRoot } from "react-dom/client"
import EkofestEngine from "./EkofestEngine"

export function defineCustomElementWith(engine: EkofestEngine) {
    customElements.define(
        "publicodes-rule-page",
        class extends HTMLElement {
            reactRoot: Root
            engine: EkofestEngine

            constructor() {
                super()
                this.reactRoot = createRoot(
                    document.getElementById(
                        "publicodes-rule-page-container"
                    ) as HTMLElement
                )
                this.engine = engine
                this.renderElement()
            }

            connectedCallback() {
                this.renderElement()
            }

            attributeChangedCallback() {
                this.renderElement()
            }

            renderElement() {
                const rulePath = this.getAttribute("rule") ?? ""
                this.reactRoot.render(
                    <RulePage
                        engine={this.engine}
                        rulePath={rulePath}
                        documentationPath={""}
                        language={"fr"}
                        renderers={{
                            Link: ({ to, children }) => (
                                <a href={to}>{children}</a>
                            ),
                        }}
                    />
                )
            }

            static get observedAttributes() {
                return ["rule"]
            }
        }
    )
}

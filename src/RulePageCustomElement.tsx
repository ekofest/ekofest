import { RulePage } from "@publicodes/react-ui"
import React from "react"
import { Root, createRoot } from "react-dom/client"
import EkofestEngine from "./EkofestEngine"

export function defineCustomElementWith(engine: EkofestEngine) {
    customElements.define(
        "publicodes-rule-page",
        class extends HTMLElement {
            shadow: ShadowRoot
            reactRoot: Root
            engine: EkofestEngine

            constructor() {
                super()
                // Encapsulates the component in a shadow DOM to avoid style conflicts
                this.shadow = this.attachShadow({ mode: "open" })
                this.reactRoot = createRoot(this.shadow)
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
                        documentationPath={""}
                        rulePath={rulePath}
                        engine={this.engine}
                        language={"fr"}
                        renderers={{
                            Link: ({ to, children }) => {
                                return <a href={to}>{children}</a>
                            },
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

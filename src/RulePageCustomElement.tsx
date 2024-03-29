import { RulePage } from "@publicodes/react-ui"
import React from "react"
import { Root, createRoot } from "react-dom/client"
import EkofestEngine from "./EkofestEngine"

const reactRootId = "react-root"

export function defineCustomElementWith(engine: EkofestEngine) {
    customElements.define(
        "publicodes-rule-page",
        class extends HTMLElement {
            reactRoot: Root
            engine: EkofestEngine

            constructor() {
                super()
                this.reactRoot = createRoot(
                    document.getElementById(reactRootId) as HTMLElement
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
                const documentationPath =
                    this.getAttribute("documentationPath") ?? ""

                if (!rulePath || !documentationPath) {
                    return null
                }

                this.reactRoot.render(
                    <RulePage
                        engine={this.engine}
                        rulePath={rulePath}
                        documentationPath={documentationPath}
                        language={"fr"}
                        searchBar={true}
                        renderers={{
                            Link: ({ to, children }) => (
                                <button
                                    onClick={(e) => {
                                        e.preventDefault()
                                        this.engine
                                            .getElmApp()
                                            .ports.reactLinkClicked.send(to)
                                    }}
                                >
                                    {children}
                                </button>
                            ),
                        }}
                    />
                )
            }

            static get observedAttributes() {
                return ["rule", "documentationPath"]
            }
        }
    )
}

import React, { Suspense } from "react"
import { Root, createRoot } from "react-dom/client"
import EkofestEngine from "./EkofestEngine"

const RulePage = React.lazy(() => import("./RulePage.tsx"))

const reactRootId = "react-root"

export function defineCustomElementWith(engine: EkofestEngine) {
    customElements.define(
        "publicodes-rule-page",
        class extends HTMLElement {
            reactRoot: Root
            engine: EkofestEngine

            static observedAttributes = [
                "rule",
                "documentationPath",
                "situation",
            ]

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
                console.log("attributeChangedCallback")
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
                    <Suspense
                        fallback={
                            <div className="flex flex-col items-center justify-center mb-8 w-full">
                                <div className="loading loading-lg text-primary mt-4"></div>
                            </div>
                        }
                    >
                        <RulePage
                            engine={this.engine}
                            rulePath={rulePath}
                            documentationPath={documentationPath}
                        />
                    </Suspense>
                )
            }
        }
    )
}

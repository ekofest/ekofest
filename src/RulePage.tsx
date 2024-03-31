import React from "react"
import { RulePage } from "@publicodes/react-ui"
import "./rule-page.css"
import Markdown from "react-markdown"
import remarkGfm from "remark-gfm"
import EkofestEngine from "./EkofestEngine"

/**
 * NOTE: I used lazy loading for the RulePage component mainly because otherwise it would
 * be bundled in the index.js file.
 * This would increase the size of the bundle and the time it takes to load any page.
 * Now, the RulePage component is bundled in a separate file and only loaded when needed.
 */

export type Props = {
    engine: EkofestEngine
    rulePath: string
    documentationPath: string
}

export default function ({ engine, rulePath, documentationPath }: Props) {
    return (
        <RulePage
            engine={engine}
            rulePath={rulePath}
            documentationPath={documentationPath}
            searchBar={true}
            language="fr"
            npmPackage="publicodes-evenements"
            renderers={{
                Text: ({ children }) => (
                    <Markdown
                        className={"markdown"}
                        remarkPlugins={[remarkGfm]}
                    >
                        {children}
                    </Markdown>
                ),
                Link: ({ to, children }) => (
                    <button
                        className="link"
                        onClick={(e) => {
                            e.preventDefault()
                            engine.getElmApp().ports.reactLinkClicked.send(to)
                        }}
                    >
                        {children}
                    </button>
                ),
            }}
        />
    )
}

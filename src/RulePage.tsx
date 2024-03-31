import React from "react"
import { RulePage } from "@publicodes/react-ui"
import "./rule-page.css"

/**
 * NOTE: I used lazy loading for the RulePage component mainly because otherwise it would
 * be bundled in the index.js file.
 * This would increase the size of the bundle and the time it takes to load any page.
 * Now, the RulePage component is bundled in a separate file and only loaded when needed.
 */

export const EkofestRulePage: typeof RulePage = (props) => {
    return <RulePage {...props} />
}

export default EkofestRulePage

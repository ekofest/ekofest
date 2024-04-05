import Engine, { ASTNode, PublicodesExpression, Rule } from 'publicodes'

export type RuleName = string
export type PublicodeValue = string | number
export type RawRule = Omit<Rule, 'nom'> | string | number
export type Situation = Record<RuleName, PublicodeValue>

export default class EkofestEngine extends Engine {
    private elmApp: any | null
    private situation: Readonly<Situation>

    constructor(rules: Record<RuleName, RawRule>) {
        super(rules)
        this.elmApp = null
        this.situation = {}
    }

    public static createAsync(
        rules: Readonly<Record<RuleName, RawRule>>,
        situation: Readonly<Situation>,
        app: any
    ) {
        return new Promise<EkofestEngine>((resolve) => {
            const nbRules = Object.keys(rules).length
            console.time(`[publicodes:parsing] ${nbRules} rules`)
            const engine = new EkofestEngine(rules).setSituation(situation)
            engine.setElmApp(app)
            console.timeEnd(`[publicodes:parsing] ${nbRules} rules`)
            resolve(engine)
        })
    }

    setElmApp(elmApp: any) {
        this.elmApp = elmApp
    }

    getElmApp() {
        return this.elmApp
    }

    getSituation(): Situation {
        return this.situation
    }

    setSituation(
        situation?: Partial<Record<RuleName, PublicodesExpression | ASTNode>>,
        options?: {
            keepPreviousSituation?: boolean
        }
    ): this {
        const filteredSituation = safeGetSituation({
            situation: situation as Situation,
            parsedRulesNames: Object.keys(this.getParsedRules()),
        })
        const res = super.setSituation(filteredSituation, options)
        this.situation = filteredSituation
        this.elmApp?.ports.situationUpdated.send(null)
        return res
    }

    evaluateAll(rules: RuleName[]) {
        const evaluatedRules = rules.map((rule) => {
            const result = super.evaluate(rule)
            const isApplicable =
                // NOTE(@EmileRolley): maybe checking [result.nodeValue !== null] is enough.
                // If we start to experience performance issues, we can remove the check
                // for [result.nodeValue !== null]
                super.evaluate({ 'est applicable': rule }).nodeValue === true
            return [
                rule,
                {
                    nodeValue: result.nodeValue ?? null,
                    isApplicable,
                },
            ]
        })
        this.elmApp?.ports.evaluatedRules.send(evaluatedRules)
        return evaluatedRules
    }
}

function safeGetSituation({
    situation,
    parsedRulesNames,
}: {
    situation: Situation
    parsedRulesNames: string[]
}): Situation {
    return Object.fromEntries(
        Object.entries(situation).filter(([ruleName, value]) => {
            // We check if the dotteName is a rule of the model
            if (!parsedRulesNames.includes(ruleName)) {
                console.warn(
                    `(warning:safeGetSituation) the rule ${ruleName} doesn't exist in the model.`
                )
                return false
            }
            // We check if the value from a mutliple choices question `dottedName`
            // is defined as a rule `dottedName . value` in the model.
            // If not, the value in the situation is an old option, that is not an option anymore.
            if (
                value &&
                typeof value === 'string' &&
                value !== 'oui' &&
                value !== 'non' &&
                !parsedRulesNames.includes(
                    `${ruleName} . ${value.replaceAll(/^'|'$/g, '')}`
                )
            ) {
                console.warn(
                    `(warning:safeGetSituation) the value ${value} for the rule ${ruleName} doesn't exist in the model.`
                )
                return false
            }
            return true
        })
    )
}

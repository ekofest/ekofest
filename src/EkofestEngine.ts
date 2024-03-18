import Engine, { ASTNode, PublicodesExpression, Rule } from "publicodes"

export type RuleName = string
export type PublicodeValue = string | number
export type RawRule = Omit<Rule, "nom"> | string | number
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
        situation: Readonly<Situation>
    ) {
        return new Promise<EkofestEngine>((resolve) => {
            const nbRules = Object.keys(rules).length
            console.time(`[publicodes:parsing] ${nbRules} rules`)
            const engine = new EkofestEngine(rules).setSituation(situation)
            console.timeEnd(`[publicodes:parsing] ${nbRules} rules`)
            resolve(engine)
        })
    }

    setElmApp(elmApp: any) {
        this.elmApp = elmApp
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
        const res = super.setSituation(situation, options)
        this.situation = situation as Situation
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
                super.evaluate({ "est applicable": rule }).nodeValue === true
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

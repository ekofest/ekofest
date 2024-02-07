import Engine, { ASTNode, PublicodesExpression, Rule } from "publicodes"

export type RuleName = string
export type PublicodeValue = string | number
export type RawRule = Omit<Rule, "nom"> | string | number
export type Situation = Record<RuleName, PublicodeValue>

export default class extends Engine {
    private elmApp: any

    constructor(rules: Record<RuleName, RawRule>, elmApp: any) {
        super(rules)
        this.elmApp = elmApp
    }

    setSituation(
        situation?: Partial<Record<RuleName, PublicodesExpression | ASTNode>>,
        options?: {
            keepPreviousSituation?: boolean
        }
    ): this {
        this.elmApp.ports.situationUpdated.send(null)
        return super.setSituation(situation, options)
    }

    evaluateAll(rules: RuleName[]) {
        const evaluatedRules = rules.map((rule) => {
            const result = super.evaluate(rule)
            return [
                rule,
                {
                    nodeValue: result.nodeValue ?? null,
                    // @ts-ignore
                    isNullable: result?.isNullable ?? false,
                    missingVariables: Object.keys(result.missingVariables),
                },
            ]
        })
        this.elmApp.ports.evaluatedRules.send(evaluatedRules)
        return evaluatedRules
    }
}

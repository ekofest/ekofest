import Engine, { ASTNode, PublicodesExpression, Rule } from "publicodes"

export type RuleName = string
export type PublicodeValue = string | number
export type RawRule = Omit<Rule, "nom"> | string | number
export type Situation = Record<RuleName, PublicodeValue>

export default class extends Engine {
    private elmApp: any
    private situation: Readonly<Situation>

    constructor(rules: Record<RuleName, RawRule>, elmApp: any) {
        super(rules)
        this.elmApp = elmApp
        this.situation = {}
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
        this.elmApp.ports.situationUpdated.send(null)
        return res
    }

    evaluateAll(rules: RuleName[]) {
        const evaluatedRules = rules.map((rule) => {
            const result = super.evaluate(rule)
            return [
                rule,
                {
                    nodeValue: result.nodeValue ?? null,
                    isNullable:
                        // @ts-ignore
                        result?.isNullable ??
                        // @ts-ignore
                        result?.explanation?.ruleDisabledByItsParent ??
                        false,

                    missingVariables: Object.keys(result.missingVariables),
                },
            ]
        })
        this.elmApp.ports.evaluatedRules.send(evaluatedRules)
        return evaluatedRules
    }
}

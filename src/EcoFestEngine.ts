import Engine, {
    ASTNode,
    EvaluatedNode,
    PublicodesExpression,
    Rule,
} from "publicodes"

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

    evaluate(value: PublicodesExpression): EvaluatedNode {
        const result = super.evaluate(value)
        this.elmApp.ports.evaluatedRule.send([
            value,
            {
                nodeValue: result.nodeValue,
                isNullable: result?.isNullable ?? false,
                missingVariables: Object.keys(result.missingVariables),
            },
        ])
        return result
    }
}

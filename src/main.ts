import Engine from "publicodes";
import { Elm } from "./Main.elm";

const rules = JSON.parse(`{
  "root": {
    "formule": "a * 10"
  },
  "a": {
    "question": "Combien ?",
    "par défaut": "1"
  }
}`);

const engine = new Engine(rules);

let total = engine.evaluate("root").nodeValue;

let app = Elm.Main.init({
  flags: {
    rules,
    total,
  },
  node: document.getElementById("elm-app"),
});

app.ports.evaluateWith.subscribe((data: string) => {
  engine.setSituation({ a: data });
  const newTotal = engine.evaluate("root").nodeValue;
  app.ports.totalUpdated.send(newTotal);
});

import { defineConfig } from "vite"
import elm from "vite-plugin-elm"
import path from "path"

export default defineConfig({
    plugins: [elm.default()],
    resolve: {
        alias: {
            "@": "./src",
        },
    },
    build: {
        outDir: "build",
        target: "esnext",
    },
    optimizeDeps: {
        exclude: ["publicodes-evenements"],
    },
})

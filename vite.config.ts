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
        target: "es2020",
    },
    optimizeDeps: {
        exclude: ["publicodes-evenements"],
    },
})

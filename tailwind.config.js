/** @type {import('tailwindcss').Config} */
export default {
    content: ["./index.html", "./src/**/*.elm"],
    theme: {
        extend: {
            fontFamily: {
                sans: ["Inter", "sans-serif"],
                serif: ["Georgia", "serif"],
                mono: ["Menlo", "monospace"],
            },
        },
    },
    plugins: [
        require("@tailwindcss/forms"),
        require("@tailwindcss/typography"),
    ],
}

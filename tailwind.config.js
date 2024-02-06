/** @type {import('tailwindcss').Config} */
export default {
    content: ["./index.html", "./src/**/*.elm"],
    theme: {
        extend: {
            fontFamily: {
                sans: [
                    /* "Syne", "Istok Web",  */ "Titillium Web",
                    "sans-serif",
                ],
                // serif: ["Georgia", "serif"],
                // mono: ["Menlo", "monospace"],
            },
        },
    },
    plugins: [require("@tailwindcss/typography"), require("daisyui")],
    daisyui: {
        themes: ["bumblebee"],
    },
}

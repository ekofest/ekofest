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
        themes: [
            {
                cutsomTheme: {
                    primary: "#bb4a02",
                    secondary: "#481600",
                    accent: "#FF5F0F",
                    neutral: "#f3f1f3",
                    "base-100": "#f3f1f3",
                    info: "#ffffff",
                    success: "#2dd4bf",
                    warning: "#ffffff",
                    error: "#ffffff",
                },
            },
        ],
    },
}

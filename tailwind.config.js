/** @type {import('tailwindcss').Config} */
export default {
    content: ["./index.html", "./src/**/*.elm"],
    theme: {
        extend: {
            fontFamily: {
                sans: ["Titillium Web", "sans-serif"],
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
                    neutral: "#fcfcfc",
                    "base-100": "#f6f6f6",
                    info: "#ffffff",
                    success: "#2dd4bf",
                    warning: "#ffffff",
                    error: "#ffffff",
                },
            },
        ],
    },
}

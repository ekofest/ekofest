/** @type {import('tailwindcss').Config} */
export default {
    content: ["./index.html", "./src/**/*.elm"],
    theme: {
        extend: {
            fontSize: {
                xs: ".75rem",
                sm: ".875rem",
                tiny: ".875rem",
                base: "1rem",
                lg: "1.125rem",
                xl: "1.25rem",
                "2xl": "1.5rem",
                "3xl": "1.875rem",
                "4xl": "2.25rem",
            },
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

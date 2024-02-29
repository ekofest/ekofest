/** @type {import('tailwindcss').Config} */
export default {
    content: ["./index.html", "./src/**/*.elm"],
    future: {
        hoverOnlyWhenSupported: true,
    },
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
                sans: ["Titillium Web", "Outfit", "sans-serif"],
            },
        },
    },
    plugins: [require("@tailwindcss/typography"), require("daisyui")],
    daisyui: {
        themes: [
            {
                cutsomTheme: {
                    // primary: "#bb4a02",
                    primary: "#EF5F06",
                    secondary: "#AFD5AA",
                    // accent: "#ffc070",
                    accent: "#5C5346",
                    neutral: "#fcfcfc",
                    "base-100": "#F0F2EF",
                    info: "#ffffff",
                    success: "#2dd4bf",
                    warning: "#ffffff",
                    error: "#ff5861",
                },
            },
        ],
    },
}

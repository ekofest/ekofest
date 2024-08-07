/** @type {import('tailwindcss').Config} */
export default {
    content: ["./index.html", "./src/**/*.elm"],
    future: {
        hoverOnlyWhenSupported: true,
    },
    theme: {
        extend: {
            screens: {
                xsm: "400px",
            },
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
                sans: ["Titillium Web", "sans-serif"],
            },
        },
        typography: {
            DEFAULT: {
                css: {
                    a: {
                        "text-decoration": "underline",
                    },
                    blockquote: {
                        "font-style": "normal",
                        "border-left": "none",
                        "padding-left": "0",
                        "border-radius": "1rem",
                        padding: "0.5rem",
                        "background-color": "grey",
                        p: {
                            margin: "0.5rem",
                        },
                        "p:first-of-type::before": {
                            content: "none",
                        },
                        "p:first-of-type::after": {
                            content: "none",
                        },
                    },
                },
            },
        },
    },
    plugins: [require("@tailwindcss/typography"), require("daisyui")],
    daisyui: {
        themes: [
            {
                cutsomTheme: {
                    primary: "#EF5F06",
                    // accent: "#CA5002",
                    secondary: "#AFD5AA",
                    // accent: "#ffc070",
                    accent: "#5C5346",
                    neutral: "#ffffff",
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

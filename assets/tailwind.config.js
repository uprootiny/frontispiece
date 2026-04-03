const plugin = require("tailwindcss/plugin")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/frontispiece_web.ex",
    "../lib/frontispiece_web/**/*.*ex"
  ],
  darkMode: "class",
  theme: {
    extend: {
      fontFamily: {
        mono: ['"SF Mono"', '"JetBrains Mono"', '"Fira Code"', 'ui-monospace', 'monospace'],
      },
    },
  },
  plugins: [
    require("@tailwindcss/typography"),
    // Custom variants for touch vs pointer
    plugin(({ addVariant }) => {
      addVariant("touch", "@media (hover: none)")
      addVariant("pointer", "@media (hover: hover)")
    })
  ],
}

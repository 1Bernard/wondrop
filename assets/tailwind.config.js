// assets/tailwind.config.js
module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/aether_drop_web.ex",
    "../lib/aether_drop_web/**/*.*ex"
  ],
  darkMode: 'class', 
  theme: {
    extend: {
        fontFamily: {
            sans: ['Inter', 'sans-serif'],
            display: ['Space Grotesk', 'sans-serif'],
        },
        colors: {
            brand: {
                cyan: '#38bdf8',
                purple: '#c084fc',
                dark: '#020617',
                card: 'rgba(15, 23, 42, 0.6)'
            },
            aether: {
                50: '#f0f9ff',
                100: '#e0f2fe',
                400: '#38bdf8',
                500: '#0ea5e9',
                600: '#0284c7',
                900: '#0c4a6e',
                dark: '#0f172a',
                card: '#1e293b'
            }
        },
        animation: {
            'float': 'float 8s ease-in-out infinite',
            'float-delayed': 'float 8s ease-in-out 4s infinite',
            'glow': 'glow 3s ease-in-out infinite',
            'tilt': 'tilt 10s infinite linear',
            'scroll': 'scroll 20s linear infinite',
            'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
            'spin-slow': 'spin 8s linear infinite',
            'slide-in': 'slideIn 0.3s ease-out forwards',
            'slide-out': 'slideOut 0.3s ease-in forwards',
        },
        keyframes: {
            float: {
                '0%, 100%': { transform: 'translateY(0)' },
                '50%': { transform: 'translateY(-20px)' },
            },
            glow: {
                '0%, 100%': { boxShadow: '0 0 20px rgba(56, 189, 248, 0.2)' },
                '50%': { boxShadow: '0 0 40px rgba(56, 189, 248, 0.5)' },
            },
            tilt: {
                '0%, 50%, 100%': { transform: 'rotate(0deg)' },
                '25%': { transform: 'rotate(1deg)' },
                '75%': { transform: 'rotate(-1deg)' },
            },
            scroll: {
                '0%': { transform: 'translateX(0)' },
                '100%': { transform: 'translateX(-100%)' },
            },
            slideIn: {
                '0%': { transform: 'translateX(100%)' },
                '100%': { transform: 'translateX(0)' },
            },
            slideOut: {
                '0%': { transform: 'translateX(0)' },
                '100%': { transform: 'translateX(100%)' },
            }
        }
    }
  },
  plugins: [
    require("@tailwindcss/forms")
  ]
}

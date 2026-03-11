/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        gmp: {
          primary: '#1e40af',
          secondary: '#059669',
          accent: '#dc2626',
          background: '#f8fafc',
          surface: '#ffffff',
          text: '#1e293b',
          textLight: '#64748b',
        }
      }
    },
  },
  plugins: [],
}

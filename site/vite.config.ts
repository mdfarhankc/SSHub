import { fileURLToPath, URL } from "node:url";
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

// base must match the repo name so asset URLs resolve under
// https://mdfarhankc.github.io/SSHub/. Set to "/" if a custom domain is added.
export default defineConfig({
  base: "/SSHub/",
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
});

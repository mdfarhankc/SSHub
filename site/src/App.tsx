import { Routes, Route } from "react-router-dom";
import { Header } from "@/components/Header";
import { Hero } from "@/components/Hero";
import { Features } from "@/components/Features";
import { Showcase } from "@/components/Showcase";
import { Comparison } from "@/components/Comparison";
import { Faq } from "@/components/Faq";
import { CallToAction } from "@/components/CallToAction";
import { Footer } from "@/components/Footer";
import { Guide } from "@/components/Guide";

function Landing() {
  return (
    <div className="min-h-screen bg-background text-foreground">
      <Header />
      <main>
        <Hero />
        <Features />
        <Showcase />
        <Comparison />
        <Faq />
        <CallToAction />
      </main>
      <Footer />
    </div>
  );
}

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Landing />} />
      <Route path="/guide" element={<Guide />} />
    </Routes>
  );
}

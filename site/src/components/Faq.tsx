import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";
import { FAQS } from "@/lib/site";

export function Faq() {
  return (
    <section id="faq" className="mx-auto max-w-3xl px-5 py-12 md:py-16">
      <div className="max-w-2xl">
        <p className="font-mono text-xs uppercase tracking-widest text-accent-ink">
          FAQ
        </p>
        <h2 className="mt-3 text-balance text-3xl font-bold tracking-tight sm:text-4xl">
          Questions, answered.
        </h2>
      </div>

      <Accordion type="single" collapsible className="mt-12 space-y-3">
        {FAQS.map((item, i) => (
          <AccordionItem
            key={item.q}
            value={`faq-${i}`}
            className="rounded-2xl border bg-card px-6 transition-colors last:border-b hover:border-primary/40"
          >
            <AccordionTrigger className="text-base font-semibold tracking-tight hover:no-underline">
              {item.q}
            </AccordionTrigger>
            <AccordionContent className="leading-relaxed text-muted-foreground">
              {item.a}
            </AccordionContent>
          </AccordionItem>
        ))}
      </Accordion>
    </section>
  );
}

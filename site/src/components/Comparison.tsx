import { Check, Minus, X } from "lucide-react";
import {
  COMPARE_APPS,
  COMPARE_ROWS,
  type CompareValue,
} from "@/lib/site";

const CELL_LABEL: Record<CompareValue, string> = {
  yes: "Yes",
  partial: "Partial",
  no: "No",
};

function Cell({ value }: { value: CompareValue }) {
  const icon =
    value === "yes" ? (
      <Check className="mx-auto h-5 w-5 text-accent-ink" />
    ) : value === "partial" ? (
      <Minus className="mx-auto h-5 w-5 text-muted-foreground" />
    ) : (
      <X className="mx-auto h-5 w-5 text-muted-foreground/40" />
    );
  return (
    <>
      {icon}
      <span className="sr-only">{CELL_LABEL[value]}</span>
    </>
  );
}

export function Comparison() {
  return (
    <section id="compare" className="mx-auto max-w-5xl px-5 py-12 md:py-16">
      <div className="max-w-2xl">
        <p className="font-mono text-xs uppercase tracking-widest text-accent-ink">
          Comparison
        </p>
        <h2 className="mt-3 text-balance text-3xl font-bold tracking-tight sm:text-4xl">
          One app, without the trade-offs.
        </h2>
        <p className="mt-4 text-lg leading-relaxed text-muted-foreground">
          Open source and free, on every device, with your data staying on your
          machine. No single alternative gives you all of it.
        </p>
      </div>

      <div className="mt-12">
        <table className="w-full border-separate border-spacing-0">
          <thead>
            <tr>
              <th className="w-2/5" />
              {COMPARE_APPS.map((app, i) => (
                <th
                  key={app}
                  className={
                    i === 0
                      ? "rounded-t-2xl border-x border-t border-primary/40 bg-primary/5 px-2 py-4 text-center text-sm font-bold tracking-tight text-foreground sm:px-4"
                      : "px-2 py-4 text-center text-sm font-semibold tracking-tight text-muted-foreground sm:px-4"
                  }
                >
                  {app}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {COMPARE_ROWS.map((row, r) => (
              <tr key={row.label}>
                <td className="border-b border-border py-3.5 pr-2 text-xs text-muted-foreground sm:pr-4 sm:text-sm">
                  {row.label}
                </td>
                {row.values.map((value, i) => (
                  <td
                    key={COMPARE_APPS[i]}
                    className={
                      i === 0
                        ? `border-x border-primary/40 bg-primary/5 px-2 py-3.5 sm:px-4 ${
                            r === COMPARE_ROWS.length - 1
                              ? "rounded-b-2xl border-b"
                              : ""
                          }`
                        : "border-b border-border px-2 py-3.5 sm:px-4"
                    }
                  >
                    <Cell value={value} />
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p className="mt-4 text-xs text-muted-foreground">
        Reflects each app's standard offering at the time of writing. The other
        apps' features and plans can change.
      </p>
    </section>
  );
}

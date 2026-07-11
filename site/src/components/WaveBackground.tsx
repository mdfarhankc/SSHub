import { useEffect, useRef } from "react";
import { cn } from "@/lib/utils";

// Animated diagonal light ribbons, rendered on a canvas. Vertical brightness
// bands are drawn in a rotated space so they read as flowing diagonal streaks.
// Tinted with the mint accent; stays subtle so hero text remains legible.
const ANGLE = -0.6; // radians; tilts the streaks bottom-left to top-right

export function WaveBackground({ className }: { className?: string }) {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const reduce = window.matchMedia(
      "(prefers-reduced-motion: reduce)"
    ).matches;

    let dpr = 1;
    let w = 0;
    let h = 0;

    function resize() {
      if (!canvas) return;
      const rect = canvas.getBoundingClientRect();
      dpr = Math.min(window.devicePixelRatio || 1, 2);
      w = rect.width;
      h = rect.height;
      canvas.width = Math.max(1, Math.floor(w * dpr));
      canvas.height = Math.max(1, Math.floor(h * dpr));
    }

    function draw(time: number) {
      if (!ctx) return;
      const isDark = document.documentElement.classList.contains("dark");
      const rgb = isDark ? "0, 229, 153" : "0, 143, 93";
      const max = isDark ? 0.14 : 0.07;

      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.clearRect(0, 0, w, h);
      ctx.globalCompositeOperation = isDark ? "lighter" : "source-over";

      const t = time * 0.00016;
      const diag = Math.hypot(w, h) + 200;

      ctx.save();
      ctx.translate(w / 2, h / 2);
      ctx.rotate(ANGLE);
      ctx.translate(-diag / 2, -diag / 2);

      const step = 2;
      for (let x = 0; x < diag; x += step) {
        const wobble = Math.sin(x * 0.004 - t * 3.2) * 2.2;
        const b = Math.sin(x * 0.014 + t * 5 + wobble);
        const bright = Math.pow(b * 0.5 + 0.5, 3);
        const alpha = bright * max;
        if (alpha < 0.004) continue;
        ctx.fillStyle = `rgba(${rgb}, ${alpha})`;
        ctx.fillRect(x, 0, step + 0.5, diag);
      }
      ctx.restore();
    }

    let raf = 0;
    function loop(time: number) {
      draw(time);
      raf = requestAnimationFrame(loop);
    }

    resize();
    if (reduce) {
      draw(0);
    } else {
      raf = requestAnimationFrame(loop);
    }

    const ro = new ResizeObserver(() => {
      resize();
      if (reduce) draw(0);
    });
    ro.observe(canvas);

    return () => {
      cancelAnimationFrame(raf);
      ro.disconnect();
    };
  }, []);

  return (
    <canvas
      ref={ref}
      aria-hidden="true"
      className={cn("pointer-events-none h-full w-full", className)}
      style={{
        maskImage:
          "linear-gradient(to bottom, black 0%, black 58%, transparent 100%)",
        WebkitMaskImage:
          "linear-gradient(to bottom, black 0%, black 58%, transparent 100%)",
      }}
    />
  );
}

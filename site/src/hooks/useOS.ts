import { useState } from "react";

export type OS = "windows" | "macos" | "linux" | "android" | "other";

function detect(): OS {
  if (typeof navigator === "undefined") return "other";
  const ua = navigator.userAgent;
  if (/Android/i.test(ua)) return "android";
  if (/Win/i.test(ua)) return "windows";
  if (/Mac/i.test(ua)) return "macos";
  if (/Linux/i.test(ua)) return "linux";
  return "other";
}

const LABELS: Record<OS, string> = {
  windows: "Download for Windows",
  macos: "Download for macOS",
  linux: "Download for Linux",
  android: "Download for Android",
  other: "Download SSHub",
};

// Maps the detected OS to the platform label shown in the platform row,
// so the matching one can be highlighted.
export const OS_TO_PLATFORM: Record<OS, string | null> = {
  windows: "Windows",
  macos: "macOS",
  linux: "Linux",
  android: "Android",
  other: null,
};

export function useOS() {
  const [os] = useState<OS>(detect);
  return { os, downloadLabel: LABELS[os] };
}

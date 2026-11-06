import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "SeatBite",
  description: "Scan. Order. Enjoy your movie."
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}

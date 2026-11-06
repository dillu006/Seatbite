import type { Metadata } from "next";
import "../globals.css";

export const metadata: Metadata = {
  title: "SeatBite",
  description: "Cinema Seat Food Ordering Platform",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}

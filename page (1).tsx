import { notFound } from "next/navigation";
import { messages, type Locale } from "@/lib/i18n/messages";

export default async function LocaleHome({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params;
  if (!["en", "te", "hi"].includes(locale)) notFound();
  const t = messages[locale as Locale];
  return <main><section className="card"><h1>{t.title}</h1><p>{t.subtitle}</p></section></main>;
}

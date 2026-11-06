import Link from "next/link";

export default function Home() {
  return (
    <main>
      <section className="card">
        <h1>SeatBite</h1>
        <p>Scan. Order. Enjoy your movie.</p>
        <p>Production starter for cinema seat-side food ordering.</p>
        <p>Languages planned: తెలుగు · English · हिन्दी</p>
        <ul>
          <li><Link href="/en">Customer experience (starter)</Link></li>
          <li><Link href="/kitchen">Kitchen dashboard (coming next)</Link></li>
          <li><Link href="/owner">Theater owner dashboard (coming next)</Link></li>
        </ul>
      </section>
    </main>
  );
}

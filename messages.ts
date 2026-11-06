export const messages = {
  en: { title: "SeatBite", subtitle: "Scan your seat QR code and order snacks." },
  te: { title: "సీట్‌బైట్", subtitle: "మీ సీట్ QR కోడ్ స్కాన్ చేసి స్నాక్స్ ఆర్డర్ చేయండి." },
  hi: { title: "सीटबाइट", subtitle: "अपनी सीट का QR कोड स्कैन करें और स्नैक्स ऑर्डर करें।" }
} as const;

export type Locale = keyof typeof messages;

// lib/utils/rating_helper.dart
class RatingHelper {
  static const Map<String, String> ratingLabels = {
    'condition': 'Zustand der Wohnung:',
    'cleanliness': 'Sauberkeit im Gebäude:',
    'landlord': 'Vermieter:',
    'equipment': 'Ausstattung:',
    'location': 'Lage:',
    'transport': 'Anbindung an öffentliche Verkehrsmittel:',
    'parking': 'Parkmöglichkeiten:',
    'neighbors': 'Nachbarn:',
    'accessibility': 'Barrierefreiheit:',
    'leisure': 'Freizeitmöglichkeiten:',
    'shopping': 'Einkaufsmöglichkeiten:',
    'safety': 'Sicherheit:',
    'valueForMoney': 'Preis-/Leistungsverhältnis gesamt:',
  };

  static const Map<String, String> tooltipMessages = {
    'condition': 'Wie gut ist der allgemeine Zustand der Wohnung?',
    'cleanliness': 'Wie sauber ist die Wohnung?',
    'landlord': 'Wie ist der Vermieter? (Allgemeine Bewertung)',
    'equipment': 'Gibt es moderne Einrichtungen wie Küche, Bad, Heizung, etc.?',
    'location': 'Wie ist die Lage der Wohnung? (z. B. ruhig, zentral)',
    'transport': 'Wie gut ist die Erreichbarkeit mit Bus, Bahn, etc.?',
    'parking': 'Gibt es ausreichend Parkplätze in der Nähe?',
    'neighbors': 'Wie sind die Nachbarn? (z. B. freundlich, laut, respektvoll)',
    'accessibility': 'Ist die Wohnung barrierefrei (z. B. für Rollstuhlfahrer)?',
    'leisure': 'Gibt es in der Nähe Parks, Sportanlagen?',
    'shopping': 'Gibt es in der Nähe genügend Einkaufsmöglichkeiten?',
    'safety': 'Wie sicher ist das Wohngebiet? (z. B. Beleuchtung, Kriminalität)',
    'valueForMoney': 'Wie bewerten Sie das Preis-/Leistungsverhältnis der Wohnung?',
  };

  static String getLabel(String key) => ratingLabels[key] ?? key;
  static String getTooltip(String key) => tooltipMessages[key] ?? '';
}
/// Every label of the employee confidential vault. Each locale table must define all of them (enforced by a unit
/// test), so a missing translation can never reach the UI.
enum PV {
  title,
  intro,
  monthlyPayslips,
  annualCu,
  cedolino,
  cu,
  netAmount,
  neverOpened,
  firstOpened,
  open,
  refresh,
  empty,
  biometricReason,
  biometricFailed,
  biometricUnavailableNotice,
  auditNotice,
  viewerTitle,
  errorForbidden,
  errorNotFound,
  errorOffline,
  errorUnauthorized,
  errorUnknown,
  retry,
}

const Map<PV, String> _en = <PV, String>{
  PV.title: 'Confidential vault',
  PV.intro: 'Your payslips and Certificazione Unica, visible only to you.',
  PV.monthlyPayslips: 'Monthly payslips',
  PV.annualCu: 'Annual CU',
  PV.cedolino: 'Payslip',
  PV.cu: 'CU',
  PV.netAmount: 'Net pay',
  PV.neverOpened: 'Never opened',
  PV.firstOpened: 'First opened',
  PV.open: 'Open',
  PV.refresh: 'Refresh',
  PV.empty: 'No documents available yet.',
  PV.biometricReason: 'Confirm your identity to open the document',
  PV.biometricFailed: 'Identity not confirmed. The document was not opened.',
  PV.biometricUnavailableNotice: 'No biometrics on this device: the access is logged without biometric confirmation.',
  PV.auditNotice:
      'Every access is recorded in a tamper-proof log (Law 4/1953).',
  PV.viewerTitle: 'Document',
  PV.errorForbidden: 'You are not allowed to see this document.',
  PV.errorNotFound: 'Document not found.',
  PV.errorOffline: 'No connection. Documents are never stored on the device.',
  PV.errorUnauthorized: 'Session expired. Sign in again.',
  PV.errorUnknown: 'Something went wrong. Try again.',
  PV.retry: 'Retry',
};

const Map<PV, String> _it = <PV, String>{
  PV.title: 'Cassaforte riservata',
  PV.intro: 'Le tue buste paga e la Certificazione Unica, visibili solo a te.',
  PV.monthlyPayslips: 'Cedolini mensili',
  PV.annualCu: 'CU annuale',
  PV.cedolino: 'Cedolino',
  PV.cu: 'CU',
  PV.netAmount: 'Netto in busta',
  PV.neverOpened: 'Mai aperto',
  PV.firstOpened: 'Aperto la prima volta il',
  PV.open: 'Apri',
  PV.refresh: 'Aggiorna',
  PV.empty: 'Nessun documento disponibile.',
  PV.biometricReason: 'Conferma la tua identità per aprire il documento',
  PV.biometricFailed:
      'Identità non confermata. Il documento non è stato aperto.',
  PV.biometricUnavailableNotice: "Nessun dato biometrico su questo dispositivo: l'accesso viene registrato senza conferma biometrica.",
  PV.auditNotice:
      'Ogni accesso è registrato in un registro non modificabile (L. 4/1953).',
  PV.viewerTitle: 'Documento',
  PV.errorForbidden: 'Non sei autorizzato a vedere questo documento.',
  PV.errorNotFound: 'Documento non trovato.',
  PV.errorOffline: 'Nessuna connessione. I documenti non vengono mai salvati sul dispositivo.',
  PV.errorUnauthorized: 'Sessione scaduta. Accedi di nuovo.',
  PV.errorUnknown: 'Qualcosa è andato storto. Riprova.',
  PV.retry: 'Riprova',
};

const Map<PV, String> _de = <PV, String>{
  PV.title: 'Vertraulicher Tresor',
  PV.intro: 'Deine Gehaltsabrechnungen und die Certificazione Unica, nur für dich sichtbar.',
  PV.monthlyPayslips: 'Monatliche Abrechnungen',
  PV.annualCu: 'Jährliche CU',
  PV.cedolino: 'Abrechnung',
  PV.cu: 'CU',
  PV.netAmount: 'Nettobetrag',
  PV.neverOpened: 'Nie geöffnet',
  PV.firstOpened: 'Erstmals geöffnet am',
  PV.open: 'Öffnen',
  PV.refresh: 'Aktualisieren',
  PV.empty: 'Noch keine Dokumente verfügbar.',
  PV.biometricReason: 'Bestätige deine Identität, um das Dokument zu öffnen',
  PV.biometricFailed:
      'Identität nicht bestätigt. Das Dokument wurde nicht geöffnet.',
  PV.biometricUnavailableNotice: 'Keine Biometrie auf diesem Gerät: Der Zugriff wird ohne biometrische Bestätigung protokolliert.',
  PV.auditNotice: 'Jeder Zugriff wird in einem manipulationssicheren Protokoll erfasst (Gesetz 4/1953).',
  PV.viewerTitle: 'Dokument',
  PV.errorForbidden: 'Du darfst dieses Dokument nicht ansehen.',
  PV.errorNotFound: 'Dokument nicht gefunden.',
  PV.errorOffline:
      'Keine Verbindung. Dokumente werden nie auf dem Gerät gespeichert.',
  PV.errorUnauthorized: 'Sitzung abgelaufen. Melde dich erneut an.',
  PV.errorUnknown: 'Etwas ist schiefgelaufen. Versuche es erneut.',
  PV.retry: 'Erneut versuchen',
};

const Map<PV, String> _fr = <PV, String>{
  PV.title: 'Coffre confidentiel',
  PV.intro: 'Vos bulletins de paie et la Certificazione Unica, visibles uniquement par vous.',
  PV.monthlyPayslips: 'Bulletins mensuels',
  PV.annualCu: 'CU annuelle',
  PV.cedolino: 'Bulletin',
  PV.cu: 'CU',
  PV.netAmount: 'Net à payer',
  PV.neverOpened: 'Jamais ouvert',
  PV.firstOpened: 'Ouvert pour la première fois le',
  PV.open: 'Ouvrir',
  PV.refresh: 'Actualiser',
  PV.empty: 'Aucun document disponible.',
  PV.biometricReason: 'Confirmez votre identité pour ouvrir le document',
  PV.biometricFailed: "Identité non confirmée. Le document n'a pas été ouvert.",
  PV.biometricUnavailableNotice: "Pas de biométrie sur cet appareil : l'accès est journalisé sans confirmation biométrique.",
  PV.auditNotice:
      'Chaque accès est enregistré dans un journal inviolable (loi 4/1953).',
  PV.viewerTitle: 'Document',
  PV.errorForbidden: "Vous n'êtes pas autorisé à voir ce document.",
  PV.errorNotFound: 'Document introuvable.',
  PV.errorOffline:
      "Pas de connexion. Les documents ne sont jamais stockés sur l'appareil.",
  PV.errorUnauthorized: 'Session expirée. Reconnectez-vous.',
  PV.errorUnknown: "Une erreur s'est produite. Réessayez.",
  PV.retry: 'Réessayer',
};

const Map<String, Map<PV, String>> payslipLocaleTables =
    <String, Map<PV, String>>{'it': _it, 'en': _en, 'de': _de, 'fr': _fr};

/// Localized labels of the vault; unknown languages fall back to English.
class PayslipStrings {
  const PayslipStrings(this.languageCode);

  final String languageCode;

  String call(PV key) =>
      (payslipLocaleTables[languageCode] ?? _en)[key] ?? _en[key] ?? '';
}

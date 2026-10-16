/// Fechas de sorteos en español y horario argentino (UTC-3),
/// independientes del idioma y la zona horaria del dispositivo.
String formatDrawDate(DateTime? value) {
  if (value == null) return '—';
  final date = value.toUtc().subtract(const Duration(hours: 3));
  const weekdays = ['lun.', 'mar.', 'mié.', 'jue.', 'vie.', 'sáb.', 'dom.'];
  const months = [
    'ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.',
    'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.',
  ];
  return '${weekdays[date.weekday - 1]} ${date.day} '
      '${months[date.month - 1]} ${date.year}';
}

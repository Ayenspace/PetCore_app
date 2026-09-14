import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/appointment_model.dart';
import '../models/medical_record.dart';
import '../models/pet_model.dart';
import '../models/vaccination_model.dart';

class PdfService {
  static pw.Document generatePetReport({
    required PetModel pet,
    required List<AppointmentModel> appointments,
    required List<MedicalRecord> records,
    required List<VaccinationModel> vaccinations,
  }) {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final generatedDate = _fmt(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(pet, generatedDate, fontBold),
        footer: (context) => _buildFooter(context, font),
        build: (context) => [
          pw.SizedBox(height: 16),
          _sectionTitle('Pet Information', fontBold),
          _petInfoTable(pet, font, fontBold),
          pw.SizedBox(height: 20),
          _sectionTitle('Appointments (${appointments.length})', fontBold),
          appointments.isEmpty
              ? _emptyRow('No appointments recorded.', font)
              : _appointmentsTable(appointments, font, fontBold),
          pw.SizedBox(height: 20),
          _sectionTitle('Medical Records (${records.length})', fontBold),
          records.isEmpty
              ? _emptyRow('No medical records recorded.', font)
              : _medicalTable(records, font, fontBold),
          pw.SizedBox(height: 20),
          _sectionTitle('Vaccinations (${vaccinations.length})', fontBold),
          vaccinations.isEmpty
              ? _emptyRow('No vaccinations recorded.', font)
              : _vaccinationsTable(vaccinations, font, fontBold),
        ],
      ),
    );

    return pdf;
  }

  // ── Header ────────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(PetModel pet, String date, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.purple800, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('PetCore Health Report',
                  style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.purple800)),
              pw.Text('${pet.name} — ${pet.species}',
                  style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.grey700)),
            ],
          ),
          pw.Text('Generated: $date',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('PetCore App', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────

  static pw.Widget _sectionTitle(String title, pw.Font fontBold) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.purple50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.purple800)),
    );
  }

  static pw.Widget _emptyRow(String msg, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 8, bottom: 8),
      child: pw.Text(msg, style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey500)),
    );
  }

  // ── Pet info table ────────────────────────────────────────────────────────

  static pw.Widget _petInfoTable(PetModel pet, pw.Font font, pw.Font fontBold) {
    final rows = [
      ['Name', pet.name],
      ['Species', pet.species],
      ['Breed', pet.breed ?? '—'],
      ['Gender', pet.gender],
      ['Age', '${pet.age} year${pet.age != 1 ? 's' : ''}'],
      ['Date of Birth', _fmt(pet.dateOfBirth)],
      if (pet.weight != null) ['Weight', '${pet.weight} kg'],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {0: const pw.FixedColumnWidth(120), 1: const pw.FlexColumnWidth()},
      children: rows.map((row) => pw.TableRow(
        children: [
          _cell(row[0], font: fontBold, bg: PdfColors.grey100),
          _cell(row[1], font: font),
        ],
      )).toList(),
    );
  }

  // ── Appointments table ────────────────────────────────────────────────────

  static pw.Widget _appointmentsTable(
      List<AppointmentModel> items, pw.Font font, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FixedColumnWidth(80),
        3: const pw.FixedColumnWidth(70),
      },
      children: [
        _tableHeader(['Service', 'Vet', 'Date', 'Status'], fontBold),
        ...items.map((a) => pw.TableRow(children: [
          _cell(a.service, font: font),
          _cell(a.vetName, font: font),
          _cell(_fmt(a.dateTime), font: font),
          _cell(a.status.name, font: font,
              color: a.status.name == 'upcoming' ? PdfColors.blue700
                  : a.status.name == 'completed' ? PdfColors.green700
                  : PdfColors.grey600),
        ])),
      ],
    );
  }

  // ── Medical records table ─────────────────────────────────────────────────

  static pw.Widget _medicalTable(
      List<MedicalRecord> items, pw.Font font, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FixedColumnWidth(80),
      },
      children: [
        _tableHeader(['Diagnosis', 'Treatment', 'Date'], fontBold),
        ...items.map((r) => pw.TableRow(children: [
          _cell(r.diagnosis, font: font),
          _cell(r.treatment, font: font),
          _cell(_fmt(r.date), font: font),
        ])),
      ],
    );
  }

  // ── Vaccinations table ────────────────────────────────────────────────────

  static pw.Widget _vaccinationsTable(
      List<VaccinationModel> items, pw.Font font, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FixedColumnWidth(80),
        2: const pw.FixedColumnWidth(80),
        3: const pw.FixedColumnWidth(70),
      },
      children: [
        _tableHeader(['Vaccine', 'Date Given', 'Next Due', 'Status'], fontBold),
        ...items.map((v) {
          final isOverdue = v.isDue;
          return pw.TableRow(children: [
            _cell(v.vaccineName, font: font),
            _cell(_fmt(v.dateGiven), font: font),
            _cell(v.nextDueDate != null ? _fmt(v.nextDueDate!) : '—', font: font),
            _cell(isOverdue ? 'Overdue' : 'Up to date', font: font,
                color: isOverdue ? PdfColors.red700 : PdfColors.green700),
          ]);
        }),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static pw.TableRow _tableHeader(List<String> labels, pw.Font fontBold) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.purple800),
      children: labels.map((l) => _cell(l, font: fontBold, color: PdfColors.white)).toList(),
    );
  }

  static pw.Widget _cell(String text,
      {required pw.Font font, PdfColor? bg, PdfColor? color}) {
    return pw.Container(
      color: bg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text,
          style: pw.TextStyle(font: font, fontSize: 10, color: color ?? PdfColors.grey800)),
    );
  }

  static String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

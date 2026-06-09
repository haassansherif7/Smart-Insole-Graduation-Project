import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';

class DoctorCommunicationScreen extends StatefulWidget {
  const DoctorCommunicationScreen({Key? key}) : super(key: key);
  @override
  State<DoctorCommunicationScreen> createState() => _DoctorCommunicationScreenState();
}

class _DoctorCommunicationScreenState extends State<DoctorCommunicationScreen> {
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _phone = '';
  List<String> _notes = [];

  // Appointment state
  String _selectedSpecialty = 'Endocrinology / الغدد الصماء';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  List<Map<String, String>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final appts = p.getStringList('doc_appts') ?? [];
    setState(() {
      _phone = p.getString('doc_phone') ?? '';
      _phoneCtrl.text = _phone;
      _notes = p.getStringList('doc_notes') ?? [];
      _appointments = appts.map((e) {
        final parts = e.split('|');
        if (parts.length < 3) return <String, String>{};
        return {'specialty': parts[0], 'date': parts[1], 'time': parts[2]};
      }).where((m) => m.isNotEmpty).toList();
    });
  }

  Future<void> _savePhone() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _phone = _phoneCtrl.text.trim());
    await p.setString('doc_phone', _phone);
  }

  Future<void> _addNote(bool isArabic) async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    setState(() => _notes.insert(0, text));
    _noteCtrl.clear();
    await p.setStringList('doc_notes', _notes);
  }

  Future<void> _deleteNote(int i) async {
    final p = await SharedPreferences.getInstance();
    setState(() => _notes.removeAt(i));
    await p.setStringList('doc_notes', _notes);
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _confirmAppointment(bool isArabic) {
    setState(() => _appointments.insert(0, {
          'specialty': _selectedSpecialty,
          'date': '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          'time': _selectedTime.format(context),
        }));
    _saveAppointments();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isArabic ? 'تم حجز الموعد ✅' : 'Appointment booked ✅'),
      backgroundColor: Colors.green,
    ));
  }

  void _deleteAppointment(int index) {
    setState(() => _appointments.removeAt(index));
    _saveAppointments();
  }

  Future<void> _saveAppointments() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      'doc_appts',
      _appointments
          .map((a) => '${a['specialty']}|${a['date']}|${a['time']}')
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<AppSettings>(context).locale.languageCode == 'ar';
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appointment booking
          Text(
            isArabic ? '📅 حجز موعد' : '📅 Book Appointment',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: _selectedSpecialty,
            decoration: InputDecoration(
              labelText: isArabic ? 'التخصص' : 'Specialty',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              'Endocrinology / الغدد الصماء',
              'Podiatry / طب القدم',
              'Cardiology / القلب',
              'Nephrology / الكلى',
              'Internal Medicine / الباطنية',
              'General Practice / طب عام',
            ]
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedSpecialty = v!),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  onPressed: _pickDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(_selectedTime.format(context)),
                  onPressed: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: Text(isArabic ? 'تأكيد الحجز' : 'Confirm Booking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C6FFF),
                foregroundColor: Colors.white,
              ),
              onPressed: () => _confirmAppointment(isArabic),
            ),
          ),

          if (_appointments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              isArabic ? 'المواعيد:' : 'Appointments:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            ..._appointments.take(3).toList().asMap().entries.map((e) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.event, color: Color(0xFF4C6FFF), size: 20),
                  title: Text(e.value['specialty'] ?? '',
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text('${e.value['date']}  ${e.value['time']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    onPressed: () => _deleteAppointment(e.key),
                  ),
                )),
          ],

          const Divider(),

          // Emergency contacts
          Text(
            isArabic ? '🚨 جهات الطوارئ' : '🚨 Emergency Contacts',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: isArabic ? 'رقم الطبيب' : 'Doctor phone',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save),
                onPressed: _savePhone,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  icon: const Icon(Icons.phone, color: Colors.white, size: 16),
                  label: Text(
                    isArabic ? 'اتصال' : 'Call',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onPressed: _phone.isNotEmpty ? () => _launch('tel:$_phone') : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366)),
                  icon: const Icon(Icons.chat, color: Colors.white, size: 16),
                  label:
                      const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                  onPressed: _phone.isNotEmpty
                      ? () => _launch(
                          'https://wa.me/${_phone.replaceAll('+', '').replaceAll(' ', '')}')
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  icon: const Icon(Icons.emergency, color: Colors.white, size: 16),
                  label: Text(
                    isArabic ? 'طوارئ' : 'Emergency',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onPressed: () => _launch('tel:123'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Nearby hospitals
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.map_outlined),
              label: Text(isArabic ? '🗺️ مستشفيات قريبة' : '🗺️ Nearby Hospitals'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C6FFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _launch(
                  'https://www.google.com/maps/search/hospitals+near+me'),
            ),
          ),
          const SizedBox(height: 20),

          // Medical notes
          Text(
            isArabic ? '📝 ملاحظات طبية' : '📝 Medical Notes',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(
                    hintText: isArabic ? 'أضف ملاحظة...' : 'Add a note...',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF4C6FFF), size: 32),
                onPressed: () => _addNote(isArabic),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._notes.asMap().entries.map((e) => ListTile(
                leading: const Icon(Icons.notes, color: Colors.blue),
                title: Text(e.value),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteNote(e.key),
                ),
              )),
        ],
      ),
    );
  }
}

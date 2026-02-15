import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../consts/consts.dart';
import '../../services/birthday_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/appbar_custom.dart';

class AddBirthdayScreen extends StatefulWidget {
  final BirthdayItem? birthday;

  const AddBirthdayScreen({super.key, this.birthday});

  @override
  State<AddBirthdayScreen> createState() => _AddBirthdayScreenState();
}

class _AddBirthdayScreenState extends State<AddBirthdayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedDay;
  int? _selectedMonth;
  int _reminderMinutes = 30; // 30 min avant 00h par défaut

  bool _isLoading = false;
  bool get _isEditing => widget.birthday != null;

  // Options de rappel en minutes avant 00h
  final List<Map<String, dynamic>> _reminderOptions = [
    {'label': 'À 00h', 'value': 0},
    {'label': '30 min avant', 'value': 30},
    {'label': '1h avant', 'value': 60},
    {'label': '2h avant', 'value': 120},
    {'label': '3h avant', 'value': 180},
  ];

  // Mois en français
  final List<String> _months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final birthday = widget.birthday!;
      _nameController.text = birthday.friendName;
      _notesController.text = birthday.notes ?? '';

      try {
        final date = DateTime.parse(birthday.birthdayDate);
        _selectedDay = date.day;
        _selectedMonth = date.month;
      } catch (e) {
        _selectedDay = null;
        _selectedMonth = null;
      }

      _reminderMinutes = birthday.reminderMinutesBefore;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showDayMonthPicker() {
    int tempDay = _selectedDay ?? 1;
    int tempMonth = _selectedMonth ?? 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Calculer le nombre de jours dans le mois sélectionné
          int daysInMonth = DateTime(2024, tempMonth + 1, 0).day; // 2024 est bissextile
          if (tempDay > daysInMonth) {
            tempDay = daysInMonth;
          }

          return Container(
            height: 350,
            decoration: const BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler', style: TextStyle(color: grayColor)),
                      ),
                      const Text(
                        'Date d\'anniversaire',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDay = tempDay;
                            _selectedMonth = tempMonth;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('OK', style: TextStyle(color: blueColor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                // Pickers
                Expanded(
                  child: Row(
                    children: [
                      // Day picker
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 45,
                          physics: const FixedExtentScrollPhysics(),
                          controller: FixedExtentScrollController(initialItem: tempDay - 1),
                          onSelectedItemChanged: (index) {
                            setModalState(() => tempDay = index + 1);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: daysInMonth,
                            builder: (context, index) {
                              final day = index + 1;
                              return Center(
                                child: Text(
                                  day.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: day == tempDay ? 22 : 18,
                                    fontWeight: day == tempDay ? FontWeight.w600 : FontWeight.normal,
                                    color: day == tempDay ? blueColor : Colors.grey.shade600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Month picker
                      Expanded(
                        flex: 2,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 45,
                          physics: const FixedExtentScrollPhysics(),
                          controller: FixedExtentScrollController(initialItem: tempMonth - 1),
                          onSelectedItemChanged: (index) {
                            setModalState(() => tempMonth = index + 1);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 12,
                            builder: (context, index) {
                              final month = index + 1;
                              return Center(
                                child: Text(
                                  _months[index],
                                  style: TextStyle(
                                    fontSize: month == tempMonth ? 20 : 16,
                                    fontWeight: month == tempMonth ? FontWeight.w600 : FontWeight.normal,
                                    color: month == tempMonth ? blueColor : Colors.grey.shade600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    // Empêcher les clics multiples
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedDay == null || _selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner le jour et le mois'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Utiliser l'année courante pour créer la date (l'année n'est pas importante)
      final now = DateTime.now();
      final birthdayDate = DateTime(now.year, _selectedMonth!, _selectedDay!);
      final birthdayDateStr = DateFormat('yyyy-MM-dd').format(birthdayDate);

      // Toujours à 00:00
      const reminderTimeStr = '00:00';

      Map<String, dynamic> result;

      if (_isEditing) {
        result = await BirthdayService.updateBirthday(
          id: widget.birthday!.id,
          friendName: _nameController.text.trim(),
          birthdayDate: birthdayDateStr,
          reminderTime: reminderTimeStr,
          reminderMinutesBefore: _reminderMinutes,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      } else {
        result = await BirthdayService.addBirthday(
          friendName: _nameController.text.trim(),
          birthdayDate: birthdayDateStr,
          reminderTime: reminderTimeStr,
          reminderMinutesBefore: _reminderMinutes,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // Programmer les rappels en arrière-plan (ne pas bloquer)
        final notificationService = NotificationService();
        notificationService.requestPermission();
        notificationService.scheduleAllBirthdayReminders();

        // Fermer la page immédiatement
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Une erreur est survenue'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: _isEditing ? "Modifier" : "Nouvel anniversaire"),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom
                const Text(
                  'Qui fête son anniversaire ?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: blackColor,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 16),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Prénom ou nom complet',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: blueColor, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Entrez un nom';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Date (jour et mois seulement)
                const Text(
                  'Jour d\'anniversaire',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: blackColor,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _showDayMonthPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: (_selectedDay != null && _selectedMonth != null)
                          ? Border.all(color: blueColor.withValues(alpha: 0.3), width: 1)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cake_outlined,
                          color: (_selectedDay != null && _selectedMonth != null) ? blueColor : Colors.grey.shade500,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            (_selectedDay != null && _selectedMonth != null)
                                ? '$_selectedDay ${_months[_selectedMonth! - 1]}'
                                : 'Choisir le jour et le mois',
                            style: TextStyle(
                              fontSize: 16,
                              color: (_selectedDay != null && _selectedMonth != null) ? blackColor : Colors.grey.shade500,
                              fontWeight: (_selectedDay != null && _selectedMonth != null) ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Rappel
                const Text(
                  'Me rappeler',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: blackColor,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _reminderOptions.map((option) {
                      return _buildReminderChip(option['label'], option['value']);
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Notes
                Row(
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: blackColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'optionnel',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  maxLength: 150,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Idées cadeaux, centres d\'intérêt...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: blueColor, width: 1.5),
                    ),
                    counterStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ),

                const SizedBox(height: 32),

                // Bouton
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueColor,
                      foregroundColor: whiteColor,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                            ),
                          )
                        : Text(
                            _isEditing ? 'Enregistrer' : 'Ajouter',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderChip(String label, int value) {
    final isSelected = _reminderMinutes == value;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _reminderMinutes = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? blueColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? whiteColor : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import '../../consts/consts.dart';
import '../../services/birthday_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/appbar_custom.dart';
import 'add_birthday_screen.dart';

final NotificationService _notificationService = NotificationService();

class BirthdaysListScreen extends StatefulWidget {
  const BirthdaysListScreen({super.key});

  @override
  State<BirthdaysListScreen> createState() => _BirthdaysListScreenState();
}

class _BirthdaysListScreenState extends State<BirthdaysListScreen> {
  List<BirthdayItem> _birthdays = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBirthdays();
  }

  Future<void> _loadBirthdays() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final birthdays = await BirthdayService.fetchBirthdays();
      setState(() {
        _birthdays = birthdays;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des anniversaires';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBirthday(BirthdayItem birthday) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Voulez-vous supprimer l\'anniversaire de ${birthday.friendName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Suppression optimiste : retirer immédiatement de la liste
      final int index = _birthdays.indexWhere((b) => b.id == birthday.id);
      if (index == -1) return;

      setState(() {
        _birthdays.removeAt(index);
      });

      // Appeler l'API en arrière-plan
      final result = await BirthdayService.deleteBirthday(birthday.id);

      if (result['success'] == true) {
        // Annuler le rappel de notification
        final notificationService = NotificationService();
        notificationService.cancelBirthdayReminder(birthday.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anniversaire supprimé')),
          );
        }
      } else {
        // En cas d'erreur, remettre l'élément dans la liste
        if (mounted) {
          setState(() {
            _birthdays.insert(index, birthday);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Erreur')),
          );
        }
      }
    }
  }

  Future<void> _toggleActive(BirthdayItem birthday) async {
    // Mise à jour optimiste : changer l'UI immédiatement
    final int index = _birthdays.indexWhere((b) => b.id == birthday.id);
    if (index == -1) return;

    final bool previousState = birthday.isActive;

    // Mettre à jour l'UI immédiatement
    setState(() {
      _birthdays[index] = birthday.copyWith(isActive: !previousState);
    });

    // Appeler l'API en arrière-plan
    final result = await BirthdayService.updateBirthday(
      id: birthday.id,
      isActive: !previousState,
    );

    if (result['success'] == true) {
      // Mettre à jour les rappels de notification
      final notificationService = NotificationService();
      notificationService.scheduleAllBirthdayReminders();
    } else {
      // En cas d'erreur, revenir à l'état précédent
      if (mounted) {
        setState(() {
          _birthdays[index] = birthday.copyWith(isActive: previousState);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Erreur')),
        );
      }
    }
  }

  String _getDaysUntilText(BirthdayItem birthday) {
    if (birthday.isToday) {
      return 'Aujourd\'hui !';
    } else if (birthday.daysUntil == 1) {
      return 'Demain';
    } else if (birthday.daysUntil <= 7) {
      return 'Dans ${birthday.daysUntil} jours';
    } else if (birthday.daysUntil <= 30) {
      return 'Dans ${(birthday.daysUntil / 7).floor()} semaines';
    } else {
      return 'Dans ${(birthday.daysUntil / 30).floor()} mois';
    }
  }

  Color _getDaysUntilColor(BirthdayItem birthday) {
    if (birthday.isToday) {
      return Colors.green;
    } else if (birthday.daysUntil <= 7) {
      return Colors.orange;
    } else {
      return grayColor;
    }
  }

  void _showTestNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: blueColor),
            SizedBox(width: 8),
            Text('Tester les notifications'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choisissez un test pour vérifier que les notifications fonctionnent :',
              style: TextStyle(fontSize: 14, color: greyColor),
            ),
            SizedBox(height: 20),
            // Test immédiat
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.flash_on, color: Colors.green),
              ),
              title: Text('Test immédiat'),
              subtitle: Text('Notification instantanée'),
              onTap: () async {
                Navigator.pop(context);
                await _notificationService.testNotificationNow();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notification envoyée !'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            Divider(),
            // Test dans 1 minute
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.timer, color: Colors.orange),
              ),
              title: Text('Test dans 1 minute'),
              subtitle: Text('Simule un rappel programmé'),
              onTap: () async {
                Navigator.pop(context);
                await _notificationService.scheduleTestNotification(minutes: 1);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notification programmée dans 1 minute'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
            Divider(),
            // Test dans 5 minutes
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: blueColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.schedule, color: blueColor),
              ),
              title: Text('Test dans 5 minutes'),
              subtitle: Text('Vérifie le réveil de l\'app'),
              onTap: () async {
                Navigator.pop(context);
                await _notificationService.scheduleTestNotification(minutes: 5);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notification programmée dans 5 minutes'),
                      backgroundColor: blueColor,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: blackColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Anniversaires",
          style: TextStyle(
            color: blackColor,
            fontFamily: bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          // Bouton de test des notifications
          IconButton(
            icon: Icon(Icons.notifications_active_outlined, color: blueColor),
            tooltip: 'Tester les notifications',
            onPressed: _showTestNotificationDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: grayColor)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBirthdays,
                        child: const Text('Reessayer'),
                      ),
                    ],
                  ),
                )
              : _birthdays.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cake_outlined, size: 64, color: grayColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucun anniversaire enregistre',
                            style: TextStyle(color: grayColor, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ajoutez les anniversaires de vos amis\npour recevoir des rappels',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: greyColor, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBirthdays,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _birthdays.length,
                        itemBuilder: (context, index) {
                          final birthday = _birthdays[index];
                          return _buildBirthdayCard(birthday);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: blueColor,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBirthdayScreen()),
          );
          if (result == true) {
            _loadBirthdays();
            // Mettre à jour les rappels de notification
            final notificationService = NotificationService();
            await notificationService.scheduleAllBirthdayReminders();
          }
        },
        child: const Icon(Icons.add, color: whiteColor),
      ),
    );
  }

  Widget _buildBirthdayCard(BirthdayItem birthday) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: blackColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: birthday.isToday ? Colors.green.withValues(alpha: 0.1) : roscColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      birthday.friendName.isNotEmpty ? birthday.friendName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: bold,
                        color: birthday.isToday ? Colors.green : blueColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        birthday.friendName,
                        style: const TextStyle(
                          fontFamily: bold,
                          fontSize: 16,
                          color: blackColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.cake, size: 14, color: grayColor),
                          const SizedBox(width: 4),
                          Text(
                            birthday.birthdayDisplay,
                            style: const TextStyle(
                              fontFamily: regular,
                              fontSize: 14,
                              color: grayColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: birthday.isActive,
                  onChanged: (value) => _toggleActive(birthday),
                  activeColor: blueColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getDaysUntilColor(birthday).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getDaysUntilText(birthday),
                    style: TextStyle(
                      fontFamily: bold,
                      fontSize: 12,
                      color: _getDaysUntilColor(birthday),
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: blueColor, size: 20),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddBirthdayScreen(birthday: birthday),
                          ),
                        );
                        if (result == true) {
                          _loadBirthdays();
                          final notificationService = NotificationService();
                          await notificationService.scheduleAllBirthdayReminders();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _deleteBirthday(birthday),
                    ),
                  ],
                ),
              ],
            ),
            if (birthday.notes != null && birthday.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                birthday.notes!,
                style: const TextStyle(
                  fontFamily: regular,
                  fontSize: 13,
                  color: greyColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

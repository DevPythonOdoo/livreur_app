import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  DateTime _selectedDay = DateTime.now();
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(_selectedDay);
  }

  DateTime _getWeekStart(DateTime day) {
    return day.subtract(Duration(days: day.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = List.generate(6, (i) => _weekStart.add(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Planning',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            Spacing.marginMobile, 8, Spacing.marginMobile, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workload overview hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Semaine ${_weekStart.weekOfYear} \u2014 ${DateFormat('MMMM', 'fr').format(_weekStart)}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                  fontFamily: 'Inter'),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Capacité Optimale',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurface
                                    .withValues(alpha: 0.6),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: 0.85,
                              backgroundColor:
                                  AppColors.surfaceContainerHigh,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryContainer),
                              strokeWidth: 6,
                            ),
                            const Center(
                              child: Text('85%',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppColors.primaryContainer,
                                      fontFamily: 'Inter')),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statItem('128', 'Livraisons'),
                      Container(
                          width: 1,
                          height: 24,
                          color: AppColors.outlineVariant),
                      _statItem('150', 'Capacité'),
                      Container(
                          width: 1,
                          height: 24,
                          color: AppColors.outlineVariant),
                      _statItem('12', 'Actifs'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Weekly calendar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekDays.map((day) {
                final isToday = _isSameDay(day, DateTime.now());
                final isSelected = _isSameDay(day, _selectedDay);
                final dayName = DateFormat('E', 'fr').format(day)[0].toUpperCase();
                final dayNum = day.day.toString();
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    width: 46,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryContainer
                          : isToday
                              ? AppColors.surfaceContainerHigh
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? AppColors.primaryContainer
                                    : AppColors.onSurface.withValues(alpha: 0.5),
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dayNum,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.onSurface,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Time slots
            _TimeSlotCard(
              time: '09:00 - 10:30',
              count: 4,
              completed: 3,
              addresses: ['12 Rue de Rivoli, Paris', '45 Blvd Saint-Michel'],
            ),
            const SizedBox(height: 10),
            _TimeSlotCard(
              time: '11:00 - 12:30',
              count: 6,
              completed: 2,
              addresses: ['88 Ave des Champs-Élysées', '34 Rue du Faubourg'],
            ),
            const SizedBox(height: 10),
            _TimeSlotCard(
              time: '14:00 - 15:30',
              count: 5,
              completed: 0,
              addresses: ['7 Place Vendôme, Paris', '22 Rue de la Paix'],
            ),
            const SizedBox(height: 10),
            _TimeSlotCard(
              time: '16:00 - 17:30',
              count: 3,
              completed: 0,
              addresses: ['15 Blvd Haussmann, Paris'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.onSurface,
                  fontFamily: 'Inter')),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                  fontFamily: 'Inter')),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

extension _WeekOfYear on DateTime {
  int get weekOfYear {
    final startOfYear = DateTime(year, 1, 1);
    final diff = difference(startOfYear).inDays;
    return ((diff + startOfYear.weekday - 1) / 7).ceil();
  }
}

class _TimeSlotCard extends StatelessWidget {
  final String time;
  final int count;
  final int completed;
  final List<String> addresses;

  const _TimeSlotCard({
    required this.time,
    required this.count,
    required this.completed,
    required this.addresses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryContainer,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$completed/$count',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.onSurface.withValues(alpha: 0.7),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...addresses.take(2).map((addr) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        addr,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurface.withValues(alpha: 0.6),
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
          if (addresses.length > 2)
            Text(
              '+${addresses.length - 2} autres',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryContainer,
                  fontFamily: 'Inter'),
            ),
        ],
      ),
    );
  }
}

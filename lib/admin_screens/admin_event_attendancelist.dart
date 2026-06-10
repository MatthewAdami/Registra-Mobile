import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminEventAttendanceList extends StatefulWidget {
  final String image;
  final String date;
  final String title;
  final String location;
  final List<dynamic> attendees;

  const AdminEventAttendanceList({
    Key? key,
    required this.image,
    required this.date,
    required this.title,
    required this.location,
    required this.attendees,
  }) : super(key: key);

  @override
  State<AdminEventAttendanceList> createState() =>
      _AdminEventAttendanceListState();
}

class _AdminEventAttendanceListState extends State<AdminEventAttendanceList> {
  static const int _pageSize = 10;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim();
        _currentPage = 1;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredAttendees {
    if (_query.isEmpty) return widget.attendees;
    final lower = _query.toLowerCase();
    return widget.attendees.where((a) {
      final name = (a['fullName'] ?? '').toString().toLowerCase();
      final email = (a['email'] ?? '').toString().toLowerCase();
      return name.contains(lower) || email.contains(lower);
    }).toList();
  }

  int get _totalPages {
    final total = _filteredAttendees.length;
    if (total == 0) return 1;
    return (total / _pageSize).ceil();
  }

  List<dynamic> get _pageItems {
    final start = (_currentPage - 1) * _pageSize;
    return _filteredAttendees.skip(start).take(_pageSize).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenWidth < 360;

    // Scale the hero image height so it never dominate tiny screens
    final imageHeight = (screenHeight * 0.22).clamp(140.0, 220.0);

    String formattedDate = '';
    try {
      final parsedDate = DateTime.parse(widget.date);
      formattedDate = DateFormat('MMMM d, y').format(parsedDate);
    } catch (_) {
      formattedDate = widget.date;
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Event Attendance List'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Event Header Card ────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event image — height clamps so it fits small screens
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      child: Image.network(
                        widget.image,
                        height: imageHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: imageHeight,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 50),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(isSmall ? 12.0 : 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmall ? 13 : 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: isSmall ? 18 : 22,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.location,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: isSmall ? 13 : 15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Search box ───────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmall ? 12.0 : 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Attendance Summary ───────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmall ? 12.0 : 16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSmall ? 12.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Summary',
                          style: TextStyle(
                            fontSize: isSmall ? 15 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // IntrinsicHeight lets all stat cards match the tallest
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildStatCard(
                                'Total',
                                widget.attendees.length.toString(),
                                Colors.blue,
                                isSmall,
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                'Attended',
                                widget.attendees
                                    .where((a) => a['attended'] == true)
                                    .length
                                    .toString(),
                                Colors.green,
                                isSmall,
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                'Absent',
                                widget.attendees
                                    .where((a) => a['attended'] != true)
                                    .length
                                    .toString(),
                                Colors.red,
                                isSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Attendees List ───────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmall ? 12.0 : 16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSmall ? 12.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendees List',
                          style: TextStyle(
                            fontSize: isSmall ? 15 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Attendee rows
                        ListView.builder(
                          itemCount: _pageItems.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final attendee = _pageItems[index];
                            final attendeeName =
                                attendee['fullName'] ?? 'Unknown';
                            final isAttended =
                                attendee['attended'] ?? false;
                            final itemNumber =
                                ((_currentPage - 1) * _pageSize) + index + 1;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.all(isSmall ? 8.0 : 12.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  // Number badge
                                  CircleAvatar(
                                    radius: isSmall ? 16 : 20,
                                    backgroundColor: Colors.blue[100],
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '$itemNumber',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmall ? 11 : 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isSmall ? 8 : 12),

                                  // Name — takes remaining space, never overflows
                                  Expanded(
                                    child: Text(
                                      attendeeName,
                                      style: TextStyle(
                                        fontSize: isSmall ? 13 : 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Status badge — fixed width prevents it
                                  // from pushing the name off-screen on narrow
                                  // devices
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmall ? 8 : 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAttended
                                          ? Colors.green[50]
                                          : Colors.red[50],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isAttended ? 'Attended' : 'Absent',
                                      style: TextStyle(
                                        color: isAttended
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmall ? 11 : 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // ── Pagination ─────────────────────────────────────
                        // Wrap in a column so the two rows stack on tiny screens
                        // instead of overflowing horizontally.
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final paginationFits = constraints.maxWidth >= 320;
                            final pageInfo = Text(
                              'Page $_currentPage of $_totalPages  •  ${_filteredAttendees.length} total',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isSmall ? 11 : 13,
                              ),
                            );
                            final prevNext = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  onPressed: _currentPage > 1
                                      ? () => setState(
                                          () => _currentPage -= 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_left,
                                      size: 18),
                                  label: const Text('Prev'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isSmall ? 4 : 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                TextButton.icon(
                                  onPressed: _currentPage < _totalPages
                                      ? () => setState(
                                          () => _currentPage += 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_right,
                                      size: 18),
                                  label: const Text('Next'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isSmall ? 4 : 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            );

                            if (paginationFits) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(child: pageInfo),
                                  prevNext,
                                ],
                              );
                            } else {
                              // Very narrow: stack vertically
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [pageInfo, prevNext],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, bool isSmall) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmall ? 10.0 : 12.0,
          horizontal: 6.0,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isSmall ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isSmall ? 10 : 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
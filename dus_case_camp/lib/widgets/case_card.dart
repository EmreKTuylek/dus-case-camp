import 'package:flutter/material.dart';
import '../models/case_model.dart';
import '../services/user_list_service.dart';
// Note: Accessing CaseDetailScreen via named route or direct push. Using placeholder for now.

class CaseCard extends StatefulWidget {
  final CaseModel caseModel;
  final VoidCallback onTap;
  final bool compact;

  const CaseCard({
    Key? key,
    required this.caseModel,
    required this.onTap,
    this.compact = false,
  }) : super(key: key);

  @override
  State<CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends State<CaseCard> {
  final UserListService _userListService = UserListService();
  bool _isFavorite = false;
  bool _isWatchLater = false;

  @override
  void initState() {
    super.initState();
    _checkUserLists();
  }

  void _checkUserLists() async {
    final fav = await _userListService.isFavorite(widget.caseModel.id);
    final wl = await _userListService.isWatchLater(widget.caseModel.id);
    if (mounted) {
      setState(() {
        _isFavorite = fav;
        _isWatchLater = wl;
      });
    }
  }

  void _toggleFavorite() async {
    if (_isFavorite) {
      await _userListService.removeFromFavorites(widget.caseModel.id);
    } else {
      await _userListService.addToFavorites(widget.caseModel);
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _toggleWatchLater() async {
    if (_isWatchLater) {
      await _userListService.removeFromWatchLater(widget.caseModel.id);
    } else {
      await _userListService.addToWatchLater(widget.caseModel);
    }
    setState(() {
      _isWatchLater = !_isWatchLater;
    });
  }

  void _addToCalendar(BuildContext context) {
    // Mock integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📅 Added to Calendar: Q&A Session')),
    );
  }

  void _showPrepMaterials(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preparation Materials',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (widget.caseModel.preparationMaterials != null &&
                  widget.caseModel.preparationMaterials!.isNotEmpty)
                ...widget.caseModel.preparationMaterials!
                    .map((url) => ListTile(
                          leading: const Icon(Icons.picture_as_pdf,
                              color: Colors.red),
                          title: Text(
                              url.split('/').last), // Simple name extraction
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Opening $url...')),
                            );
                          },
                        ))
                    .toList()
              else
                const Text('No materials available for this case.'),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return Card(
        margin: EdgeInsets.zero, // Controlled by parent
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: widget.caseModel.mediaUrls.isNotEmpty
                    ? Image.network(
                        widget.caseModel.mediaUrls.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (c, e, s) =>
                            Container(color: Colors.grey[200]),
                      )
                    : Container(color: Colors.grey[200]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.caseModel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(widget.caseModel.level.name,
                          style: TextStyle(fontSize: 10)),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Header
          GestureDetector(
            onTap: widget.onTap,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: widget.caseModel.mediaUrls.isNotEmpty
                        ? Image.network(
                            widget.caseModel.mediaUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                Container(color: Colors.grey[200]),
                          )
                        : Container(
                            color: Colors.blueGrey[100],
                            child: const Icon(Icons.medical_services,
                                size: 50, color: Colors.white)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.caseModel.speciality,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(widget.caseModel.level),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.caseModel.level.name.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Teaser
                Text(
                  widget.caseModel.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.caseModel.teaser ?? widget.caseModel.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Actions
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : Colors.grey),
                          onPressed: _toggleFavorite,
                          tooltip: 'Favorite',
                        ),
                        IconButton(
                          icon: Icon(
                              _isWatchLater
                                  ? Icons.watch_later
                                  : Icons.watch_later_outlined,
                              color: _isWatchLater ? Colors.blue : Colors.grey),
                          onPressed: _toggleWatchLater,
                          tooltip: 'Watch Later',
                        ),
                      ],
                    ),

                    // Right Action (Main)
                    ElevatedButton(
                      onPressed: widget.onTap,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Open Case'),
                    ),
                  ],
                ),
                const Divider(),
                // Secondary Text Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showPrepMaterials(context),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('Materials'),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700]),
                    ),
                    TextButton.icon(
                      onPressed: () => _addToCalendar(context),
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: const Text('Add Logic'),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700]),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(CaseLevel level) {
    switch (level) {
      case CaseLevel.easy:
        return Colors.green;
      case CaseLevel.medium:
        return Colors.orange;
      case CaseLevel.hard:
        return Colors.red;
    }
  }
}

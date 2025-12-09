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

  Color _getDifficultyColor(CaseLevel level) {
    switch (level) {
      case CaseLevel.easy:
        return Colors.green.shade400;
      case CaseLevel.medium:
        return Colors.orange.shade400;
      case CaseLevel.hard:
        return Theme.of(context).colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = widget.compact;

    if (isCompact) {
      return Card(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: widget.caseModel.thumbnailUrl != null
                    ? Image.network(widget.caseModel.thumbnailUrl!,
                        fit: BoxFit.cover, width: double.infinity)
                    : (widget.caseModel.mediaUrls.isNotEmpty
                        ? Image.network(widget.caseModel.mediaUrls.first,
                            fit: BoxFit.cover, width: double.infinity)
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.caseModel.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(widget.caseModel.level)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(widget.caseModel.level.name.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _getDifficultyColor(
                                      widget.caseModel.level),
                                  fontWeight: FontWeight.bold))),
                      const Spacer(),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const Text(" 70 XP",
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
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
      // margin handled by theme mostly, but we can override if needed
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image with Chips
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: widget.caseModel.thumbnailUrl != null
                        ? Image.network(widget.caseModel.thumbnailUrl!,
                            fit: BoxFit.cover)
                        : (widget.caseModel.mediaUrls.isNotEmpty
                            ? Image.network(widget.caseModel.mediaUrls.first,
                                fit: BoxFit.cover)
                            : Container(
                                color: const Color(0xFFE0E0E0),
                                child: Icon(Icons.medical_services_outlined,
                                    size: 48, color: Colors.grey[400]),
                              )),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                    child: Text(
                      widget.caseModel.speciality,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(widget.caseModel.level),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                    child: Text(
                      widget.caseModel.level.name.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.caseModel.title,
                          style: theme.textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite
                              ? theme.colorScheme.error
                              : Colors.grey.shade400,
                        ),
                        onPressed: _toggleFavorite,
                        constraints: BoxConstraints(), // tight
                        padding: EdgeInsets.zero,
                        tooltip: 'Favorite',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.caseModel.teaser ?? widget.caseModel.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // Meta Row
                  Row(
                    children: [
                      // XP Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.bolt, size: 16, color: Colors.amber),
                            SizedBox(width: 4),
                            Text("70 XP",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.amber)), // Dynamic later
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Type / Duration
                      Row(
                        children: [
                          Icon(Icons.play_circle_outline,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(widget.caseModel.videoType.name.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600])),
                        ],
                      ),

                      const Spacer(),

                      OutlinedButton(
                        onPressed: widget.onTap,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 0),
                          minimumSize: const Size(0, 32),
                          side: BorderSide(
                              color: theme.primaryColor.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text("Start Case",
                            style: TextStyle(
                                fontSize: 13, color: theme.primaryColor)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

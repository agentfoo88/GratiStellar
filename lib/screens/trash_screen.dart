import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../storage.dart';
import '../features/gratitudes/presentation/state/gratitude_provider.dart';
import '../font_scaling.dart';
import '../l10n/app_localizations.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gratitudeProvider = Provider.of<GratitudeProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A2238).withValues(alpha: 0.95),
        title: Text(
          l10n.trashScreenTitle,
          style: FontScaling.getHeadingMedium(context).copyWith(
            color: Color(0xFFFFE135),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFFFE135)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<GratitudeStar>>(
        future: gratitudeProvider.getDeletedGratitudes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Color(0xFFFFE135)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                l10n.errorLoadingTrash,
                style: FontScaling.getBodyMedium(context).copyWith(
                  color: Colors.white70,
                ),
              ),
            );
          }

          final deletedStars = snapshot.data ?? [];

          if (deletedStars.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 64,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 16),
                  Text(
                    l10n.trashEmpty,
                    style: FontScaling.getBodyLarge(context).copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    l10n.trashEmptyDescription,
                    style: FontScaling.getBodySmall(context).copyWith(
                      color: Colors.white38,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Sort by deletion date (newest first)
          deletedStars.sort((a, b) {
            final aDate = a.deletedAt ?? a.updatedAt;
            final bDate = b.deletedAt ?? b.updatedAt;
            return bDate.compareTo(aDate);
          });

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: deletedStars.length,
            itemBuilder: (context, index) {
              final star = deletedStars[index];
              final deletedAt = star.deletedAt ?? star.updatedAt;
              final daysAgo = DateTime.now().difference(deletedAt).inDays;
              final daysRemaining = 30 - daysAgo;

              return Card(
                color: Color(0xFF1A2238).withValues(alpha: 0.7),
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    star.text,
                    style: FontScaling.getBodyMedium(context).copyWith(
                      color: Colors.white,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.white54,
                        ),
                        SizedBox(width: 4),
                        Text(
                          l10n.deletedOn(DateFormat.yMMMd().format(deletedAt)),
                          style: FontScaling.getCaption(context).copyWith(
                            color: Colors.white54,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: daysRemaining <= 7
                                ? Colors.red.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.daysRemaining(daysRemaining),
                            style: FontScaling.getCaption(context).copyWith(
                              color: daysRemaining <= 7 ? Colors.red[300] : Colors.orange[300],
                              fontWeight: FontScaling.boldWeight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Restore button
                      IconButton(
                        icon: Icon(Icons.restore, color: Color(0xFFFFE135)),
                        tooltip: AppLocalizations.of(context)!.restoreTooltip,
                        onPressed: () async {
                          await _showRestoreDialog(context, star, gratitudeProvider);
                        },
                      ),
                      // Permanently delete button
                      IconButton(
                        icon: Icon(Icons.delete_forever, color: Colors.red[300]),
                        tooltip: AppLocalizations.of(context)!.deletePermanentlyTooltip,
                        onPressed: () async {
                          await _showPermanentDeleteDialog(context, star, gratitudeProvider);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showRestoreDialog(
      BuildContext context,
      GratitudeStar star,
      GratitudeProvider gratitudeProvider,
      ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A2238),
        title: Text(
          l10n.restoreDialogTitle,
          style: FontScaling.getModalTitle(context),
        ),
        content: Text(
          l10n.restoreDialogContent,
          style: FontScaling.getBodyMedium(context).copyWith(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.restoreButton, style: TextStyle(color: Color(0xFFFFE135))),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await gratitudeProvider.restoreGratitude(star);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.gratitudeRestored),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Refresh the screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => TrashScreen()),
        );
      }
    }
  }

  Future<void> _showPermanentDeleteDialog(
      BuildContext context,
      GratitudeStar star,
      GratitudeProvider gratitudeProvider,
      ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A2238),
        title: Text(
          l10n.permanentDeleteDialogTitle,
          style: FontScaling.getModalTitle(context).copyWith(
            color: Colors.red[300],
          ),
        ),
        content: Text(
          l10n.permanentDeleteDialogContent,
          style: FontScaling.getBodyMedium(context).copyWith(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton, style: FontScaling.getButtonText(context).copyWith(
              color: Colors.white70,
            )),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.deleteForeverButton,
              style: TextStyle(color: Colors.red[300], fontWeight: FontScaling.boldWeight),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await gratitudeProvider.permanentlyDeleteGratitude(star);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.gratitudePermanentlyDeleted),
            backgroundColor: Colors.red[700],
            duration: Duration(seconds: 2),
          ),
        );

        // Refresh the screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => TrashScreen()),
        );
      }
    }
  }
}
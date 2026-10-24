import 'package:coldchat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../components/surface.dart';
import '../../data/filesharing/upload_queue_cubit.dart';
import '../../data/filesharing/upload_task.dart';

/// The strip of upload chips above the message input.
///
/// Sits in the same slot as the reply preview and only takes space while
/// something is uploading, so the composer stays exactly where it was and the
/// user can keep typing and sending throughout.
class UploadQueueBar extends StatelessWidget {
  final String channelName;

  const UploadQueueBar({
    super.key,
    required this.channelName,
  });

  /// Past this many chips the strip scrolls instead of eating the chat.
  static const double _maxHeight = 64.0 * 3;

  @override
  Widget build(BuildContext context) => BlocBuilder<UploadQueueCubit, List<UploadTask>>(
        bloc: context.read<UploadQueueCubit>(),
        builder: (context, tasks) {
          final mine = tasks.where((task) => task.channelName == channelName).toList();
          if (mine.isEmpty) return const SizedBox.shrink();

          return ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: _maxHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final task in mine) _UploadChip(task: task),
                ],
              ),
            ),
          );
        },
      );
}

class _UploadChip extends StatelessWidget {
  final UploadTask task;

  const _UploadChip({required this.task});

  @override
  Widget build(BuildContext context) {
    final failed = task.status == UploadStatus.failed;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Surface(
      type: failed ? SurfaceType.error : SurfaceType.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12.0, 8.0, 4.0, 8.0),
        child: Row(
          children: [
            Icon(
              failed ? Icons.error_outline_rounded : Icons.image_outlined,
              size: 20.0,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.filename,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        _trailingLabel(context, l10n),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  if (!failed)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2.0),
                      // Null value = indeterminate, which is exactly right once
                      // every byte is out and we are waiting on the host.
                      child: LinearProgressIndicator(
                        value: task.progress,
                        minHeight: 4.0,
                      ),
                    ),
                  if (failed)
                    // Short and localized; the raw exception text from every
                    // host is one tap away instead of truncated in the chip.
                    InkWell(
                      onTap: () => _showDetails(context, l10n),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${_errorMessage(l10n)} · '),
                            TextSpan(
                              text: l10n.uploadErrorDetails,
                              style: const TextStyle(decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                      ),
                    ),
                  // Only shown while a later host is carrying the upload, so
                  // switching hosts is never silent.
                  if (!failed && task.attempts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        l10n.uploadRetryingWith(task.hostName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            if (failed)
              IconButton(
                tooltip: l10n.uploadRetry,
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => context.read<UploadQueueCubit>().retry(task),
              ),
            IconButton(
              tooltip: failed ? l10n.uploadDismiss : l10n.uploadCancel,
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                final queue = context.read<UploadQueueCubit>();
                failed ? queue.remove(task) : queue.cancel(task);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _errorMessage(AppLocalizations l10n) {
    final host = task.errorHost ?? task.hostName;
    switch (task.errorKind) {
      case UploadErrorKind.offline:
        return l10n.uploadErrorOffline;
      case UploadErrorKind.timeout:
        return l10n.uploadErrorTimeout(host);
      case UploadErrorKind.rejected:
        return l10n.uploadErrorRejected(host, '${task.errorStatus ?? '?'}');
      case UploadErrorKind.badResponse:
        return l10n.uploadErrorBadResponse(host);
      case UploadErrorKind.network:
        return l10n.uploadErrorNetwork(host);
      case UploadErrorKind.unreadableFile:
        return l10n.uploadErrorUnreadableFile;
      case UploadErrorKind.unknown:
      case null:
        return l10n.uploadErrorUnknown(host);
    }
  }

  /// Every host's technical error, selectable so it can be copied into a bug
  /// report.
  void _showDetails(BuildContext context, AppLocalizations l10n) {
    final lines = [
      for (final failure in task.attempts) '${failure.hostName}: ${failure.message}',
      if (task.errorDetail != null) task.errorDetail!,
    ];

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_errorMessage(l10n)),
        content: SingleChildScrollView(
          child: SelectableText(lines.join('\n\n')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  String _trailingLabel(BuildContext context, AppLocalizations l10n) {
    switch (task.status) {
      case UploadStatus.uploading:
        final progress = task.progress;
        final percent = progress == null ? '' : ' ${(progress * 100).round()}%';
        return '${l10n.uploadingTo(task.hostName)}$percent';
      case UploadStatus.processing:
        // Count the wait so a slow host reads as slow, not stuck. Hidden for
        // the first second to avoid flashing "0s" on fast hosts.
        final seconds = task.processingSeconds ?? 0;
        return seconds >= 1 ? '${l10n.uploadProcessing} ${seconds}s' : l10n.uploadProcessing;
      case UploadStatus.failed:
        return l10n.uploadFailed;
      case UploadStatus.done:
        return l10n.uploadDone;
      case UploadStatus.cancelled:
        return '';
    }
  }
}

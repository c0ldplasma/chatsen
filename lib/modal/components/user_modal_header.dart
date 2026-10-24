import 'package:cached_network_image/cached_network_image.dart';
import 'package:coldchat/modal/components/modal_header.dart';
import 'package:flutter/material.dart';

import '../../api/twitch/twitch_profile.dart';

class UserModalHeader extends StatelessWidget {
  final TwitchProfile profile;

  const UserModalHeader({
    super.key,
    required this.profile,
  });

  TwitchUser get user => profile.user;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Positioned.fill(
                child: Ink.image(
                  image: CachedNetworkImageProvider(user.offlineImageUrl ?? user.profileImageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.75),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Material(
                          borderRadius: BorderRadius.circular(8.0),
                          clipBehavior: Clip.antiAlias,
                          elevation: 8.0,
                          child: Ink.image(
                            image: CachedNetworkImageProvider(user.profileImageUrl),
                            width: 64.0,
                            height: 64.0,
                            child: InkWell(
                              onTap: () {},
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        SelectableText.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: user.displayName, style: Theme.of(context).textTheme.titleLarge),
                              TextSpan(text: '#${user.id}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75))),
                            ],
                          ),
                        ),
                        if (profile.followerCount != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_alt, color: Theme.of(context).textTheme.bodyMedium!.color, size: Theme.of(context).textTheme.bodyMedium!.fontSize),
                              Text(' ${profile.followerCount}', style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const ModalHeader(),
            ],
          ),
          if (profile.stream != null)
            Stack(
              children: [
                Positioned.fill(
                  child: Ink.image(
                    image: CachedNetworkImageProvider(profile.stream!.thumbnailUrl.replaceAll('{width}', '1920').replaceAll('{height}', '1080')),
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(child: Container(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.75))),
                Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (profile.stream!.gameBoxArtUrl != null) ...[
                            Material(
                              borderRadius: BorderRadius.circular(8.0),
                              clipBehavior: Clip.antiAlias,
                              elevation: 8.0,
                              child: Ink.image(
                                image: CachedNetworkImageProvider(profile.stream!.gameBoxArtUrl!),
                                fit: BoxFit.cover,
                                width: 64.0,
                                height: 64.0,
                                child: InkWell(
                                  onTap: () {},
                                ),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                          ],
                          Expanded(
                            child: SelectableText.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: '${profile.stream!.title}\n', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${profile.stream!.gameName}\n', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).textTheme.titleMedium!.color!.withValues(alpha: 0.75))),
                                  WidgetSpan(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.timelapse, color: Theme.of(context).textTheme.bodyMedium!.color, size: Theme.of(context).textTheme.bodyMedium!.fontSize),
                                        Text(' ${DateTime.now().difference(profile.stream!.startedAt)}'.split('.').first, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const WidgetSpan(child: SizedBox(width: 16.0)),
                                  WidgetSpan(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.remove_red_eye, color: Theme.of(context).textTheme.bodyMedium!.color, size: Theme.of(context).textTheme.bodyMedium!.fontSize),
                                        Text(' ${profile.stream!.viewerCount}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      );
}

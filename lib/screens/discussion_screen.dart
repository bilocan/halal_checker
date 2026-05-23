import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../localization/format_relative_time.dart';
import '../models/community.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';

part 'discussion/discussion_tabs.dart';
part 'discussion/discussion_comments.dart';

class DiscussionScreen extends StatefulWidget {
  final String barcode;
  final String productName;

  const DiscussionScreen({
    super.key,
    required this.barcode,
    required this.productName,
  });

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  List<Discussion> _discussions = [];
  List<IngredientChallenge> _challenges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      CommunityService.getDiscussions(widget.barcode),
      CommunityService.getChallenges(widget.barcode),
    ]);
    if (!mounted) return;
    setState(() {
      _discussions = results[0] as List<Discussion>;
      _challenges = results[1] as List<IngredientChallenge>;
      _loading = false;
    });
  }

  void _startDiscussion() {
    if (AuthService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).signInToDiscuss)),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StartDiscussionSheet(barcode: widget.barcode),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.productName, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: AppLocalizations.of(context).discussions),
              Tab(text: AppLocalizations.of(context).challenges),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab_discussion',
          onPressed: _startDiscussion,
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context).newDiscussion),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _DiscussionsTab(
                    discussions: _discussions,
                    barcode: widget.barcode,
                    productName: widget.productName,
                    onRefresh: _load,
                  ),
                  _ChallengesTab(challenges: _challenges),
                ],
              ),
      ),
    );
  }
}

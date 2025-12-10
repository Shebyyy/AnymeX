import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/contributor.dart';
import '../../../controllers/contributors/contributor_controller.dart';
import '../../../widgets/anymex_bottomsheet.dart';

class ContributorsPage extends StatefulWidget {
  @override
  State<ContributorsPage> createState() => _ContributorsPageState();
}

class _ContributorsPageState extends State<ContributorsPage> {
  late Future<List<Contributor>> future;

  @override
  void initState() {
    super.initState();
    future = ContributorController.getContributors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contributors")),
      body: FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final list = snapshot.data!;

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final c = list[i];

              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(c.avatar)),
                title: Text(c.name),
                subtitle: Text(c.role ?? "Contributor"),
                onTap: () => _openContributor(c),
              );
            },
          );
        },
      ),
    );
  }

  void _openContributor(Contributor c) {
    showAnymexBottomSheet(
      context,
      child: Column(
        children: [
          if (c.banner != null && c.banner!.isNotEmpty)
            Image.network(c.banner!, height: 120, fit: BoxFit.cover),

          const SizedBox(height: 16),

          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(c.avatar),
          ),

          const SizedBox(height: 12),

          Text(
            c.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          if (c.role != null)
            Text(
              c.role!,
              style: const TextStyle(color: Colors.grey),
            ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              final url = Uri.parse(c.profileUrl);
              launchUrl(url, mode: LaunchMode.externalApplication);
            },
            child: const Text("View Profile"),
          ),
        ],
      ),
    );
  }
}

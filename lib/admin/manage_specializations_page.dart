import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/models/CreateSpecializationModel.dart';

class ManageSpecializationsPage extends StatefulWidget {
  const ManageSpecializationsPage({super.key});

  @override
  State<ManageSpecializationsPage> createState() => _ManageSpecializationsPageState();
}

class _ManageSpecializationsPageState extends State<ManageSpecializationsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<SpecializationModel> _specializations = [];

  @override
  void initState() {
    super.initState();
    _fetchSpecializations();
  }

  Future<void> _fetchSpecializations() async {
    setState(() => _isLoading = true);
    try {
      final specs = await _apiService.getAllSpecializations();
      setState(() {
        _specializations = specs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching specializations: $e")),
        );
      }
    }
  }

  void _showAddEditDialog({SpecializationModel? spec}) {
    final nameController = TextEditingController(text: spec?.name ?? "");
    final descriptionController = TextEditingController(text: spec?.description ?? "");
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(spec == null ? "Add Specialization" : "Edit Specialization"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final createModel = CreateSpecializationModel(
                  name: nameController.text,
                  description: descriptionController.text,
                );
                
                bool success;
                if (spec == null) {
                  success = await _apiService.createSpecialization(createModel);
                } else {
                  success = await _apiService.updateSpecialization(spec.id, createModel);
                }

                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    _fetchSpecializations();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Action failed")),
                    );
                  }
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Specializations", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _specializations.isEmpty
              ? const Center(child: Text("No specializations found"))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _specializations.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final spec = _specializations[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.category_rounded, color: primaryColor),
                        ),
                        title: Text(spec.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(spec.description),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Colors.grey),
                          onPressed: () => _showAddEditDialog(spec: spec),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/models/CreateSpecializationModel.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          spec == null ? "Add Specialization" : "Edit Specialization",
          style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category_rounded),
                ),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description_rounded),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: CommonAppBar(
        pageName: "Specializations",
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSpecializations,
        color: primaryColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryColor))
            : _specializations.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.category_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 10),
                            Text("No specializations found", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _specializations.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final spec = _specializations[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(Icons.category_rounded, color: primaryColor, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    spec.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    spec.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.grey),
                              onPressed: () => _showAddEditDialog(spec: spec),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

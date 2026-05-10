import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/models/CreateSpecializationModel.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: context.subText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSaving ? null : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() => isSaving = true);
                  
                  final createModel = CreateSpecializationModel(
                    name: nameController.text,
                    description: descriptionController.text,
                  );
                  
                  try {
                    bool success;
                    if (spec == null) {
                      success = await _apiService.createSpecialization(createModel);
                    } else {
                      success = await _apiService.updateSpecialization(spec.id, createModel);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(spec == null ? "Created successfully" : "Updated successfully"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _fetchSpecializations();
                      }
                    }
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSpecialization(SpecializationModel spec) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Specialization", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text("Are you sure you want to delete '${spec.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: context.subText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final success = await _apiService.deleteSpecialization(spec.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Deleted successfully"), backgroundColor: Colors.green),
          );
          _fetchSpecializations();
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
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
            ? Skeletonizer(
                enabled: true,
                child: ListView.separated(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 90),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: 5,
                  separatorBuilder: (context, index) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final dummySpec = SpecializationModel(
                      id: 0,
                      name: "Loading Name",
                      description: "Loading description text...",
                    );
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.04),
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
                                  dummySpec.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: context.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dummySpec.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.subText,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_rounded, color: context.subText),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            : _specializations.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.category_outlined, size: 60, color: context.subText.withValues(alpha: 0.5)),
                            const SizedBox(height: 10),
                            Text("No specializations found", style: TextStyle(color: context.subText)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 90),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _specializations.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final spec = _specializations[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.04),
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: context.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    spec.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.subText,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit_rounded, color: context.subText),
                                  onPressed: () => _showAddEditDialog(spec: spec),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                  onPressed: () => _deleteSpecialization(spec),
                                ),
                              ],
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

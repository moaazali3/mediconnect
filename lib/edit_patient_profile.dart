import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';

class EditPatientProfile extends StatefulWidget {
  const EditPatientProfile({super.key});

  @override
  State<EditPatientProfile> createState() => _EditPatientProfileState();
}

class _EditPatientProfileState extends State<EditPatientProfile> {
  final formKey = GlobalKey<FormState>();

  final fNameController = TextEditingController();
  final lNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final emergencyController = TextEditingController();
  final emailController = TextEditingController();
  final ageController = TextEditingController();
  String? selectedBloodType;

  @override
  void initState() {
    super.initState();
    fNameController.text = "John";
    lNameController.text = "Doe";
    emailController.text = "johndoe@example.com";
    phoneController.text = "01234567890";
    addressController.text = "Cairo, Egypt";
    weightController.text = "75";
    heightController.text = "180";
    emergencyController.text = "01987654321";
    ageController.text = "26";
    selectedBloodType = "A+";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: primaryColor,
                    child: CircleAvatar(
                      radius: 47,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person_rounded, size: 55, color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                _buildSectionTitle("Personal Information"),
                _buildEditCard([
                  _buildEditRow(label: "Email (Read Only)", controller: emailController, icon: Icons.email_outlined, isReadOnly: true),
                  _buildDivider(),
                  Row(
                    children: [
                      Expanded(child: _buildEditRow(label: "First Name", controller: fNameController, icon: Icons.person_outline)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildEditRow(label: "Last Name", controller: lNameController, icon: Icons.person_outline)),
                    ],
                  ),
                  _buildDivider(),
                  Row(
                    children: [
                      Expanded(child: _buildEditRow(label: "Phone", controller: phoneController, icon: Icons.phone_android_rounded)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildEditRow(label: "Age", controller: ageController, icon: Icons.cake_rounded)),
                    ],
                  ),
                  _buildDivider(),
                  _buildEditRow(label: "Address", controller: addressController, icon: Icons.location_on_outlined),
                ]),

                const SizedBox(height: 20),
                _buildSectionTitle("Medical Background"),
                _buildEditCard([
                  Row(
                    children: [
                      Expanded(child: _buildEditRow(label: "Height (cm)", controller: heightController, icon: Icons.height_rounded)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildEditRow(label: "Weight (kg)", controller: weightController, icon: Icons.monitor_weight_outlined)),
                    ],
                  ),
                  _buildDivider(),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          label: "Blood Type",
                          icon: Icons.bloodtype_outlined,
                          value: selectedBloodType,
                          items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                          onChanged: (val) => setState(() => selectedBloodType = val),
                        ),
                      ),
                    ],
                  ),
                  _buildDivider(),
                  _buildEditRow(label: "Emergency Contact", controller: emergencyController, icon: Icons.contact_emergency_rounded),
                ]),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context, {
                          'fName': fNameController.text,
                          'lName': lNameController.text,
                          'phone': phoneController.text,
                          'address': addressController.text,
                          'weight': weightController.text,
                          'height': heightController.text,
                          'emergency': emergencyController.text,
                          'age': ageController.text,
                          'blood': selectedBloodType ?? "A+",
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile Updated Successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text("SAVE CHANGES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: TextButton(
                    onPressed: () => _showChangePasswordDialog(context),
                    child: const Text("Change Password", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
    );
  }

  Widget _buildEditCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildEditRow({required String label, required TextEditingController controller, required IconData icon, bool isReadOnly = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: isReadOnly,
        keyboardType: keyboardType,
        style: TextStyle(color: isReadOnly ? Colors.grey : Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          border: InputBorder.none,
          isDense: true,
        ),
        validator: isReadOnly ? null : (value) => (value == null || value.isEmpty) ? "Required" : null,
      ),
    );
  }

  Widget _buildDropdownField({required String label, required IconData icon, required String? value, required List<String> items, required Function(String?) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 45, endIndent: 15, color: Colors.grey.shade100);
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final passKey = GlobalKey<FormState>();
    bool isObscured = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
          content: Form(
            key: passKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPopupField(controller: oldPass, label: "Old Password", icon: Icons.lock_outline, isObscured: isObscured),
                const SizedBox(height: 10),
                _buildPopupField(
                  controller: newPass, 
                  label: "New Password", 
                  icon: Icons.lock_reset_rounded, 
                  isObscured: isObscured,
                  suffix: IconButton(
                    icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                    onPressed: () => setState(() => isObscured = !isObscured),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () { if (passKey.currentState!.validate()) Navigator.pop(context); },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text("Update", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupField({required TextEditingController controller, required String label, required IconData icon, bool isObscured = false, Widget? suffix}) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
    );
  }
}

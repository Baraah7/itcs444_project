import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEditEquipmentPage extends StatefulWidget {
  final String? equipmentId;
  final String? initialName;
  final String? initialDescription;
  final String? initialType;

  const AddEditEquipmentPage({
    super.key,
    this.equipmentId,
    this.initialName,
    this.initialDescription,
    this.initialType,
  });

  @override
  State<AddEditEquipmentPage> createState() => _AddEditEquipmentPageState();
}

class _AddEditEquipmentPageState extends State<AddEditEquipmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Medical equipment types for dropdown
  final List<String> _equipmentTypes = [
    'Mobility Aid',
    'Bathroom Aid',
    'Hospital Furniture',
    'Other'
  ];
  
  String _selectedType = 'Other';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize form fields with existing data if editing
    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
    if (widget.initialType != null && _equipmentTypes.contains(widget.initialType)) {
      _selectedType = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final equipmentData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.equipmentId == null) {
        // Create new equipment
        equipmentData['createdAt'] = FieldValue.serverTimestamp();
        equipmentData['totalItems'] = 0;
        equipmentData['availableItems'] = 0;
        
        await FirebaseFirestore.instance
            .collection('equipment')
            .add(equipmentData);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Equipment added successfully'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Update existing equipment
        await FirebaseFirestore.instance
            .collection('equipment')
            .doc(widget.equipmentId)
            .update(equipmentData);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Equipment updated successfully'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteEquipment() async {
    if (widget.equipmentId == null) return;
    
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Equipment',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        content: const Text(
          'This will permanently delete this equipment and all items under it. This action cannot be undone.',
          style: TextStyle(
            color: Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    if (result == true && context.mounted) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // First, delete all items in the subcollection
        final itemsSnapshot = await FirebaseFirestore.instance
            .collection('equipment')
            .doc(widget.equipmentId)
            .collection('Items')
            .get();
        
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in itemsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        
        // Then delete the equipment document
        await FirebaseFirestore.instance
            .collection('equipment')
            .doc(widget.equipmentId)
            .delete();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Equipment deleted successfully'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'wheelchair':
        return const Icon(Icons.accessible_forward, color: Color(0xFF2B6C67));
      case 'crutches':
        return const Icon(Icons.directions_walk, color: Color(0xFF2B6C67));
      case 'walker':
        return const Icon(Icons.directions_walk, color: Color(0xFF2B6C67));
      case 'hospital bed':
        return const Icon(Icons.bed, color: Color(0xFF2B6C67));
      case 'oxygen tank':
        return const Icon(Icons.air, color: Color(0xFF2B6C67));
      case 'nebulizer':
        return const Icon(Icons.medical_services, color: Color(0xFF2B6C67));
      case 'blood pressure monitor':
        return const Icon(Icons.monitor_heart, color: Color(0xFF2B6C67));
      case 'glucose meter':
        return const Icon(Icons.monitor, color: Color(0xFF2B6C67));
      case 'thermometer':
        return const Icon(Icons.thermostat, color: Color(0xFF2B6C67));
      case 'first aid kit':
        return const Icon(Icons.medical_services, color: Color(0xFF2B6C67));
      default:
        return const Icon(Icons.medical_services, color: Color(0xFF2B6C67));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2B6C67)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.equipmentId == null ? 'Add New Equipment' : 'Edit Equipment',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (widget.equipmentId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              onPressed: _isLoading ? null : _deleteEquipment,
              tooltip: 'Delete Equipment',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B6C67),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color.fromARGB(255, 56, 146, 137),
                            Color.fromARGB(255, 122, 201, 194),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.equipmentId == null 
                                  ? Icons.add_circle_outline 
                                  : Icons.edit,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.equipmentId == null 
                                      ? 'Add Equipment' 
                                      : 'Update Equipment Details',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Fill in the details below',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Equipment Name Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Equipment Name *',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'e.g., Standard Wheelchair, Portable Oxygen Tank',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2B6C67)),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.medical_services,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 15,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Equipment name is required';
                            }
                            if (value.trim().length < 3) {
                              return 'Name must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Equipment Type Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Equipment Type *',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE8ECEF)),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedType,
                              isExpanded: true,
                              icon: Container(
                                padding: const EdgeInsets.only(right: 16),
                                child: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              items: _equipmentTypes.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      children: [
                                        _buildTypeIcon(value),
                                        const SizedBox(width: 12),
                                        Text(
                                          value,
                                          style: const TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedType = newValue;
                                  });
                                }
                              },
                              selectedItemBuilder: (BuildContext context) {
                                return _equipmentTypes.map<Widget>((String value) {
                                  return Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      children: [
                                        _buildTypeIcon(value),
                                        const SizedBox(width: 12),
                                        Text(
                                          value,
                                          style: const TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Description Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description *',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 5,
                          minLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Describe the equipment, specifications, usage instructions, maintenance requirements...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2B6C67)),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            alignLabelWithHint: true,
                          ),
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 15,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Description is required';
                            }
                            if (value.trim().length < 10) {
                              return 'Description must be at least 10 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    Row(
                      children: [
                        // Cancel Button
                        if (widget.equipmentId != null)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF64748B),
                                side: const BorderSide(color: Color(0xFFE8ECEF)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        
                        if (widget.equipmentId != null) const SizedBox(width: 12),
                        
                        // Save Button
                        Expanded(
                          flex: widget.equipmentId == null ? 1 : 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveEquipment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2B6C67),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        widget.equipmentId == null
                                            ? Icons.add_circle_outline
                                            : Icons.save,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.equipmentId == null
                                            ? 'Add Equipment'
                                            : 'Save Changes',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Help Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD1FAE5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Tips for adding equipment:',
                                style: TextStyle(
                                  color: Color(0xFF065F46),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• Use descriptive names that clearly identify the equipment',
                                style: TextStyle(
                                  color: Color(0xFF047857),
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '• Include brand, model, and specifications in description',
                                style: TextStyle(
                                  color: Color(0xFF047857),
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '• Add maintenance requirements and safety instructions',
                                style: TextStyle(
                                  color: Color(0xFF047857),
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '• Specify usage limitations if applicable',
                                style: TextStyle(
                                  color: Color(0xFF047857),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
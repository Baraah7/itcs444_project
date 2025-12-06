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
  
  // Equipment types for dropdown
  final List<String> _equipmentTypes = [
    'Power Tools',
    'Hand Tools',
    'Electrical',
    'Plumbing',
    'Gardening',
    'Cleaning',
    'Safety',
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
            const SnackBar(
              content: Text('Equipment added successfully'),
              backgroundColor: Colors.green,
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
            const SnackBar(
              content: Text('Equipment updated successfully'),
              backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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
        title: const Text('Delete Equipment'),
        content: const Text('This will permanently delete this equipment and all items under it. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
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
            const SnackBar(
              content: Text('Equipment deleted successfully'),
              backgroundColor: Colors.green,
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
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'power tools':
        return const Icon(Icons.build, color: Colors.blue);
      case 'hand tools':
        return const Icon(Icons.handyman, color: Colors.green);
      case 'electrical':
        return const Icon(Icons.electrical_services, color: Colors.yellow);
      case 'plumbing':
        return const Icon(Icons.plumbing, color: Colors.blueAccent);
      case 'gardening':
        return const Icon(Icons.nature, color: Colors.greenAccent);
      case 'cleaning':
        return const Icon(Icons.cleaning_services, color: Colors.cyan);
      case 'safety':
        return const Icon(Icons.security, color: Colors.red);
      default:
        return const Icon(Icons.devices_other, color: Colors.grey);
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'power tools':
        return Colors.blue;
      case 'hand tools':
        return Colors.green;
      case 'electrical':
        return Colors.yellow[700]!;
      case 'plumbing':
        return Colors.blue[300]!;
      case 'gardening':
        return Colors.green[700]!;
      case 'cleaning':
        return Colors.cyan;
      case 'safety':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.equipmentId == null ? 'Add New Equipment' : 'Edit Equipment',
          style: const TextStyle(fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (widget.equipmentId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _deleteEquipment,
              tooltip: 'Delete Equipment',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Equipment Name Field
                    Text(
                      'Equipment Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Equipment Name *',
                        hintText: 'e.g., Power Drill, Safety Helmet',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.devices),
                        filled: true,
                        fillColor: Colors.grey[50],
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
                    const SizedBox(height: 20),

                    // Equipment Type Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Equipment Type *',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[50],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedType,
                              isExpanded: true,
                              icon: const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Icon(Icons.arrow_drop_down),
                              ),
                              items: _equipmentTypes.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      children: [
                                        _buildTypeIcon(value),
                                        const SizedBox(width: 12),
                                        Text(value),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      children: [
                                        _buildTypeIcon(value),
                                        const SizedBox(width: 12),
                                        Text(
                                          value,
                                          style: TextStyle(
                                            color: _getTypeColor(value),
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
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Describe the equipment, its uses, and any important notes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.description),
                        filled: true,
                        fillColor: Colors.grey[50],
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
                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveEquipment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
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
                                  Icon(widget.equipmentId == null
                                      ? Icons.add_circle_outline
                                      : Icons.save),
                                  const SizedBox(width: 10),
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

                    // Cancel Button
                    if (widget.equipmentId != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Help Text
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Tips for adding equipment:',
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Use descriptive names that are easy to recognize\n'
                            '• Choose the most appropriate type for better filtering\n'
                            '• Include details like brand, model, or specifications in the description',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                            ),
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
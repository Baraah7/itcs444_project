import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEditItemPage extends StatefulWidget {
  final String equipmentId;
  final String? itemId;
  final String? initialSerial;
  final String? initialCondition;
  final String? initialDonor;
  final bool? initialAvailability;
  final String? initialNotes;

  const AddEditItemPage({
    super.key,
    required this.equipmentId,
    this.itemId,
    this.initialSerial,
    this.initialCondition,
    this.initialDonor,
    this.initialAvailability,
    this.initialNotes,
  });

  @override
  State<AddEditItemPage> createState() => _AddEditItemPageState();
}

class _AddEditItemPageState extends State<AddEditItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _serialController = TextEditingController();
  final _conditionController = TextEditingController();
  final _donorController = TextEditingController();
  final _notesController = TextEditingController();
  bool _availability = true;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSerial != null) {
      _serialController.text = widget.initialSerial!;
    }
    if (widget.initialCondition != null) {
      _conditionController.text = widget.initialCondition!;
    }
    if (widget.initialDonor != null) {
      _donorController.text = widget.initialDonor!;
    }
    if (widget.initialNotes != null) {
      _notesController.text = widget.initialNotes!;
    }
    _availability = widget.initialAvailability ?? true;
  }

  @override
  void dispose() {
    _serialController.dispose();
    _conditionController.dispose();
    _donorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final itemData = {
        'serial': _serialController.text.trim(),
        'condition': _conditionController.text.trim(),
        'donor': _donorController.text.trim(),
        'availability': _availability,
        'notes': _notesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.itemId == null) {
        // Create new item
        itemData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('equipment')
            .doc(widget.equipmentId)
            .collection('Items')
            .add(itemData);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        // Update existing item
        await FirebaseFirestore.instance
            .collection('equipment')
            .doc(widget.equipmentId)
            .collection('Items')
            .doc(widget.itemId)
            .update(itemData);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item updated successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId == null ? 'Add Item' : 'Edit Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _serialController,
                decoration: const InputDecoration(
                  labelText: 'Serial Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter serial number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conditionController,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.assessment),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter condition';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _donorController,
                decoration: const InputDecoration(
                  labelText: 'Donor',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter donor name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Available'),
                subtitle: const Text('Is this item currently available?'),
                value: _availability,
                onChanged: (value) {
                  setState(() {
                    _availability = value;
                  });
                },
                secondary: Icon(
                  _availability ? Icons.check_circle : Icons.cancel,
                  color: _availability ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(widget.itemId == null ? 'Add Item' : 'Update Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
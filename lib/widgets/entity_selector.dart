// lib/widgets/entity_selector.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EntitySelector extends StatefulWidget {
  final String entityType; // 'landlords' oder 'apartments'
  final String? selectedEntityId;
  final String? selectedEntityName;
  final Function(String?, String?) onEntitySelected;
  final String placeholderText;
  final String createButtonText;

  const EntitySelector({
    Key? key,
    required this.entityType,
    required this.selectedEntityId,
    required this.selectedEntityName,
    required this.onEntitySelected,
    required this.placeholderText,
    required this.createButtonText,
  }) : super(key: key);

  @override
  _EntitySelectorState createState() => _EntitySelectorState();
}

class _EntitySelectorState extends State<EntitySelector> {
  List<Map<String, dynamic>> _allEntities = [];
  List<Map<String, dynamic>> _filteredEntities = [];
  bool _isLoading = false;
  final int _entitiesPerPage = 20;
  int _currentPage = 1;
  int _totalPages = 1;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEntities();
  }

Future<void> _loadEntities() async {
  if (_isLoading) return;

  setState(() {
    _isLoading = true;
  });

  try {
    Query query = FirebaseFirestore.instance
        .collection(widget.entityType)
        .orderBy('name')
        .limit(500);

    final snapshot = await query.get();

    final entities = <Map<String, dynamic>>[];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      
      // Safe extraction of name with proper casting
      String name = 'Unbekannt';
      if (data != null) {
        final typedData = data as Map<String, dynamic>;
        name = typedData['name'] as String? ?? 
               typedData['addresslong'] as String? ?? 
               'Unbekannt';
      }
      
      entities.add({
        'id': doc.id,
        'name': name,
      });
    }

    setState(() {
      _allEntities = entities;
      _totalPages = (_allEntities.length / _entitiesPerPage).ceil();
      if (_totalPages == 0) _totalPages = 1;
      _currentPage = 1;
      _isLoading = false;
    });
    
    _updateFilteredEntities();
    
  } catch (e) {
    print('Fehler beim Laden der Entities: $e');
    setState(() {
      _isLoading = false;
    });
  }
}

  void _updateFilteredEntities() {
    final filtered = _allEntities.where((entity) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return (entity['name']?.toLowerCase().contains(query) ?? false);
    }).toList();

    final startIndex = (_currentPage - 1) * _entitiesPerPage;
    
    setState(() {
      _filteredEntities = filtered.skip(startIndex).take(_entitiesPerPage).toList();
      _totalPages = (filtered.length / _entitiesPerPage).ceil();
      if (_totalPages == 0) _totalPages = 1;
    });
  }

  void _loadFilteredEntities(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
    _updateFilteredEntities();
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _updateFilteredEntities();
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _updateFilteredEntities();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.entityType == 'landlords' ? 'Vermieter (optional)' : 'Wohnung (optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            
            // Info-Text
            if (widget.entityType == 'landlords')
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  'ℹ️ Sie können den Vermieter auch später erstellen und dieser Wohnung dann zuweisen.',
                  style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                ),
              ),
            SizedBox(height: 12),
            
            // Suchfeld
            TextField(
              decoration: InputDecoration(
                labelText: 'Suchen',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                hintText: 'Name eingeben...',
              ),
              onChanged: (value) {
                _loadFilteredEntities(value);
              },
            ),
            SizedBox(height: 12),
            
            // Pagination-Controls
            if (_totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Seite $_currentPage von $_totalPages',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: _currentPage > 1 ? _previousPage : null,
                        iconSize: 20,
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: _currentPage < _totalPages ? _nextPage : null,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
            SizedBox(height: 12),
            
            // Entities-Liste
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_filteredEntities.isEmpty)
              Column(
                children: [
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Keine ${widget.entityType == 'landlords' ? 'Vermieter' : 'Wohnungen'} für "${_searchQuery}" gefunden'
                        : 'Keine ${widget.entityType == 'landlords' ? 'Vermieter' : 'Wohnungen'} gefunden',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadEntities,
                    child: Text('Erneut laden'),
                  ),
                ],
              )
            else
              Container(
                height: 200,
                child: ListView.builder(
                  itemCount: _filteredEntities.length,
                  itemBuilder: (context, index) {
                    final entity = _filteredEntities[index];
                    final isSelected = widget.selectedEntityId == entity['id'];
                    
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 2),
                      elevation: isSelected ? 4 : 1,
                      color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        title: Text(
                          entity['name'].length > 40 
                              ? '${entity['name'].substring(0, 40)}...' 
                              : entity['name'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Icon(
                          isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                          color: isSelected ? Colors.blue : Colors.grey,
                          size: 20,
                        ),
                        onTap: () {
                          if (isSelected) {
                            widget.onEntitySelected(null, null);
                          } else {
                            widget.onEntitySelected(entity['id'], entity['name']);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 12),
            Text(
              'Wählen Sie einen bestehenden Eintrag aus oder erstellen Sie einen neuen',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
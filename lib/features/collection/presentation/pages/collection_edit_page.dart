import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fftcg_companion/shared/utils/snackbar_helper.dart';
import '../../../../core/widgets/cached_card_image.dart';
import '../../../../core/providers/card_cache_provider.dart';
import '../../../../core/storage/card_cache.dart';
import '../../domain/models/collection_item.dart';
import '../../domain/utils/grading_scales.dart';
import '../../domain/providers/collection_providers.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/presentation/providers/search_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filtered_search_provider.dart';

/// Page to add or edit a collection item
class CollectionEditPage extends ConsumerStatefulWidget {
  final String? cardId;
  final CollectionItem? existingItem;
  final bool? startWithSearch;

  const CollectionEditPage({
    super.key,
    this.cardId,
    this.existingItem,
    this.startWithSearch,
  });

  @override
  ConsumerState<CollectionEditPage> createState() => _CollectionEditPageState();
}

class _CollectionEditPageState extends ConsumerState<CollectionEditPage> {
  late int regularQty;
  late int foilQty;
  late Map<String, CardCondition> condition;
  late Map<String, PurchaseInfo> purchaseInfo;
  late Map<String, GradingInfo> gradingInfo;

  final _regularPriceController = TextEditingController();
  final _foilPriceController = TextEditingController();
  final _regularCertNumberController = TextEditingController();
  final _foilCertNumberController = TextEditingController();
  final _searchController = TextEditingController();

  DateTime? _regularPurchaseDate;
  DateTime? _foilPurchaseDate;
  DateTime? _regularGradedDate;
  DateTime? _foilGradedDate;

  CardCondition? _regularCondition;
  CardCondition? _foilCondition;

  GradingCompany? _regularGradingCompany;
  GradingCompany? _foilGradingCompany;
  String? _regularGrade;
  String? _foilGrade;

  bool _isSearching = false;
  String? _selectedCardId;
  models.Card? _selectedCard;

  @override
  void initState() {
    super.initState();

    // Initialize with existing values or defaults
    regularQty = widget.existingItem?.regularQty ?? 0;
    foilQty = widget.existingItem?.foilQty ?? 0;
    condition = Map.from(widget.existingItem?.condition ?? {});
    purchaseInfo = Map.from(widget.existingItem?.purchaseInfo ?? {});
    gradingInfo = Map.from(widget.existingItem?.gradingInfo ?? {});

    // Initialize controllers
    if (purchaseInfo.containsKey('regular')) {
      _regularPriceController.text = purchaseInfo['regular']!.price.toString();
      _regularPurchaseDate = purchaseInfo['regular']!.date.toDate();
    }

    if (purchaseInfo.containsKey('foil')) {
      _foilPriceController.text = purchaseInfo['foil']!.price.toString();
      _foilPurchaseDate = purchaseInfo['foil']!.date.toDate();
    }

    // Initialize conditions
    _regularCondition = condition['regular'];
    _foilCondition = condition['foil'];

    // Initialize grading info
    if (gradingInfo.containsKey('regular')) {
      _regularGradingCompany = gradingInfo['regular']!.company;
      _regularGrade = gradingInfo['regular']!.grade;
      _regularCertNumberController.text =
          gradingInfo['regular']!.certNumber ?? '';
      _regularGradedDate = gradingInfo['regular']!.gradedDate?.toDate();
    }

    if (gradingInfo.containsKey('foil')) {
      _foilGradingCompany = gradingInfo['foil']!.company;
      _foilGrade = gradingInfo['foil']!.grade;
      _foilCertNumberController.text = gradingInfo['foil']!.certNumber ?? '';
      _foilGradedDate = gradingInfo['foil']!.gradedDate?.toDate();
    }

    // Set the selected card ID if provided
    _selectedCardId = widget.cardId;

    // If we have a card ID from the route, start in edit mode
    // Otherwise, check if we should start with search
    _isSearching = _selectedCardId == null || widget.startWithSearch == true;
  }

  @override
  void dispose() {
    _regularPriceController.dispose();
    _foilPriceController.dispose();
    _regularCertNumberController.dispose();
    _foilCertNumberController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });

    if (!_isSearching) {
      _searchController.clear();
      ref.read(searchQueryProvider.notifier).state = '';
    }
  }

  void _selectCard(models.Card card) {
    setState(() {
      _selectedCardId = card.productId.toString();
      _selectedCard = card;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.existingItem != null;
    final cardCacheAsync = ref.watch(cardCacheNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: "Search for a card...",
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                autofocus: true,
              )
            : Text(isEditing ? 'Edit Card' : 'Add Card'),
        actions: [
          // Search toggle button
          if (_selectedCardId == null || _isSearching)
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              tooltip: _isSearching ? 'Cancel' : 'Search',
              onPressed: _toggleSearch,
            ),

          // Save button (only show when not searching)
          if (!_isSearching && _selectedCardId != null)
            TextButton(
              onPressed: _saveCard,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _isSearching
          ? _buildSearchResults()
          : (_selectedCardId == null
              ? _buildEmptyState()
              : _buildCardForm(context, theme, colorScheme, cardCacheAsync)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for a card to add',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Use the search button to find cards',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Search Cards'),
            onPressed: () => setState(() => _isSearching = true),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchResults = ref.watch(filteredSearchNotifierProvider);

    return searchResults.when(
      data: (cards) {
        if (cards.isEmpty) {
          return const Center(
            child: Text('No cards found. Try a different search term.'),
          );
        }

        return ListView.builder(
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return ListTile(
              leading: SizedBox(
                width: 40,
                height: 56,
                child: CachedCardImage(
                  imageUrl: card.getBestImageUrl() ?? '',
                  fit: BoxFit.contain,
                ),
              ),
              title: Text(card.name),
              subtitle: Text(card.displayNumber ?? ''),
              onTap: () => _selectCard(card),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text('Error loading cards. Please try again.'),
      ),
    );
  }

  Widget _buildCardForm(BuildContext context, ThemeData theme,
      ColorScheme colorScheme, AsyncValue<CardCache> cardCacheAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card image and info
          cardCacheAsync.when(
            data: (cardCache) => FutureBuilder<List<models.Card>>(
              future: cardCache.getCachedCards(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  );
                }

                // Find the card in the cache
                final cards = snapshot.data!;
                final card = _selectedCard ??
                    cards.firstWhere(
                      (c) => c.productId.toString() == _selectedCardId,
                      orElse: () => const models.Card(
                        productId: 0,
                        name: 'Unknown Card',
                        cleanName: 'Unknown Card',
                        fullResUrl: '',
                        highResUrl: '',
                        lowResUrl: '',
                        groupId: 0,
                      ),
                    );

                // Get the best image URL
                final imageUrl = card.getBestImageUrl();

                if (imageUrl == null || imageUrl.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card image
                    Center(
                      child: SizedBox(
                        height: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedCardImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card name and set
                    Text(
                      card.name,
                      style: theme.textTheme.titleLarge,
                    ),
                    if (card.displayNumber != null)
                      Text(
                        '${card.displayNumber} · ${card.set.join(' · ')}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                );
              },
            ),
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(
              height: 200,
              child: Center(
                child: Icon(Icons.error, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quantities section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quantities',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Regular'),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: regularQty > 0
                                      ? () => setState(() => regularQty--)
                                      : null,
                                ),
                                Text(
                                  regularQty.toString(),
                                  style: theme.textTheme.titleLarge,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => setState(() => regularQty++),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Foil'),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: foilQty > 0
                                      ? () => setState(() => foilQty--)
                                      : null,
                                ),
                                Text(
                                  foilQty.toString(),
                                  style: theme.textTheme.titleLarge,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => setState(() => foilQty++),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Condition section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Condition',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Regular'),
                            DropdownButton<CardCondition>(
                              value: _regularCondition,
                              hint: const Text('Select'),
                              onChanged: regularQty > 0
                                  ? (value) =>
                                      setState(() => _regularCondition = value)
                                  : null,
                              items: CardCondition.values.map((condition) {
                                return DropdownMenuItem(
                                  value: condition,
                                  child: Text(condition.code),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Foil'),
                            DropdownButton<CardCondition>(
                              value: _foilCondition,
                              hint: const Text('Select'),
                              onChanged: foilQty > 0
                                  ? (value) =>
                                      setState(() => _foilCondition = value)
                                  : null,
                              items: CardCondition.values.map((condition) {
                                return DropdownMenuItem(
                                  value: condition,
                                  child: Text(condition.code),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Purchase info section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Purchase Information',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  // Regular purchase info
                  if (regularQty > 0) ...[
                    Text(
                      'Regular',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _regularPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: const Text('Purchase Date'),
                      subtitle: Text(
                        _regularPurchaseDate != null
                            ? '${_regularPurchaseDate!.month}/${_regularPurchaseDate!.day}/${_regularPurchaseDate!.year}'
                            : 'Not set',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true, false),
                    ),
                    const Divider(),
                  ],

                  // Foil purchase info
                  if (foilQty > 0) ...[
                    Text(
                      'Foil',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _foilPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: const Text('Purchase Date'),
                      subtitle: Text(
                        _foilPurchaseDate != null
                            ? '${_foilPurchaseDate!.month}/${_foilPurchaseDate!.day}/${_foilPurchaseDate!.year}'
                            : 'Not set',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, false, false),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Grading info section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grading Information',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  // Regular grading info
                  if (regularQty > 0) ...[
                    Text(
                      'Regular',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<GradingCompany>(
                            value: _regularGradingCompany,
                            hint: const Text('Grading Company'),
                            isExpanded: true,
                            onChanged: (value) => setState(() {
                              _regularGradingCompany = value;
                              _regularGrade =
                                  null; // Reset grade when company changes
                            }),
                            items: GradingCompany.values.map((company) {
                              return DropdownMenuItem(
                                value: company,
                                child: Text(company.name),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _regularGrade,
                            hint: const Text('Grade'),
                            isExpanded: true,
                            onChanged: _regularGradingCompany != null
                                ? (value) =>
                                    setState(() => _regularGrade = value)
                                : null,
                            items: _regularGradingCompany != null
                                ? GradingScales.getGradesForCompany(
                                        _regularGradingCompany!.name)
                                    .map((grade) {
                                    return DropdownMenuItem(
                                      value: grade,
                                      child: Text(grade),
                                    );
                                  }).toList()
                                : [],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _regularCertNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Certification Number',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: const Text('Graded Date'),
                      subtitle: Text(
                        _regularGradedDate != null
                            ? '${_regularGradedDate!.month}/${_regularGradedDate!.day}/${_regularGradedDate!.year}'
                            : 'Not set',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true, true),
                    ),
                    const Divider(),
                  ],

                  // Foil grading info
                  if (foilQty > 0) ...[
                    Text(
                      'Foil',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<GradingCompany>(
                            value: _foilGradingCompany,
                            hint: const Text('Grading Company'),
                            isExpanded: true,
                            onChanged: (value) => setState(() {
                              _foilGradingCompany = value;
                              _foilGrade =
                                  null; // Reset grade when company changes
                            }),
                            items: GradingCompany.values.map((company) {
                              return DropdownMenuItem(
                                value: company,
                                child: Text(company.name),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _foilGrade,
                            hint: const Text('Grade'),
                            isExpanded: true,
                            onChanged: _foilGradingCompany != null
                                ? (value) => setState(() => _foilGrade = value)
                                : null,
                            items: _foilGradingCompany != null
                                ? GradingScales.getGradesForCompany(
                                        _foilGradingCompany!.name)
                                    .map((grade) {
                                    return DropdownMenuItem(
                                      value: grade,
                                      child: Text(grade),
                                    );
                                  }).toList()
                                : [],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _foilCertNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Certification Number',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: const Text('Graded Date'),
                      subtitle: Text(
                        _foilGradedDate != null
                            ? '${_foilGradedDate!.month}/${_foilGradedDate!.day}/${_foilGradedDate!.year}'
                            : 'Not set',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, false, true),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, bool isRegular, bool isGradedDate) async {
    final initialDate = isGradedDate
        ? (isRegular ? _regularGradedDate : _foilGradedDate) ?? DateTime.now()
        : (isRegular ? _regularPurchaseDate : _foilPurchaseDate) ??
            DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        if (isGradedDate) {
          if (isRegular) {
            _regularGradedDate = selectedDate;
          } else {
            _foilGradedDate = selectedDate;
          }
        } else {
          if (isRegular) {
            _regularPurchaseDate = selectedDate;
          } else {
            _foilPurchaseDate = selectedDate;
          }
        }
      });
    }
  }

  void _saveCard() {
    if (_selectedCardId == null) {
      SnackBarHelper.showErrorSnackBar(
        context: context,
        message: 'Please select a card first',
      );
      return;
    }

    // Update condition map
    final updatedCondition = <String, CardCondition>{};
    if (regularQty > 0 && _regularCondition != null) {
      updatedCondition['regular'] = _regularCondition!;
    }
    if (foilQty > 0 && _foilCondition != null) {
      updatedCondition['foil'] = _foilCondition!;
    }

    // Update purchase info map
    final updatedPurchaseInfo = <String, PurchaseInfo>{};
    if (regularQty > 0 &&
        _regularPriceController.text.isNotEmpty &&
        _regularPurchaseDate != null) {
      final price = double.tryParse(_regularPriceController.text) ?? 0.0;
      updatedPurchaseInfo['regular'] = PurchaseInfo(
        price: price,
        date: Timestamp.fromDate(_regularPurchaseDate!),
      );
    }
    if (foilQty > 0 &&
        _foilPriceController.text.isNotEmpty &&
        _foilPurchaseDate != null) {
      final price = double.tryParse(_foilPriceController.text) ?? 0.0;
      updatedPurchaseInfo['foil'] = PurchaseInfo(
        price: price,
        date: Timestamp.fromDate(_foilPurchaseDate!),
      );
    }

    // Update grading info map
    final updatedGradingInfo = <String, GradingInfo>{};
    if (regularQty > 0 &&
        _regularGradingCompany != null &&
        _regularGrade != null) {
      updatedGradingInfo['regular'] = GradingInfo(
        company: _regularGradingCompany!,
        grade: _regularGrade!,
        certNumber: _regularCertNumberController.text.isNotEmpty
            ? _regularCertNumberController.text
            : null,
        gradedDate: _regularGradedDate != null
            ? Timestamp.fromDate(_regularGradedDate!)
            : null,
      );
    }
    if (foilQty > 0 && _foilGradingCompany != null && _foilGrade != null) {
      updatedGradingInfo['foil'] = GradingInfo(
        company: _foilGradingCompany!,
        grade: _foilGrade!,
        certNumber: _foilCertNumberController.text.isNotEmpty
            ? _foilCertNumberController.text
            : null,
        gradedDate: _foilGradedDate != null
            ? Timestamp.fromDate(_foilGradedDate!)
            : null,
      );
    }

    // Save card
    ref.read(userCollectionProvider.notifier).addOrUpdateCard(
          cardId: _selectedCardId!,
          regularQty: regularQty,
          foilQty: foilQty,
          condition: updatedCondition,
          purchaseInfo: updatedPurchaseInfo,
          gradingInfo: updatedGradingInfo,
        );

    // Navigate back
    context.go('/collection');
  }
}

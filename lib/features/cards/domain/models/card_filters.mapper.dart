// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'card_filters.dart';

class CardFiltersMapper extends ClassMapperBase<CardFilters> {
  CardFiltersMapper._();

  static CardFiltersMapper? _instance;
  static CardFiltersMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CardFiltersMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CardFilters';

  static Set<String> _$elements(CardFilters v) => v.elements;
  static const Field<CardFilters, Set<String>> _f$elements =
      Field('elements', _$elements, opt: true, def: const {});
  static Set<String> _$types(CardFilters v) => v.types;
  static const Field<CardFilters, Set<String>> _f$types =
      Field('types', _$types, opt: true, def: const {});
  static int? _$minCost(CardFilters v) => v.minCost;
  static const Field<CardFilters, int> _f$minCost =
      Field('minCost', _$minCost, opt: true);
  static int? _$maxCost(CardFilters v) => v.maxCost;
  static const Field<CardFilters, int> _f$maxCost =
      Field('maxCost', _$maxCost, opt: true);
  static int? _$minPower(CardFilters v) => v.minPower;
  static const Field<CardFilters, int> _f$minPower =
      Field('minPower', _$minPower, opt: true);
  static int? _$maxPower(CardFilters v) => v.maxPower;
  static const Field<CardFilters, int> _f$maxPower =
      Field('maxPower', _$maxPower, opt: true);
  static Set<String> _$set(CardFilters v) => v.set;
  static const Field<CardFilters, Set<String>> _f$set =
      Field('set', _$set, opt: true, def: const {});
  static Set<String> _$categories(CardFilters v) => v.categories;
  static const Field<CardFilters, Set<String>> _f$categories =
      Field('categories', _$categories, opt: true, def: const {});
  static Set<String> _$rarities(CardFilters v) => v.rarities;
  static const Field<CardFilters, Set<String>> _f$rarities =
      Field('rarities', _$rarities, opt: true, def: const {});
  static bool? _$isNormalOnly(CardFilters v) => v.isNormalOnly;
  static const Field<CardFilters, bool> _f$isNormalOnly =
      Field('isNormalOnly', _$isNormalOnly, opt: true);
  static bool? _$isFoilOnly(CardFilters v) => v.isFoilOnly;
  static const Field<CardFilters, bool> _f$isFoilOnly =
      Field('isFoilOnly', _$isFoilOnly, opt: true);
  static String? _$searchText(CardFilters v) => v.searchText;
  static const Field<CardFilters, String> _f$searchText =
      Field('searchText', _$searchText, opt: true);
  static String? _$sortField(CardFilters v) => v.sortField;
  static const Field<CardFilters, String> _f$sortField =
      Field('sortField', _$sortField, opt: true);
  static bool _$sortDescending(CardFilters v) => v.sortDescending;
  static const Field<CardFilters, bool> _f$sortDescending =
      Field('sortDescending', _$sortDescending, opt: true, def: false);
  static bool _$showSealedProducts(CardFilters v) => v.showSealedProducts;
  static const Field<CardFilters, bool> _f$showSealedProducts =
      Field('showSealedProducts', _$showSealedProducts, opt: true, def: true);
  static bool _$showFavoritesOnly(CardFilters v) => v.showFavoritesOnly;
  static const Field<CardFilters, bool> _f$showFavoritesOnly =
      Field('showFavoritesOnly', _$showFavoritesOnly, opt: true, def: false);
  static bool _$showWishlistOnly(CardFilters v) => v.showWishlistOnly;
  static const Field<CardFilters, bool> _f$showWishlistOnly =
      Field('showWishlistOnly', _$showWishlistOnly, opt: true, def: false);

  @override
  final MappableFields<CardFilters> fields = const {
    #elements: _f$elements,
    #types: _f$types,
    #minCost: _f$minCost,
    #maxCost: _f$maxCost,
    #minPower: _f$minPower,
    #maxPower: _f$maxPower,
    #set: _f$set,
    #categories: _f$categories,
    #rarities: _f$rarities,
    #isNormalOnly: _f$isNormalOnly,
    #isFoilOnly: _f$isFoilOnly,
    #searchText: _f$searchText,
    #sortField: _f$sortField,
    #sortDescending: _f$sortDescending,
    #showSealedProducts: _f$showSealedProducts,
    #showFavoritesOnly: _f$showFavoritesOnly,
    #showWishlistOnly: _f$showWishlistOnly,
  };

  static CardFilters _instantiate(DecodingData data) {
    return CardFilters(
        elements: data.dec(_f$elements),
        types: data.dec(_f$types),
        minCost: data.dec(_f$minCost),
        maxCost: data.dec(_f$maxCost),
        minPower: data.dec(_f$minPower),
        maxPower: data.dec(_f$maxPower),
        set: data.dec(_f$set),
        categories: data.dec(_f$categories),
        rarities: data.dec(_f$rarities),
        isNormalOnly: data.dec(_f$isNormalOnly),
        isFoilOnly: data.dec(_f$isFoilOnly),
        searchText: data.dec(_f$searchText),
        sortField: data.dec(_f$sortField),
        sortDescending: data.dec(_f$sortDescending),
        showSealedProducts: data.dec(_f$showSealedProducts),
        showFavoritesOnly: data.dec(_f$showFavoritesOnly),
        showWishlistOnly: data.dec(_f$showWishlistOnly));
  }

  @override
  final Function instantiate = _instantiate;

  static CardFilters fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CardFilters>(map);
  }

  static CardFilters fromJson(String json) {
    return ensureInitialized().decodeJson<CardFilters>(json);
  }
}

mixin CardFiltersMappable {
  String toJson() {
    return CardFiltersMapper.ensureInitialized()
        .encodeJson<CardFilters>(this as CardFilters);
  }

  Map<String, dynamic> toMap() {
    return CardFiltersMapper.ensureInitialized()
        .encodeMap<CardFilters>(this as CardFilters);
  }

  CardFiltersCopyWith<CardFilters, CardFilters, CardFilters> get copyWith =>
      _CardFiltersCopyWithImpl<CardFilters, CardFilters>(
          this as CardFilters, $identity, $identity);
  @override
  String toString() {
    return CardFiltersMapper.ensureInitialized()
        .stringifyValue(this as CardFilters);
  }

  @override
  bool operator ==(Object other) {
    return CardFiltersMapper.ensureInitialized()
        .equalsValue(this as CardFilters, other);
  }

  @override
  int get hashCode {
    return CardFiltersMapper.ensureInitialized().hashValue(this as CardFilters);
  }
}

extension CardFiltersValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CardFilters, $Out> {
  CardFiltersCopyWith<$R, CardFilters, $Out> get $asCardFilters =>
      $base.as((v, t, t2) => _CardFiltersCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CardFiltersCopyWith<$R, $In extends CardFilters, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {Set<String>? elements,
      Set<String>? types,
      int? minCost,
      int? maxCost,
      int? minPower,
      int? maxPower,
      Set<String>? set,
      Set<String>? categories,
      Set<String>? rarities,
      bool? isNormalOnly,
      bool? isFoilOnly,
      String? searchText,
      String? sortField,
      bool? sortDescending,
      bool? showSealedProducts,
      bool? showFavoritesOnly,
      bool? showWishlistOnly});
  CardFiltersCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CardFiltersCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CardFilters, $Out>
    implements CardFiltersCopyWith<$R, CardFilters, $Out> {
  _CardFiltersCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CardFilters> $mapper =
      CardFiltersMapper.ensureInitialized();
  @override
  $R call(
          {Set<String>? elements,
          Set<String>? types,
          Object? minCost = $none,
          Object? maxCost = $none,
          Object? minPower = $none,
          Object? maxPower = $none,
          Set<String>? set,
          Set<String>? categories,
          Set<String>? rarities,
          Object? isNormalOnly = $none,
          Object? isFoilOnly = $none,
          Object? searchText = $none,
          Object? sortField = $none,
          bool? sortDescending,
          bool? showSealedProducts,
          bool? showFavoritesOnly,
          bool? showWishlistOnly}) =>
      $apply(FieldCopyWithData({
        if (elements != null) #elements: elements,
        if (types != null) #types: types,
        if (minCost != $none) #minCost: minCost,
        if (maxCost != $none) #maxCost: maxCost,
        if (minPower != $none) #minPower: minPower,
        if (maxPower != $none) #maxPower: maxPower,
        if (set != null) #set: set,
        if (categories != null) #categories: categories,
        if (rarities != null) #rarities: rarities,
        if (isNormalOnly != $none) #isNormalOnly: isNormalOnly,
        if (isFoilOnly != $none) #isFoilOnly: isFoilOnly,
        if (searchText != $none) #searchText: searchText,
        if (sortField != $none) #sortField: sortField,
        if (sortDescending != null) #sortDescending: sortDescending,
        if (showSealedProducts != null) #showSealedProducts: showSealedProducts,
        if (showFavoritesOnly != null) #showFavoritesOnly: showFavoritesOnly,
        if (showWishlistOnly != null) #showWishlistOnly: showWishlistOnly
      }));
  @override
  CardFilters $make(CopyWithData data) => CardFilters(
      elements: data.get(#elements, or: $value.elements),
      types: data.get(#types, or: $value.types),
      minCost: data.get(#minCost, or: $value.minCost),
      maxCost: data.get(#maxCost, or: $value.maxCost),
      minPower: data.get(#minPower, or: $value.minPower),
      maxPower: data.get(#maxPower, or: $value.maxPower),
      set: data.get(#set, or: $value.set),
      categories: data.get(#categories, or: $value.categories),
      rarities: data.get(#rarities, or: $value.rarities),
      isNormalOnly: data.get(#isNormalOnly, or: $value.isNormalOnly),
      isFoilOnly: data.get(#isFoilOnly, or: $value.isFoilOnly),
      searchText: data.get(#searchText, or: $value.searchText),
      sortField: data.get(#sortField, or: $value.sortField),
      sortDescending: data.get(#sortDescending, or: $value.sortDescending),
      showSealedProducts:
          data.get(#showSealedProducts, or: $value.showSealedProducts),
      showFavoritesOnly:
          data.get(#showFavoritesOnly, or: $value.showFavoritesOnly),
      showWishlistOnly:
          data.get(#showWishlistOnly, or: $value.showWishlistOnly));

  @override
  CardFiltersCopyWith<$R2, CardFilters, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _CardFiltersCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

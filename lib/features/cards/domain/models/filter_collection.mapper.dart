// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'filter_collection.dart';

class FilterCollectionMapper extends ClassMapperBase<FilterCollection> {
  FilterCollectionMapper._();

  static FilterCollectionMapper? _instance;
  static FilterCollectionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FilterCollectionMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'FilterCollection';

  static List<String> _$cardType(FilterCollection v) => v.cardType;
  static const Field<FilterCollection, List<String>> _f$cardType =
      Field('cardType', _$cardType);
  static List<String> _$category(FilterCollection v) => v.category;
  static const Field<FilterCollection, List<String>> _f$category =
      Field('category', _$category);
  static List<String> _$cost(FilterCollection v) => v.cost;
  static const Field<FilterCollection, List<String>> _f$cost =
      Field('cost', _$cost);
  static List<String> _$elements(FilterCollection v) => v.elements;
  static const Field<FilterCollection, List<String>> _f$elements =
      Field('elements', _$elements);
  static List<String> _$power(FilterCollection v) => v.power;
  static const Field<FilterCollection, List<String>> _f$power =
      Field('power', _$power);
  static List<String> _$rarity(FilterCollection v) => v.rarity;
  static const Field<FilterCollection, List<String>> _f$rarity =
      Field('rarity', _$rarity);
  static List<String> _$set(FilterCollection v) => v.set;
  static const Field<FilterCollection, List<String>> _f$set =
      Field('set', _$set);

  @override
  final MappableFields<FilterCollection> fields = const {
    #cardType: _f$cardType,
    #category: _f$category,
    #cost: _f$cost,
    #elements: _f$elements,
    #power: _f$power,
    #rarity: _f$rarity,
    #set: _f$set,
  };

  static FilterCollection _instantiate(DecodingData data) {
    return FilterCollection(
        cardType: data.dec(_f$cardType),
        category: data.dec(_f$category),
        cost: data.dec(_f$cost),
        elements: data.dec(_f$elements),
        power: data.dec(_f$power),
        rarity: data.dec(_f$rarity),
        set: data.dec(_f$set));
  }

  @override
  final Function instantiate = _instantiate;

  static FilterCollection fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FilterCollection>(map);
  }

  static FilterCollection fromJson(String json) {
    return ensureInitialized().decodeJson<FilterCollection>(json);
  }
}

mixin FilterCollectionMappable {
  String toJson() {
    return FilterCollectionMapper.ensureInitialized()
        .encodeJson<FilterCollection>(this as FilterCollection);
  }

  Map<String, dynamic> toMap() {
    return FilterCollectionMapper.ensureInitialized()
        .encodeMap<FilterCollection>(this as FilterCollection);
  }

  FilterCollectionCopyWith<FilterCollection, FilterCollection, FilterCollection>
      get copyWith =>
          _FilterCollectionCopyWithImpl<FilterCollection, FilterCollection>(
              this as FilterCollection, $identity, $identity);
  @override
  String toString() {
    return FilterCollectionMapper.ensureInitialized()
        .stringifyValue(this as FilterCollection);
  }

  @override
  bool operator ==(Object other) {
    return FilterCollectionMapper.ensureInitialized()
        .equalsValue(this as FilterCollection, other);
  }

  @override
  int get hashCode {
    return FilterCollectionMapper.ensureInitialized()
        .hashValue(this as FilterCollection);
  }
}

extension FilterCollectionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FilterCollection, $Out> {
  FilterCollectionCopyWith<$R, FilterCollection, $Out>
      get $asFilterCollection => $base
          .as((v, t, t2) => _FilterCollectionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class FilterCollectionCopyWith<$R, $In extends FilterCollection, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get cardType;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get category;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get cost;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get elements;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get power;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get rarity;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get set;
  $R call(
      {List<String>? cardType,
      List<String>? category,
      List<String>? cost,
      List<String>? elements,
      List<String>? power,
      List<String>? rarity,
      List<String>? set});
  FilterCollectionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _FilterCollectionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FilterCollection, $Out>
    implements FilterCollectionCopyWith<$R, FilterCollection, $Out> {
  _FilterCollectionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FilterCollection> $mapper =
      FilterCollectionMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get cardType =>
      ListCopyWith($value.cardType, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(cardType: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get category =>
      ListCopyWith($value.category, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(category: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get cost =>
      ListCopyWith($value.cost, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(cost: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get elements =>
      ListCopyWith($value.elements, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(elements: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get power =>
      ListCopyWith($value.power, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(power: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get rarity =>
      ListCopyWith($value.rarity, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(rarity: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get set =>
      ListCopyWith($value.set, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(set: v));
  @override
  $R call(
          {List<String>? cardType,
          List<String>? category,
          List<String>? cost,
          List<String>? elements,
          List<String>? power,
          List<String>? rarity,
          List<String>? set}) =>
      $apply(FieldCopyWithData({
        if (cardType != null) #cardType: cardType,
        if (category != null) #category: category,
        if (cost != null) #cost: cost,
        if (elements != null) #elements: elements,
        if (power != null) #power: power,
        if (rarity != null) #rarity: rarity,
        if (set != null) #set: set
      }));
  @override
  FilterCollection $make(CopyWithData data) => FilterCollection(
      cardType: data.get(#cardType, or: $value.cardType),
      category: data.get(#category, or: $value.category),
      cost: data.get(#cost, or: $value.cost),
      elements: data.get(#elements, or: $value.elements),
      power: data.get(#power, or: $value.power),
      rarity: data.get(#rarity, or: $value.rarity),
      set: data.get(#set, or: $value.set));

  @override
  FilterCollectionCopyWith<$R2, FilterCollection, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _FilterCollectionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class FilterCollectionCacheMapper
    extends ClassMapperBase<FilterCollectionCache> {
  FilterCollectionCacheMapper._();

  static FilterCollectionCacheMapper? _instance;
  static FilterCollectionCacheMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FilterCollectionCacheMapper._());
      FilterCollectionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FilterCollectionCache';

  static FilterCollection _$filters(FilterCollectionCache v) => v.filters;
  static const Field<FilterCollectionCache, FilterCollection> _f$filters =
      Field('filters', _$filters);
  static DateTime _$lastUpdated(FilterCollectionCache v) => v.lastUpdated;
  static const Field<FilterCollectionCache, DateTime> _f$lastUpdated =
      Field('lastUpdated', _$lastUpdated);

  @override
  final MappableFields<FilterCollectionCache> fields = const {
    #filters: _f$filters,
    #lastUpdated: _f$lastUpdated,
  };

  static FilterCollectionCache _instantiate(DecodingData data) {
    return FilterCollectionCache(
        filters: data.dec(_f$filters), lastUpdated: data.dec(_f$lastUpdated));
  }

  @override
  final Function instantiate = _instantiate;

  static FilterCollectionCache fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FilterCollectionCache>(map);
  }

  static FilterCollectionCache fromJson(String json) {
    return ensureInitialized().decodeJson<FilterCollectionCache>(json);
  }
}

mixin FilterCollectionCacheMappable {
  String toJson() {
    return FilterCollectionCacheMapper.ensureInitialized()
        .encodeJson<FilterCollectionCache>(this as FilterCollectionCache);
  }

  Map<String, dynamic> toMap() {
    return FilterCollectionCacheMapper.ensureInitialized()
        .encodeMap<FilterCollectionCache>(this as FilterCollectionCache);
  }

  FilterCollectionCacheCopyWith<FilterCollectionCache, FilterCollectionCache,
      FilterCollectionCache> get copyWith => _FilterCollectionCacheCopyWithImpl<
          FilterCollectionCache, FilterCollectionCache>(
      this as FilterCollectionCache, $identity, $identity);
  @override
  String toString() {
    return FilterCollectionCacheMapper.ensureInitialized()
        .stringifyValue(this as FilterCollectionCache);
  }

  @override
  bool operator ==(Object other) {
    return FilterCollectionCacheMapper.ensureInitialized()
        .equalsValue(this as FilterCollectionCache, other);
  }

  @override
  int get hashCode {
    return FilterCollectionCacheMapper.ensureInitialized()
        .hashValue(this as FilterCollectionCache);
  }
}

extension FilterCollectionCacheValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FilterCollectionCache, $Out> {
  FilterCollectionCacheCopyWith<$R, FilterCollectionCache, $Out>
      get $asFilterCollectionCache => $base.as(
          (v, t, t2) => _FilterCollectionCacheCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class FilterCollectionCacheCopyWith<
    $R,
    $In extends FilterCollectionCache,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  FilterCollectionCopyWith<$R, FilterCollection, FilterCollection> get filters;
  $R call({FilterCollection? filters, DateTime? lastUpdated});
  FilterCollectionCacheCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _FilterCollectionCacheCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FilterCollectionCache, $Out>
    implements FilterCollectionCacheCopyWith<$R, FilterCollectionCache, $Out> {
  _FilterCollectionCacheCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FilterCollectionCache> $mapper =
      FilterCollectionCacheMapper.ensureInitialized();
  @override
  FilterCollectionCopyWith<$R, FilterCollection, FilterCollection>
      get filters => $value.filters.copyWith.$chain((v) => call(filters: v));
  @override
  $R call({FilterCollection? filters, DateTime? lastUpdated}) =>
      $apply(FieldCopyWithData({
        if (filters != null) #filters: filters,
        if (lastUpdated != null) #lastUpdated: lastUpdated
      }));
  @override
  FilterCollectionCache $make(CopyWithData data) => FilterCollectionCache(
      filters: data.get(#filters, or: $value.filters),
      lastUpdated: data.get(#lastUpdated, or: $value.lastUpdated));

  @override
  FilterCollectionCacheCopyWith<$R2, FilterCollectionCache, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _FilterCollectionCacheCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

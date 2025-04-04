// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'card_filter_options.dart';

class CardFilterOptionsMapper extends ClassMapperBase<CardFilterOptions> {
  CardFilterOptionsMapper._();

  static CardFilterOptionsMapper? _instance;
  static CardFilterOptionsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CardFilterOptionsMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CardFilterOptions';

  static Set<String> _$elements(CardFilterOptions v) => v.elements;
  static const Field<CardFilterOptions, Set<String>> _f$elements =
      Field('elements', _$elements);
  static Set<String> _$types(CardFilterOptions v) => v.types;
  static const Field<CardFilterOptions, Set<String>> _f$types =
      Field('types', _$types);
  static Set<String> _$set(CardFilterOptions v) => v.set;
  static const Field<CardFilterOptions, Set<String>> _f$set =
      Field('set', _$set);
  static Set<String> _$rarities(CardFilterOptions v) => v.rarities;
  static const Field<CardFilterOptions, Set<String>> _f$rarities =
      Field('rarities', _$rarities);
  static List<int> _$costRange(CardFilterOptions v) => v.costRange;
  static const Field<CardFilterOptions, List<int>> _f$costRange =
      Field('costRange', _$costRange);
  static List<int> _$powerRange(CardFilterOptions v) => v.powerRange;
  static const Field<CardFilterOptions, List<int>> _f$powerRange =
      Field('powerRange', _$powerRange);

  @override
  final MappableFields<CardFilterOptions> fields = const {
    #elements: _f$elements,
    #types: _f$types,
    #set: _f$set,
    #rarities: _f$rarities,
    #costRange: _f$costRange,
    #powerRange: _f$powerRange,
  };

  static CardFilterOptions _instantiate(DecodingData data) {
    return CardFilterOptions(
        elements: data.dec(_f$elements),
        types: data.dec(_f$types),
        set: data.dec(_f$set),
        rarities: data.dec(_f$rarities),
        costRange: data.dec(_f$costRange),
        powerRange: data.dec(_f$powerRange));
  }

  @override
  final Function instantiate = _instantiate;

  static CardFilterOptions fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CardFilterOptions>(map);
  }

  static CardFilterOptions fromJson(String json) {
    return ensureInitialized().decodeJson<CardFilterOptions>(json);
  }
}

mixin CardFilterOptionsMappable {
  String toJson() {
    return CardFilterOptionsMapper.ensureInitialized()
        .encodeJson<CardFilterOptions>(this as CardFilterOptions);
  }

  Map<String, dynamic> toMap() {
    return CardFilterOptionsMapper.ensureInitialized()
        .encodeMap<CardFilterOptions>(this as CardFilterOptions);
  }

  CardFilterOptionsCopyWith<CardFilterOptions, CardFilterOptions,
          CardFilterOptions>
      get copyWith =>
          _CardFilterOptionsCopyWithImpl<CardFilterOptions, CardFilterOptions>(
              this as CardFilterOptions, $identity, $identity);
  @override
  String toString() {
    return CardFilterOptionsMapper.ensureInitialized()
        .stringifyValue(this as CardFilterOptions);
  }

  @override
  bool operator ==(Object other) {
    return CardFilterOptionsMapper.ensureInitialized()
        .equalsValue(this as CardFilterOptions, other);
  }

  @override
  int get hashCode {
    return CardFilterOptionsMapper.ensureInitialized()
        .hashValue(this as CardFilterOptions);
  }
}

extension CardFilterOptionsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CardFilterOptions, $Out> {
  CardFilterOptionsCopyWith<$R, CardFilterOptions, $Out>
      get $asCardFilterOptions => $base
          .as((v, t, t2) => _CardFilterOptionsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CardFilterOptionsCopyWith<$R, $In extends CardFilterOptions,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get costRange;
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get powerRange;
  $R call(
      {Set<String>? elements,
      Set<String>? types,
      Set<String>? set,
      Set<String>? rarities,
      List<int>? costRange,
      List<int>? powerRange});
  CardFilterOptionsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _CardFilterOptionsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CardFilterOptions, $Out>
    implements CardFilterOptionsCopyWith<$R, CardFilterOptions, $Out> {
  _CardFilterOptionsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CardFilterOptions> $mapper =
      CardFilterOptionsMapper.ensureInitialized();
  @override
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get costRange =>
      ListCopyWith($value.costRange, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(costRange: v));
  @override
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get powerRange =>
      ListCopyWith($value.powerRange, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(powerRange: v));
  @override
  $R call(
          {Set<String>? elements,
          Set<String>? types,
          Set<String>? set,
          Set<String>? rarities,
          List<int>? costRange,
          List<int>? powerRange}) =>
      $apply(FieldCopyWithData({
        if (elements != null) #elements: elements,
        if (types != null) #types: types,
        if (set != null) #set: set,
        if (rarities != null) #rarities: rarities,
        if (costRange != null) #costRange: costRange,
        if (powerRange != null) #powerRange: powerRange
      }));
  @override
  CardFilterOptions $make(CopyWithData data) => CardFilterOptions(
      elements: data.get(#elements, or: $value.elements),
      types: data.get(#types, or: $value.types),
      set: data.get(#set, or: $value.set),
      rarities: data.get(#rarities, or: $value.rarities),
      costRange: data.get(#costRange, or: $value.costRange),
      powerRange: data.get(#powerRange, or: $value.powerRange));

  @override
  CardFilterOptionsCopyWith<$R2, CardFilterOptions, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _CardFilterOptionsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

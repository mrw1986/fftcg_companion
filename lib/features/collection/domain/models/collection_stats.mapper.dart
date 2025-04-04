// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'collection_stats.dart';

class CollectionStatsMapper extends ClassMapperBase<CollectionStats> {
  CollectionStatsMapper._();

  static CollectionStatsMapper? _instance;
  static CollectionStatsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CollectionStatsMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CollectionStats';

  static int _$totalCards(CollectionStats v) => v.totalCards;
  static const Field<CollectionStats, int> _f$totalCards =
      Field('totalCards', _$totalCards);
  static int _$uniqueCards(CollectionStats v) => v.uniqueCards;
  static const Field<CollectionStats, int> _f$uniqueCards =
      Field('uniqueCards', _$uniqueCards);
  static Map<String, int> _$elementDistribution(CollectionStats v) =>
      v.elementDistribution;
  static const Field<CollectionStats, Map<String, int>> _f$elementDistribution =
      Field('elementDistribution', _$elementDistribution);
  static Map<String, int> _$typeDistribution(CollectionStats v) =>
      v.typeDistribution;
  static const Field<CollectionStats, Map<String, int>> _f$typeDistribution =
      Field('typeDistribution', _$typeDistribution);
  static Map<String, int> _$rarityDistribution(CollectionStats v) =>
      v.rarityDistribution;
  static const Field<CollectionStats, Map<String, int>> _f$rarityDistribution =
      Field('rarityDistribution', _$rarityDistribution);
  static Map<String, int> _$setDistribution(CollectionStats v) =>
      v.setDistribution;
  static const Field<CollectionStats, Map<String, int>> _f$setDistribution =
      Field('setDistribution', _$setDistribution);
  static int _$foilCount(CollectionStats v) => v.foilCount;
  static const Field<CollectionStats, int> _f$foilCount =
      Field('foilCount', _$foilCount);
  static int _$normalCount(CollectionStats v) => v.normalCount;
  static const Field<CollectionStats, int> _f$normalCount =
      Field('normalCount', _$normalCount);
  static double _$collectionCompleteness(CollectionStats v) =>
      v.collectionCompleteness;
  static const Field<CollectionStats, double> _f$collectionCompleteness =
      Field('collectionCompleteness', _$collectionCompleteness);
  static double _$estimatedValue(CollectionStats v) => v.estimatedValue;
  static const Field<CollectionStats, double> _f$estimatedValue =
      Field('estimatedValue', _$estimatedValue);

  @override
  final MappableFields<CollectionStats> fields = const {
    #totalCards: _f$totalCards,
    #uniqueCards: _f$uniqueCards,
    #elementDistribution: _f$elementDistribution,
    #typeDistribution: _f$typeDistribution,
    #rarityDistribution: _f$rarityDistribution,
    #setDistribution: _f$setDistribution,
    #foilCount: _f$foilCount,
    #normalCount: _f$normalCount,
    #collectionCompleteness: _f$collectionCompleteness,
    #estimatedValue: _f$estimatedValue,
  };

  static CollectionStats _instantiate(DecodingData data) {
    return CollectionStats(
        totalCards: data.dec(_f$totalCards),
        uniqueCards: data.dec(_f$uniqueCards),
        elementDistribution: data.dec(_f$elementDistribution),
        typeDistribution: data.dec(_f$typeDistribution),
        rarityDistribution: data.dec(_f$rarityDistribution),
        setDistribution: data.dec(_f$setDistribution),
        foilCount: data.dec(_f$foilCount),
        normalCount: data.dec(_f$normalCount),
        collectionCompleteness: data.dec(_f$collectionCompleteness),
        estimatedValue: data.dec(_f$estimatedValue));
  }

  @override
  final Function instantiate = _instantiate;

  static CollectionStats fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CollectionStats>(map);
  }

  static CollectionStats fromJson(String json) {
    return ensureInitialized().decodeJson<CollectionStats>(json);
  }
}

mixin CollectionStatsMappable {
  String toJson() {
    return CollectionStatsMapper.ensureInitialized()
        .encodeJson<CollectionStats>(this as CollectionStats);
  }

  Map<String, dynamic> toMap() {
    return CollectionStatsMapper.ensureInitialized()
        .encodeMap<CollectionStats>(this as CollectionStats);
  }

  CollectionStatsCopyWith<CollectionStats, CollectionStats, CollectionStats>
      get copyWith =>
          _CollectionStatsCopyWithImpl<CollectionStats, CollectionStats>(
              this as CollectionStats, $identity, $identity);
  @override
  String toString() {
    return CollectionStatsMapper.ensureInitialized()
        .stringifyValue(this as CollectionStats);
  }

  @override
  bool operator ==(Object other) {
    return CollectionStatsMapper.ensureInitialized()
        .equalsValue(this as CollectionStats, other);
  }

  @override
  int get hashCode {
    return CollectionStatsMapper.ensureInitialized()
        .hashValue(this as CollectionStats);
  }
}

extension CollectionStatsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CollectionStats, $Out> {
  CollectionStatsCopyWith<$R, CollectionStats, $Out> get $asCollectionStats =>
      $base.as((v, t, t2) => _CollectionStatsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CollectionStatsCopyWith<$R, $In extends CollectionStats, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>>
      get elementDistribution;
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>>
      get typeDistribution;
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>>
      get rarityDistribution;
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>>
      get setDistribution;
  $R call(
      {int? totalCards,
      int? uniqueCards,
      Map<String, int>? elementDistribution,
      Map<String, int>? typeDistribution,
      Map<String, int>? rarityDistribution,
      Map<String, int>? setDistribution,
      int? foilCount,
      int? normalCount,
      double? collectionCompleteness,
      double? estimatedValue});
  CollectionStatsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _CollectionStatsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CollectionStats, $Out>
    implements CollectionStatsCopyWith<$R, CollectionStats, $Out> {
  _CollectionStatsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CollectionStats> $mapper =
      CollectionStatsMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>>
      get elementDistribution => MapCopyWith(
          $value.elementDistribution,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(elementDistribution: v));
  @override
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>>
      get typeDistribution => MapCopyWith(
          $value.typeDistribution,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(typeDistribution: v));
  @override
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>>
      get rarityDistribution => MapCopyWith(
          $value.rarityDistribution,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(rarityDistribution: v));
  @override
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>>
      get setDistribution => MapCopyWith(
          $value.setDistribution,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(setDistribution: v));
  @override
  $R call(
          {int? totalCards,
          int? uniqueCards,
          Map<String, int>? elementDistribution,
          Map<String, int>? typeDistribution,
          Map<String, int>? rarityDistribution,
          Map<String, int>? setDistribution,
          int? foilCount,
          int? normalCount,
          double? collectionCompleteness,
          double? estimatedValue}) =>
      $apply(FieldCopyWithData({
        if (totalCards != null) #totalCards: totalCards,
        if (uniqueCards != null) #uniqueCards: uniqueCards,
        if (elementDistribution != null)
          #elementDistribution: elementDistribution,
        if (typeDistribution != null) #typeDistribution: typeDistribution,
        if (rarityDistribution != null) #rarityDistribution: rarityDistribution,
        if (setDistribution != null) #setDistribution: setDistribution,
        if (foilCount != null) #foilCount: foilCount,
        if (normalCount != null) #normalCount: normalCount,
        if (collectionCompleteness != null)
          #collectionCompleteness: collectionCompleteness,
        if (estimatedValue != null) #estimatedValue: estimatedValue
      }));
  @override
  CollectionStats $make(CopyWithData data) => CollectionStats(
      totalCards: data.get(#totalCards, or: $value.totalCards),
      uniqueCards: data.get(#uniqueCards, or: $value.uniqueCards),
      elementDistribution:
          data.get(#elementDistribution, or: $value.elementDistribution),
      typeDistribution:
          data.get(#typeDistribution, or: $value.typeDistribution),
      rarityDistribution:
          data.get(#rarityDistribution, or: $value.rarityDistribution),
      setDistribution: data.get(#setDistribution, or: $value.setDistribution),
      foilCount: data.get(#foilCount, or: $value.foilCount),
      normalCount: data.get(#normalCount, or: $value.normalCount),
      collectionCompleteness:
          data.get(#collectionCompleteness, or: $value.collectionCompleteness),
      estimatedValue: data.get(#estimatedValue, or: $value.estimatedValue));

  @override
  CollectionStatsCopyWith<$R2, CollectionStats, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _CollectionStatsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

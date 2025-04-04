// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'price.dart';

class PriceMapper extends ClassMapperBase<Price> {
  PriceMapper._();

  static PriceMapper? _instance;
  static PriceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PriceMapper._());
      PriceDataMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Price';

  static int _$productId(Price v) => v.productId;
  static const Field<Price, int> _f$productId = Field('productId', _$productId);
  static DateTime _$lastUpdated(Price v) => v.lastUpdated;
  static const Field<Price, DateTime> _f$lastUpdated =
      Field('lastUpdated', _$lastUpdated);
  static PriceData _$normal(Price v) => v.normal;
  static const Field<Price, PriceData> _f$normal = Field('normal', _$normal);
  static PriceData _$foil(Price v) => v.foil;
  static const Field<Price, PriceData> _f$foil = Field('foil', _$foil);

  @override
  final MappableFields<Price> fields = const {
    #productId: _f$productId,
    #lastUpdated: _f$lastUpdated,
    #normal: _f$normal,
    #foil: _f$foil,
  };

  static Price _instantiate(DecodingData data) {
    return Price(
        productId: data.dec(_f$productId),
        lastUpdated: data.dec(_f$lastUpdated),
        normal: data.dec(_f$normal),
        foil: data.dec(_f$foil));
  }

  @override
  final Function instantiate = _instantiate;

  static Price fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Price>(map);
  }

  static Price fromJson(String json) {
    return ensureInitialized().decodeJson<Price>(json);
  }
}

mixin PriceMappable {
  String toJson() {
    return PriceMapper.ensureInitialized().encodeJson<Price>(this as Price);
  }

  Map<String, dynamic> toMap() {
    return PriceMapper.ensureInitialized().encodeMap<Price>(this as Price);
  }

  PriceCopyWith<Price, Price, Price> get copyWith =>
      _PriceCopyWithImpl<Price, Price>(this as Price, $identity, $identity);
  @override
  String toString() {
    return PriceMapper.ensureInitialized().stringifyValue(this as Price);
  }

  @override
  bool operator ==(Object other) {
    return PriceMapper.ensureInitialized().equalsValue(this as Price, other);
  }

  @override
  int get hashCode {
    return PriceMapper.ensureInitialized().hashValue(this as Price);
  }
}

extension PriceValueCopy<$R, $Out> on ObjectCopyWith<$R, Price, $Out> {
  PriceCopyWith<$R, Price, $Out> get $asPrice =>
      $base.as((v, t, t2) => _PriceCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PriceCopyWith<$R, $In extends Price, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  PriceDataCopyWith<$R, PriceData, PriceData> get normal;
  PriceDataCopyWith<$R, PriceData, PriceData> get foil;
  $R call(
      {int? productId,
      DateTime? lastUpdated,
      PriceData? normal,
      PriceData? foil});
  PriceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PriceCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Price, $Out>
    implements PriceCopyWith<$R, Price, $Out> {
  _PriceCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Price> $mapper = PriceMapper.ensureInitialized();
  @override
  PriceDataCopyWith<$R, PriceData, PriceData> get normal =>
      $value.normal.copyWith.$chain((v) => call(normal: v));
  @override
  PriceDataCopyWith<$R, PriceData, PriceData> get foil =>
      $value.foil.copyWith.$chain((v) => call(foil: v));
  @override
  $R call(
          {int? productId,
          DateTime? lastUpdated,
          PriceData? normal,
          PriceData? foil}) =>
      $apply(FieldCopyWithData({
        if (productId != null) #productId: productId,
        if (lastUpdated != null) #lastUpdated: lastUpdated,
        if (normal != null) #normal: normal,
        if (foil != null) #foil: foil
      }));
  @override
  Price $make(CopyWithData data) => Price(
      productId: data.get(#productId, or: $value.productId),
      lastUpdated: data.get(#lastUpdated, or: $value.lastUpdated),
      normal: data.get(#normal, or: $value.normal),
      foil: data.get(#foil, or: $value.foil));

  @override
  PriceCopyWith<$R2, Price, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _PriceCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PriceDataMapper extends ClassMapperBase<PriceData> {
  PriceDataMapper._();

  static PriceDataMapper? _instance;
  static PriceDataMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PriceDataMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'PriceData';

  static double? _$lowPrice(PriceData v) => v.lowPrice;
  static const Field<PriceData, double> _f$lowPrice =
      Field('lowPrice', _$lowPrice, opt: true);

  @override
  final MappableFields<PriceData> fields = const {
    #lowPrice: _f$lowPrice,
  };

  static PriceData _instantiate(DecodingData data) {
    return PriceData(lowPrice: data.dec(_f$lowPrice));
  }

  @override
  final Function instantiate = _instantiate;

  static PriceData fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PriceData>(map);
  }

  static PriceData fromJson(String json) {
    return ensureInitialized().decodeJson<PriceData>(json);
  }
}

mixin PriceDataMappable {
  String toJson() {
    return PriceDataMapper.ensureInitialized()
        .encodeJson<PriceData>(this as PriceData);
  }

  Map<String, dynamic> toMap() {
    return PriceDataMapper.ensureInitialized()
        .encodeMap<PriceData>(this as PriceData);
  }

  PriceDataCopyWith<PriceData, PriceData, PriceData> get copyWith =>
      _PriceDataCopyWithImpl<PriceData, PriceData>(
          this as PriceData, $identity, $identity);
  @override
  String toString() {
    return PriceDataMapper.ensureInitialized()
        .stringifyValue(this as PriceData);
  }

  @override
  bool operator ==(Object other) {
    return PriceDataMapper.ensureInitialized()
        .equalsValue(this as PriceData, other);
  }

  @override
  int get hashCode {
    return PriceDataMapper.ensureInitialized().hashValue(this as PriceData);
  }
}

extension PriceDataValueCopy<$R, $Out> on ObjectCopyWith<$R, PriceData, $Out> {
  PriceDataCopyWith<$R, PriceData, $Out> get $asPriceData =>
      $base.as((v, t, t2) => _PriceDataCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PriceDataCopyWith<$R, $In extends PriceData, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({double? lowPrice});
  PriceDataCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PriceDataCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PriceData, $Out>
    implements PriceDataCopyWith<$R, PriceData, $Out> {
  _PriceDataCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PriceData> $mapper =
      PriceDataMapper.ensureInitialized();
  @override
  $R call({Object? lowPrice = $none}) =>
      $apply(FieldCopyWithData({if (lowPrice != $none) #lowPrice: lowPrice}));
  @override
  PriceData $make(CopyWithData data) =>
      PriceData(lowPrice: data.get(#lowPrice, or: $value.lowPrice));

  @override
  PriceDataCopyWith<$R2, PriceData, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _PriceDataCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

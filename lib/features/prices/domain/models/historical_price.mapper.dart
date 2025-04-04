// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'historical_price.dart';

class HistoricalPriceMapper extends ClassMapperBase<HistoricalPrice> {
  HistoricalPriceMapper._();

  static HistoricalPriceMapper? _instance;
  static HistoricalPriceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = HistoricalPriceMapper._());
      HistoricalPriceDataMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'HistoricalPrice';

  static int _$productId(HistoricalPrice v) => v.productId;
  static const Field<HistoricalPrice, int> _f$productId =
      Field('productId', _$productId);
  static String _$groupId(HistoricalPrice v) => v.groupId;
  static const Field<HistoricalPrice, String> _f$groupId =
      Field('groupId', _$groupId);
  static DateTime _$date(HistoricalPrice v) => v.date;
  static const Field<HistoricalPrice, DateTime> _f$date = Field('date', _$date);
  static HistoricalPriceData _$normal(HistoricalPrice v) => v.normal;
  static const Field<HistoricalPrice, HistoricalPriceData> _f$normal =
      Field('normal', _$normal);
  static HistoricalPriceData _$foil(HistoricalPrice v) => v.foil;
  static const Field<HistoricalPrice, HistoricalPriceData> _f$foil =
      Field('foil', _$foil);

  @override
  final MappableFields<HistoricalPrice> fields = const {
    #productId: _f$productId,
    #groupId: _f$groupId,
    #date: _f$date,
    #normal: _f$normal,
    #foil: _f$foil,
  };

  static HistoricalPrice _instantiate(DecodingData data) {
    return HistoricalPrice(
        productId: data.dec(_f$productId),
        groupId: data.dec(_f$groupId),
        date: data.dec(_f$date),
        normal: data.dec(_f$normal),
        foil: data.dec(_f$foil));
  }

  @override
  final Function instantiate = _instantiate;

  static HistoricalPrice fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<HistoricalPrice>(map);
  }

  static HistoricalPrice fromJson(String json) {
    return ensureInitialized().decodeJson<HistoricalPrice>(json);
  }
}

mixin HistoricalPriceMappable {
  String toJson() {
    return HistoricalPriceMapper.ensureInitialized()
        .encodeJson<HistoricalPrice>(this as HistoricalPrice);
  }

  Map<String, dynamic> toMap() {
    return HistoricalPriceMapper.ensureInitialized()
        .encodeMap<HistoricalPrice>(this as HistoricalPrice);
  }

  HistoricalPriceCopyWith<HistoricalPrice, HistoricalPrice, HistoricalPrice>
      get copyWith =>
          _HistoricalPriceCopyWithImpl<HistoricalPrice, HistoricalPrice>(
              this as HistoricalPrice, $identity, $identity);
  @override
  String toString() {
    return HistoricalPriceMapper.ensureInitialized()
        .stringifyValue(this as HistoricalPrice);
  }

  @override
  bool operator ==(Object other) {
    return HistoricalPriceMapper.ensureInitialized()
        .equalsValue(this as HistoricalPrice, other);
  }

  @override
  int get hashCode {
    return HistoricalPriceMapper.ensureInitialized()
        .hashValue(this as HistoricalPrice);
  }
}

extension HistoricalPriceValueCopy<$R, $Out>
    on ObjectCopyWith<$R, HistoricalPrice, $Out> {
  HistoricalPriceCopyWith<$R, HistoricalPrice, $Out> get $asHistoricalPrice =>
      $base.as((v, t, t2) => _HistoricalPriceCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class HistoricalPriceCopyWith<$R, $In extends HistoricalPrice, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  HistoricalPriceDataCopyWith<$R, HistoricalPriceData, HistoricalPriceData>
      get normal;
  HistoricalPriceDataCopyWith<$R, HistoricalPriceData, HistoricalPriceData>
      get foil;
  $R call(
      {int? productId,
      String? groupId,
      DateTime? date,
      HistoricalPriceData? normal,
      HistoricalPriceData? foil});
  HistoricalPriceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _HistoricalPriceCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, HistoricalPrice, $Out>
    implements HistoricalPriceCopyWith<$R, HistoricalPrice, $Out> {
  _HistoricalPriceCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<HistoricalPrice> $mapper =
      HistoricalPriceMapper.ensureInitialized();
  @override
  HistoricalPriceDataCopyWith<$R, HistoricalPriceData, HistoricalPriceData>
      get normal => $value.normal.copyWith.$chain((v) => call(normal: v));
  @override
  HistoricalPriceDataCopyWith<$R, HistoricalPriceData, HistoricalPriceData>
      get foil => $value.foil.copyWith.$chain((v) => call(foil: v));
  @override
  $R call(
          {int? productId,
          String? groupId,
          DateTime? date,
          HistoricalPriceData? normal,
          HistoricalPriceData? foil}) =>
      $apply(FieldCopyWithData({
        if (productId != null) #productId: productId,
        if (groupId != null) #groupId: groupId,
        if (date != null) #date: date,
        if (normal != null) #normal: normal,
        if (foil != null) #foil: foil
      }));
  @override
  HistoricalPrice $make(CopyWithData data) => HistoricalPrice(
      productId: data.get(#productId, or: $value.productId),
      groupId: data.get(#groupId, or: $value.groupId),
      date: data.get(#date, or: $value.date),
      normal: data.get(#normal, or: $value.normal),
      foil: data.get(#foil, or: $value.foil));

  @override
  HistoricalPriceCopyWith<$R2, HistoricalPrice, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _HistoricalPriceCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class HistoricalPriceDataMapper extends ClassMapperBase<HistoricalPriceData> {
  HistoricalPriceDataMapper._();

  static HistoricalPriceDataMapper? _instance;
  static HistoricalPriceDataMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = HistoricalPriceDataMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'HistoricalPriceData';

  static double? _$low(HistoricalPriceData v) => v.low;
  static const Field<HistoricalPriceData, double> _f$low =
      Field('low', _$low, opt: true);

  @override
  final MappableFields<HistoricalPriceData> fields = const {
    #low: _f$low,
  };

  static HistoricalPriceData _instantiate(DecodingData data) {
    return HistoricalPriceData(low: data.dec(_f$low));
  }

  @override
  final Function instantiate = _instantiate;

  static HistoricalPriceData fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<HistoricalPriceData>(map);
  }

  static HistoricalPriceData fromJson(String json) {
    return ensureInitialized().decodeJson<HistoricalPriceData>(json);
  }
}

mixin HistoricalPriceDataMappable {
  String toJson() {
    return HistoricalPriceDataMapper.ensureInitialized()
        .encodeJson<HistoricalPriceData>(this as HistoricalPriceData);
  }

  Map<String, dynamic> toMap() {
    return HistoricalPriceDataMapper.ensureInitialized()
        .encodeMap<HistoricalPriceData>(this as HistoricalPriceData);
  }

  HistoricalPriceDataCopyWith<HistoricalPriceData, HistoricalPriceData,
      HistoricalPriceData> get copyWith => _HistoricalPriceDataCopyWithImpl<
          HistoricalPriceData, HistoricalPriceData>(
      this as HistoricalPriceData, $identity, $identity);
  @override
  String toString() {
    return HistoricalPriceDataMapper.ensureInitialized()
        .stringifyValue(this as HistoricalPriceData);
  }

  @override
  bool operator ==(Object other) {
    return HistoricalPriceDataMapper.ensureInitialized()
        .equalsValue(this as HistoricalPriceData, other);
  }

  @override
  int get hashCode {
    return HistoricalPriceDataMapper.ensureInitialized()
        .hashValue(this as HistoricalPriceData);
  }
}

extension HistoricalPriceDataValueCopy<$R, $Out>
    on ObjectCopyWith<$R, HistoricalPriceData, $Out> {
  HistoricalPriceDataCopyWith<$R, HistoricalPriceData, $Out>
      get $asHistoricalPriceData => $base.as(
          (v, t, t2) => _HistoricalPriceDataCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class HistoricalPriceDataCopyWith<$R, $In extends HistoricalPriceData,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call({double? low});
  HistoricalPriceDataCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _HistoricalPriceDataCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, HistoricalPriceData, $Out>
    implements HistoricalPriceDataCopyWith<$R, HistoricalPriceData, $Out> {
  _HistoricalPriceDataCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<HistoricalPriceData> $mapper =
      HistoricalPriceDataMapper.ensureInitialized();
  @override
  $R call({Object? low = $none}) =>
      $apply(FieldCopyWithData({if (low != $none) #low: low}));
  @override
  HistoricalPriceData $make(CopyWithData data) =>
      HistoricalPriceData(low: data.get(#low, or: $value.low));

  @override
  HistoricalPriceDataCopyWith<$R2, HistoricalPriceData, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _HistoricalPriceDataCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

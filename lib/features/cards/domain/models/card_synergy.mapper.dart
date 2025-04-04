// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'card_synergy.dart';

class SynergyTypeMapper extends EnumMapper<SynergyType> {
  SynergyTypeMapper._();

  static SynergyTypeMapper? _instance;
  static SynergyTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SynergyTypeMapper._());
    }
    return _instance!;
  }

  static SynergyType fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  SynergyType decode(dynamic value) {
    switch (value) {
      case r'element':
        return SynergyType.element;
      case r'ability':
        return SynergyType.ability;
      case r'job':
        return SynergyType.job;
      case r'name':
        return SynergyType.name;
      case r'category':
        return SynergyType.category;
      case r'combo':
        return SynergyType.combo;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(SynergyType self) {
    switch (self) {
      case SynergyType.element:
        return r'element';
      case SynergyType.ability:
        return r'ability';
      case SynergyType.job:
        return r'job';
      case SynergyType.name:
        return r'name';
      case SynergyType.category:
        return r'category';
      case SynergyType.combo:
        return r'combo';
    }
  }
}

extension SynergyTypeMapperExtension on SynergyType {
  String toValue() {
    SynergyTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<SynergyType>(this) as String;
  }
}

class CardSynergyMapper extends ClassMapperBase<CardSynergy> {
  CardSynergyMapper._();

  static CardSynergyMapper? _instance;
  static CardSynergyMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CardSynergyMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CardSynergy';

  static String _$sourceCardId(CardSynergy v) => v.sourceCardId;
  static const Field<CardSynergy, String> _f$sourceCardId =
      Field('sourceCardId', _$sourceCardId);
  static String _$targetCardId(CardSynergy v) => v.targetCardId;
  static const Field<CardSynergy, String> _f$targetCardId =
      Field('targetCardId', _$targetCardId);
  static String _$synergyType(CardSynergy v) => v.synergyType;
  static const Field<CardSynergy, String> _f$synergyType =
      Field('synergyType', _$synergyType);
  static double _$synergyStrength(CardSynergy v) => v.synergyStrength;
  static const Field<CardSynergy, double> _f$synergyStrength =
      Field('synergyStrength', _$synergyStrength);
  static String? _$description(CardSynergy v) => v.description;
  static const Field<CardSynergy, String> _f$description =
      Field('description', _$description, opt: true);

  @override
  final MappableFields<CardSynergy> fields = const {
    #sourceCardId: _f$sourceCardId,
    #targetCardId: _f$targetCardId,
    #synergyType: _f$synergyType,
    #synergyStrength: _f$synergyStrength,
    #description: _f$description,
  };

  static CardSynergy _instantiate(DecodingData data) {
    return CardSynergy(
        sourceCardId: data.dec(_f$sourceCardId),
        targetCardId: data.dec(_f$targetCardId),
        synergyType: data.dec(_f$synergyType),
        synergyStrength: data.dec(_f$synergyStrength),
        description: data.dec(_f$description));
  }

  @override
  final Function instantiate = _instantiate;

  static CardSynergy fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CardSynergy>(map);
  }

  static CardSynergy fromJson(String json) {
    return ensureInitialized().decodeJson<CardSynergy>(json);
  }
}

mixin CardSynergyMappable {
  String toJson() {
    return CardSynergyMapper.ensureInitialized()
        .encodeJson<CardSynergy>(this as CardSynergy);
  }

  Map<String, dynamic> toMap() {
    return CardSynergyMapper.ensureInitialized()
        .encodeMap<CardSynergy>(this as CardSynergy);
  }

  CardSynergyCopyWith<CardSynergy, CardSynergy, CardSynergy> get copyWith =>
      _CardSynergyCopyWithImpl<CardSynergy, CardSynergy>(
          this as CardSynergy, $identity, $identity);
  @override
  String toString() {
    return CardSynergyMapper.ensureInitialized()
        .stringifyValue(this as CardSynergy);
  }

  @override
  bool operator ==(Object other) {
    return CardSynergyMapper.ensureInitialized()
        .equalsValue(this as CardSynergy, other);
  }

  @override
  int get hashCode {
    return CardSynergyMapper.ensureInitialized().hashValue(this as CardSynergy);
  }
}

extension CardSynergyValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CardSynergy, $Out> {
  CardSynergyCopyWith<$R, CardSynergy, $Out> get $asCardSynergy =>
      $base.as((v, t, t2) => _CardSynergyCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CardSynergyCopyWith<$R, $In extends CardSynergy, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {String? sourceCardId,
      String? targetCardId,
      String? synergyType,
      double? synergyStrength,
      String? description});
  CardSynergyCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CardSynergyCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CardSynergy, $Out>
    implements CardSynergyCopyWith<$R, CardSynergy, $Out> {
  _CardSynergyCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CardSynergy> $mapper =
      CardSynergyMapper.ensureInitialized();
  @override
  $R call(
          {String? sourceCardId,
          String? targetCardId,
          String? synergyType,
          double? synergyStrength,
          Object? description = $none}) =>
      $apply(FieldCopyWithData({
        if (sourceCardId != null) #sourceCardId: sourceCardId,
        if (targetCardId != null) #targetCardId: targetCardId,
        if (synergyType != null) #synergyType: synergyType,
        if (synergyStrength != null) #synergyStrength: synergyStrength,
        if (description != $none) #description: description
      }));
  @override
  CardSynergy $make(CopyWithData data) => CardSynergy(
      sourceCardId: data.get(#sourceCardId, or: $value.sourceCardId),
      targetCardId: data.get(#targetCardId, or: $value.targetCardId),
      synergyType: data.get(#synergyType, or: $value.synergyType),
      synergyStrength: data.get(#synergyStrength, or: $value.synergyStrength),
      description: data.get(#description, or: $value.description));

  @override
  CardSynergyCopyWith<$R2, CardSynergy, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _CardSynergyCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

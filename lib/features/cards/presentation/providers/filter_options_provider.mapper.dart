// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'filter_options_provider.dart';

class SetCategoryMapper extends EnumMapper<SetCategory> {
  SetCategoryMapper._();

  static SetCategoryMapper? _instance;
  static SetCategoryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SetCategoryMapper._());
    }
    return _instance!;
  }

  static SetCategory fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  SetCategory decode(dynamic value) {
    switch (value) {
      case r'promotional':
        return SetCategory.promotional;
      case r'collection':
        return SetCategory.collection;
      case r'opus':
        return SetCategory.opus;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(SetCategory self) {
    switch (self) {
      case SetCategory.promotional:
        return r'promotional';
      case SetCategory.collection:
        return r'collection';
      case SetCategory.opus:
        return r'opus';
    }
  }
}

extension SetCategoryMapperExtension on SetCategory {
  String toValue() {
    SetCategoryMapper.ensureInitialized();
    return MapperContainer.globals.toValue<SetCategory>(this) as String;
  }
}

class SetInfoMapper extends ClassMapperBase<SetInfo> {
  SetInfoMapper._();

  static SetInfoMapper? _instance;
  static SetInfoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SetInfoMapper._());
      SetCategoryMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SetInfo';

  static String _$id(SetInfo v) => v.id;
  static const Field<SetInfo, String> _f$id = Field('id', _$id);
  static String _$name(SetInfo v) => v.name;
  static const Field<SetInfo, String> _f$name = Field('name', _$name);
  static String? _$abbreviation(SetInfo v) => v.abbreviation;
  static const Field<SetInfo, String> _f$abbreviation =
      Field('abbreviation', _$abbreviation, opt: true);
  static SetCategory _$category(SetInfo v) => v.category;
  static const Field<SetInfo, SetCategory> _f$category =
      Field('category', _$category);
  static DateTime _$publishedDate(SetInfo v) => v.publishedDate;
  static const Field<SetInfo, DateTime> _f$publishedDate =
      Field('publishedDate', _$publishedDate);
  static int _$sortOrder(SetInfo v) => v.sortOrder;
  static const Field<SetInfo, int> _f$sortOrder =
      Field('sortOrder', _$sortOrder);

  @override
  final MappableFields<SetInfo> fields = const {
    #id: _f$id,
    #name: _f$name,
    #abbreviation: _f$abbreviation,
    #category: _f$category,
    #publishedDate: _f$publishedDate,
    #sortOrder: _f$sortOrder,
  };

  static SetInfo _instantiate(DecodingData data) {
    return SetInfo(
        id: data.dec(_f$id),
        name: data.dec(_f$name),
        abbreviation: data.dec(_f$abbreviation),
        category: data.dec(_f$category),
        publishedDate: data.dec(_f$publishedDate),
        sortOrder: data.dec(_f$sortOrder));
  }

  @override
  final Function instantiate = _instantiate;

  static SetInfo fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SetInfo>(map);
  }

  static SetInfo fromJson(String json) {
    return ensureInitialized().decodeJson<SetInfo>(json);
  }
}

mixin SetInfoMappable {
  String toJson() {
    return SetInfoMapper.ensureInitialized()
        .encodeJson<SetInfo>(this as SetInfo);
  }

  Map<String, dynamic> toMap() {
    return SetInfoMapper.ensureInitialized()
        .encodeMap<SetInfo>(this as SetInfo);
  }

  SetInfoCopyWith<SetInfo, SetInfo, SetInfo> get copyWith =>
      _SetInfoCopyWithImpl<SetInfo, SetInfo>(
          this as SetInfo, $identity, $identity);
  @override
  String toString() {
    return SetInfoMapper.ensureInitialized().stringifyValue(this as SetInfo);
  }

  @override
  bool operator ==(Object other) {
    return SetInfoMapper.ensureInitialized()
        .equalsValue(this as SetInfo, other);
  }

  @override
  int get hashCode {
    return SetInfoMapper.ensureInitialized().hashValue(this as SetInfo);
  }
}

extension SetInfoValueCopy<$R, $Out> on ObjectCopyWith<$R, SetInfo, $Out> {
  SetInfoCopyWith<$R, SetInfo, $Out> get $asSetInfo =>
      $base.as((v, t, t2) => _SetInfoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SetInfoCopyWith<$R, $In extends SetInfo, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {String? id,
      String? name,
      String? abbreviation,
      SetCategory? category,
      DateTime? publishedDate,
      int? sortOrder});
  SetInfoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SetInfoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SetInfo, $Out>
    implements SetInfoCopyWith<$R, SetInfo, $Out> {
  _SetInfoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SetInfo> $mapper =
      SetInfoMapper.ensureInitialized();
  @override
  $R call(
          {String? id,
          String? name,
          Object? abbreviation = $none,
          SetCategory? category,
          DateTime? publishedDate,
          int? sortOrder}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (name != null) #name: name,
        if (abbreviation != $none) #abbreviation: abbreviation,
        if (category != null) #category: category,
        if (publishedDate != null) #publishedDate: publishedDate,
        if (sortOrder != null) #sortOrder: sortOrder
      }));
  @override
  SetInfo $make(CopyWithData data) => SetInfo(
      id: data.get(#id, or: $value.id),
      name: data.get(#name, or: $value.name),
      abbreviation: data.get(#abbreviation, or: $value.abbreviation),
      category: data.get(#category, or: $value.category),
      publishedDate: data.get(#publishedDate, or: $value.publishedDate),
      sortOrder: data.get(#sortOrder, or: $value.sortOrder));

  @override
  SetInfoCopyWith<$R2, SetInfo, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _SetInfoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

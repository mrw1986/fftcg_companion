// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'deck.dart';

class DeckMapper extends ClassMapperBase<Deck> {
  DeckMapper._();

  static DeckMapper? _instance;
  static DeckMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeckMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Deck';

  static String _$id(Deck v) => v.id;
  static const Field<Deck, String> _f$id = Field('id', _$id);
  static String _$name(Deck v) => v.name;
  static const Field<Deck, String> _f$name = Field('name', _$name);
  static String _$userId(Deck v) => v.userId;
  static const Field<Deck, String> _f$userId = Field('userId', _$userId);
  static Map<String, int> _$cards(Deck v) => v.cards;
  static const Field<Deck, Map<String, int>> _f$cards = Field('cards', _$cards);
  static String? _$description(Deck v) => v.description;
  static const Field<Deck, String> _f$description =
      Field('description', _$description, opt: true);
  static DateTime? _$lastModified(Deck v) => v.lastModified;
  static const Field<Deck, DateTime> _f$lastModified =
      Field('lastModified', _$lastModified, opt: true);
  static bool _$isPublic(Deck v) => v.isPublic;
  static const Field<Deck, bool> _f$isPublic =
      Field('isPublic', _$isPublic, opt: true, def: false);
  static List<String> _$tags(Deck v) => v.tags;
  static const Field<Deck, List<String>> _f$tags =
      Field('tags', _$tags, opt: true, def: const []);

  @override
  final MappableFields<Deck> fields = const {
    #id: _f$id,
    #name: _f$name,
    #userId: _f$userId,
    #cards: _f$cards,
    #description: _f$description,
    #lastModified: _f$lastModified,
    #isPublic: _f$isPublic,
    #tags: _f$tags,
  };

  static Deck _instantiate(DecodingData data) {
    return Deck(
        id: data.dec(_f$id),
        name: data.dec(_f$name),
        userId: data.dec(_f$userId),
        cards: data.dec(_f$cards),
        description: data.dec(_f$description),
        lastModified: data.dec(_f$lastModified),
        isPublic: data.dec(_f$isPublic),
        tags: data.dec(_f$tags));
  }

  @override
  final Function instantiate = _instantiate;

  static Deck fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Deck>(map);
  }

  static Deck fromJson(String json) {
    return ensureInitialized().decodeJson<Deck>(json);
  }
}

mixin DeckMappable {
  String toJson() {
    return DeckMapper.ensureInitialized().encodeJson<Deck>(this as Deck);
  }

  Map<String, dynamic> toMap() {
    return DeckMapper.ensureInitialized().encodeMap<Deck>(this as Deck);
  }

  DeckCopyWith<Deck, Deck, Deck> get copyWith =>
      _DeckCopyWithImpl<Deck, Deck>(this as Deck, $identity, $identity);
  @override
  String toString() {
    return DeckMapper.ensureInitialized().stringifyValue(this as Deck);
  }

  @override
  bool operator ==(Object other) {
    return DeckMapper.ensureInitialized().equalsValue(this as Deck, other);
  }

  @override
  int get hashCode {
    return DeckMapper.ensureInitialized().hashValue(this as Deck);
  }
}

extension DeckValueCopy<$R, $Out> on ObjectCopyWith<$R, Deck, $Out> {
  DeckCopyWith<$R, Deck, $Out> get $asDeck =>
      $base.as((v, t, t2) => _DeckCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DeckCopyWith<$R, $In extends Deck, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>> get cards;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get tags;
  $R call(
      {String? id,
      String? name,
      String? userId,
      Map<String, int>? cards,
      String? description,
      DateTime? lastModified,
      bool? isPublic,
      List<String>? tags});
  DeckCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _DeckCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Deck, $Out>
    implements DeckCopyWith<$R, Deck, $Out> {
  _DeckCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Deck> $mapper = DeckMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>> get cards =>
      MapCopyWith($value.cards, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(cards: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get tags =>
      ListCopyWith($value.tags, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(tags: v));
  @override
  $R call(
          {String? id,
          String? name,
          String? userId,
          Map<String, int>? cards,
          Object? description = $none,
          Object? lastModified = $none,
          bool? isPublic,
          List<String>? tags}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (name != null) #name: name,
        if (userId != null) #userId: userId,
        if (cards != null) #cards: cards,
        if (description != $none) #description: description,
        if (lastModified != $none) #lastModified: lastModified,
        if (isPublic != null) #isPublic: isPublic,
        if (tags != null) #tags: tags
      }));
  @override
  Deck $make(CopyWithData data) => Deck(
      id: data.get(#id, or: $value.id),
      name: data.get(#name, or: $value.name),
      userId: data.get(#userId, or: $value.userId),
      cards: data.get(#cards, or: $value.cards),
      description: data.get(#description, or: $value.description),
      lastModified: data.get(#lastModified, or: $value.lastModified),
      isPublic: data.get(#isPublic, or: $value.isPublic),
      tags: data.get(#tags, or: $value.tags));

  @override
  DeckCopyWith<$R2, Deck, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _DeckCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class DeckValidationMapper extends ClassMapperBase<DeckValidation> {
  DeckValidationMapper._();

  static DeckValidationMapper? _instance;
  static DeckValidationMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeckValidationMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'DeckValidation';

  static bool _$isValid(DeckValidation v) => v.isValid;
  static const Field<DeckValidation, bool> _f$isValid =
      Field('isValid', _$isValid);
  static List<String> _$errors(DeckValidation v) => v.errors;
  static const Field<DeckValidation, List<String>> _f$errors =
      Field('errors', _$errors, opt: true, def: const []);
  static List<String> _$warnings(DeckValidation v) => v.warnings;
  static const Field<DeckValidation, List<String>> _f$warnings =
      Field('warnings', _$warnings, opt: true, def: const []);
  static Map<String, int> _$elementCount(DeckValidation v) => v.elementCount;
  static const Field<DeckValidation, Map<String, int>> _f$elementCount =
      Field('elementCount', _$elementCount);
  static Map<String, int> _$costDistribution(DeckValidation v) =>
      v.costDistribution;
  static const Field<DeckValidation, Map<String, int>> _f$costDistribution =
      Field('costDistribution', _$costDistribution);
  static double _$averageCost(DeckValidation v) => v.averageCost;
  static const Field<DeckValidation, double> _f$averageCost =
      Field('averageCost', _$averageCost);

  @override
  final MappableFields<DeckValidation> fields = const {
    #isValid: _f$isValid,
    #errors: _f$errors,
    #warnings: _f$warnings,
    #elementCount: _f$elementCount,
    #costDistribution: _f$costDistribution,
    #averageCost: _f$averageCost,
  };

  static DeckValidation _instantiate(DecodingData data) {
    return DeckValidation(
        isValid: data.dec(_f$isValid),
        errors: data.dec(_f$errors),
        warnings: data.dec(_f$warnings),
        elementCount: data.dec(_f$elementCount),
        costDistribution: data.dec(_f$costDistribution),
        averageCost: data.dec(_f$averageCost));
  }

  @override
  final Function instantiate = _instantiate;

  static DeckValidation fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DeckValidation>(map);
  }

  static DeckValidation fromJson(String json) {
    return ensureInitialized().decodeJson<DeckValidation>(json);
  }
}

mixin DeckValidationMappable {
  String toJson() {
    return DeckValidationMapper.ensureInitialized()
        .encodeJson<DeckValidation>(this as DeckValidation);
  }

  Map<String, dynamic> toMap() {
    return DeckValidationMapper.ensureInitialized()
        .encodeMap<DeckValidation>(this as DeckValidation);
  }

  DeckValidationCopyWith<DeckValidation, DeckValidation, DeckValidation>
      get copyWith =>
          _DeckValidationCopyWithImpl<DeckValidation, DeckValidation>(
              this as DeckValidation, $identity, $identity);
  @override
  String toString() {
    return DeckValidationMapper.ensureInitialized()
        .stringifyValue(this as DeckValidation);
  }

  @override
  bool operator ==(Object other) {
    return DeckValidationMapper.ensureInitialized()
        .equalsValue(this as DeckValidation, other);
  }

  @override
  int get hashCode {
    return DeckValidationMapper.ensureInitialized()
        .hashValue(this as DeckValidation);
  }
}

extension DeckValidationValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DeckValidation, $Out> {
  DeckValidationCopyWith<$R, DeckValidation, $Out> get $asDeckValidation =>
      $base.as((v, t, t2) => _DeckValidationCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DeckValidationCopyWith<$R, $In extends DeckValidation, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get errors;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get warnings;
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>> get elementCount;
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>>
      get costDistribution;
  $R call(
      {bool? isValid,
      List<String>? errors,
      List<String>? warnings,
      Map<String, int>? elementCount,
      Map<String, int>? costDistribution,
      double? averageCost});
  DeckValidationCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _DeckValidationCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DeckValidation, $Out>
    implements DeckValidationCopyWith<$R, DeckValidation, $Out> {
  _DeckValidationCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DeckValidation> $mapper =
      DeckValidationMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get errors =>
      ListCopyWith($value.errors, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(errors: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get warnings =>
      ListCopyWith($value.warnings, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(warnings: v));
  @override
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>> get elementCount =>
      MapCopyWith(
          $value.elementCount,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(elementCount: v));
  @override
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>>
      get costDistribution => MapCopyWith(
          $value.costDistribution,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(costDistribution: v));
  @override
  $R call(
          {bool? isValid,
          List<String>? errors,
          List<String>? warnings,
          Map<String, int>? elementCount,
          Map<String, int>? costDistribution,
          double? averageCost}) =>
      $apply(FieldCopyWithData({
        if (isValid != null) #isValid: isValid,
        if (errors != null) #errors: errors,
        if (warnings != null) #warnings: warnings,
        if (elementCount != null) #elementCount: elementCount,
        if (costDistribution != null) #costDistribution: costDistribution,
        if (averageCost != null) #averageCost: averageCost
      }));
  @override
  DeckValidation $make(CopyWithData data) => DeckValidation(
      isValid: data.get(#isValid, or: $value.isValid),
      errors: data.get(#errors, or: $value.errors),
      warnings: data.get(#warnings, or: $value.warnings),
      elementCount: data.get(#elementCount, or: $value.elementCount),
      costDistribution:
          data.get(#costDistribution, or: $value.costDistribution),
      averageCost: data.get(#averageCost, or: $value.averageCost));

  @override
  DeckValidationCopyWith<$R2, DeckValidation, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _DeckValidationCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

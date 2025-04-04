// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'card.dart';

class ImageQualityMapper extends EnumMapper<ImageQuality> {
  ImageQualityMapper._();

  static ImageQualityMapper? _instance;
  static ImageQualityMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ImageQualityMapper._());
    }
    return _instance!;
  }

  static ImageQuality fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ImageQuality decode(dynamic value) {
    switch (value) {
      case r'low':
        return ImageQuality.low;
      case r'medium':
        return ImageQuality.medium;
      case r'high':
        return ImageQuality.high;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ImageQuality self) {
    switch (self) {
      case ImageQuality.low:
        return r'low';
      case ImageQuality.medium:
        return r'medium';
      case ImageQuality.high:
        return r'high';
    }
  }
}

extension ImageQualityMapperExtension on ImageQuality {
  String toValue() {
    ImageQualityMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ImageQuality>(this) as String;
  }
}

class CardMapper extends ClassMapperBase<Card> {
  CardMapper._();

  static CardMapper? _instance;
  static CardMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CardMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Card';

  static int _$productId(Card v) => v.productId;
  static const Field<Card, int> _f$productId = Field('productId', _$productId);
  static String _$name(Card v) => v.name;
  static const Field<Card, String> _f$name = Field('name', _$name);
  static String _$cleanName(Card v) => v.cleanName;
  static const Field<Card, String> _f$cleanName =
      Field('cleanName', _$cleanName);
  static String _$fullResUrl(Card v) => v.fullResUrl;
  static const Field<Card, String> _f$fullResUrl =
      Field('fullResUrl', _$fullResUrl);
  static String _$highResUrl(Card v) => v.highResUrl;
  static const Field<Card, String> _f$highResUrl =
      Field('highResUrl', _$highResUrl);
  static String _$lowResUrl(Card v) => v.lowResUrl;
  static const Field<Card, String> _f$lowResUrl =
      Field('lowResUrl', _$lowResUrl);
  static DateTime? _$lastUpdated(Card v) => v.lastUpdated;
  static const Field<Card, DateTime> _f$lastUpdated =
      Field('lastUpdated', _$lastUpdated, opt: true);
  static int _$groupId(Card v) => v.groupId;
  static const Field<Card, int> _f$groupId = Field('groupId', _$groupId);
  static bool _$isNonCard(Card v) => v.isNonCard;
  static const Field<Card, bool> _f$isNonCard =
      Field('isNonCard', _$isNonCard, opt: true, def: false);
  static String? _$cardType(Card v) => v.cardType;
  static const Field<Card, String> _f$cardType =
      Field('cardType', _$cardType, opt: true);
  static String? _$category(Card v) => v.category;
  static const Field<Card, String> _f$category =
      Field('category', _$category, opt: true);
  static List<String> _$categories(Card v) => v.categories;
  static const Field<Card, List<String>> _f$categories =
      Field('categories', _$categories, opt: true, def: const []);
  static int? _$cost(Card v) => v.cost;
  static const Field<Card, int> _f$cost = Field('cost', _$cost, opt: true);
  static String? _$description(Card v) => v.description;
  static const Field<Card, String> _f$description =
      Field('description', _$description, opt: true);
  static List<String> _$elements(Card v) => v.elements;
  static const Field<Card, List<String>> _f$elements =
      Field('elements', _$elements, opt: true, def: const []);
  static String? _$job(Card v) => v.job;
  static const Field<Card, String> _f$job = Field('job', _$job, opt: true);
  static String? _$number(Card v) => v.number;
  static const Field<Card, String> _f$number =
      Field('number', _$number, opt: true);
  static int? _$power(Card v) => v.power;
  static const Field<Card, int> _f$power = Field('power', _$power, opt: true);
  static String? _$rarity(Card v) => v.rarity;
  static const Field<Card, String> _f$rarity =
      Field('rarity', _$rarity, opt: true);
  static List<String> _$cardNumbers(Card v) => v.cardNumbers;
  static const Field<Card, List<String>> _f$cardNumbers =
      Field('cardNumbers', _$cardNumbers, opt: true, def: const []);
  static List<String> _$searchTerms(Card v) => v.searchTerms;
  static const Field<Card, List<String>> _f$searchTerms =
      Field('searchTerms', _$searchTerms, opt: true, def: const []);
  static List<String> _$set(Card v) => v.set;
  static const Field<Card, List<String>> _f$set =
      Field('set', _$set, opt: true, def: const []);
  static String? _$fullCardNumber(Card v) => v.fullCardNumber;
  static const Field<Card, String> _f$fullCardNumber =
      Field('fullCardNumber', _$fullCardNumber, opt: true);

  @override
  final MappableFields<Card> fields = const {
    #productId: _f$productId,
    #name: _f$name,
    #cleanName: _f$cleanName,
    #fullResUrl: _f$fullResUrl,
    #highResUrl: _f$highResUrl,
    #lowResUrl: _f$lowResUrl,
    #lastUpdated: _f$lastUpdated,
    #groupId: _f$groupId,
    #isNonCard: _f$isNonCard,
    #cardType: _f$cardType,
    #category: _f$category,
    #categories: _f$categories,
    #cost: _f$cost,
    #description: _f$description,
    #elements: _f$elements,
    #job: _f$job,
    #number: _f$number,
    #power: _f$power,
    #rarity: _f$rarity,
    #cardNumbers: _f$cardNumbers,
    #searchTerms: _f$searchTerms,
    #set: _f$set,
    #fullCardNumber: _f$fullCardNumber,
  };

  static Card _instantiate(DecodingData data) {
    return Card(
        productId: data.dec(_f$productId),
        name: data.dec(_f$name),
        cleanName: data.dec(_f$cleanName),
        fullResUrl: data.dec(_f$fullResUrl),
        highResUrl: data.dec(_f$highResUrl),
        lowResUrl: data.dec(_f$lowResUrl),
        lastUpdated: data.dec(_f$lastUpdated),
        groupId: data.dec(_f$groupId),
        isNonCard: data.dec(_f$isNonCard),
        cardType: data.dec(_f$cardType),
        category: data.dec(_f$category),
        categories: data.dec(_f$categories),
        cost: data.dec(_f$cost),
        description: data.dec(_f$description),
        elements: data.dec(_f$elements),
        job: data.dec(_f$job),
        number: data.dec(_f$number),
        power: data.dec(_f$power),
        rarity: data.dec(_f$rarity),
        cardNumbers: data.dec(_f$cardNumbers),
        searchTerms: data.dec(_f$searchTerms),
        set: data.dec(_f$set),
        fullCardNumber: data.dec(_f$fullCardNumber));
  }

  @override
  final Function instantiate = _instantiate;

  static Card fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Card>(map);
  }

  static Card fromJson(String json) {
    return ensureInitialized().decodeJson<Card>(json);
  }
}

mixin CardMappable {
  String toJson() {
    return CardMapper.ensureInitialized().encodeJson<Card>(this as Card);
  }

  Map<String, dynamic> toMap() {
    return CardMapper.ensureInitialized().encodeMap<Card>(this as Card);
  }

  CardCopyWith<Card, Card, Card> get copyWith =>
      _CardCopyWithImpl<Card, Card>(this as Card, $identity, $identity);
  @override
  String toString() {
    return CardMapper.ensureInitialized().stringifyValue(this as Card);
  }

  @override
  bool operator ==(Object other) {
    return CardMapper.ensureInitialized().equalsValue(this as Card, other);
  }

  @override
  int get hashCode {
    return CardMapper.ensureInitialized().hashValue(this as Card);
  }
}

extension CardValueCopy<$R, $Out> on ObjectCopyWith<$R, Card, $Out> {
  CardCopyWith<$R, Card, $Out> get $asCard =>
      $base.as((v, t, t2) => _CardCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CardCopyWith<$R, $In extends Card, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get categories;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get elements;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get cardNumbers;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get searchTerms;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get set;
  $R call(
      {int? productId,
      String? name,
      String? cleanName,
      String? fullResUrl,
      String? highResUrl,
      String? lowResUrl,
      DateTime? lastUpdated,
      int? groupId,
      bool? isNonCard,
      String? cardType,
      String? category,
      List<String>? categories,
      int? cost,
      String? description,
      List<String>? elements,
      String? job,
      String? number,
      int? power,
      String? rarity,
      List<String>? cardNumbers,
      List<String>? searchTerms,
      List<String>? set,
      String? fullCardNumber});
  CardCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CardCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Card, $Out>
    implements CardCopyWith<$R, Card, $Out> {
  _CardCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Card> $mapper = CardMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get categories =>
      ListCopyWith($value.categories, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(categories: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get elements =>
      ListCopyWith($value.elements, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(elements: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get cardNumbers => ListCopyWith(
          $value.cardNumbers,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(cardNumbers: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get searchTerms => ListCopyWith(
          $value.searchTerms,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(searchTerms: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get set =>
      ListCopyWith($value.set, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(set: v));
  @override
  $R call(
          {int? productId,
          String? name,
          String? cleanName,
          String? fullResUrl,
          String? highResUrl,
          String? lowResUrl,
          Object? lastUpdated = $none,
          int? groupId,
          bool? isNonCard,
          Object? cardType = $none,
          Object? category = $none,
          List<String>? categories,
          Object? cost = $none,
          Object? description = $none,
          List<String>? elements,
          Object? job = $none,
          Object? number = $none,
          Object? power = $none,
          Object? rarity = $none,
          List<String>? cardNumbers,
          List<String>? searchTerms,
          List<String>? set,
          Object? fullCardNumber = $none}) =>
      $apply(FieldCopyWithData({
        if (productId != null) #productId: productId,
        if (name != null) #name: name,
        if (cleanName != null) #cleanName: cleanName,
        if (fullResUrl != null) #fullResUrl: fullResUrl,
        if (highResUrl != null) #highResUrl: highResUrl,
        if (lowResUrl != null) #lowResUrl: lowResUrl,
        if (lastUpdated != $none) #lastUpdated: lastUpdated,
        if (groupId != null) #groupId: groupId,
        if (isNonCard != null) #isNonCard: isNonCard,
        if (cardType != $none) #cardType: cardType,
        if (category != $none) #category: category,
        if (categories != null) #categories: categories,
        if (cost != $none) #cost: cost,
        if (description != $none) #description: description,
        if (elements != null) #elements: elements,
        if (job != $none) #job: job,
        if (number != $none) #number: number,
        if (power != $none) #power: power,
        if (rarity != $none) #rarity: rarity,
        if (cardNumbers != null) #cardNumbers: cardNumbers,
        if (searchTerms != null) #searchTerms: searchTerms,
        if (set != null) #set: set,
        if (fullCardNumber != $none) #fullCardNumber: fullCardNumber
      }));
  @override
  Card $make(CopyWithData data) => Card(
      productId: data.get(#productId, or: $value.productId),
      name: data.get(#name, or: $value.name),
      cleanName: data.get(#cleanName, or: $value.cleanName),
      fullResUrl: data.get(#fullResUrl, or: $value.fullResUrl),
      highResUrl: data.get(#highResUrl, or: $value.highResUrl),
      lowResUrl: data.get(#lowResUrl, or: $value.lowResUrl),
      lastUpdated: data.get(#lastUpdated, or: $value.lastUpdated),
      groupId: data.get(#groupId, or: $value.groupId),
      isNonCard: data.get(#isNonCard, or: $value.isNonCard),
      cardType: data.get(#cardType, or: $value.cardType),
      category: data.get(#category, or: $value.category),
      categories: data.get(#categories, or: $value.categories),
      cost: data.get(#cost, or: $value.cost),
      description: data.get(#description, or: $value.description),
      elements: data.get(#elements, or: $value.elements),
      job: data.get(#job, or: $value.job),
      number: data.get(#number, or: $value.number),
      power: data.get(#power, or: $value.power),
      rarity: data.get(#rarity, or: $value.rarity),
      cardNumbers: data.get(#cardNumbers, or: $value.cardNumbers),
      searchTerms: data.get(#searchTerms, or: $value.searchTerms),
      set: data.get(#set, or: $value.set),
      fullCardNumber: data.get(#fullCardNumber, or: $value.fullCardNumber));

  @override
  CardCopyWith<$R2, Card, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _CardCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'loading_state_provider.dart';

class LoadingStateMapper extends ClassMapperBase<LoadingState> {
  LoadingStateMapper._();

  static LoadingStateMapper? _instance;
  static LoadingStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LoadingStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'LoadingState';

  static String _$message(LoadingState v) => v.message;
  static const Field<LoadingState, String> _f$message =
      Field('message', _$message);
  static double? _$progress(LoadingState v) => v.progress;
  static const Field<LoadingState, double> _f$progress =
      Field('progress', _$progress, opt: true);
  static bool _$isLoading(LoadingState v) => v.isLoading;
  static const Field<LoadingState, bool> _f$isLoading =
      Field('isLoading', _$isLoading, opt: true, def: false);

  @override
  final MappableFields<LoadingState> fields = const {
    #message: _f$message,
    #progress: _f$progress,
    #isLoading: _f$isLoading,
  };

  static LoadingState _instantiate(DecodingData data) {
    return LoadingState(
        message: data.dec(_f$message),
        progress: data.dec(_f$progress),
        isLoading: data.dec(_f$isLoading));
  }

  @override
  final Function instantiate = _instantiate;

  static LoadingState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LoadingState>(map);
  }

  static LoadingState fromJson(String json) {
    return ensureInitialized().decodeJson<LoadingState>(json);
  }
}

mixin LoadingStateMappable {
  String toJson() {
    return LoadingStateMapper.ensureInitialized()
        .encodeJson<LoadingState>(this as LoadingState);
  }

  Map<String, dynamic> toMap() {
    return LoadingStateMapper.ensureInitialized()
        .encodeMap<LoadingState>(this as LoadingState);
  }

  LoadingStateCopyWith<LoadingState, LoadingState, LoadingState> get copyWith =>
      _LoadingStateCopyWithImpl<LoadingState, LoadingState>(
          this as LoadingState, $identity, $identity);
  @override
  String toString() {
    return LoadingStateMapper.ensureInitialized()
        .stringifyValue(this as LoadingState);
  }

  @override
  bool operator ==(Object other) {
    return LoadingStateMapper.ensureInitialized()
        .equalsValue(this as LoadingState, other);
  }

  @override
  int get hashCode {
    return LoadingStateMapper.ensureInitialized()
        .hashValue(this as LoadingState);
  }
}

extension LoadingStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LoadingState, $Out> {
  LoadingStateCopyWith<$R, LoadingState, $Out> get $asLoadingState =>
      $base.as((v, t, t2) => _LoadingStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LoadingStateCopyWith<$R, $In extends LoadingState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? message, double? progress, bool? isLoading});
  LoadingStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _LoadingStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LoadingState, $Out>
    implements LoadingStateCopyWith<$R, LoadingState, $Out> {
  _LoadingStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LoadingState> $mapper =
      LoadingStateMapper.ensureInitialized();
  @override
  $R call({String? message, Object? progress = $none, bool? isLoading}) =>
      $apply(FieldCopyWithData({
        if (message != null) #message: message,
        if (progress != $none) #progress: progress,
        if (isLoading != null) #isLoading: isLoading
      }));
  @override
  LoadingState $make(CopyWithData data) => LoadingState(
      message: data.get(#message, or: $value.message),
      progress: data.get(#progress, or: $value.progress),
      isLoading: data.get(#isLoading, or: $value.isLoading));

  @override
  LoadingStateCopyWith<$R2, LoadingState, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _LoadingStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

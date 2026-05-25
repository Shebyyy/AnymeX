import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:anymex/utils/logger.dart';

final class _EventRegToken extends Struct {
  @Int64()
  external int value;
}

final class _CallbackObj extends Struct {
  external Pointer<Void> lpVtbl;
  @Int32()
  external int refCount;
}

typedef _QiFn = Int32 Function(Pointer<Void>, Pointer<GUID>, Pointer<Pointer<Void>>);
typedef _ArFn = Uint32 Function(Pointer<Void>);
typedef _RlFn = Uint32 Function(Pointer<Void>);
typedef _InvFn = Int32 Function(Pointer<Void>, Pointer<Void>, Pointer<Void>);

final Pointer<GUID> _IID_Unknown = Guid.parse('{00000000-0000-0000-C000-000000000046}').toNativeGUID();
final Pointer<GUID> _IID_ActFactory = Guid.parse('{00000035-0000-0000-C000-000000000046}').toNativeGUID();
final Pointer<GUID> _IID_MediaPlayer = Guid.parse('{94EA8842-6E1B-4EB8-A82E-7CC0E942862E}').toNativeGUID();
final Pointer<GUID> _IID_SMTC = Guid.parse('{21107246-0F0E-4ACA-82D2-CB2B9E08B9B7}').toNativeGUID();
final Pointer<GUID> _IID_SMTCDU = Guid.parse('{EDD11392-8A97-487C-AB2E-B8A513FC4F95}').toNativeGUID();
final Pointer<GUID> _IID_BtnHandler = Guid.parse('{607E6825-4F35-4690-BEA0-12F04F9B8847}').toNativeGUID();

late final WindowsSmtc windowsSmtc = WindowsSmtc._();

WindowsSmtc? _activeSmtc;

bool _guidEq(Pointer<GUID> a, Pointer<GUID> b) {
  return a.ref.Data1 == b.ref.Data1 &&
      a.ref.Data2 == b.ref.Data2 &&
      a.ref.Data3 == b.ref.Data3 &&
      a.ref.Data4 == b.ref.Data4;
}

int _cbQi(Pointer<Void> self, Pointer<GUID> iid, Pointer<Pointer<Void>> ppv) {
  if (ppv.address == 0) return 0x80004004;
  if (_guidEq(iid, _IID_Unknown) || _guidEq(iid, _IID_BtnHandler)) {
    ppv.value = self;
    final o = Pointer<_CallbackObj>.fromAddress(self.address);
    o.ref.refCount++;
    return 0;
  }
  ppv.value = nullptr;
  return 0x80004002;
}

int _cbAr(Pointer<Void> self) {
  final o = Pointer<_CallbackObj>.fromAddress(self.address);
  return ++o.ref.refCount;
}

int _cbRl(Pointer<Void> self) {
  final o = Pointer<_CallbackObj>.fromAddress(self.address);
  return --o.ref.refCount;
}

int _cbInv(Pointer<Void> self, Pointer<Void> sender, Pointer<Void> args) {
  final smtc = _activeSmtc;
  if (smtc == null) return 0;
  try {
    final vt = args.cast<Pointer<Pointer<Void>>>().value;
    final fn = vt.elementAt(6).cast<Pointer<NativeFunction<Int32 Function(Pointer<Void>, Pointer<Int32>)>>>().value;
    final bp = calloc<Int32>();
    try {
      final hr = fn.asFunction<int Function(Pointer<Void>, Pointer<Int32>)>()(args, bp);
      if (hr != 0) return hr;
      switch (bp.value) {
        case 0: smtc._onPlay?.call();
        case 1: smtc._onPause?.call();
        case 3: smtc._onNext?.call();
        case 4: smtc._onPrevious?.call();
      }
    } finally { free(bp); }
  } catch (e) { Logger.w('SMTC btn: $e'); }
  return 0;
}

late final NativeCallable<_QiFn> _qiNC;
late final NativeCallable<_ArFn> _arNC;
late final NativeCallable<_RlFn> _rlNC;
late final NativeCallable<_InvFn> _ivNC;

class WindowsSmtc {
  WindowsSmtc._();

  bool _initialized = false;
  Pointer<Void>? _smtc;
  Pointer<Void>? _smtcDu;
  Pointer<Void>? _musicProps;
  Pointer<_EventRegToken>? _cookie;
  Pointer<_CallbackObj>? _cbObj;
  Pointer<Pointer<Void>>? _cbVt;

  void Function()? _onPlay;
  void Function()? _onPause;
  void Function()? _onNext;
  void Function()? _onPrevious;

  void init({
    required void Function() onPlay,
    required void Function() onPause,
    required void Function(Duration) onSeek,
    required void Function() onNext,
    required void Function() onPrevious,
  }) {
    if (!Platform.isWindows || _initialized) return;
    _onPlay = onPlay;
    _onPause = onPause;
    _onNext = onNext;
    _onPrevious = onPrevious;

    try {
      CoInitializeEx(nullptr, COINIT_MULTITHREADED);
      final hr = RoInitialize(1);
      if (hr != 0 && hr != 0x80010106 && hr != 2147942407) return;

      final mp = _createMediaPlayer();
      if (mp == null) { Logger.w('SMTC: no MediaPlayer'); return; }

      _smtc = _qiOn(mp, _IID_SMTC);
      if (_smtc == null) { _rel(mp); Logger.w('SMTC: no SMTC'); return; }

      _putBool(7, true); _putBool(9, true); _putBool(11, true);
      _putBool(15, true); _putBool(17, true);

      _smtcDu = _qiOn(_smtc!, _IID_SMTCDU);
      if (_smtcDu != null) { _duPutI32(7, 1); _musicProps = _duGet(12); }

      _regBtn();
      _rel(mp);
      _initialized = true;
      _activeSmtc = this;
      Logger.i('SMTC initialized');
    } catch (e) { Logger.w('SMTC init: $e'); }
  }

  void updateMetadata({required String title, required String artist, String? artworkUrl, Duration? duration}) {
    if (!_initialized || _musicProps == null) return;
    try {
      final tH = _mkHs(title), aH = _mkHs(artist);
      try {
        _propPutHs(_musicProps!, 7, tH);
        _propPutHs(_musicProps!, 11, aH);
        if (_smtcDu != null) _duCall0(15);
      } finally {
        if (tH != 0) WindowsDeleteString(tH);
        if (aH != 0) WindowsDeleteString(aH);
      }
    } catch (e) { Logger.w('SMTC meta: $e'); }
  }

  void updatePlaybackState({required Duration position, required bool isPlaying, required bool isBuffering, required double playbackSpeed}) {
    if (!_initialized || _smtc == null) return;
    try { _putI32(19, isBuffering ? 1 : (isPlaying ? 3 : 4)); } catch (_) {}
  }

  void updateSkipButtons({required bool canSkipNext, required bool canSkipPrevious}) {
    if (!_initialized || _smtc == null) return;
    try { _putBool(15, canSkipNext); _putBool(17, canSkipPrevious); } catch (_) {}
  }

  void stop() {
    if (!_initialized) return;
    try { if (_smtc != null) { _putI32(19, 0); _putBool(7, false); } _unregBtn(); } catch (_) {}
    _initialized = false; _activeSmtc = null;
  }

  Pointer<Void>? _createMediaPlayer() {
    final cn = 'Windows.Media.Playback.MediaPlayer'.toNativeUtf16();
    final hs = calloc<IntPtr>();
    try {
      if (WindowsCreateString(cn, -1, hs) != 0) return null;
      final fp = calloc<IntPtr>();
      if (RoGetActivationFactory(hs.value, _IID_ActFactory, fp.cast<Pointer<Pointer>>()) != 0) return null;
      final factoryAddr = fp.value; free(fp);
      final ip = calloc<IntPtr>();
      _vtCall1(Pointer<Void>.fromAddress(factoryAddr), 6, ip);
      _rel(Pointer<Void>.fromAddress(factoryAddr));
      return ip.value != 0 ? _qiOn(Pointer<Void>.fromAddress(ip.value), _IID_MediaPlayer) : null;
    } finally { free(cn); if (hs.value != 0) WindowsDeleteString(hs.value); free(hs); }
  }

  void _regBtn() {
    if (_smtc == null) return;
    try {
      _qiNC = NativeCallable<_QiFn>.isolateLocal(_cbQi, exceptionalReturn: 0x80004002);
      _arNC = NativeCallable<_ArFn>.isolateLocal(_cbAr, exceptionalReturn: 0);
      _rlNC = NativeCallable<_RlFn>.isolateLocal(_cbRl, exceptionalReturn: 0);
      _ivNC = NativeCallable<_InvFn>.isolateLocal(_cbInv, exceptionalReturn: 0x80004005);
      _cbVt = malloc<Pointer<Void>>(4);
      _cbVt![0] = Pointer<Void>.fromAddress(_qiNC.nativeFunction.address);
      _cbVt![1] = Pointer<Void>.fromAddress(_arNC.nativeFunction.address);
      _cbVt![2] = Pointer<Void>.fromAddress(_rlNC.nativeFunction.address);
      _cbVt![3] = Pointer<Void>.fromAddress(_ivNC.nativeFunction.address);
      _cbObj = malloc<_CallbackObj>();
      _cbObj!.ref.lpVtbl = _cbVt!.cast();
      _cbObj!.ref.refCount = 1;
      _cookie = calloc<_EventRegToken>();
      _smtcCall2(21, _cbObj!.cast(), _cookie!);
    } catch (e) { Logger.w('SMTC btn reg: $e'); }
  }

  void _unregBtn() {
    if (_smtc != null && _cookie != null) { try { _smtcCall1(22, _cookie!); } catch (_) {} }
    if (_cookie != null) { free(_cookie!); _cookie = null; }
    if (_cbObj != null) { malloc.free(_cbObj!); _cbObj = null; }
    if (_cbVt != null) { malloc.free(_cbVt!); _cbVt = null; }
  }

  int _mkHs(String s) {
    if (s.isEmpty) return 0;
    final u = s.toNativeUtf16(), h = calloc<IntPtr>();
    try { return WindowsCreateString(u, s.length, h) == 0 ? h.value : 0; }
    finally { free(u); free(h); }
  }

  static Pointer<Void>? _qiOn(Pointer<Void> obj, Pointer<GUID> iid) {
    final r = calloc<Pointer<Void>>();
    try {
      final vt = obj.cast<Pointer<Pointer<Void>>>().value;
      final fn = vt.elementAt(0).cast<Pointer<NativeFunction<Int32 Function(Pointer<Void>, Pointer<GUID>, Pointer<Pointer<Void>>)>>>().value;
      return fn.asFunction<int Function(Pointer<Void>, Pointer<GUID>, Pointer<Pointer<Void>>)>()(obj, iid, r) == 0
          ? r.value : null;
    } finally { free(r); }
  }

  static void _rel(Pointer<Void> obj) {
    if (obj.address == 0) return;
    final vt = obj.cast<Pointer<Pointer<Void>>>().value;
    vt.elementAt(2).cast<Pointer<NativeFunction<Uint32 Function(Pointer<Void>)>>>().value
        .asFunction<int Function(Pointer<Void>)>()(obj);
  }

  static int _vtCall1(Pointer<Void> obj, int offset, Pointer<IntPtr> out) {
    final vt = obj.cast<Pointer<Pointer<Void>>>().value;
    return vt.elementAt(offset).cast<Pointer<NativeFunction<Int32 Function(Pointer<Void>, Pointer<IntPtr>)>>>().value
        .asFunction<int Function(Pointer<Void>, Pointer<IntPtr>)>()(obj, out);
  }

  void _putBool(int off, bool v) {
    final vt = _smtc!.cast<Pointer<Pointer<Void>>>().value;
    vt.elementAt(off).cast<Pointer<NativeFunction<Int32 Function(Pointer<Void>, Int32)>>>().value
        .asFunction<int Function(Pointer<Void>, int)>()(_smtc!, v ? 1 : 0);
  }

  void _putI32(int off, int v) {
    final vt = _smtc!.cast<Pointer<Pointer<Void>>>().value;
    vt.elementAt(off).cast<Pointer<NativeFunction<Int32 Function(Pointer<Void>, Int32)>>>().value
        .asFunction<int Function(Pointer<Void>, int)>()(_smtc!, v);
  }

  void _smtcCall1(int off, Pointer<_EventRegToken> tok) {
    final vt = _smtc!.cast<Pointer<Pointer<Void>>>().value;
    vt.elementAt(off).cast<Pointer<NativeFunction<Int32 Function(Pointer<Void>, Pointer<_EventRegToken>)>>>().value
        .asFunction<int Function(Pointer<Void>, Pointer<_EventRegToken>)>()(_smtc!, tok);
  }

  void _smtcCall2(int off, Pointer<Void> a1, Pointer<_EventRegToken> a2) {
    final vt = _smtc!.cast<Pointer<Pointer<Void>>>().value;
    vt.elementAt(off).cast<Pointer<NativeFunction<Int32 Function(Pointer<Void>, Pointer<Void>, Pointer<_EventRegToken>)>>>().value
        .asFunction<int Function(Pointer<Void>, Pointer<Void>, Pointer<_EventRegToken>)>()(_smtc!, a1, a2);
  }

  void _duPutI32(int off, int v) {
    final vt = _smtcDu!.cast<Pointer<Pointer<Void>>>().value;
    vt.elementAt(off).cast<Pointer<NativeFunction<Int32 Function(Pointer<Void>, Int32)>>>().value
        .asFunction<int Function(Pointer<Void>, int)>()(_smtcDu!, v);
  }

  void _duCall0(int off) {
    final vt = _smtcDu!.cast<Pointer<Pointer<Void>>>().value;
    vt.elementAt(off).cast<Pointer<NativeFunction<Int32 Function(Pointer<Void>)>>>().value
        .asFunction<int Function(Pointer<Void>)>()(_smtcDu!);
  }

  Pointer<Void>? _duGet(int off) {
    final vt = _smtcDu!.cast<Pointer<Pointer<Void>>>().value;
    final r = calloc<IntPtr>();
    try {
      return vt.elementAt(off).cast<Pointer<NativeFunction<Int32 Function(Pointer<Void>, Pointer<IntPtr>)>>>().value
          .asFunction<int Function(Pointer<Void>, Pointer<IntPtr>)>()(_smtcDu!, r) == 0
          ? Pointer<Void>.fromAddress(r.value) : null;
    } finally { free(r); }
  }

  void _propPutHs(Pointer<Void> obj, int off, int hs) {
    final vt = obj.cast<Pointer<Pointer<Void>>>().value;
    vt.elementAt(off).cast<Pointer<NativeFunction<Int32 Function(Pointer<Void>, IntPtr)>>>().value
        .asFunction<int Function(Pointer<Void>, int)>()(obj, hs);
  }
}

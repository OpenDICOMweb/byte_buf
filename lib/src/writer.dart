// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

//TODO: add UTF8 and ASCII converters
part of odw.sdk.byte_buf;

//TODO: Add a way to retrieve error messages
//TODO: Add the ability to Write objects (Uid, Uuid, Uri, etc.)

// names with char or Char(suffix) return [int]s.
// names with string or String(suffix) return [String]s.
// If a Writers returns [null], the [index] is not changed.

/// Writer Interface
///
/// _start = 0
/// _start <= _rIndex <= _wIndex <= _end
/// _rRemaining = _wIndex - _rIndex
/// _wRemaining = _end - _wIndex
/// isWritable = _rRemaining > 0;
/// isWritable = _wRemaining > 0;
///

abstract class Writer extends ByteBuf {
  Writer(int readIndex, int writeIndex) : super(readIndex, writeIndex);

  String toSubString(int start, int end);

  /// Returns a valid Write limit, which might be less than [n],
  /// or [null] if no valid limit exists. [n] can be positive or negative.
  int _getWLength(String s, int min, int max) {
    int len = s.length;
    int v = ((_wIndex + len) > _end) ? _end - _wIndex : _wIndex + len;
    return (v > 0) ? v : null;
  }
/*
    /// Moves [_rIndex] forward or backward.
    ///
    /// If [index] [+] [count] is valid, moves the [_rIndex] to that value and
    /// returns [true]; otherwise, the [_rIndex] is not moved and returns [false].
    /// Returns [true] if [index + count] is a valid [_rIndex].
    bool skip(int count) {
        int pos = _rIndex + count;
        if (_isValidRIndex(pos)) {
            _rIndex = pos;
            return true;
        }
        return false;
    }
    */

  /// Returns the code unit at [_wIndex] and increments [_wIndex], or [null] if
  /// the [buf] [isWritable].
  bool write(int c) => (isWritable) ? _write(c) : null;

  /// _Internal_: Must only be called when [isEmpty] is false.
  bool _write(int c) {
    _buf[_wIndex] = c;
    _wIndex++;
    return true;
  }

  /* Flush if not used
  _wGuard(Function f) {
    int start = _wIndex;
    var value;
    try {
      value = f();
    } catch (e) {
      _wIndex = start;
      //TODO: add this
      //   log.info(e);
      //  print(e);
      return null;
    }
    return value;
  }
 */

  /// Returns a [String] with a minimum length of [min] and a maximum length of [max],
  /// or [null] if a [String] of [min] length is not available.
  bool writeString(String s, [int min = 0, int max]) {
    int len = _getWLength(s, min, max);
    if (len == null || len < min || max < len) return null;
    return _writeString(s, len);
  }

  bool _writeString(String s, int length) {
    if (_wRemaining < length) return false;
    for (int i = 0; i < length; i++) _write(s.codeUnitAt(i));
    return true;
  }

  /// Writes a [String] checking each code unit to verify it is valid.
  /// If all code units pass [test] returns a [String] of [min] to [max] length;
  /// otherwise, returns null;
  String writeChecked(String s, int min, int max, _CharTest test) {
    int limit = _getRLimit(min, max);
    if (limit == null || limit < min) return null;
    int start = _wIndex;
    try {
      for (int i = 0; i < limit; i++) {
        int c = s.codeUnitAt(i);
        if (!test(c)) {
          _wIndex = start;
          throw 'Failed predicate test($test) at index($i)';
        }
        _write(c);
      }
    } catch (e) {
      _wIndex = start;
      return null;
    }
    _wIndex = _wIndex + limit;
    return toSubString(start, limit);
  }

  // **** Simple Matchers ****

  /// Writes the
  bool matchString(String s) {
    if (s.length > rRemaining) return false;
    int start = _rIndex;
    for (int i = 0; i < s.length; i++) {
      int c = s.codeUnitAt(0);
      if (c != _write) {
        _rIndex == start;
        return false;
      }
    }
    return true;
  }

  /// Writes and returns the integer value of a code point between "0" and "9".
  bool writeDigit(int digit) => write(digit + k0);

  /// Writes an unsigned [int] from [max] code units, which must be between
  /// "0" and "9" and returns the corresponding integer value. If [_buf] does
  /// not have [max] code units remaining, or if the code units corresponding
  /// to [max] do not contain digits, returns [null].
  bool writeUint(int n, [int min = 1, int max]) {
    //  print('WriteUint: n($n), min($min), max($max)');
    String s = n.toString();
    int len = _getWLength(s, min, max);
    if (len == null || len == 0) return false;
    //  print('length($len), index($_wIndex)');
    return _writeUint(s, len);
  }

  bool _writeUint(String s, int length) {
    //  print('_writeUint: limit($length), @$_wIndex');
    for (int i = 0; i < length; i++, _wIndex++) {
      bool v = writeDigit(s.codeUnitAt(i));
      if (v == false) return false;
      //  print('v: $v');
    }
    return true;
  }

  /* Flush if not needed
  bool get _isHex {
    int c = peek;
    return (k0 <= c && c <= k9) || (kA <= c && c <= kF) || (ka <= c && c <= kf);
  }
  */

  bool hex(int c) => (isWritable) ? _toHex(c) : null;

  /// Writes and returns the integer value of a code point between "0" and "9",
  /// "A" and "F", and "a" and "f".
  bool _toHex(int c, [bool useLowercase = true]) {
    // print('@$_rIndex hex: c= "$c" "${c - k0}"');
    if (0 <= c && c <= 9) return write(c + k0);
    if (useLowercase == true) {
      if (10 <= c && c <= 16) return write(ka + c);
    } else {
      if (10 <= c && c <= 16) return write(kA + 10);
    }
    return null;
  }

  /// Writes [max] code units, which must be hexadecimal code points (0-9, A-F, a-f),
  /// and returns the corresponding integer value. If [_buf] does not have [max]
  /// code units remaining, or if the code units corresponding to [max] do not contain digits,
  /// returns [null].
  bool writeHex(int n, int min, int max) {
    if (max <= 0 || rRemaining < max) return false;
    return _writeHex(n, max, max);
  }

  bool _writeHex(int n, int min, int max) {
    //  print('n($n), min($min), max($max)');
    String s = n.toRadixString(16);
    int length = _getWLength(s, min, max);
    return writeString(s, length);
  }

  // **** Signed Integers ****

  //TODO: edit.
  /// Writes a sign code unit (+, -) and returns +1 or -1.
  /// If the next code unit is a digit then return 1, but does not
  /// advance the [_rIndex].
  void writeSign(int value, [bool usePlusSign = false]) {
    if (value.isNegative) write(kMinusSign);
    if (usePlusSign == true) write(kPlusSign);
  }

  /// Writes an signed [int] from [max] code units, which must be between
  /// "0" and "9" and returns the corresponding integer value. If [_buf] does
  /// not have [max] code units remaining, or if the code units corresponding
  /// to [max] do not contain digits, returns [null].
  bool writeInt(int n, [int min = 1, int max]) {
    max = RangeError.checkValidRange(1, max, _rRemaining);
    writeSign(n);
    return writeUint(n.abs(), min, max);
  }

  //DICOM max length
  int maxDecimalLength = 16;

  bool decimal(num n) => writeDecimal(n, maxDecimalLength);

  //TODO: validate
  bool writeDecimal(num n, [int min = 1, int max]) {
    String s = n.toString();
    int limit = _getWLength(s, min, max);
    if (limit == null) return null;
    return writeString(s, limit);
  }

  // **** Write dates, times, dateTimes, and durations. ****

  DateTime today = new DateTime.now();

  bool allowVariableWidthDateTimeValues = false;

  bool year(int y) => writeUint(y, 4, 4);
  bool month(int m) => writeUint(m, 2, 2);
  bool vMonth(int m) => writeUint(m, 1, 2);

  /// Writes and returns a [int] between 1 and 31, or [null]. Note: does not
  /// validate months with 28, 29, or 30 days.
  bool day(int d) => writeUint(d, 2, 2);
  bool vDay(int d) => writeUint(d, 1, 2);

  /// Writes and returns a date in fixed format yyyymmdd.
  bool date(Date d) {
    if (wRemaining < 8) return null;
    year(d.year);
    month(d.month);
    day(d.day);
    return true;
  }

  /// Writes and returns a date in fixed format yyyymmdd.
  bool vDate(Date d) {
    String s = d.toString();
    if (wRemaining < s.length) return null;
    writeString(s);
    return true;
  }

  int maxFractionDigits = 6;

  // Times
  bool hour(int h) => writeUint(h, 2, 2);
  bool vHour(int h) => writeUint(h, 1, 2);

  bool minute(int m) => writeUint(m, 2, 2);
  bool vMinute(int m) => writeUint(m, 1, 2);

  bool second(int s) => writeUint(s, 2, 2);
  bool vSecond(int s) => writeUint(s, 1, 2);

  bool fraction(int f) => writeUint(f, maxFractionDigits);

  ///
  void time(Time t) {}

  ///
  void vTime(Time t) {}

  // Time Zone

  /// Writes the next [char] and returns -1 if it is "-",
  /// 0 if it is "Z" or "z", or 1 if it is "+"; otherwise,
  /// [unWrite]s and returns [null].
  void writeTimeZone(int minutes) {}

  // **** UID
  // bool writeUid(Uid uid) => writeString(uid.string, 0, 64);

  bool writeUri([int start = 0, int end]) {
    //TODO: do something more efficient
    //UR - Universal Resource Identifier (URI)
    return null;
  }
}

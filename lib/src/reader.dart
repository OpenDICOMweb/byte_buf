// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

//TODO: add UTF8 and ASCII converters
//TODO: add UidParser
//TODO: add Date and Time parsers
//TODO: document
part of odw.sdk.byte_buf;

//TODO: Add a way to retrieve error messages
//TODO: Add the ability to read object (Uid, Uuid, Uri, etc.)

// names with char or Char(suffix) return [int]s.
// names with string or String(suffix) return [String]s.
// If a Readers returns [null], the [index] is not changed.

// **** Every Getter or Method should leave the [_rIndex] in the correct position,
// **** unless stated otherwise.

typedef bool _CharTest(int code);

/* flush
int checkBufferLength(int bufferLength, int start, int end) {
  if (end == null) end = bufferLength;
  if (end < 0 || bufferLength < end)
    throw new ArgumentError("Invalid end($end) for buffer with length($bufferLength)");
  if (start < 0 || end < start)
    throw new ArgumentError("Invalid start($start) for buffer with end($end)");
  return end;
}
*/
/// Reader Interface
///
/// _start = 0
/// _start <= _rIndex <= _wIndex <= _end
/// _rRemaining = _wIndex - _rIndex
/// _wRemaining = _end - _wIndex
/// isReadable = _rRemaining > 0;
/// isWritable = _wRemaining > 0;
///

typedef int _CharConverter(int c);

abstract class Reader extends ByteBuf {
  //List<int> _buf;
  //int _rIndex;
  //int _wIndex;
  //List<Issue> issues = [];

  // **** Abstract methods that must be implemented.

  Reader(int readIndex, int writeIndex) : super(readIndex, writeIndex);

  /// Returns a [List] containing a copy of the elements from [start] to [end].
  List<int> sublist(int start, int end);

  /// Returns a [Reader] that is a [slice] of [this].
  Reader slice(int start, int end);

  /// Returns a [String] containing characters that correspond to the elements
  /// from [start] to [end].
  String substring(int start, int end);

  // **** end of abstract methods.

  @override
  int operator [](int i) => _buf[i];

  @override
  int get length => _buf.length;

  // **** Peek, read, or unread at [index].

  /// Returns the code unit at [_rIndex], but does not increment [_rIndex].
  int get peek => (_isReadable) ? _buf[_rIndex] : null;

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

  bool _matchChar(int char) {
    int c = peek;
    if (c != char) return false;
    _rIndex++;
    return true;
  }

  /// Returns the code unit at [_rIndex] and increments [_rIndex], or [null] if
  /// the [buf] [_isReadable].
  int get read => (_isReadable) ? _read : null;

  /// _Internal_: Must only be called when [isEmpty] is false.
  int get _read {
    int c = _buf[_rIndex];
    _rIndex++;
    return c;
  }

  /// Decrements the [_rIndex] by 1 and returns [true]; however, if decrementing
  /// the [_rIndex] would result in a negative [_rIndex] returns [false]
  bool get unread {
    if ((_rIndex - 1) >= 0) {
      _rIndex--;
      return true;
    }
    return false;
  }

  /* Flush if not needed
  dynamic _rGuard(Function f) {
    int start = _rIndex;
    var value;
    try {
      value = f();
    } catch (e) {
      _rIndex = start;
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
  String readString([int min = 0, int max]) {
    int limit = _getRLimit(min, max);
    if (limit == null) return null;
    String s = substring(_rIndex, limit);
    _rIndex = limit;
    return s;
  }

/* Flush if not used
  /// Reads a [String] checking each code unit to verify it is valid.
  /// If all code units pass [test] returns a [String] of [min] to [max] length;
  /// otherwise, returns null;
  bool _isFilteredString(int min, int max, _CharTest test) {
    int limit = _getRLimit(min, max);
    if (limit == null) return null;
    for (int i = _rIndex; i < limit; i++) if (!test(_buf[i])) return false;
    return true;
  }
*/
  int _getFilteredEndOfString(int min, int max, _CharTest test) {
    int limit = _getRLimit(min, max);
    if (limit == null) return null;
    for (int i = _rIndex; i < limit; i++) if (!test(_buf[i])) return null;
    return limit;
  }

  /* Flush if not used
  /// Returns an error message for a filtered string.
  String _getFilteredStringErrorMsg(int min, int max, _CharTest test) {
    int limit = _getRLimit(min, max);
    if (limit == null) return null;
    for (int i = _rIndex; i < limit; i++)
      if (!test(_buf[i]))
        return _invalidChar(substring(_rIndex, limit), _buf[i], i);
    return null;
  }
  */
  /// Reads a [String] checking each code unit to verify it is valid.
  /// If all code units pass [test] returns a [String] of [min] to [max] length;
  /// otherwise, returns null;
  String _readFilteredString(int min, int max, _CharTest test) {
    int start = _rIndex;
    int limit = _getFilteredEndOfString(min, max, test);
    if (limit == null) return null;
    _rIndex = limit;
    return substring(start, limit);
  }

/* Flush if not needed
  /// Reads the elements from [readIndex] to [limit] checking that each element
  /// satisfies the [test].  Returns a Slice (or View) of this [Reader],
  /// If all element pass [test], otherwise, returns null.
  ///
  /// Note: this doesn't check for [kSpace] or [kNull] at the end of the string.
  /// The user must do that in the caller, if appropriate.
  Reader _readFilteredSlice(int min, int max, _CharTest test) {
    int start = _rIndex;
    int limit = _getFilteredEndOfString(min, max, test);
    if (limit == null) return null;
    _rIndex = limit;
    return slice(start, limit);
  }

  // VR: SH, LO, UC
  bool _dcmStringFilter(int c) =>
      !(c < kSpace || c == kBackslash || c == kDelete);

  // bool _isDcmString(int max) => _isFilteredString(0, max, _dcmStringFilter);

  //String _checkDcmString(int length)  => (_isDcmString(length)) ? s : null;

  String _readDcmString(int length) =>
      _readFilteredString(length, length, _dcmStringFilter);

  Reader _readDcmSlice(int length) =>
      _readFilteredSlice(length, length, _dcmStringFilter);

  bool _isTextString(int max) => _isFilteredString(0, max, _dcmTextFilter);

  String _checkTextString(int max) => (_isTextString(max)) ? s : null;

  // VR: ST, LT, UT
  bool _dcmTextFilter(int c) => !(c < kSpace || c == kDelete);

  String _readTextString(int length) =>
      _readFilteredString(length, length, _dcmTextFilter);

  Reader _readTextSlice(int length) =>
      _readFilteredSlice(length, length, _dcmTextFilter);

  //TODO: this does not handle escape sequences
  List<String> _hasError(int min, int max, bool filter(int c)) {
    int limit = _getRLimit(min, max);
    if (limit == null) return null;
    String msg0 = _rangeErrorMsg(limit, min, max);
    for (int i = _rIndex; i < limit; i++) {
      int c = _buf[i];
      if (filter(c))
        return <String>[msg0, _invalidChar(substring(_rIndex, limit), c, i)];
    }
    // Success
    return null;
  }
*/
  //TODO: this does not handle escape sequences
  List<String> _stringErrors(String s, int max, bool filter(int c)) {
    int limit = _getRLimit(0, max);
    if (limit == null) return null;
    String msg0 = _rangeErrorMsg(s.length, 0, max);
    for (int i = _rIndex; i < _wIndex; i++) {
      int c = s.codeUnitAt(i);
      if (filter(c))
        return <String>[msg0, _invalidChar(substring(_rIndex, limit), c, i)];
    }
    return null; // Success
  }

  // DICOM Text Strings
  bool _stringFilter(int c) => (c < kSpace || c == kBackslash || c == kDelete);
  List<String> getErrorsAE(String s) => _stringErrors(s, 16, _stringFilter);
  List<String> getErrorsCS(String s) => _stringErrors(s, 16, _stringFilter);
  List<String> getErrorsPN(String s) => _stringErrors(s, 5 * 64, _stringFilter);
  List<String> getErrorsSH(String s) => _stringErrors(s, 16, _stringFilter);
  List<String> getErrorsLO(String s) => _stringErrors(s, 64, _stringFilter);
  List<String> getErrorsUC(String s) =>
      _stringErrors(s, kMaxLongVF, _stringFilter);

  // DICOM Texts
  bool _textFilter(int c) => (c < kSpace || c == kDelete);
  List<String> getErrorsST(String s) => _stringErrors(s, 1024, _textFilter);
  List<String> getErrorsLT(String s) => _stringErrors(s, 10240, _textFilter);
  List<String> getErrorsUT(String s) =>
      _stringErrors(s, kMaxLongVF, _textFilter);

  List<String> getErrorsDS(String s) {
    String msg0 = _rangeErrorMsg(s.length, 0, 16);
    int v = num.parse(s, (s) => null);
    String valueMsg = (v == null) ? 'Invalid Character in DS String: "$s"' : "";
    return [msg0, valueMsg];
  }

  // **** Simple Matchers ****

  /// Compares the characters ([int]) in [String] [s] with the characters in the [ByteBuf]
  /// starting from [readIndex], and returns [true] if they match; otherwise, false.
  /// If there is a match the [readIndex] is advanced by [s.length] positions.
  bool matchString(String s) {
    if (s.length > rRemaining) return false;
    for (int i = 0; i < s.length; i++)
      if (s.codeUnitAt(0) != _buf[_rIndex + i]) return false;
    _rIndex += s.length;
    return true;
  }

  bool nextMatches(int code) => peek == code;
  bool nthMatches(int offset, int code) =>
      (hasReadable(offset)) ? _buf[offset] == code : null;

  /// Reads the next code unit and returns [true] if it matches [code].
  bool readMatchingCode(int code) {
    if (code == peek) {
      _rIndex++;
      return true;
    }
    return false;
  }

  // **** Read numbers ****

  bool _isDigit(c) => k0 <= c && c >= k9;

  /*
  bool _hasNDigits(int length) {
    for (int i = 0; i < length; i++) if (!_isDigit(peek)) return false;
    return true;
  }
  */
  /// Reads a character. If it is a decimal character returns it values
  /// as an integer; otherwise, returns null.
  int _toDigit(int c) {
    if (k0 <= c && c <= k9) return c - k0;
    return null;
  }

  /// Reads and returns the integer value of a code point between "0" and "9",
  /// "A" and "F", and "a" and "f".
  int _toHex(int c) {
    // print('@$_rIndex hex: c= "$c" "${c - k0}"');
    if (k0 <= c && c <= k9) return c - k0;
    if (kA <= c && c <= kF) return c - kA + 10;
    if (ka <= c && c <= kf) return c - ka + 10;
    return null;
  }

  int _peekDigit(_CharConverter convert) {
    //  print('@$_rIndex peekDigit');
    return convert(peek);
  }

  /*
  int _getDigit(_CharConverter convert) {
  //  print('@$_rIndex _getDigit');
    int c = convert(_read);
    if (c != null) return c;
    _rIndex--;
    return null;
  }
  */

  /// Reads and returns the integer value of a code point between "0" and "9".
  int get digit {
    //  print('@$_rIndex _Digit');
    int c = _peekDigit(_toDigit);
    //  print('@$_rIndex _Digit= $c');
    if (c == null) return null;
    _rIndex++;
    return c;
  }

  int get hex {
    //  print('@$_rIndex _Digit');
    int c = _peekDigit(_toHex);
    if (c == null) return null;
    _rIndex++;
    return c;
  }

  /// Reads an unsigned [int] from [max] code units, which must be between
  /// "0" and "9" and returns the corresponding integer value. If [_buf] does
  /// not have [max] code units remaining, or if the code units corresponding
  /// to [max] do not contain digits, returns [null].
  int readUint([int min = 1, int max]) {
    //  print('readUint: min($min), max($max)');
    int limit = _getRLimit(min, max);
    //  print('@$_rIndex limit($limit)');
    if (limit == null) return null;
    return _readUint(min, limit);
  }

  int _readUint(int min, int limit) {
    //  print('@$_rIndex[$limit], _readUint: limit($limit),');
    int n = 0;
    int start = _rIndex;
    while(_rIndex < limit) {
      //  print('@$_rIndex _readUint: $info limit($limit)');
      int v = digit;
      //  print('v= $v');
      if (v == null) break;
      n = (n * 10) + v;
      //  print('@$_rIndex: v($v), N($n)');
    }
    if (_rIndex - start < min) {
      //  print('too few read ${_rIndex - start} < min($min)');
      _rIndex = start;
      return null;
    }
    return n;
  }

  List<String> getErrorsIS(String s) {
    String lengthMsg = _rangeErrorMsg(s.length, 0, 12);
    int v = int.parse(s, onError: (s) => null);
    String valueMsg = (v == null) ? 'Invalid Character in IS String: "$s"' : "";
    return [lengthMsg + valueMsg];
  }

  /* Flush if not needed
  bool get _isHex {
    int c = peek;
    return (k0 <= c && c <= k9) || (kA <= c && c <= kF) || (ka <= c && c <= kf);
  }
  */

  /// Reads [count] code units, which must be hexadecimal code points (0-9, A-F, a-f),
  /// and returns the corresponding integer value. If [_buf] does not have [count]
  /// code units remaining, or if the code units corresponding to [count] do not contain digits,
  /// returns [null].
  int readHex(int count) {
    if (count <= 0 || rRemaining < count) return null;
    return _readHex(count, count);
  }

  int _readHex(int min, int max) {
    //  print('min($min), max($max)');
    int limit = _rIndex + max;
    int start = _rIndex;
    int n = 0;
    //  print('@$_rIndex start n: $n');
    for (; _rIndex < limit; _rIndex++) {
      int v = _toHex(_buf[_rIndex]);
      //  print('@$_rIndex v: $v');
      if (v == null) return v;
      n = (n * 16) + v;
      //  print('@$_rIndex n: $n');
    }
    if ((_rIndex - start) < min) {
      _rIndex = start;
      return null;
    }
    return n;
  }

  /// Returns an [int] by reading
  int readVHex(int max) {
    int width = (_rIndex + max > _wIndex) ? _wIndex - _rIndex : max;
    if (width <= 0) return null;
    return _readHex(1, width);
  }

  // **** Signed Integers ****

  //TODO: edit.
  /// Reads a sign code unit (+, -) and returns +1 or -1.
  /// If the next code unit is a digit then return 1, but does not
  /// advance the [_rIndex].
  int get sign {
    int c = peek;
    int sign = 1;
    if (c == kMinusSign) {
      sign = -1;
      _rIndex++;
    } else if (c == kPlusSign) {
      _rIndex++;
    }
    return sign;
  }

  /// Reads an signed [int] from [max] code units, which must be between
  /// "0" and "9" and returns the corresponding integer value. If [_buf] does
  /// not have [max] code units remaining, or if the code units corresponding
  /// to [max] do not contain digits, returns [null].
  /// [min] specifies the number of digits to read, but note that there might be
  /// an optional +/- sign, that does not count against min.
  int readInt([int min = 1, int max]) {
    if (isNotReadable) return null;
    int limit = _getRLimit(min, max);
    //TODO: decide whether to implement onErrorThrow
    if (limit == null) return null;
    int s = sign;
    int start = _rIndex;
    int n = _readUint(min, limit);
    if (n == null) {
      _rIndex = start;
      return null;
    }
    return s * n;
  }

  //DICOM max length
  int maxDecimalLength = 16;

  num get decimal => readDecimal(maxDecimalLength);

  //TODO: validate
  num readDecimal([int min = 1, int max]) {
    int limit = _getRLimit(min, max);
    if (limit == null) return null;
    int n = readInt(limit);
    if (n == null) return null;
    int f = _readFraction(1, limit);
    if (f == null) return n;
    int e = _readExponent(limit);
    if (e == null) return n + (1 / f);
    return pow(n + (1 / f), e);
  }

  int kDecimalMark = kDot;

  /// Reads a fraction starting with a [kDecimalMark].
  int _readFraction(int min, int max) {
    int limit = _getRLimit(min, max);
    if (limit == null) return null;
    int p = peek;
    //TODO: what should this do if it reads only a decimal mark, but no digit?
    // currently returns null.
    if (p != kDecimalMark || (!_isDigit(_buf[_rIndex + 2]))) return null;
    _rIndex++;
    int v = _readUint(1, max);
    if (v != null) return v;
    _rIndex--;
    return null;
  }

  int _readExponent(int limit) {
    int c = peek;
    if (c != kE || c != ke) return null;
    _rIndex++;
    return _readUint(0, limit);
  }

  // **** Read dates, times, dateTimes, and durations. ****

  //Flush??
  // DateTime today = new DateTime.now();

  bool allowVariableWidthDateTimeValues = false;
  int dateSeparator = kDash;

  int get year => checkYear(readUint(4, 4));
  int get month => checkMonth(readUint(2, 2));
  int get vMonth => checkMonth(readUint(1, 2));

  /// Reads and returns a [int] between 1 and 31, or [null]. Note: does not
  /// validate months with 28, 29, or 30 days.
  int get day => checkSimpleDay(readUint(2, 2));
  int get vDay => checkSimpleDay(readUint(1, 2));

  /// Reads and returns a valid day, given the month [m] and year [y]; otherwise, returns [null].
  int readDay(int y, int m, int d) => checkDay(y, m, readUint(2, 2));
  int readVDay(int y, int m, int d) => checkDay(y, m, readUint(1, 2));

  /// Reads and returns a date in fixed format yyyymmdd.
  Date get dicomDate {
    if (rRemaining < 8) return null;
    int y = year;
    if (y == null) return null;
    int m = month;
    if (m == null) return null;
    int d = readDay(y, m, readUint(2, 2));
    if (d == null) return null;
    _rIndex += 8;
    return new Date(y, m, d);
  }

  /// Reads and returns a date in fixed format yyyymmdd.
  Date get internetDate {
    if (rRemaining < 10) return null;
    int y = year;
    if (y == null) return null;
    if (!_matchChar(kDash)) return null;
    int m = month;
    if (m == null) return null;
    if (!_matchChar(kDash)) return null;
    int d = readDay(y, m, readUint(2, 2));
    if (d == null) return null;
    _rIndex += 10;
    return new Date(y, m, d);
  }

  int maxFractionDigits = 6;

  // Times
  int get hour => checkHour(readUint(2, 2));
  int get vHour => checkHour(readUint(1, 2));

  int get minute => checkMinute(readUint(2, 2));
  int get vMinute => checkMinute(readUint(1, 2));

  int get second => checkSecond(readUint(2, 2));
  int get vSecond => checkSecond(readUint(1, 2));

  int get fraction => checkFraction(_readFraction(1, maxFractionDigits));

  ///
  Time readDcmTime(int length) {
    int h, m, s, f;
    if (length >= 2 && hasReadable(2)) {
      h = hour;
      if (h == null) return null;
    }
    if (length >= 4 && rRemaining >= 2) {
      m = minute;
      if (m == null) return new Time(h, 0, 0);
    }
    if (length >= 6 && rRemaining >= 2) {
      s = second;
      if (s == null) return new Time(h, m, 0);
    }
    if (length >= 8 && rRemaining >= 2) {
      int f = fraction;
      if (f == null) return new Time(h, m, s);
    }
    return new Time(h, m, s, f);
  }

  ///
  Time get dicomTime {
    int h = hour;
    if (h == null) return null;
    if (!_matchChar(kColon)) return null;
    int m = minute;
    if (m == null) return null;
    if (!_matchChar(kColon)) return null;
    int s = second;
    if (s == null) return null;
    int f = fraction;
    if (f == null) return null;
    return new Time(h, m, s, f);
  }

  Time get internetTime {
    int h = hour;
    if (h == null) return null;
    if (!_matchChar(kColon)) return null;
    int m = minute;
    if (m == null) return null;
    if (!_matchChar(kColon)) return null;
    int s = second;
    if (s == null) return null;
    return new Time(h, m, s);
  }

  Time time([bool internet = false]) => (internet) ? internetTime : dicomTime;

  // **** Time Zone

  /// Reads the next character and returns -1 if it is "-",
  /// 0 if it is "Z" or "z", or 1 if it is "+"; otherwise,
  /// returns [null].
  int get tzSign {
    int sign;
    int c = peek;
    if (c == null) return null;
    if (c == kMinus) sign = -1;
    if (c == kPlus) sign = 1;
    if (c == kZ || c == kz) sign = 0;
    _rIndex++;
    return sign;
  }

  int get tzHour => checkHour(readInt(2));
  int get tzMinute => checkMinute(readInt(2));

  TimeZone get dicomTimeZone {
    int s = sign;
    if (s == null) return null;
    int h = hour;
    if (h == null) return null;
    int m = tzMinute;
    if (m == null) return null;
    return new TimeZone.fromOffset(s, h, m);
  }

  TimeZone get internetTimeZone {
    int s = tzSign;
    if (s == null) return null;
    if (s == 0) return TimeZone.utc;
    int h = hour;
    if (h == null) return null;
    int m = tzMinute;
    if (m == null) return null;
    return new TimeZone.fromOffset(s, h, m);
  }

  // **** DateTime

  DcmDateTime get dicomDateTime =>
      new DcmDateTime.fromDateAndTime_(dicomDate, dicomTime, dicomTimeZone);

  // **** Oid

  //TODO: this should have the option to do a complete check.
  String get oid => _readFilteredString(0, 64, isOidChar);

  String readUri([int start = 0, int end]) {
    //TODO: do something more efficient
    //UR - Universal Resource Identifier (URI)
    return null;
  }

  static const List<int> ageUnits = const <int>[kD, kW, kM, kY];

  String get age {
    int start = _rIndex;
    int n = readUint(3, 3);
    if (n == null) return null;
    int unit = peek;
    if (ageUnits.indexOf(unit) == null) return null;
    return substring(start, _rIndex);
  }

  String get info => '$runtimeType(0 <= $_rIndex <= $_wIndex <= $length)';

  List<String> getErrorsDA(String s) {
    String msg0 = _rangeErrorMsg(s.length, 8, 8);
    int v = num.parse(s, (String s) => null);
    String valueMsg = (v == null) ? 'Invalid Character in DS String: "$s"' : "";
    return <String>[msg0, valueMsg];
  }

  List<String> getErrorsDT(String s) {
    String msg0 = _rangeErrorMsg(s.length, 8, 8);
    int v = num.parse(s, (String s) => null);
    String valueMsg = (v == null) ? 'Invalid Character in DS String: "$s"' : "";
    return <String>[msg0, valueMsg];
  }

  List<String> getErrorsTM(String s) {
    String msg0 = _rangeErrorMsg(s.length, 0, 16);
    int v = num.parse(s, (String s) => null);
    String valueMsg = (v == null) ? 'Invalid Character in DS String: "$s"' : "";
    return <String>[msg0, valueMsg];
  }

  List<String> getErrorsUI(String s) {
    String msg0 = _rangeErrorMsg(s.length, 8, 64);
    int v = num.parse(s, (String s) => null);
    String valueMsg = (v == null) ? 'Invalid Character in DS String: "$s"' : "";
    return <String>[msg0, valueMsg];
  }

  //TODO: do something more efficient
  //UR - Universal Resource Identifier (URI)
  List<String> getErrorsUR(String s) {
    String msg0 = _rangeErrorMsg(s.length, 0, kMaxLongVF);
    Uri uri;
    try {
      uri = Uri.parse(s);
    } on FormatException catch (e) {
      return <String>[msg0, 'Invalid URI($uri) - error at offset(${e.offset}'];
    }
    // Success
    return null;
  }

  List<String> getErrorsAS(String s) {
    String msg0 = _rangeErrorMsg(s.length, 4, 4);
    int v = num.parse(s, (String s) => null);
    String valueMsg = (v == null) ? 'Invalid Character in DS String: "$s"' : "";
    return <String>[msg0, valueMsg];
  }

  @override
  String toString() => '$runtimeType: length($length)';
}

class StringReader extends Reader {
  // final List<Issue> issues = <Issue>[];
  @override
  final List<int> _buf;
  final String s;

  StringReader(this.s, [int start = 0, int end])
      : _buf = s.codeUnits,
        super(start, checkBufferLength(s.length, start, end));

  /*
  StringReader.fromList(List<int> list) : _buf = Uint16.toUint16List(list);
  */
  // ByteBuffer get buffer => _buf.buffer;

  int get elementSizeInBytes => 2;

  @override
  int get length => _wIndex - _start;

  int get lengthInBytes => length * 2;

  int get offsetInBytes => _start * 2;

  StringReader view([int start = 0, int end]) =>
      new StringReader(s, start, end);

  @override
  StringReader slice(int start, int end) => new StringReader(s, start, end);

  @override
  List<int> sublist(int start, int end) {
    end = checkBufferLength(this._wIndex, start, end);
    return _buf.sublist(start, end);
  }

  @override
  String substring(int start, int end) =>
      new String.fromCharCodes(_buf, start, end);
}

class Utf16Reader extends Reader {
  // final List<Issue> issues = <Issue>[];
  @override
  final Uint16List _buf;

  Utf16Reader(String s, [int start = 0, int end])
      : _buf = new Uint16List.fromList(s.codeUnits),
        super(start, checkBufferLength(s.length, start, end));

  Utf16Reader.fromCodeUnits(Uint16List buf, [int start = 0, int end])
      : _buf = buf,
        super(start, checkBufferLength(buf.length, start, end));

  Utf16Reader.fromList(List<int> list)
      : _buf = Uint16.toUint16List(list),
        super(0, list.length);

  ByteBuffer get buffer => _buf.buffer;

  int get elementSizeInBytes => 2;

  int get lengthInBytes => _buf.lengthInBytes;

  int get offsetInBytes => _buf.offsetInBytes;

  Utf16Reader view([int start = 0, int end]) {
    int wIndex = checkBufferLength(this._wIndex, start, end);
    Uint16List buf = _buf.buffer.asUint16List(start, end);
    return new Utf16Reader.fromCodeUnits(buf, start, wIndex);
  }

  @override
  Utf16Reader slice(int start, int end) =>
      new Utf16Reader.fromCodeUnits(_buf.buffer.asUint16List(start, end));

  @override
  List<int> sublist(int start, int end) {
    end = checkBufferLength(this._wIndex, start, end);
    return _buf.sublist(start, end);
  }

  @override
  String substring(int start, int end) =>
      new String.fromCharCodes(_buf, start, end);
}

class BytesReader extends Reader {
  //final List<Issue> issues = <Issue>[];
  @override
  final Uint8List _buf;

  BytesReader(Uint8List buf, [int start = 0, int end])
      : _buf = buf,
        super(start, checkBufferLength(buf.length, start, end));

  ByteBuffer get buffer => _buf.buffer;

  int get elementSizeInBytes => 1;

  int get lengthInBytes => _buf.lengthInBytes;

  int get offsetInBytes => _buf.offsetInBytes;

  BytesReader view([int start = 0, int end]) {
    int limit = checkBufferLength(this._wIndex, start, end);
    return new BytesReader(_buf.buffer.asUint8List(start, limit));
  }

  @override
  BytesReader slice(int start, int end) => view(start, end);

  @override
  List<int> sublist(int start, int end) {
    int limit = checkBufferLength(this._wIndex, start, end);
    return _buf.sublist(start, limit);
  }

  @override
  String substring(int start, int end) =>
      _buf.buffer.asUint8List(start, end).toString();
}

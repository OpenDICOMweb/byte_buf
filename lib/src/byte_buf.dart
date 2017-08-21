// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
library odw.sdk.byte_buf;

//TODO: add UTF8 and ASCII converters

//import 'dart:convert';

import 'dart:math';
import 'dart:typed_data';

import 'package:base/base.dart';
import 'package:date_time/date_time.dart';
//FIX: merge common/date_time with date_time/date_time
//import 'package:date_time/date_time.dart';
import 'package:number/number.dart';
import 'package:system/system.dart';

part 'reader.dart';
part 'writer.dart';

//TODO: Add a way to retrieve error messages
//TODO: Add the ability to read object (Uid, Uuid, Uri, etc.)

// names with char or Char(suffix) return [int]s.
// names with string or String(suffix) return [String]s.
// If a Readers returns [null], the [index] is not changed.

// **** helpers

/// The following must be true:
///
///     0 <= min <= length <= max <= _buf.length
///
/// But [_inRange] doesn't check
bool _inRange(int v, int min, int max) => (v < min || v > max) ? false : true;

/* Flush if not used
int _rangeError(int v, int min, int max) {
  if (_inRange(v, min, max))
    throw 'RangeError: min($min) <= Value($v) <= max($max)';
  return v;
}
*/

String _rangeErrorMsg(int v, int min, int max) => (_inRange(v, min, max))
    ? 'RangeError: min($min) <= value($v) <= max($max)'
    : null;

String _invalidChar(String s, int c, int pos) =>
    'Invalid character($c) at position($pos) in $s';

int checkBufferLength(int bufferLength, int start, int end) {
  if (end == null) end = bufferLength;
  if (end < 0 || bufferLength < end)
    throw new ArgumentError(
        "Invalid end($end) for buffer with length($bufferLength)");
  if (start < 0 || end < start)
    throw new ArgumentError("Invalid start($start) for buffer with end($end)");
  return end;
}

// **** end of helpers.

/// Reader Interface
///
/// _start = 0
/// _start <= _rIndex <= _wIndex <= _end
/// _rRemaining = _wIndex - _rIndex
/// _wRemaining = _end - _wIndex
/// isReadable = _rRemaining > 0;
/// isWritable = _wRemaining > 0;
///
abstract class ByteBuf {
  /// The current read position in the [_buf]. Must be between [_start] and [_end].
  int _rIndex;

  /// The current write position in the [_buf]. Must be between [_rIndex] and [emd].
  int _wIndex;

  ByteBuf(this._rIndex, this._wIndex);

  /// Returns the element at index [i] if [i] [_isValidRIndex]; otherwise, returns [null].
  int operator [](int i) => _buf[i];

  /// The [_buf] always [_start]s at _rIndex = 0.
  List<int> get _buf;

  /// **** Getters and Methods related to [_rIndex] and [_buf].[length].

  /// The 0Th position in the [_buf].
  int get _start => 0;

  /// Returns the index of the end of the buffer (same as length).
  int get _end => _buf.length;

  /// Returns the number of elements [E] contained in [_buf].
  int get length => _end;

  /// The current read position in the [_buf]. Starts at [_start].
  int get readIndex => _rIndex;

  /// Returns an [true] if [n] is a valid [_rIndex] in [_buf].
  bool _isValidRIndex(int n) => (0 <= n && n <= _wIndex);

  /// Returns [true] if all characters have been read, i.e. [index] [==] [_wIndex].
  int get _rRemaining => _wIndex - _rIndex;
  int get rRemaining => _rRemaining;
  bool get _isReadable => _rRemaining > 0;
  bool get isReadable => _isReadable;
  bool get isNotReadable => !_isReadable;

  /// Returns [true] if [_buf] has at least [count] code units remaining.
  bool hasReadable(int n) => _rRemaining >= n;

  int get readReset {
    _wIndex = _end;
    return _rIndex = 0;
  }

  /// Returns a valid read limit, which might be [min] <= [limit] <= [max],
  /// or [null] if no valid limit exists. [min] and [max] must be positive integers.
  int _getRLimit(int min, int max) {
    max = (max == null) ? _wIndex : max;
    if (min < 0 || max < 1) return null;
    int limit = _rIndex + max;
    if (limit > _wIndex) {
      if (_rIndex + min > _wIndex) {
        return null;
      } else {
        return _wIndex - _rIndex;
      }
    } else {
      return limit;
    }
  }

  /// The current write position in the [_buf]. Ends at [_end].
  int get writeIndex => _wIndex;
  int get _wRemaining => _end - _wIndex;
  int get wRemaining => _wRemaining;

  /// Returns an [true] if [n] is a valid [_rIndex] in [_buf].
  bool get isWritable => _wRemaining > 0;
  bool hasWritable(int n) => _wRemaining >= n;

  int get writeReset {
    _rIndex = 0;
    return _wIndex = 0;
  }

  int get minYear => 0;
  int get maxYear => 2050;
}

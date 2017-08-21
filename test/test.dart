// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

void main() {
  String s = '0123';
  List l = s.codeUnits;
  print('l is ${l.runtimeType}, ${l is Uint16List}');
  //StringReader buf = new StringReader(s);

  //print('peek(0): ${buf.peek}');

  //print('int 0123: ${buf.readUint(4, 4)}');
}

// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:byte_buf/byte_buf.dart';
import 'package:test/test.dart';

void main() {
  simpleReadTest();
  stringReaderTest();
}

void simpleReadTest() {
  test("Empty Buffer Test", () {
    String s0 = "";
    Utf16Reader buf = new Utf16Reader(s0);
    //  print(buf.info);
    int length = s0.length;

    // check length, index, and simple read error
    expect(buf.length, equals(length));
    expect(buf.readIndex, equals(0));
    expect(buf.read, equals(null));
    expect(buf.readIndex, equals(0));

    // check skip on 0 length buffer
    expect(buf.skip(1), equals(false));
    expect(buf.skip(-1), equals(false));
    expect(buf.readIndex, equals(0));
  });

  test("Simple String Read Test", () {
    String s1 = "abcdefg";
    Utf16Reader buf = new Utf16Reader(s1);
    int length = s1.length;

    expect(buf.length, equals(length));
    // read one character at a time
    expect(buf.read, equals("a".codeUnitAt(0)));
    expect(buf.read, equals("b".codeUnitAt(0)));
    expect(buf.read, equals("c".codeUnitAt(0)));
    expect(buf.read, equals("d".codeUnitAt(0)));
    expect(buf.read, equals("e".codeUnitAt(0)));
    expect(buf.read, equals("f".codeUnitAt(0)));
    expect(buf.read, equals("g".codeUnitAt(0)));
    expect(buf.read, equals(null));
    buf.skip(-2);
    expect(buf.read, equals("f".codeUnitAt(0)));
    expect(buf.read, equals("g".codeUnitAt(0)));

    buf.skip(-length);
    expect(buf.read, equals("a".codeUnitAt(0)));
    expect(buf.read, equals("b".codeUnitAt(0)));
  });

  test("Uint Simple Read Test", () {
    String s;
    int length;
    Utf16Reader buf;

    s = "000";
    length = s.length;
    buf = new Utf16Reader(s);
    expect(buf.length, equals(length));
    expect(buf.read, equals("0".codeUnitAt(0)));
    expect(buf.readUint(2, 2), equals(0));
    expect(buf.readUint(0, 3), equals(0));
    expect(buf.readUint(4, 4), equals(null));

    s = "1234";
    length = s.length;
    buf = new Utf16Reader(s);
    expect(buf.length, equals(length));
    expect(buf.read, equals("1".codeUnitAt(0)));
    buf.readReset;
    buf.info;
    expect(buf.readUint(1, 1), equals(1));
    expect(buf.readUint(1, 1), equals(2));
    buf.readReset;
    expect(buf.readUint(2, 2), equals(12));
    buf.readReset;
    expect(buf.readUint(0, 3), equals(123));
    buf.readReset;
    expect(buf.readUint(4, 4), equals(1234));
    // TODO make this catch the error
    //expect(buf.readUint(1, 4), equals(null));

    s = "12a3";
    buf = new Utf16Reader(s);
    expect(buf.readUint(2, 2), equals(12));
    expect(buf.readUint(3, 3), equals(null));
  });

  test("Uint Read Test", () {
    String s;
    int length;
    Utf16Reader buf;

    s = "00000";
    length = s.length;
    buf = new Utf16Reader(s);
    expect(buf.length, equals(length));
    expect(buf.read, equals("0".codeUnitAt(0)));
    buf.readReset;
    expect(buf.readUint(5, 5), equals(0));
    buf.readReset;
    expect(buf.readUint(6, 6), equals(null));

    s = "123456";
    buf = new Utf16Reader(s);
    expect(buf.readUint(1, 1), equals(1));
    buf.readReset;
    //  print('reset: ${buf.info}');
    int v = buf.readUint(2, 2);
    expect(v, equals(12));
    buf.readReset;
    expect(buf.readUint(3, 3), equals(123));
    buf.readReset;
    expect(buf.readUint(4, 4), equals(1234));
    buf.readReset;
    expect(buf.readUint(5, 5), equals(12345));
    buf.readReset;
    expect(buf.readUint(6, 6), equals(123456));
    buf.readReset;
    expect(buf.readUint(7, 7), equals(null));

    s = "12a3";
    buf = new Utf16Reader(s);
    expect(buf.readUint(-1, -1), equals(null));
    expect(buf.readUint(0, 0), equals(null));
    expect(buf.readUint(2, 2), equals(12));
    buf.readReset;
    expect(buf.readUint(3, 3), equals(null));
    buf.readReset;
    expect(buf.readUint(2, 3), equals(12));
    buf.readReset;
    expect(buf.readUint(2, 4), equals(12));
  });

  test("Int Read Test", () {
    String s;
    int length;
    Utf16Reader buf;

    s = "+1";
    length = s.length;
    buf = new Utf16Reader(s);
    expect(buf.length, equals(length));
    expect(buf.read, equals("+".codeUnitAt(0)));
    expect(buf.read, equals("1".codeUnitAt(0)));
    buf.readReset;
    expect(buf.readIndex, equals(0));
    //  print('readIndex: ${buf.readIndex}');
    //  print('x: ${buf.readInt(1)}');
    buf.readReset;
    expect(buf.readInt(1), equals(1));
    buf.readReset;
    expect(buf.readInt(2), equals(null));

    s = "-1";
    length = s.length;
    buf = new Utf16Reader(s);
    expect(buf.length, equals(length));
    expect(buf.read, equals("-".codeUnitAt(0)));
    buf.readReset;
    expect(buf.readInt(1), equals(-1));

    s = "1";
    length = s.length;
    buf = new Utf16Reader(s);
    expect(buf.length, equals(length));
    expect(buf.read, equals("1".codeUnitAt(0)));
    buf.readReset;
    expect(buf.readInt(1), equals(1));
  });

  test("Hex Read Test", () {
    String s;
    int length;
    Utf16Reader buf;

    s = "0a";
    length = s.length;
    buf = new Utf16Reader(s);
    expect(buf.length, equals(length));
    // expect(buf.read, equals("0".codeUnitAt(0)));
    expect(buf.hex, equals(0));
    expect(buf.hex, equals(10));
    buf.readReset;
    expect(buf.readHex(2), equals(0xa));

    s = "abcdef";
    length = s.length;
    buf = new Utf16Reader(s);
    expect(buf.length, equals(length));
    expect(buf.readHex(0), equals(null));
    expect(buf.readHex(1), equals(0xa));
    buf.readReset;
    expect(buf.readHex(2), equals(0xab));
    buf.readReset;
    expect(buf.readHex(3), equals(0xabc));
    buf.readReset;
    expect(buf.readHex(4), equals(0xabcd));
    buf.readReset;
    expect(buf.readHex(5), equals(0xabcde));
    buf.readReset;
    expect(buf.readHex(6), equals(0xabcdef));
    buf.readReset;
    expect(buf.readHex(7), equals(null));

    s = "0a1b2c3d4e5f";
    length = s.length;
    buf = new Utf16Reader(s);
    expect(buf.length, equals(length));
    expect(buf.readHex(0), equals(null));
    expect(buf.readHex(2), equals(0x0a));
    buf.readReset;
    expect(buf.readHex(4), equals(0x0a1b));
    buf.readReset;
    expect(buf.readHex(6), equals(0x0a1b2c));
    buf.readReset;
    expect(buf.readHex(8), equals(0x0a1b2c3d));
    buf.readReset;
    expect(buf.readHex(10), equals(0x0a1b2c3d4e));
    buf.readReset;
    expect(buf.readHex(12), equals(0x0a1b2c3d4e5f));
    buf.readReset;
    expect(buf.readHex(14), equals(null));

    s = "0a1b2c3d4e5f";
    length = s.length;
    buf = new Utf16Reader(s);
    expect(buf.length, equals(length));
    expect(buf.readVHex(0), equals(null));
    buf.readReset;
    expect(buf.readVHex(2), equals(0x0a));
    buf.readReset;
    expect(buf.readVHex(3), equals(0x0a1));
    buf.readReset;
    expect(buf.readVHex(5), equals(0x0a1b2));
    buf.readReset;
    expect(buf.readVHex(6), equals(0x0a1b2c));
    buf.readReset;
    expect(buf.readVHex(8), equals(0x0a1b2c3d));
    buf.readReset;
    expect(buf.readVHex(9), equals(0x0a1b2c3d4));
    buf.readReset;
    expect(buf.readVHex(14), equals(0x0a1b2c3d4e5f));
  });
}

void readVUintTest() {
  test("Read VUint Test", () {
    String s0 = "";
    Utf16Reader buf = new Utf16Reader(s0);
    int length = s0.length;

    // check length, readIndex, and simple read error
    expect(buf.length, equals(length));
    expect(buf.readIndex, equals(0));
    expect(buf.read, equals(null));
    expect(buf.readIndex, equals(0));

    // check skip on 0 length buffer
    expect(buf.skip(1), equals(null));
    expect(buf.skip(-1), equals(null));
    expect(buf.readIndex, equals(0));
  });
}

void stringReaderTest() {
  test("string reader test", () {
    String s0 = "abcdefghijklmnopqr";
    StringReader sr = new StringReader(s0);
    expect(sr.length == s0.length, true);
    //print('sr length: ${sr.length}');
    //sr.elementSizeInBytes;
    //print('sr each char size: ${sr.elementSizeInBytes}');
    expect(sr.lengthInBytes, equals(s0.length * sr.elementSizeInBytes));
    expect(sr.offsetInBytes == 0, true);
    //sr.slice(4,6);

    print((sr.slice(4, 6)));
    StringReader sr1 = new StringReader(s0, 5);
    expect(
        sr1.length ==
            (s0.length - (sr1.offsetInBytes / sr1.elementSizeInBytes)),
        true); //==s0.length,true);

    expect(sr.lengthInBytes, equals(s0.length * 2));
  });
}

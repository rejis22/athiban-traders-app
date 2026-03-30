// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BillItemAdapter extends TypeAdapter<BillItem> {
  @override
  final int typeId = 2;

  @override
  BillItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BillItem(
      product: fields[0] as Product?,
      productName: fields[1] as String,
      quantity: fields[2] as double,
      price: fields[3] as double,
      discount: fields[4] as double,
      total: fields[5] as double,
      hsnCode: fields[6] as String,
      taxRate: fields[7] as double,
      discountPercentage: fields[8] as double,
      cgst: fields[9] as double,
      sgst: fields[10] as double,
      igst: fields[11] as double,
    );
  }

  @override
  void write(BinaryWriter writer, BillItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.product)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.discount)
      ..writeByte(5)
      ..write(obj.total)
      ..writeByte(6)
      ..write(obj.hsnCode)
      ..writeByte(7)
      ..write(obj.taxRate)
      ..writeByte(8)
      ..write(obj.discountPercentage)
      ..writeByte(9)
      ..write(obj.cgst)
      ..writeByte(10)
      ..write(obj.sgst)
      ..writeByte(11)
      ..write(obj.igst);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BillAdapter extends TypeAdapter<Bill> {
  @override
  final int typeId = 3;

  @override
  Bill read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Bill(
      id: fields[0] as String,
      billNumber: fields[1] as String,
      date: fields[2] as DateTime,
      customer: fields[3] as Customer?,
      customerName: fields[12] as String?,
      customerPhone: fields[13] as String?,
      customerAddress: fields[14] as String?,
      items: (fields[4] as List).cast<BillItem>(),
      subTotal: fields[5] as double,
      taxRate: fields[6] as double,
      taxAmount: fields[7] as double,
      discount: fields[8] as double,
      roundOff: fields[9] as double,
      grandTotal: fields[10] as double,
      isSynced: fields[11] as bool,
      cgst: fields[15] as double,
      sgst: fields[16] as double,
      igst: fields[17] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Bill obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.billNumber)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.customer)
      ..writeByte(12)
      ..write(obj.customerName)
      ..writeByte(13)
      ..write(obj.customerPhone)
      ..writeByte(14)
      ..write(obj.customerAddress)
      ..writeByte(4)
      ..write(obj.items)
      ..writeByte(5)
      ..write(obj.subTotal)
      ..writeByte(6)
      ..write(obj.taxRate)
      ..writeByte(7)
      ..write(obj.taxAmount)
      ..writeByte(8)
      ..write(obj.discount)
      ..writeByte(9)
      ..write(obj.roundOff)
      ..writeByte(10)
      ..write(obj.grandTotal)
      ..writeByte(11)
      ..write(obj.isSynced)
      ..writeByte(15)
      ..write(obj.cgst)
      ..writeByte(16)
      ..write(obj.sgst)
      ..writeByte(17)
      ..write(obj.igst);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

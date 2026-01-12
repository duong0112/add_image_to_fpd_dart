import 'package:flutter/material.dart';

import 'table_new_v3.dart';

class DemoTableV3 extends StatelessWidget {
  DemoTableV3({super.key});
  final defaultCols = [
    TableColumnConfig(
      key: 'id',
      title: 'ID',
      width: 80,
    ),
    TableColumnConfig(
      key: 'name',
      title: 'Name',
      width: 180,
    ),
    TableColumnConfig(
      key: 'age',
      title: 'Age',
      width: 80,
    ),
    TableColumnConfig(
      key: 'email',
      title: 'Email',
      width: 240,
      hideOnSmallScreen: true,
    ),
    TableColumnConfig(
      key: 'joined',
      title: 'Joined Date',
      width: 160,
    ),
    TableColumnConfig(
      key: 'salary',
      title: 'Salary',
      width: 140,
    ),
  ];

  final rows = [
    {
      'id': 1,
      'name': 'Nguyễn Văn An',
      'age': 29,
      'email': 'an.nguyen@example.com',
      'joined': DateTime(2023, 5, 15),
      'salary': 1350,
    },
    {
      'id': 2,
      'name': 'Trần Thị Bình',
      'age': 24,
      'email': 'binh.tran@example.com',
      'joined': DateTime(2022, 7, 8),
      'salary': 1500,
    },
    {
      'id': 3,
      'name': 'Hoàng Đình Cường',
      'age': 32,
      'email': 'cuong.hoang@example.com',
      'joined': DateTime(2021, 12, 20),
      'salary': 1780,
    },
    {
      'id': 4,
      'name': 'Phạm Thảo',
      'age': 27,
      'email': 'thao.pham@example.com',
      'joined': DateTime(2023, 2, 1),
      'salary': 1620,
    },
    {
      'id': 5,
      'name': 'Đỗ Minh Đức',
      'age': 30,
      'email': 'duc.do@example.com',
      'joined': DateTime(2020, 10, 10),
      'salary': 1850,
    },
    {
      'id': 6,
      'name': 'Nguyễn Thị Hường',
      'age': 26,
      'email': 'huong.nguyen@example.com',
      'joined': DateTime(2023, 8, 21),
      'salary': 1450,
    },
    {
      'id': 7,
      'name': 'Lê Anh Tuấn',
      'age': 22,
      'email': 'tuan.le@example.com',
      'joined': DateTime(2024, 1, 5),
      'salary': 1200,
    },
    {
      'id': 8,
      'name': 'Phan Thanh Tâm',
      'age': 35,
      'email': 'tam.phan@example.com',
      'joined': DateTime(2018, 4, 18),
      'salary': 2100,
    },
    {
      'id': 9,
      'name': 'Võ Hoài Nam',
      'age': 28,
      'email': 'nam.vo@example.com',
      'joined': DateTime(2021, 3, 2),
      'salary': 1580,
    },
    {
      'id': 10,
      'name': 'Dương Minh Khoa',
      'age': 31,
      'email': 'khoa.duong@example.com',
      'joined': DateTime(2022, 12, 11),
      'salary': 1720,
    },
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Advanced Table Demo")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TableNewV3(
          initialConfigs: defaultCols,
          rows: rows,
        ),
      ),
    );
  }
}

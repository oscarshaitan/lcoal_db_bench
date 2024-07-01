import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_db_benchmark/bench_clasess.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Benchmark(),
    );
  }
}

class Benchmark extends StatefulWidget {
  const Benchmark({super.key});

  @override
  State<Benchmark> createState() => _BenchmarkState();
}

class _BenchmarkState extends State<Benchmark> {
  late BenchmarkDataList _benchmarkDataList;
  late List<BenchmarkData> _benchmarkData;
  List<List<int>> _benchmarkImages = [];
  late final SharedPreferences _sp;
  late final Database _db;
  late Box<List<int>> _imagesBox;
  final _store = intMapStoreFactory.store();
  final TextEditingController countBench = TextEditingController(text: '1000');
  final TextEditingController countProduct = TextEditingController(text: '3');
  final TextEditingController countImages = TextEditingController(text: '3');
  final TextEditingController imagesSizeController = TextEditingController(text: '350');
  final PageController pageControllerBench = PageController();
  final PageController pageControllerCharts = PageController();
  final PageController pageControllerCharts2 = PageController();

  late int _key;

  final List<int> _keys = [];
  final List<int> _imagesKeys = [];
  bool blocRuns = false;
  bool spCreated = false;
  bool sbCreated = false;
  bool hiveCreated = false;
  bool showChart = true;
  int countOfBenchData = 1000;
  int countOfProducts = 3;
  int countOfImages = 3;
  int sizeOfImagesKB = 350;
  int writeTimeSP = 0;
  int readTimeSP = 0;
  int deleteTimeSP = 0;
  int writeTimeSB = 0;
  int readTimeSB = 0;
  int deleteTimeSB = 0;
  int writeTimeSBImages = 0;
  int readTimeSBImages = 0;
  int deleteTimeSBImages = 0;

  int writeTimeHiveImages = 0;
  int readTimeHiveImages = 0;
  int deleteTimeHiveImages = 0;

  bool get _canRun => !blocRuns && sbCreated && spCreated && hiveCreated;

  @override
  initState() {
    SharedPreferences.getInstance().then((sp) {
      _sp = sp;
      spCreated = true;
      print('SP created');
    });

    Hive.initFlutter().then((_) {
      Hive.openBox<List<int>>('images').then((box) {
        _imagesBox = box;
        setState(() {
          hiveCreated = true;
          print('Hive created');
        });
      });
    });

    _createSB().then((_) {
      setState(() {
        sbCreated = true;
        print('SB created');
      });
    });
    super.initState();
  }

  _createSB() async {
    if (kIsWeb) {
      var factory = databaseFactoryWeb;
      _db = await factory.openDatabase('my_database_web.db');
    }else{
      var dir = await getApplicationDocumentsDirectory();
      await dir.create(recursive: true);
      var dbPath = join(dir.path, 'my_database.db');
      _db = await databaseFactoryIo.openDatabase(dbPath);
    }
  }

  BarChartGroupData writeGroupData(int writeSP, int writeSB) {
    return BarChartGroupData(
      barsSpace: 4,
      x: 0,
      barRods: [
        BarChartRodData(
          toY: writeSP.toDouble(),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
          color: Colors.green,
          width: 32,
        ),
        BarChartRodData(
          toY: writeSB.toDouble(),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
          color: Colors.blue,
          width: 32,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benchmark'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: () {
                    pageControllerBench.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.linear);
                  },
                  child: Text('Data test')),
              ElevatedButton(
                  onPressed: () {
                    pageControllerBench.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.linear);
                  },
                  child: Text('Images test')),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                const Text('Show chart'),
                Switch(
                    value: showChart,
                    onChanged: (value) {
                      setState(() {
                        showChart = value;
                      });
                    }),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: pageControllerBench,
              children: [_getCrudBench(), _getImageBench()],
            ),
          ),
        ],
      ),
    );
  }

  Column _getImageBench() {
    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: showChart
                ? Column(
                    children: [
                      Wrap(spacing: 16, children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'SB',
                              style: TextStyle(
                                color: Color(0xff757391),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Hive',
                              style: TextStyle(
                                color: Color(0xff757391),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      ]),
                      Expanded(
                        child: Stack(
                          children: [
                            PageView(
                              controller: pageControllerCharts2,
                              children: [
                                _getWriteImageChart(),
                                _getReadImageChart(),
                                _getDeleteImageChart(),
                              ],
                            ),
                            Positioned(
                                top: 0,
                                bottom: 0,
                                left: 0,
                                child: InkWell(
                                    onTap: () {
                                      pageControllerCharts2.previousPage(
                                          duration: const Duration(milliseconds: 250), curve: Curves.linear);
                                    },
                                    child: const Icon(
                                      Icons.chevron_left,
                                      size: 40,
                                    ))),
                            Positioned(
                                top: 0,
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                    onTap: () {
                                      pageControllerCharts2.nextPage(
                                          duration: const Duration(milliseconds: 250), curve: Curves.linear);
                                    },
                                    child: const Icon(
                                      Icons.chevron_right_outlined,
                                      size: 40,
                                    )))
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Write Time',
                        style: TextStyle(fontSize: 24),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            'SB: ${writeTimeSBImages}ms',
                            style: const TextStyle(fontSize: 24),
                          ),
                          Text(
                            'Hive: ${writeTimeHiveImages}ms',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                      const Text(
                        'Read Time',
                        style: TextStyle(fontSize: 24),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            'SB: ${readTimeSBImages}ms',
                            style: const TextStyle(fontSize: 24),
                          ),
                          Text(
                            'Hive:  ${readTimeHiveImages}ms',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                      const Text(
                        'Delete Time',
                        style: TextStyle(fontSize: 24),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            'SB: ${deleteTimeSBImages}ms',
                            style: const TextStyle(fontSize: 24),
                          ),
                          Text(
                            'Hive: ${deleteTimeHiveImages}ms',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: countImages,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('# Images'),
                    hintText: 'Number of Images',
                  ),
                  onChanged: (value) {
                    setState(() {
                      countOfImages = int.parse(value == '' ? '0' : value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8, height: 1),
              Expanded(
                child: TextField(
                  controller: imagesSizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('Size of Images in KB'),
                    hintText: 'Size of images KB',
                  ),
                  onChanged: (value) {
                    setState(() {
                      sizeOfImagesKB = int.parse(value == '' ? '0' : value);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
            onPressed: _canRun
                ? () async {
                    setState(() {
                      writeTimeSBImages = 0;
                      readTimeSBImages = 0;
                      deleteTimeSBImages = 0;
                      writeTimeHiveImages = 0;
                      readTimeHiveImages = 0;
                      deleteTimeHiveImages = 0;
                    });
                    Future.wait([imagesBenchSB(), imagesBenchHive()]).then((_) {
                      setState(() {
                        blocRuns = false;
                      });
                    });
                  }
                : null,
            child: const Text('Run Image bench')),
      ],
    );
  }

//region UI

  Column _getCrudBench() {
    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: showChart
                ? Column(
                    children: [
                      Wrap(spacing: 16, children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'SP',
                              style: TextStyle(
                                color: Color(0xff757391),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'SB',
                              style: TextStyle(
                                color: Color(0xff757391),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      ]),
                      Expanded(
                        child: Stack(
                          children: [
                            PageView(
                              controller: pageControllerCharts,
                              children: [
                                _getWriteChart(),
                                _getReadChart(),
                                _getDeleteChart(),
                              ],
                            ),
                            Positioned(
                                top: 0,
                                bottom: 0,
                                left: 0,
                                child: InkWell(
                                    onTap: () {
                                      pageControllerCharts.previousPage(
                                          duration: const Duration(milliseconds: 250), curve: Curves.linear);
                                    },
                                    child: const Icon(
                                      Icons.chevron_left,
                                      size: 40,
                                    ))),
                            Positioned(
                                top: 0,
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                    onTap: () {
                                      pageControllerCharts.nextPage(
                                          duration: const Duration(milliseconds: 250), curve: Curves.linear);
                                    },
                                    child: const Icon(
                                      Icons.chevron_right_outlined,
                                      size: 40,
                                    )))
                          ],
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Write Time',
                          style: TextStyle(fontSize: 24),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              'SP: ${writeTimeSP}ms',
                              style: const TextStyle(fontSize: 24),
                            ),
                            Text(
                              'SB: ${writeTimeSB}ms',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ],
                        ),
                        const Text(
                          'Read Time',
                          style: TextStyle(fontSize: 24),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              'SP: ${readTimeSP}ms',
                              style: const TextStyle(fontSize: 24),
                            ),
                            Text(
                              'SB:  ${readTimeSB}ms',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ],
                        ),
                        const Text(
                          'Delete Time',
                          style: TextStyle(fontSize: 24),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              'SB: ${deleteTimeSB}ms',
                              style: const TextStyle(fontSize: 24),
                            ),
                            Text(
                              'SP: ${deleteTimeSP}ms',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: countBench,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('# BenchmarkData'),
                    hintText: 'Number of BenchmarkData',
                  ),
                  onChanged: (value) {
                    setState(() {
                      countOfBenchData = int.parse(value == '' ? '0' : value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8, height: 1),
              Expanded(
                child: TextField(
                  controller: countProduct,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('# Products'),
                    hintText: 'Number of Products on each BenchmarkData',
                  ),
                  onChanged: (value) {
                    setState(() {
                      countOfProducts = int.parse(value == '' ? '0' : value);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
            onPressed: _canRun
                ? () async {
                    setState(() {
                      blocRuns = true;
                    });
                    await _clearDBs();
                    setState(() {
                      writeTimeSP = 0;
                      readTimeSP = 0;
                      deleteTimeSP = 0;
                      writeTimeSB = 0;
                      readTimeSB = 0;
                      deleteTimeSB = 0;
                    });
                    Future.wait([spBenchmarkDataList(), sembastBenchmarkDataList()]).then((_) {
                      setState(() {
                        blocRuns = false;
                      });
                    });
                  }
                : null,
            child: const Text('Run BenchmarkDataList')),
        const Text('BenchmarkDataList is a class with a list of BenchmarkData '),
        ElevatedButton(
            onPressed: _canRun
                ? () async {
                    setState(() {
                      blocRuns = true;
                    });
                    await _clearDBs();
                    setState(() {
                      writeTimeSP = 0;
                      readTimeSP = 0;
                      deleteTimeSP = 0;
                      writeTimeSB = 0;
                      readTimeSB = 0;
                      deleteTimeSB = 0;
                    });
                    Future.wait([spBenchmarkList(), sbBenchmarkList()]).then((_) {
                      setState(() {
                        blocRuns = false;
                      });
                    });
                  }
                : null,
            child: const Text('Run List BenchmarkData')),
        const Text('using a List<BenchmarkData> directly'),
        ElevatedButton(
            onPressed: _canRun
                ? () async {
                    setState(() {
                      blocRuns = true;
                    });
                    await _clearDBs();
                    setState(() {
                      writeTimeSP = 0;
                      readTimeSP = 0;
                      deleteTimeSP = 0;
                      writeTimeSB = 0;
                      readTimeSB = 0;
                      deleteTimeSB = 0;
                      blocRuns = false;
                    });
                  }
                : null,
            child: const Text('Clear')),
      ],
    );
  }

  Future<void> _clearDBs() async {
    await _sp.clear();
    await _store.drop(_db);
    await _imagesBox.clear();
  }

  Container _getDeleteChart() {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: BarChart(
        BarChartData(
          maxY: max(deleteTimeSP.toDouble(), deleteTimeSB.toDouble()) * 1.2,
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: const Text('Delete'),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [writeGroupData(deleteTimeSP, deleteTimeSB)],
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  Container _getReadChart() {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: BarChart(
        BarChartData(
          maxY: max(readTimeSP.toDouble(), readTimeSB.toDouble()) * 1.2,
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: const Text('Read'),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            writeGroupData(readTimeSP, readTimeSB),
          ],
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  Container _getWriteChart() {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: BarChart(
        BarChartData(
          maxY: max(writeTimeSP.toDouble(), writeTimeSB.toDouble()) * 1.2,
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: const Text('Write'),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            writeGroupData(writeTimeSP, writeTimeSB),
          ],
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  Container _getWriteImageChart() {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: BarChart(
        BarChartData(
          maxY: max(writeTimeSBImages.toDouble(), writeTimeHiveImages.toDouble()) * 1.2,
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: const Text('Write'),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            writeGroupData(writeTimeSBImages, writeTimeHiveImages),
          ],
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  Container _getDeleteImageChart() {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: BarChart(
        BarChartData(
          maxY: max(deleteTimeSBImages.toDouble(), deleteTimeHiveImages.toDouble()) * 1.2,
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: const Text('Delete'),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [writeGroupData(deleteTimeSBImages, deleteTimeHiveImages)],
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  Container _getReadImageChart() {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: BarChart(
        BarChartData(
          maxY: max(readTimeSBImages.toDouble(), readTimeHiveImages.toDouble()) * 1.2,
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: const Text('Read'),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            writeGroupData(readTimeSBImages, readTimeHiveImages),
          ],
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

//endregion

//region ImagesBench

  Future<void> imagesBenchSB() async {
    _imagesKeys.clear();
    print('imagesBenchSB');
    setState(() {
      blocRuns = true;
    });

    _benchmarkImages = generateRandomImageBytesList(countOfImages);
    final stopwatch = Stopwatch()..start();
    await Future.wait(_benchmarkImages.map((image) async {
      return _imagesKeys.add(await _store.add(_db, {'bytes': image}));
    }));

    stopwatch.stop();

    setState(() {
      writeTimeSBImages = stopwatch.elapsedMilliseconds;
    });
    readImagesBenchSB();
  }

  Future<void> readImagesBenchSB() async {
    print('readImagesBenchSB');
    final stopwatch = Stopwatch()..start();
    await Future.wait(_imagesKeys.map((key) async {
      return (await _store.record(key).get(_db))!['bytes'];
    }));

    stopwatch.stop();

    setState(() {
      readTimeSBImages = stopwatch.elapsedMilliseconds;
    });
    deleteImagesBenchSB();
  }

  Future<void> deleteImagesBenchSB() async {
    print('deleteImagesBenchSB');
    final stopwatch = Stopwatch()..start();
    await Future.wait(_imagesKeys.map((key) async {
      return await _store.record(key).delete(_db);
    }));

    stopwatch.stop();

    setState(() {
      deleteTimeSBImages = stopwatch.elapsedMilliseconds;
    });
  }

  Future<void> imagesBenchHive() async {
    print('imagesBenchHive');
    setState(() {
      blocRuns = true;
    });
    final stopwatch = Stopwatch()..start();
    await Future.wait(_benchmarkImages.mapIndexed((index, image) async {
      return await _imagesBox.put('$index', image);
    }));

    stopwatch.stop();

    setState(() {
      writeTimeHiveImages = stopwatch.elapsedMilliseconds;
    });
    readImagesBenchHive();
  }

  Future<void> readImagesBenchHive() async {
    print('readImagesBenchHive');
    final stopwatch = Stopwatch()..start();
    await Future.wait(_benchmarkImages.mapIndexed((index, image) async {
      return _imagesBox.get('$index');
    }));

    stopwatch.stop();

    setState(() {
      readTimeHiveImages = stopwatch.elapsedMilliseconds;
    });
    deleteImagesBenchHive();
  }

  Future<void> deleteImagesBenchHive() async {
    print('deleteImagesBenchHive');
    final stopwatch = Stopwatch()..start();
    await Future.wait(_benchmarkImages.mapIndexed((index, image) async {
      return _imagesBox.delete('$index');
    }));

    stopwatch.stop();

    setState(() {
      deleteTimeHiveImages = stopwatch.elapsedMilliseconds;
    });
  }

//endregion
//region SB

  Future<void> sembastBenchmarkDataList() async {
    print('sembastBenchmarkDataList');
    setState(() {
      blocRuns = true;
    });
    _benchmarkDataList = _generateBenchmarkDataList(countOfBenchData);

    final stopwatch = Stopwatch()..start();
    var key = await _store.add(_db, _benchmarkDataList.toJson());
    stopwatch.stop();

    setState(() {
      _key = key;
      writeTimeSB = stopwatch.elapsedMilliseconds;
    });
    readSembastBenchmarkDataList();
  }

  readSembastBenchmarkDataList() async {
    print('readSembastBenchmarkDataList');
    final stopwatch = Stopwatch()..start();

    var readMap = await _store.record(_key).get(_db);
    BenchmarkDataList.fromJson(readMap!);
    stopwatch.stop();

    setState(() {
      readTimeSB = stopwatch.elapsedMilliseconds;
    });
    deleteSembastBenchmarkDataList();
  }

  Future<void> deleteSembastBenchmarkDataList() async {
    print('deleteSembastBenchmarkDataList');
    final stopwatch = Stopwatch()..start();
    await _store.record(_key).delete(_db);
    stopwatch.stop();
    setState(() {
      deleteTimeSB = stopwatch.elapsedMilliseconds;
    });
  }

  Future<void> sbBenchmarkList() async {
    print('sbBenchmarkList');
    _keys.clear();
    setState(() {
      blocRuns = true;
    });
    _benchmarkData = _generateBenchmarkData(countOfBenchData);

    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < countOfBenchData; i++) {
      _keys.add(await _store.add(_db, _benchmarkData[i].toJson()));
    }

    stopwatch.stop();

    setState(() {
      writeTimeSB = stopwatch.elapsedMilliseconds;
    });
    readBenchmarkListSembast();
  }

  readBenchmarkListSembast() async {
    print('readBenchmarkListSembast');
    final stopwatch = Stopwatch()..start();

    for (var i = 0; i < countOfBenchData; i++) {
      var readMap = await _store.record(_keys[i]).get(_db);
      BenchmarkData.fromJson(readMap!);
    }

    stopwatch.stop();

    setState(() {
      readTimeSB = stopwatch.elapsedMilliseconds;
    });
    deleteSembast();
  }

  Future<void> deleteSembast() async {
    print('deleteSembast');
    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < countOfBenchData; i++) {
      await _store.record(_keys[i]).delete(_db);
    }
    stopwatch.stop();
    setState(() {
      deleteTimeSB = stopwatch.elapsedMilliseconds;
    });
  }

//endregion

//region SP
  Future<void> spBenchmarkDataList() async {
    print('spBenchmarkDataList');
    setState(() {
      blocRuns = true;
    });
    _benchmarkDataList = _generateBenchmarkDataList(countOfBenchData);

    final stopwatch = Stopwatch()..start();

    var encodeData = jsonEncode(_benchmarkDataList.toJson());
    await _sp.setString('determinsitic', encodeData);
    stopwatch.stop();

    setState(() {
      writeTimeSP = stopwatch.elapsedMilliseconds;
    });
    readSharedPreferences();
  }

  readSharedPreferences() {
    print('readSharedPreferences');
    final stopwatch = Stopwatch()..start();
    var encodedData = _sp.getString('determinsitic');
    var decodedData = jsonDecode(encodedData!);
    BenchmarkDataList.fromJson(decodedData);
    stopwatch.stop();

    setState(() {
      readTimeSP = stopwatch.elapsedMilliseconds;
    });
    deleteSharedPreferences();
  }

  Future<void> deleteSharedPreferences() async {
    print('deleteSharedPreferences');
    final stopwatch = Stopwatch()..start();
    await _sp.remove('determinsitic');
    stopwatch.stop();
    setState(() {
      deleteTimeSP = stopwatch.elapsedMilliseconds;
    });
  }

  Future<void> spBenchmarkList() async {
    print('spBenchmarkList');
    setState(() {
      blocRuns = true;
    });
    _benchmarkData = _generateBenchmarkData(countOfBenchData);

    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < countOfBenchData; i++) {
      var encodeData = jsonEncode(_benchmarkData[i].toJson());

      await _sp.setString('dataKey_$i', encodeData);
    }

    stopwatch.stop();

    setState(() {
      writeTimeSP = stopwatch.elapsedMilliseconds;
    });
    readBenchmarkListSharedPreferences();
  }

  readBenchmarkListSharedPreferences() {
    print('readBenchmarkListSharedPreferences');
    final stopwatch = Stopwatch()..start();

    for (var i = 0; i < countOfBenchData; i++) {
      var encodedData = _sp.getString('dataKey_$i');
      var decodedData = jsonDecode(encodedData!);
      BenchmarkData.fromJson(decodedData);
    }

    stopwatch.stop();

    setState(() {
      readTimeSP = stopwatch.elapsedMilliseconds;
    });
    deleteSharedPreferences();
  }

  Future<void> deleteBenchmarkListSharedPreferences() async {
    print('deleteBenchmarkListSharedPreferences');
    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < countOfBenchData; i++) {
      await _sp.remove('dataKey_$i');
    }
    stopwatch.stop();
    setState(() {
      deleteTimeSP = stopwatch.elapsedMilliseconds;
    });
  }

//endregion

//region Bench DATA
  BenchmarkDataList _generateBenchmarkDataList(int iterations) {
    final benchmarkData = _generateBenchmarkData(iterations);

    return BenchmarkDataList(data: benchmarkData);
  }

  List<BenchmarkData> _generateBenchmarkData(int iterations) {
    final sizeMap = {'S': 10, 'M': 5, 'L': 2};

    final benchmarkData = List.generate(
        iterations,
        (index) => BenchmarkData(
              name: 'Product $index',
              id: index,
              price: 10.0 * (index % 10),
              isActive: index % 2 == 0,
              colors: [
                'Red',
                'Green',
                'Blue',
                'Yellow',
                'Orange',
                'Purple',
                'Pink',
                'Black',
                'White',
                'Gray',
                'Teal',
                'Navy',
                'Maroon',
                'Silver',
                'Gold',
                'Olive',
                'Lime',
                'Aqua',
                'Fuchsia',
                'Violet',
              ],
              sizes: sizeMap,
              createdAt: DateTime(2024, 6, 1).add(Duration(days: index)),
              imageUrl: Uri.parse('https://example.com/image.jpg'),
              /* imageBytesList: generateRandomImageBytesList(countOfImages),*/
              products: List.generate(
                countOfProducts,
                (productIndex) => Product(
                  name: 'Product ${index}_$productIndex',
                  description: 'Description for product ${index}_$productIndex',
                  price: 5.0 * productIndex,
                ),
              ),
            ));

    return benchmarkData;
  }

  List<List<int>> generateRandomImageBytesList(int imageCount) {
    final random = Random();
    final imageBytesList = List.generate(imageCount, (_) => List.generate(sizeOfImagesKB, (_) => random.nextInt(256)));
    return imageBytesList;
  }

//endregion
}

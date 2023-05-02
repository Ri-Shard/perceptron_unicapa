import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';

class PerceptronPage extends StatefulWidget {
  @override
  _PerceptronPageState createState() => _PerceptronPageState();
}

class _PerceptronPageState extends State<PerceptronPage> {
  String selectedFilePath;
  List<List<double>> entradas;
  List<double> salidasEsperadas;
  List<double> salidasObtenidas;
  List<double> pesos;
  double tasaAprendizaje = 0.1;
  double error = 0.1;
  int iteraciones = 1000;
  bool entrenando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Perceptrón multicapa"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _getFilePath,
              child: Text("Seleccionar archivo"),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "Archivo seleccionado: $selectedFilePath",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(
              height: 20,
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: "Tasa de aprendizaje",
                border: OutlineInputBorder(),
              ),
              initialValue: tasaAprendizaje.toString(),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {
                  tasaAprendizaje = double.tryParse(value) ?? 0;
                });
              },
            ),
            SizedBox(
              height: 10,
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: "Error",
                border: OutlineInputBorder(),
              ),
              initialValue: error.toString(),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {
                  error = double.tryParse(value) ?? 0;
                });
              },
            ),
            SizedBox(
              height: 10,
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: "Iteraciones",
                border: OutlineInputBorder(),
              ),
              initialValue: iteraciones.toString(),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  iteraciones = int.tryParse(value) ?? 0;
                });
              },
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: entrenando ? null : _entrenarPerceptron,
              child: Text("Entrenar perceptrón"),
            ),
            SizedBox(
              height: 20,
            ),
            if (entrenando) Text("Entrenando... por favor espera"),
            if (!entrenando && salidasObtenidas != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Número de entradas: ${entradas.length}",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    "Pesos: $pesos",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: entradas.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Entradas: ${entradas[index]}",
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                "Salida esperada: ${salidasEsperadas[index]}",
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                "Salida obtenida: ${salidasObtenidas[index]}",
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _getFilePath() async {
    InputElement uploadInput = FileUploadInputElement();
    uploadInput.click();
    uploadInput.onChange.listen((event) {
      final file = uploadInput.files.first;
      final reader = FileReader();

      reader.readAsText(file);

      reader.onLoadEnd.listen((event) {
        final csvData = CsvToListConverter(reader.result as String);
        entradas = [];
        salidasEsperadas = [];

        for (final row in csvData) {
          final entradasFila = [
            for (final entrada in row.sublist(0, row.length - 1))
              double.tryParse(entrada.toString())
          ];
          final salidaFila = double.tryParse(row.last.toString());
          entradas.add(entradasFila);
          salidasEsperadas.add(salidaFila);
        }

        setState(() {
          selectedFilePath = file.name;
          salidasEsperadas = salidasEsperadas;
          pesos = [for (int i = 0; i < entradas.first.length; i++) 0.0];
        });
      });
    });
  }

  List<List<double>> CsvToListConverter(String csv) {
    List<List<double>> data = [];
    List<String> rows = const LineSplitter().convert(csv);
    for (int i = 0; i < rows.length; i++) {
      List<String> row = rows[i].split(",");
      List<double> rowAsDoubles =
          row.map((e) => double.tryParse(e) ?? 0).toList();
      data.add(rowAsDoubles);
    }
    return data;
  }

  void _entrenarPerceptron() async {
    setState(() {
      entrenando = true;
    });
    for (int i = 0; i < iteraciones; i++) {
      bool errorEnIteracion = false;

      for (int j = 0; j < entradas.length; j++) {
        final salidaObtenida = _calcularSalida(entradas[j], pesos);
        salidasObtenidas ??= [];
        salidasObtenidas.add(salidaObtenida);

        final error = salidasEsperadas[j] - salidaObtenida;
        if (error.abs() > this.error) {
          errorEnIteracion = true;
          for (int k = 0; k < pesos.length; k++) {
            pesos[k] += tasaAprendizaje * error * entradas[j][k];
          }
        }
      }

      if (!errorEnIteracion) {
        break;
      }
    }

    setState(() {
      entrenando = false;
    });
  }

  double _calcularSalida(List<double> entradas, List<double> pesos) {
    double suma = 0;
    for (int i = 0; i < entradas.length; i++) {
      suma += entradas[i] * pesos[i];
    }

    return suma > 0 ? 1 : 0;
  }
}

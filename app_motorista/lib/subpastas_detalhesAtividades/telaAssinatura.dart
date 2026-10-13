import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ResultadoAssinatura {
  final String nomeRecebedor;
  final Uint8List assinaturaBytes;

  ResultadoAssinatura({
    required this.nomeRecebedor,
    required this.assinaturaBytes,
  });
}

class TelaAssinatura extends StatefulWidget {
  final String? nomeInicial;

  const TelaAssinatura({super.key, this.nomeInicial});

  @override
  State<TelaAssinatura> createState() => _TelaAssinaturaState();
}

class _TelaAssinaturaState extends State<TelaAssinatura> {
  final TextEditingController _nomeController = TextEditingController();
  final List<List<Offset>> _tracos = [];
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.nomeInicial != null && widget.nomeInicial!.isNotEmpty) {
      _nomeController.text = widget.nomeInicial!;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _limpar() {
    setState(() {
      _tracos.clear();
    });
  }

  Future<void> _salvarAssinatura() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe o nome de quem está recebendo.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_tracos.isEmpty || _tracos.every((t) => t.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, colete a assinatura na tela.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 1. Calcula o Bounding Box de todos os pontos desenhados para recortar e centralizar
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    int totalPontos = 0;
    for (final traco in _tracos) {
      for (final pt in traco) {
        totalPontos++;
        if (pt.dx < minX) minX = pt.dx;
        if (pt.dx > maxX) maxX = pt.dx;
        if (pt.dy < minY) minY = pt.dy;
        if (pt.dy > maxY) maxY = pt.dy;
      }
    }

    if (totalPontos == 0 || minX > maxX || minY > maxY) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, colete a assinatura na tela.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Renderiza a assinatura em imagem PNG de alta resolução e centralizada
    const double canvasW = 600.0;
    const double canvasH = 320.0;
    const double margem = 28.0;

    double contentW = maxX - minX;
    double contentH = maxY - minY;
    if (contentW < 40) contentW = 40;
    if (contentH < 40) contentH = 40;

    final double availW = canvasW - (margem * 2);
    final double availH = canvasH - (margem * 2);
    final double scale = (availW / contentW).clamp(0.1, availH / contentH);

    final double centerX = (minX + maxX) / 2.0;
    final double centerY = (minY + maxY) / 2.0;
    final double canvasCenterX = canvasW / 2.0;
    final double canvasCenterY = canvasH / 2.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, canvasW, canvasH),
    );

    // Fundo branco sólido
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, canvasW, canvasH), bgPaint);

    // Linha de assinatura nítida e encorpada
    final strokeWidth = (3.5 * (scale.clamp(0.8, 2.0))).clamp(3.5, 6.0);
    final linePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    Offset transformPoint(Offset p) {
      return Offset(
        canvasCenterX + (p.dx - centerX) * scale,
        canvasCenterY + (p.dy - centerY) * scale,
      );
    }

    for (final traco in _tracos) {
      if (traco.isEmpty) continue;
      if (traco.length == 1) {
        canvas.drawCircle(transformPoint(traco.first), strokeWidth / 2, dotPaint);
      } else {
        final path = Path();
        final firstPt = transformPoint(traco.first);
        path.moveTo(firstPt.dx, firstPt.dy);
        for (int i = 1; i < traco.length; i++) {
          final pt = transformPoint(traco[i]);
          path.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(path, linePaint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(canvasW.toInt(), canvasH.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao processar imagem da assinatura.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final bytes = byteData.buffer.asUint8List();

    if (mounted) {
      Navigator.pop(
        context,
        ResultadoAssinatura(
          nomeRecebedor: nome,
          assinaturaBytes: bytes,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Assinatura do Recebedor",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            tooltip: "Limpar Assinatura",
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
            onPressed: _limpar,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo para o nome de quem está recebendo
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _nomeController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.person_outline, color: Colors.blue),
                    labelText: "Nome de quem está recebendo *",
                    hintText: "Ex: Carlos Silva (Mestre de Obras)",
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Orientação
              const Row(
                children: [
                  Icon(Icons.draw_outlined, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Peça para a pessoa assinar com o dedo no quadro abaixo:",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Área de Assinatura (Canvas)
              Expanded(
                child: Container(
                  key: _canvasKey,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Linha guia de assinatura
                      Positioned(
                        left: 30,
                        right: 30,
                        bottom: 40,
                        child: Container(
                          height: 1.5,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      Positioned(
                        left: 30,
                        bottom: 16,
                        child: Text(
                          "X  Assinatura do responsável",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),

                      // Canvas de toque
                      GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            _tracos.add([details.localPosition]);
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            if (_tracos.isNotEmpty) {
                              _tracos.last.add(details.localPosition);
                            }
                          });
                        },
                        onPanEnd: (_) {},
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _AssinaturaPainter(tracos: _tracos),
                        ),
                      ),

                      // Botão rápido para limpar sobre o canvas
                      if (_tracos.isNotEmpty)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFFEE2E2),
                              foregroundColor: const Color(0xFFDC2626),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text(
                              "Limpar",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _limpar,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botões de Ação
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("CANCELAR", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check, size: 20),
                        label: const Text(
                          "CONFIRMAR ASSINATURA",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: _salvarAssinatura,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssinaturaPainter extends CustomPainter {
  final List<List<Offset>> tracos;

  _AssinaturaPainter({required this.tracos});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    for (final traco in tracos) {
      if (traco.isEmpty) continue;
      if (traco.length == 1) {
        canvas.drawCircle(traco.first, 2.0, dotPaint);
      } else {
        final path = Path();
        path.moveTo(traco.first.dx, traco.first.dy);
        for (int i = 1; i < traco.length; i++) {
          path.lineTo(traco[i].dx, traco[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AssinaturaPainter oldDelegate) => true;
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_motorista/subpastas_detalhesAtividades/abaCliente.dart';
import 'package:app_motorista/subpastas_detalhesAtividades/botaoLocalizacao.dart';
import 'package:app_motorista/subpastas_detalhesAtividades/telaAssinatura.dart';
import 'package:app_motorista/subpastas_homepage/atividades.dart';
import 'package:app_motorista/paginas_principais/homepage.dart';

class Detalhesatividade extends StatefulWidget {
  final String id;
  final bool concluido;
  final String atividade;
  final Color cor;
  final String clienteNome;
  final String endereco;
  final String cacambaNumero;
  final String cacambaId;
  final String cacambaVelhaNumero;
  final String dataEntrega;
  final String horaEntrega;
  final Timestamp? concluidoEm;

  const Detalhesatividade({
    super.key,
    required this.id,
    required this.cor,
    required this.atividade,
    required this.concluido,
    required this.clienteNome,
    required this.endereco,
    required this.cacambaNumero,
    required this.cacambaId,
    this.cacambaVelhaNumero = '',
    this.dataEntrega = '',
    this.horaEntrega = '',
    this.concluidoEm,
  });

  @override
  State<Detalhesatividade> createState() => _DetalhesatividadeState();
}

class _DetalhesatividadeState extends State<Detalhesatividade> {
  XFile? _fotoComprovante;
  Uint8List? _fotoBytes;
  Uint8List? _assinaturaBytes;
  String _nomeRecebedor = '';
  String? _fotoCarregadaUrl;
  String? _assinaturaCarregadaUrl;
  String? _nomeRecebedorCarregado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.concluido) {
      _carregarDadosConcluidos();
    }
  }

  Future<void> _carregarDadosConcluidos() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('locacoes')
          .doc(widget.id)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _fotoCarregadaUrl = data['foto_confirmacao_url'];
            _assinaturaCarregadaUrl = data['assinatura_url'];
            _nomeRecebedorCarregado = data['recebedor_nome'];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _tirarFoto() async {
    if (widget.concluido) return;

    final ImagePicker buscador = ImagePicker();
    final XFile? fotoTirada = await buscador.pickImage(
      source: ImageSource.camera,
      imageQuality: 40,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (fotoTirada != null) {
      final bytes = await fotoTirada.readAsBytes();
      setState(() {
        _fotoComprovante = fotoTirada;
        _fotoBytes = bytes;
      });
    }
  }

  Future<void> _coletarAssinatura() async {
    if (widget.concluido) return;

    final resultado = await Navigator.push<ResultadoAssinatura>(
      context,
      MaterialPageRoute(
        builder: (context) => TelaAssinatura(nomeInicial: _nomeRecebedor),
      ),
    );

    if (resultado != null) {
      setState(() {
        _nomeRecebedor = resultado.nomeRecebedor;
        _assinaturaBytes = resultado.assinaturaBytes;
      });
    }
  }

  Future<void> _confirmarServico() async {
    if (_fotoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, tire uma foto do local/caçamba antes de confirmar.',
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (_assinaturaBytes == null || _nomeRecebedor.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, recolha a assinatura digital e o nome de quem recebeu antes de confirmar.',
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Coleta dados locais antes da navegação para evitar problemas com widget desmontado
    final String docId = widget.id;
    final String atividade = widget.atividade;
    final String cacambaId = widget.cacambaId;
    final Uint8List bytesFotoToUpload = _fotoBytes!;
    final Uint8List bytesAssinaturaToUpload = _assinaturaBytes!;
    final String nomeRecebedorFinal = _nomeRecebedor.trim();
    final bool isRetirada =
        atividade == 'RETIRADA' ||
        atividade == 'retirada_pendente' ||
        atividade == 'aguardando_retirada';
    final bool isTroca =
        atividade.toUpperCase() == 'TROCA' ||
        atividade == 'troca_pendente' ||
        atividade == 'aguardando_troca';

    // Determina novos status
    final String novoStatusLocacao = isRetirada ? 'concluida' : 'na_obra';
    final String novoStatusCacamba = isRetirada ? 'disponivel' : 'em_uso';

    final DateTime nowObj = DateTime.now();
    final String dataHojeStr =
        "${nowObj.year}-${nowObj.month.toString().padLeft(2, '0')}-${nowObj.day.toString().padLeft(2, '0')}";
    final retirObj = nowObj.add(const Duration(days: 15));
    final String dataRetiradaCalculada =
        "${retirObj.year}-${retirObj.month.toString().padLeft(2, '0')}-${retirObj.day.toString().padLeft(2, '0')}";

    // 2. Navega imediatamente de volta para a Homepage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Atividade concluída! Enviando comprovante em segundo plano...'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Homepage()),
      (route) => false,
    );

    // 3. Executa todo o processo em background
    Future.microtask(() async {
      String fotoUrl = 'erro_upload_comprovante';
      // A. Upload da Foto para o Firebase Storage
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('locacoes')
            .child(docId)
            .child('comprovante.jpg');

        await ref.putData(
          bytesFotoToUpload,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        fotoUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint("Tentativa 1 falhou para foto: $e. Tentando com bucket alternativo...");
        try {
          final altStorage = FirebaseStorage.instanceFor(bucket: 'gs://gerenciamento-de-cacambas.firebasestorage.app');
          final refAlt = altStorage
              .ref()
              .child('locacoes')
              .child(docId)
              .child('comprovante.jpg');
          
          await refAlt.putData(
            bytesFotoToUpload,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          fotoUrl = await refAlt.getDownloadURL();
        } catch (e2) {
          debugPrint("Erro no upload do comprovante: $e2");
          fotoUrl = 'Erro no upload: ${e2.toString()}';
        }
      }

      // B. Upload da Assinatura Digital para o Firebase Storage
      String assinaturaUrl = '';
      try {
        final refAssinatura = FirebaseStorage.instance
            .ref()
            .child('locacoes')
            .child(docId)
            .child('assinatura.png');

        await refAssinatura.putData(
          bytesAssinaturaToUpload,
          SettableMetadata(contentType: 'image/png'),
        );
        assinaturaUrl = await refAssinatura.getDownloadURL();
      } catch (eAss) {
        debugPrint("Tentativa 1 falhou para assinatura: $eAss. Tentando com bucket alternativo...");
        try {
          final altStorage = FirebaseStorage.instanceFor(bucket: 'gs://gerenciamento-de-cacambas.firebasestorage.app');
          final refAltAss = altStorage
              .ref()
              .child('locacoes')
              .child(docId)
              .child('assinatura.png');

          await refAltAss.putData(
            bytesAssinaturaToUpload,
            SettableMetadata(contentType: 'image/png'),
          );
          assinaturaUrl = await refAltAss.getDownloadURL();
        } catch (eAss2) {
          debugPrint("Erro no upload da assinatura: $eAss2");
          assinaturaUrl = '';
        }
      }

      try {
        // C. Atualiza a Locação no Firestore com tudo junto (status, datas, fotoUrl, assinaturaUrl, recebedor_nome)
        final Map<String, dynamic> updateFields = {
          'status': novoStatusLocacao,
          'foto_confirmacao_url': fotoUrl,
          'assinatura_url': assinaturaUrl,
          'recebedor_nome': nomeRecebedorFinal,
          'assinatura_em': FieldValue.serverTimestamp(),
          'concluido_em': FieldValue.serverTimestamp(),
        };

        if (isRetirada) {
          updateFields['data_retirada'] = dataHojeStr;
        } else if (isTroca) {
          updateFields['data_entrega'] = dataHojeStr;
          updateFields['data_retirada'] = dataRetiradaCalculada;
        } else {
          updateFields['data_entrega'] = dataHojeStr;
          updateFields['data_retirada'] = dataRetiradaCalculada;
        }

        await FirebaseFirestore.instance
            .collection('locacoes')
            .doc(docId)
            .update(updateFields);

        // C. Atualiza status da caçamba atual
        if (cacambaId.isNotEmpty) {
          try {
            await FirebaseFirestore.instance
                .collection('cacambas')
                .doc(cacambaId)
                .update({'status': novoStatusCacamba});
          } catch (e) {
            debugPrint("Erro ao atualizar status da caçamba: $e");
          }
        }

        // D. Se for troca, libera a caçamba antiga
        if (isTroca) {
          try {
            final docSnap = await FirebaseFirestore.instance
                .collection('locacoes')
                .doc(docId)
                .get();
            final docData = docSnap.data();
            if (docData != null && docData['cacamba_velha_id'] != null) {
              final velhaId = docData['cacamba_velha_id'] as String;
              if (velhaId.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('cacambas')
                    .doc(velhaId)
                    .update({'status': 'disponivel'});
              }
            }
          } catch (e) {
            debugPrint("Erro ao liberar caçamba velha: $e");
          }
        }
      } catch (e) {
        debugPrint("Erro ao atualizar locação no Firestore: $e");
      }
    });
  }

  String _formatarProgramado() {
    if (widget.dataEntrega.isEmpty) return "-";
    try {
      final parts = widget.dataEntrega.split('-');
      if (parts.length == 3) {
        final dataFormatada = "${parts[2]}/${parts[1]}/${parts[0]}";
        if (widget.horaEntrega.isNotEmpty) {
          return "$dataFormatada ${widget.horaEntrega}";
        }
        return dataFormatada;
      }
    } catch (_) {}
    return widget.dataEntrega;
  }

  String _formatarRealizado() {
    if (!widget.concluido) return "Pendente";
    if (widget.concluidoEm == null) return "Concluído";
    try {
      final dateUtc = widget.concluidoEm!.toDate().toUtc();
      final date = dateUtc.subtract(const Duration(hours: 3));
      final dia = date.day.toString().padLeft(2, '0');
      final mes = date.month.toString().padLeft(2, '0');
      final ano = date.year.toString();
      final hora = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');
      return "$dia/$mes/$ano $hora:$min";
    } catch (_) {}
    return "Concluído";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ordem de Serviço",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            OrdemDeServico(atividade: widget.atividade, cor: widget.cor),
            const SizedBox(height: 20),
            
            // Card de Prazos e Datas
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        "Prazos e Datas",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Programado:",
                        style: TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _formatarProgramado(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Realizado:",
                        style: TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _formatarRealizado(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: widget.concluido ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Abacliente(
              clienteNome: widget.clienteNome,
              endereco: widget.endereco,
              cacambaNumero: widget.cacambaNumero,
              cacambaVelhaNumero: widget.cacambaVelhaNumero,
              atividade: widget.atividade,
            ),
            const SizedBox(height: 20),
            Botaolocalizacao(endereco: widget.endereco),
            const SizedBox(height: 20),

            // Área de Foto de Confirmação
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Comprovação de serviço",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _tirarFoto,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!, width: 4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _fotoBytes != null
                            ? Image.memory(
                                _fotoBytes!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              )
                            : (_fotoCarregadaUrl != null && _fotoCarregadaUrl!.startsWith('http'))
                            ? Image.network(
                                _fotoCarregadaUrl!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              )
                            : widget.concluido
                            ? const Icon(
                                Icons.photo,
                                size: 50,
                                color: Colors.grey,
                              )
                            : const Icon(
                                Icons.camera_alt_outlined,
                                size: 50,
                                color: Colors.blue,
                              ),
                        const SizedBox(height: 8),
                        if (_fotoComprovante == null && _fotoCarregadaUrl == null && !widget.concluido)
                          const Text(
                            "Toque para tirar a foto da caçamba no local",
                            style: TextStyle(fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Área de Assinatura Digital do Recebedor
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.draw_outlined, size: 20, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    const Text(
                      "Assinatura do Recebedor",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (!widget.concluido) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "Obrigatório",
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                if (widget.concluido) ...[
                  // Exibição quando atividade já está concluída
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_nomeRecebedorCarregado != null && _nomeRecebedorCarregado!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.person, size: 18, color: Color(0xFF10B981)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Recebido por: $_nomeRecebedorCarregado",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_assinaturaCarregadaUrl != null && _assinaturaCarregadaUrl!.startsWith('http'))
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              color: const Color(0xFFF8FAFC),
                              padding: const EdgeInsets.all(8),
                              child: Image.network(
                                _assinaturaCarregadaUrl!,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        else
                          const Text(
                            "Assinatura digital não vinculada.",
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  ),
                ] else if (_assinaturaBytes != null) ...[
                  // Assinatura recém coletada pelo motorista
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, size: 18, color: Color(0xFF10B981)),
                                const SizedBox(width: 6),
                                Text(
                                  "Recebido por: $_nomeRecebedor",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.edit, size: 14, color: Color(0xFF2563EB)),
                              label: const Text(
                                "Alterar",
                                style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                              ),
                              onPressed: _coletarAssinatura,
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Container(
                          height: 110,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.memory(
                            _assinaturaBytes!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Botão chamativo para coletar assinatura
                  InkWell(
                    onTap: _coletarAssinatura,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note_rounded, size: 40, color: Color(0xFF2563EB)),
                          SizedBox(height: 8),
                          Text(
                            "COLETAR ASSINATURA DIGITAL",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Pergunte o nome do recebedor e peça para assinar na tela",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),

            // Botão de Confirmação
            if (widget.concluido)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 70,
              )
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _confirmarServico,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "CONFIRMAR SERVIÇO",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

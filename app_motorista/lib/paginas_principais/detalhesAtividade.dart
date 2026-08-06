import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_motorista/subpastas_detalhesAtividades/abaCliente.dart';
import 'package:app_motorista/subpastas_detalhesAtividades/botaoLocalizacao.dart';
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
  File? _fotoComprovante;
  bool _isLoading = false;

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
      setState(() {
        _fotoComprovante = File(fotoTirada.path);
      });
    }
  }

  Future<void> _confirmarServico() async {
    if (_fotoComprovante == null) {
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

    setState(() => _isLoading = true);

    // 1. Coleta dados locais antes da navegação para evitar problemas com widget desmontado
    final String docId = widget.id;
    final String atividade = widget.atividade;
    final String cacambaId = widget.cacambaId;
    final File fileToUpload = _fotoComprovante!;
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
      try {
        // A. Upload para o Firebase Storage
        final ref = FirebaseStorage.instance
            .ref()
            .child('locacoes')
            .child(docId)
            .child('comprovante.jpg');

        final bytes = await fileToUpload.readAsBytes();
        await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        fotoUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint("Tentativa 1 falhou: $e. Tentando com bucket alternativo...");
        try {
          final altStorage = FirebaseStorage.instanceFor(bucket: 'gs://gerenciamento-de-cacambas.appspot.com');
          final refAlt = altStorage
              .ref()
              .child('locacoes')
              .child(docId)
              .child('comprovante.jpg');
          
          final bytes = await fileToUpload.readAsBytes();
          await refAlt.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          fotoUrl = await refAlt.getDownloadURL();
        } catch (e2) {
          debugPrint("Erro no upload do comprovante: $e2");
          fotoUrl = 'Erro no upload: ${e2.toString()}. Dica: Ative o Storage no Console do Firebase (clique em Começar).';
        }
      }

      try {
        // B. Atualiza a Locação no Firestore com tudo junto (status, datas, fotoUrl final)
        final Map<String, dynamic> updateFields = {
          'status': novoStatusLocacao,
          'foto_confirmacao_url': fotoUrl,
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
                        _fotoComprovante != null
                            ? Image.file(
                                _fotoComprovante!,
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
                        if (_fotoComprovante == null && !widget.concluido)
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

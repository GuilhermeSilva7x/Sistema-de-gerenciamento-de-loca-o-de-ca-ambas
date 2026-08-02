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
          content: Text('Por favor, tire uma foto do local/caçamba antes de confirmar.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Determina o Novo Status da Locação e da Caçamba
      String novoStatusLocacao = 'na_obra';
      String novoStatusCacamba = 'em_uso';

      final nowObj = DateTime.now();
      final String dataHojeStr = "${nowObj.year}-${nowObj.month.toString().padLeft(2, '0')}-${nowObj.day.toString().padLeft(2, '0')}";
      final retirObj = nowObj.add(const Duration(days: 15));
      final String dataRetiradaCalculada = "${retirObj.year}-${retirObj.month.toString().padLeft(2, '0')}-${retirObj.day.toString().padLeft(2, '0')}";

      final bool isRetirada = widget.atividade == 'RETIRADA' || widget.atividade == 'retirada_pendente' || widget.atividade == 'aguardando_retirada';
      final bool isTroca = widget.atividade.toUpperCase() == 'TROCA' || widget.atividade == 'troca_pendente' || widget.atividade == 'aguardando_troca';

      if (isRetirada) {
        novoStatusLocacao = 'concluida';
        novoStatusCacamba = 'disponivel';
      }

      // 2. Atualiza a Locação e a Caçamba no Firestore IMEDIATAMENTE (sem await) para atualizar a UI instantaneamente
      final docRef = FirebaseFirestore.instance.collection('locacoes').doc(widget.id);
      
      final Map<String, dynamic> updateFields = {
        'status': novoStatusLocacao,
        'foto_confirmacao_url': 'uploading',
      };

      if (isRetirada) {
        updateFields['data_retirada'] = dataHojeStr;
      } else if (isTroca) {
        updateFields['tipo_servico'] = 'entrega';
        updateFields['data_entrega'] = dataHojeStr;
        updateFields['data_retirada'] = dataRetiradaCalculada;
      } else {
        // Entrega
        updateFields['data_entrega'] = dataHojeStr;
        updateFields['data_retirada'] = dataRetiradaCalculada;
      }

      docRef.update(updateFields);

      if (widget.cacambaId.isNotEmpty) {
        FirebaseFirestore.instance.collection('cacambas').doc(widget.cacambaId).update({
          'status': novoStatusCacamba,
        });
      }

      final isTroca = widget.atividade.toUpperCase() == 'TROCA';
      if (isTroca) {
        docRef.get().then((docSnap) {
          final docData = docSnap.data();
          if (docData != null && docData['cacamba_velha_id'] != null) {
            final velhaId = docData['cacamba_velha_id'] as String;
            if (velhaId.isNotEmpty) {
              FirebaseFirestore.instance.collection('cacambas').doc(velhaId).update({
                'status': 'disponivel',
              });
            }
          }
        });
      }

      // 3. Dispara o Upload e atualização da URL final em background
      final storageInstance = FirebaseStorage.instance;
      storageInstance.setMaxUploadRetryTime(const Duration(seconds: 5));
      final fileToUpload = _fotoComprovante!;

      Future.microtask(() async {
        try {

          final ref = storageInstance
              .ref()
              .child('locacoes')
              .child(widget.id)
              .child('comprovante.jpg');

          await ref.putFile(fileToUpload);
          final fotoUrl = await ref.getDownloadURL();
          
          await docRef.update({
            'foto_confirmacao_url': fotoUrl,
          });
        } catch (e) {
          // Se falhar o upload da foto em background, atualiza com a string de erro para não ficar como 'uploading'
          await docRef.update({
            'foto_confirmacao_url': 'erro_upload_comprovante',
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atividade concluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Homepage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao finalizar serviço: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            Abacliente(
              clienteNome: widget.clienteNome,
              endereco: widget.endereco,
              cacambaNumero: widget.cacambaNumero,
              cacambaVelhaNumero: widget.cacambaVelhaNumero,
              atividade: widget.atividade,
            ),
            const SizedBox(height: 20),
            const Botaolocalizacao(),
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
                                ? const Icon(Icons.photo, size: 50, color: Colors.grey)
                                : const Icon(Icons.camera_alt_outlined, size: 50, color: Colors.blue),
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

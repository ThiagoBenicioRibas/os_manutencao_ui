import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import 'package:os_manutencao_ui/controllers/evidencia_controller.dart';
import 'package:os_manutencao_ui/models/evidencia.dart';
import 'package:os_manutencao_ui/repositories/evidencia_repository.dart';
import 'package:os_manutencao_ui/services/armazenamento_evidencias_service.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Gerencia as fotografias de uma única ordem de serviço.
/// O controlador é local para não misturar dados de outras ordens.
class OrderEvidencesPage extends StatefulWidget {
  const OrderEvidencesPage({
    super.key,
    required this.ordemId,
    required this.codigo,
  });

  final int ordemId;
  final String codigo;

  @override
  State<OrderEvidencesPage> createState() => _OrderEvidencesPageState();
}

class _OrderEvidencesPageState extends State<OrderEvidencesPage> {
  final EvidenciaController _controlador = EvidenciaController();
  final ArmazenamentoEvidenciasService _arquivos =
      ArmazenamentoEvidenciasService();
  final EvidenciaRepository _repositorio = EvidenciaRepository();

  bool _processando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _carregar();
    });
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _carregar() async {
    try {
      await _controlador.carregarPorOrdem(widget.ordemId);
    } catch (_) {
      _avisar('Não foi possível carregar as fotografias desta ordem.');
    }
  }

  String _tipoImagem(String caminho) {
    final extensao = p.extension(caminho).toLowerCase();
    if (extensao == '.jpg' || extensao == '.jpeg') return 'image/jpeg';
    if (extensao == '.png') return 'image/png';
    if (extensao == '.webp') return 'image/webp';
    return 'image/*';
  }

  /// Retorna null quando o usuário cancela o formulário.
  Future<String?> _solicitarDescricao() async {
    final campo = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Descrição da fotografia'),
          content: TextField(
            controller: campo,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Descrição (opcional)',
              hintText: 'Ex.: Equipamento antes do reparo',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(campo.text.trim()),
              child: const Text('Salvar fotografia'),
            ),
          ],
        ),
      );
    } finally {
      campo.dispose();
    }
  }

  Future<void> _adicionar() async {
    if (_processando || _controlador.carregando) return;
    setState(() => _processando = true);

    String? caminhoCopiado;
    try {
      // file_picker 13.x: seleção de um único arquivo pela API estática.
      final selecionado = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (!mounted || selecionado == null) return;

      final origem = selecionado.path;
      if (origem == null || origem.isEmpty) {
        throw StateError('O arquivo selecionado não possui caminho local.');
      }

      final descricao = await _solicitarDescricao();
      if (!mounted || descricao == null) return;

      // Primeiro copia a foto. Depois cadastra o caminho no SQLite.
      caminhoCopiado = await _arquivos.salvarImagem(
        ordemId: widget.ordemId,
        caminhoOrigem: origem,
      );
      await _controlador.cadastrar(
        Evidencia(
          ordemId: widget.ordemId,
          caminhoArquivo: caminhoCopiado,
          descricao: descricao.isEmpty ? null : descricao,
          tipo: _tipoImagem(origem),
          dataRegistro: DateTime.now(),
        ),
      );
      _avisar('Fotografia adicionada com sucesso.');
    } catch (_) {
      // Se o SQLite falhar, remove a cópia, mas somente quando
      // confirmarmos que não existe um registro apontando para ela.
      bool? registrada;
      if (caminhoCopiado != null) {
        try {
          final lista = await _repositorio.listarPorOrdem(widget.ordemId);
          registrada = lista.any(
            (e) => e.caminhoArquivo == caminhoCopiado,
          );
          if (!registrada) await _arquivos.excluirImagem(caminhoCopiado);
        } catch (_) {
          // Em caso de dúvida, preserva o arquivo.
        }
      }
      _avisar(
        registrada == true
            ? 'Fotografia registrada, mas a lista não atualizou. '
                'Use o botão Atualizar.'
            : 'Não foi possível adicionar a fotografia.',
      );
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _visualizar(Evidencia evidencia) async {
    try {
      final imagem = await _arquivos.localizarImagem(
        evidencia.caminhoArquivo,
      );
      if (!mounted) return;
      if (imagem == null) {
        _avisar('A fotografia não foi encontrada no armazenamento.');
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(evidencia.descricao?.isNotEmpty == true
              ? evidencia.descricao!
              : 'Fotografia da ordem de serviço'),
          content: SizedBox(
            width: 560,
            height: 390,
            child: InteractiveViewer(
              child: Image.file(
                imagem,
                fit: BoxFit.contain,
                semanticLabel: evidencia.descricao ?? 'Fotografia da OS',
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text('Não foi possível abrir esta imagem.'),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (_) {
      _avisar('Não foi possível visualizar a fotografia.');
    }
  }

  Future<void> _excluir(Evidencia evidencia) async {
    final id = evidencia.id;
    if (_processando || id == null) return;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir fotografia?'),
        content: const Text(
          'A fotografia será excluída desta ordem de serviço. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar exclusão'),
          ),
        ],
      ),
    );
    if (!mounted || confirmou != true) return;

    setState(() => _processando = true);
    try {
      // Remove primeiro o registro; nunca deixa um registro
      // apontando para uma imagem que acabamos de apagar.
      var removidaDoBanco = false;
      try {
        await _controlador.excluir(id);
        removidaDoBanco = true;
      } catch (_) {
        // O registro pode ter sido excluído e a atualização da
        // lista ter falhado: consulta o banco antes de prosseguir.
        try {
          removidaDoBanco = await _repositorio.buscarPorId(id) == null;
        } catch (_) {
          removidaDoBanco = false;
        }
      }

      if (!removidaDoBanco) {
        _avisar('Não foi possível excluir o registro da fotografia.');
        return;
      }

      try {
        await _arquivos.excluirImagem(evidencia.caminhoArquivo);
        _avisar('Fotografia excluída com sucesso.');
      } catch (_) {
        _avisar('Registro excluído, mas o arquivo não pôde ser removido.');
      }

      if (_controlador.erro != null) await _carregar();
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Widget _miniatura(Evidencia evidencia) {
    return SizedBox(
      width: 96,
      height: 96,
      child: FutureBuilder<File?>(
        future: _arquivos.localizarImagem(evidencia.caminhoArquivo),
        builder: (context, resultado) {
          if (resultado.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (resultado.hasError || resultado.data == null) {
            return const Icon(
              Icons.broken_image_outlined,
              semanticLabel: 'Prévia da imagem indisponível',
            );
          }
          return Image.file(
            resultado.data!,
            fit: BoxFit.cover,
            semanticLabel: evidencia.descricao ?? 'Fotografia da OS',
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.broken_image_outlined,
              semanticLabel: 'Prévia da imagem indisponível',
            ),
          );
        },
      ),
    );
  }

  Widget _cartao(Evidencia evidencia, bool ocupado) {
    final titulo = evidencia.descricao?.isNotEmpty == true
        ? evidencia.descricao!
        : 'Fotografia sem descrição';
    final data = DateFormat('dd/MM/yyyy HH:mm').format(evidencia.dataRegistro);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _miniatura(evidencia),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Registrada em: $data'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: ocupado ? null : () => _visualizar(evidencia),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Visualizar fotografia'),
                ),
                OutlinedButton.icon(
                  onPressed: ocupado ? null : () => _excluir(evidencia),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir fotografia'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controlador,
      builder: (context, _) {
        final evidencias = _controlador.evidencias
            .where((e) => e.ordemId == widget.ordemId)
            .toList();
        final ocupado = _processando || _controlador.carregando;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Evidências fotográficas'),
            actions: [
              IconButton(
                tooltip: 'Atualizar fotografias',
                onPressed: ocupado ? null : _carregar,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionCard(
                      title: 'Ordem de Serviço',
                      child: Text(widget.codigo),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Fotografias do atendimento',
                      subtitle: 'Imagens vinculadas a esta ordem de serviço.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: ocupado ? null : _adicionar,
                              icon: const Icon(Icons.add_a_photo_outlined),
                              label: const Text('Adicionar fotografia'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_controlador.carregando)
                            const Center(child: CircularProgressIndicator())
                          else if (_controlador.erro != null)
                            Text(_controlador.erro!)
                          else if (evidencias.isEmpty)
                            const Text('Nenhuma fotografia cadastrada para esta ordem.')
                          else
                            for (final evidencia in evidencias)
                              _cartao(evidencia, ocupado),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

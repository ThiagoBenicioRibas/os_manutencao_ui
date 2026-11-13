
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Gerencia os arquivos físicos das evidências fotográficas.
///
/// As imagens ficam na pasta de suporte do aplicativo,
/// separadas por ordem de serviço.
///
/// O SQLite armazena apenas o caminho relativo da imagem.
class ArmazenamentoEvidenciasService {
  ArmazenamentoEvidenciasService({
    Directory? diretorioBase,
  }) : _diretorioBase = diretorioBase;

  /// Permite utilizar uma pasta temporária nos testes.
  final Directory? _diretorioBase;

  final Random _aleatorio = Random.secure();

  static const Set<String> _extensoesPermitidas = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  /// Localiza a pasta permanente das evidências.
  Future<Directory> _diretorioEvidencias() async {
    final base = _diretorioBase ??
        await getApplicationSupportDirectory();

    final diretorio = Directory(
      p.join(base.path, 'evidencias'),
    );

    await diretorio.create(recursive: true);

    return diretorio;
  }

  /// Gera um identificador aleatório para evitar
  /// nomes de arquivos duplicados.
  String _gerarIdentificador() {
    return List.generate(
      12,
      (_) => _aleatorio.nextInt(256)
          .toRadixString(16)
          .padLeft(2, '0'),
    ).join();
  }

  /// Copia uma imagem selecionada para a pasta
  /// permanente da ordem de serviço.
  ///
  /// Retorna o caminho relativo que deverá ser
  /// armazenado na tabela evidencias do SQLite.
  Future<String> salvarImagem({
    required int ordemId,
    required String caminhoOrigem,
  }) async {
    if (ordemId <= 0) {
      throw ArgumentError(
        'Informe uma ordem de serviço válida.',
      );
    }

    if (caminhoOrigem.trim().isEmpty) {
      throw ArgumentError(
        'Selecione uma imagem válida.',
      );
    }

    final origem = File(caminhoOrigem);

    if (!await origem.exists()) {
      throw FileSystemException(
        'A imagem selecionada não foi encontrada.',
        caminhoOrigem,
      );
    }

    final extensao =
        p.extension(caminhoOrigem).toLowerCase();

    if (!_extensoesPermitidas.contains(extensao)) {
      throw ArgumentError(
        'Formato não permitido. '
        'Utilize JPG, JPEG, PNG ou WEBP.',
      );
    }

    final raiz = await _diretorioEvidencias();

    final pastaDaOrdem = Directory(
      p.join(raiz.path, 'ordem_$ordemId'),
    );

    await pastaDaOrdem.create(recursive: true);

    // Evita gravar fora da pasta de evidências
    // caso exista um redirecionamento por link simbólico.
    final raizReal = await raiz.resolveSymbolicLinks();
    final pastaReal =
        await pastaDaOrdem.resolveSymbolicLinks();

    if (!p.isWithin(raizReal, pastaReal)) {
      throw StateError(
        'A pasta de destino das imagens não é segura.',
      );
    }

    final nomeArquivo =
        'foto_${DateTime.now().microsecondsSinceEpoch}_'
        '${_gerarIdentificador()}$extensao';

    final destino = File(
      p.join(pastaDaOrdem.path, nomeArquivo),
    );

    await origem.copy(destino.path);

    // Caminho relativo à pasta de suporte
    // do aplicativo, e não ao computador do usuário.
    return p.join(
      'evidencias',
      'ordem_$ordemId',
      nomeArquivo,
    );
  }

  /// Resolve um caminho armazenado no SQLite,
  /// impedindo acesso a arquivos fora da pasta
  /// de evidências do aplicativo.
  Future<File> _resolverArquivoSeguro(
    String caminhoRelativo,
  ) async {
    if (caminhoRelativo.trim().isEmpty ||
        p.isAbsolute(caminhoRelativo)) {
      throw ArgumentError(
        'Caminho de evidência inválido.',
      );
    }

    final raiz = await _diretorioEvidencias();

    final caminhoRaiz = p.normalize(
      p.absolute(raiz.path),
    );

    final pastaSuporte = p.dirname(caminhoRaiz);

    final caminhoArquivo = p.normalize(
      p.absolute(
        p.join(pastaSuporte, caminhoRelativo),
      ),
    );

    // Bloqueia caminhos que tentem sair da pasta
    // de evidências, como ../ ou caminhos absolutos.
    if (!p.isWithin(caminhoRaiz, caminhoArquivo)) {
      throw ArgumentError(
        'O arquivo está fora da pasta de evidências.',
      );
    }

    final arquivo = File(caminhoArquivo);
    final pastaArquivo = arquivo.parent;

    // Verifica também links simbólicos existentes.
    if (await pastaArquivo.exists()) {
      final raizReal =
          await raiz.resolveSymbolicLinks();

      final pastaReal =
          await pastaArquivo.resolveSymbolicLinks();

      if (pastaReal != raizReal &&
          !p.isWithin(raizReal, pastaReal)) {
        throw ArgumentError(
          'O caminho da imagem não é seguro.',
        );
      }

      if (await arquivo.exists()) {
        final arquivoReal =
            await arquivo.resolveSymbolicLinks();

        if (!p.isWithin(raizReal, arquivoReal)) {
          throw ArgumentError(
            'A imagem está fora da pasta permitida.',
          );
        }
      }
    }

    return arquivo;
  }

  /// Localiza uma imagem salva anteriormente.
  ///
  /// Retorna null se o arquivo não existir.
  Future<File?> localizarImagem(
    String caminhoRelativo,
  ) async {
    final arquivo = await _resolverArquivoSeguro(
      caminhoRelativo,
    );

    if (!await arquivo.exists()) {
      return null;
    }

    return arquivo;
  }

  /// Remove uma imagem armazenada pelo aplicativo.
  ///
  /// Retorna true quando o arquivo foi excluído
  /// e false quando ele já não existia.
  ///
  /// Nunca remove arquivos fora da pasta
  /// permanente de evidências.
  Future<bool> excluirImagem(
    String caminhoRelativo,
  ) async {
    final arquivo = await _resolverArquivoSeguro(
      caminhoRelativo,
    );

    if (!await arquivo.exists()) {
      return false;
    }

    await arquivo.delete();

    return true;
  }
}

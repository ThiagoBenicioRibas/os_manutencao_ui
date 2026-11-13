
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:os_manutencao_ui/services/armazenamento_evidencias_service.dart';

void main() {
  group('Etapa 7 - Armazenamento de evidências', () {
    late Directory diretorioTemporario;
    late Directory diretorioSuporte;
    late File imagemOrigem;
    late ArmazenamentoEvidenciasService servico;

    setUp(() async {
      // Cada teste utiliza uma pasta independente.
      diretorioTemporario =
          await Directory.systemTemp.createTemp(
        'teste_armazenamento_evidencias_',
      );

      diretorioSuporte = Directory(
        p.join(diretorioTemporario.path, 'suporte'),
      );

      await diretorioSuporte.create(recursive: true);

      imagemOrigem = File(
        p.join(diretorioTemporario.path, 'imagem_teste.png'),
      );

      // Bytes de teste para verificar a cópia do arquivo.
      // Não é necessário utilizar uma fotografia real.
      await imagemOrigem.writeAsBytes([
        137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3,
      ]);

      servico = ArmazenamentoEvidenciasService(
        diretorioBase: diretorioSuporte,
      );
    });

    tearDown(() async {
      if (await diretorioTemporario.exists()) {
        await diretorioTemporario.delete(
          recursive: true,
        );
      }
    });

    test('Copia a imagem para a pasta da ordem', () async {
      final caminho = await servico.salvarImagem(
        ordemId: 10,
        caminhoOrigem: imagemOrigem.path,
      );

      expect(p.isAbsolute(caminho), isFalse);
      expect(
        p.split(caminho),
        contains('ordem_10'),
      );

      final imagemSalva =
          await servico.localizarImagem(caminho);

      expect(imagemSalva, isNotNull);
      expect(await imagemSalva!.exists(), isTrue);

      expect(
        await imagemSalva.readAsBytes(),
        await imagemOrigem.readAsBytes(),
      );

      // A imagem original não pode ser removida.
      expect(await imagemOrigem.exists(), isTrue);
    });

    test('Mantém a imagem acessível após recriar o serviço',
        () async {
      final caminho = await servico.salvarImagem(
        ordemId: 11,
        caminhoOrigem: imagemOrigem.path,
      );

      // Simula uma nova instância do serviço,
      // usando a mesma pasta permanente.
      final servicoReaberto =
          ArmazenamentoEvidenciasService(
        diretorioBase: diretorioSuporte,
      );

      final imagemRecuperada =
          await servicoReaberto.localizarImagem(caminho);

      expect(imagemRecuperada, isNotNull);
      expect(await imagemRecuperada!.exists(), isTrue);

      expect(
        await imagemRecuperada.readAsBytes(),
        await imagemOrigem.readAsBytes(),
      );
    });

    test('Organiza imagens por OS e evita nomes repetidos',
        () async {
      final primeira = await servico.salvarImagem(
        ordemId: 20,
        caminhoOrigem: imagemOrigem.path,
      );

      final segunda = await servico.salvarImagem(
        ordemId: 20,
        caminhoOrigem: imagemOrigem.path,
      );

      final terceira = await servico.salvarImagem(
        ordemId: 21,
        caminhoOrigem: imagemOrigem.path,
      );

      expect(primeira, isNot(segunda));

      expect(p.split(primeira), contains('ordem_20'));
      expect(p.split(segunda), contains('ordem_20'));
      expect(p.split(terceira), contains('ordem_21'));

      expect(
        await servico.localizarImagem(primeira),
        isNotNull,
      );

      expect(
        await servico.localizarImagem(segunda),
        isNotNull,
      );

      expect(
        await servico.localizarImagem(terceira),
        isNotNull,
      );
    });

    test('Rejeita dados e formatos inválidos', () async {
      await expectLater(
        servico.salvarImagem(
          ordemId: 0,
          caminhoOrigem: imagemOrigem.path,
        ),
        throwsA(isA<ArgumentError>()),
      );

      await expectLater(
        servico.salvarImagem(
          ordemId: 10,
          caminhoOrigem: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );

      final arquivoTexto = File(
        p.join(diretorioTemporario.path, 'documento.txt'),
      );

      await arquivoTexto.writeAsString('Teste');

      await expectLater(
        servico.salvarImagem(
          ordemId: 10,
          caminhoOrigem: arquivoTexto.path,
        ),
        throwsA(isA<ArgumentError>()),
      );

      await expectLater(
        servico.salvarImagem(
          ordemId: 10,
          caminhoOrigem: p.join(
            diretorioTemporario.path,
            'inexistente.png',
          ),
        ),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('Bloqueia caminhos fora da pasta de evidências',
        () async {
      final arquivoExterno = File(
        p.join(diretorioTemporario.path, 'externo.png'),
      );

      await arquivoExterno.writeAsBytes([1, 2, 3]);

      await expectLater(
        servico.localizarImagem(arquivoExterno.path),
        throwsA(isA<ArgumentError>()),
      );

      await expectLater(
        servico.excluirImagem('../externo.png'),
        throwsA(isA<ArgumentError>()),
      );

      await expectLater(
        servico.localizarImagem(
          p.join('evidencias', '..', 'externo.png'),
        ),
        throwsA(isA<ArgumentError>()),
      );

      // O arquivo externo deve permanecer intacto.
      expect(await arquivoExterno.exists(), isTrue);
      expect(
        await arquivoExterno.readAsBytes(),
        [1, 2, 3],
      );
    });

    test('Exclui somente a imagem armazenada', () async {
      final caminho = await servico.salvarImagem(
        ordemId: 30,
        caminhoOrigem: imagemOrigem.path,
      );

      expect(
        await servico.excluirImagem(caminho),
        isTrue,
      );

      expect(
        await servico.localizarImagem(caminho),
        isNull,
      );

      // Uma segunda exclusão não deve causar falha.
      expect(
        await servico.excluirImagem(caminho),
        isFalse,
      );

      // O arquivo original continua existindo.
      expect(await imagemOrigem.exists(), isTrue);
    });

    test('Retorna null para imagem que não existe', () async {
      final caminho = p.join(
        'evidencias',
        'ordem_99',
        'foto_inexistente.png',
      );

      final resultado =
          await servico.localizarImagem(caminho);

      expect(resultado, isNull);
    });
  });
}

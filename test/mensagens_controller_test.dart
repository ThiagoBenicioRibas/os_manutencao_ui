import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/controllers/cliente_controller.dart';
import 'package:os_manutencao_ui/repositories/cliente_repository.dart';
import 'package:os_manutencao_ui/models/cliente.dart';
import 'package:os_manutencao_ui/controllers/tecnico_controller.dart';
import 'package:os_manutencao_ui/repositories/tecnico_repository.dart';
import 'package:os_manutencao_ui/models/tecnico.dart';
import 'package:os_manutencao_ui/controllers/equipamento_controller.dart';
import 'package:os_manutencao_ui/repositories/equipamento_repository.dart';
import 'package:os_manutencao_ui/models/equipamento.dart';
import 'package:os_manutencao_ui/controllers/ordem_servico_controller.dart';
import 'package:os_manutencao_ui/repositories/ordem_servico_repository.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/controllers/item_utilizado_controller.dart';
import 'package:os_manutencao_ui/repositories/item_utilizado_repository.dart';
import 'package:os_manutencao_ui/models/item_utilizado.dart';
import 'package:os_manutencao_ui/controllers/historico_status_controller.dart';
import 'package:os_manutencao_ui/repositories/historico_status_repository.dart';
import 'package:os_manutencao_ui/models/historico_status.dart';
import 'package:os_manutencao_ui/controllers/evidencia_controller.dart';
import 'package:os_manutencao_ui/repositories/evidencia_repository.dart';
import 'package:os_manutencao_ui/models/evidencia.dart';

class ClienteComFalha extends ClienteRepository {
  @override
  Future<List<Cliente>> listar() async =>
      throw Exception('SQLITE caminho interno privado');
}

class TecnicoComFalha extends TecnicoRepository {
  @override
  Future<List<Tecnico>> listar() async =>
      throw Exception('SQLITE caminho interno privado');
}

class EquipamentoComFalha extends EquipamentoRepository {
  @override
  Future<List<Equipamento>> listar() async =>
      throw Exception('SQLITE caminho interno privado');
}

class OrdemServicoComFalha extends OrdemServicoRepository {
  @override
  Future<List<OrdemServico>> listar() async =>
      throw Exception('SQLITE caminho interno privado');
}

class ItemUtilizadoComFalha extends ItemUtilizadoRepository {
  @override
  Future<List<ItemUtilizado>> listar() async =>
      throw Exception('SQLITE caminho interno privado');
}

class HistoricoStatusComFalha extends HistoricoStatusRepository {
  @override
  Future<List<HistoricoStatus>> listar() async =>
      throw Exception('SQLITE caminho interno privado');
}

class EvidenciaComFalha extends EvidenciaRepository {
  @override
  Future<List<Evidencia>> listar() async =>
      throw Exception('SQLITE caminho interno privado');
}

void main() {
  test('Cliente: falha de consulta não expõe exceção técnica', () async {
    final controller = ClienteController(repositorio: ClienteComFalha());
    addTearDown(controller.dispose);
    await expectLater(controller.carregar(), throwsException);
    expect(controller.carregando, isFalse);
    expect(controller.erro, startsWith('Não foi possível'));
    expect(controller.erro, isNot(contains('SQLITE')));
    expect(controller.erro, isNot(contains('privado')));
  });
  test('Tecnico: falha de consulta não expõe exceção técnica', () async {
    final controller = TecnicoController(repositorio: TecnicoComFalha());
    addTearDown(controller.dispose);
    await expectLater(controller.carregar(), throwsException);
    expect(controller.carregando, isFalse);
    expect(controller.erro, startsWith('Não foi possível'));
    expect(controller.erro, isNot(contains('SQLITE')));
    expect(controller.erro, isNot(contains('privado')));
  });
  test('Equipamento: falha de consulta não expõe exceção técnica', () async {
    final controller =
        EquipamentoController(repositorio: EquipamentoComFalha());
    addTearDown(controller.dispose);
    await expectLater(controller.carregar(), throwsException);
    expect(controller.carregando, isFalse);
    expect(controller.erro, startsWith('Não foi possível'));
    expect(controller.erro, isNot(contains('SQLITE')));
    expect(controller.erro, isNot(contains('privado')));
  });
  test('OrdemServico: falha de consulta não expõe exceção técnica', () async {
    final controller =
        OrdemServicoController(repositorio: OrdemServicoComFalha());
    addTearDown(controller.dispose);
    await expectLater(controller.carregar(), throwsException);
    expect(controller.carregando, isFalse);
    expect(controller.erro, startsWith('Não foi possível'));
    expect(controller.erro, isNot(contains('SQLITE')));
    expect(controller.erro, isNot(contains('privado')));
  });
  test('ItemUtilizado: falha de consulta não expõe exceção técnica', () async {
    final controller =
        ItemUtilizadoController(repositorio: ItemUtilizadoComFalha());
    addTearDown(controller.dispose);
    await expectLater(controller.carregar(), throwsException);
    expect(controller.carregando, isFalse);
    expect(controller.erro, startsWith('Não foi possível'));
    expect(controller.erro, isNot(contains('SQLITE')));
    expect(controller.erro, isNot(contains('privado')));
  });
  test('HistoricoStatus: falha de consulta não expõe exceção técnica',
      () async {
    final controller =
        HistoricoStatusController(repositorio: HistoricoStatusComFalha());
    addTearDown(controller.dispose);
    await expectLater(controller.carregar(), throwsException);
    expect(controller.carregando, isFalse);
    expect(controller.erro, startsWith('Não foi possível'));
    expect(controller.erro, isNot(contains('SQLITE')));
    expect(controller.erro, isNot(contains('privado')));
  });
  test('Evidencia: falha de consulta não expõe exceção técnica', () async {
    final controller = EvidenciaController(repositorio: EvidenciaComFalha());
    addTearDown(controller.dispose);
    await expectLater(controller.carregar(), throwsException);
    expect(controller.carregando, isFalse);
    expect(controller.erro, startsWith('Não foi possível'));
    expect(controller.erro, isNot(contains('SQLITE')));
    expect(controller.erro, isNot(contains('privado')));
  });
}

# OS Manutenção

Autor: Thiago Benício Ribas. RU: 4391569.

Repositório: [os_manutencao_ui no GitHub](https://github.com/ThiagoBenicioRibas/os_manutencao_ui.git).

Aplicativo acadêmico Flutter para gerenciar ordens de serviço e manutenção técnica, com persistência local SQLite. A plataforma de trabalho e validação é Windows; os diretórios das demais plataformas não representam compatibilidade já testada.

## Funcionalidades

- Identificação local por nome, válida durante a sessão. Sair limpa a identificação. Não há senha, autenticação de identidade ou perfis de acesso.
- Cadastro, consulta, edição e exclusão de clientes, técnicos e equipamentos, com proteção dos vínculos pelo banco.
- Ordens com cliente/equipamento, técnico, prioridade, prazo, diagnóstico, solução e mão de obra.
- Busca por código, cliente, equipamento ou técnico; filtros por status, prioridade e responsável.
- Fluxo de status com histórico: Aberta, Atribuída, Em atendimento, Aguardando peça, Concluída e Cancelada.
- Peças e materiais com quantidade e valor unitário. Valores financeiros são inteiros em centavos.
- Seleção de arquivos de imagens, armazenamento local e gerenciamento de evidências.
- Dashboard com oito indicadores reais, distribuição pelos seis status e até três alertas de ordens pendentes.

## Executar no Windows

É necessário Flutter com suporte a desktop Windows, Dart compatível com o projeto e ferramentas C++ do Visual Studio para compilar. A auditoria utilizou Flutter 3.47.9 e Dart 3.13.7. As dependências e restrições estão em `pubspec.yaml` e `pubspec.lock`. O projeto já contém a pasta `windows`; não é necessário recriá-lo com `flutter create .`.

Na raiz do projeto, pelo PowerShell:

```powershell
flutter doctor -v
```

Confira se a ferramenta aponta pendências para Windows. Depois:

```powershell
flutter pub get
```

```powershell
flutter run -d windows
```

Informe seu nome, cadastre cliente e equipamento, abra uma OS e use os detalhes para alterar status, gerenciar materiais e fotografias. A primeira abertura cria o banco automaticamente; não há carga automática de dados demonstrativos.

## Dados e regras

`DatabaseService` abre `os_manutencao.db` no diretório de suporte do aplicativo obtido por `path_provider`. As imagens são copiadas para a subpasta `evidencias`, com caminhos relativos no banco. A localização concreta depende do ambiente. Para preservar dados, copie banco e imagens com o aplicativo fechado.

A edição comum não altera status nem data de conclusão. O fluxo de status registra o histórico em transação. Estados Atribuída, Em atendimento e Aguardando peça exigem técnico; sua remoção também é bloqueada na edição de uma OS concluída. Conclusão exige diagnóstico e solução, conforme a regra adotada pelo projeto. Edição concluída não pode apagar esses campos.

Equipamentos com OS vinculadas não podem mudar de cliente, inclusive quando a OS está encerrada. Sem OS, a troca é permitida. O equipamento da ordem deve pertencer ao cliente informado.

Atraso significa prazo anterior ao dia atual, excluindo concluídas/canceladas. No Dashboard, urgentes e valor registrado incluem todos os status; alertas mostram apenas pendentes. O valor registrado soma mão de obra e subtotais dos itens. Na falha de carga dos materiais, o resumo financeiro dos detalhes fica indisponível até nova tentativa bem-sucedida.

## Organização

- `lib/models`: entidades e conversão para registros do banco.
- `lib/repositories`: consultas, gravações e proteção de integridade.
- `lib/controllers`: estado observável com ChangeNotifier/Provider.
- `lib/services`: SQLite, evidências, regras de OS e cálculos do Dashboard.
- `lib/screens` e `lib/widgets`: telas e componentes acessíveis.
- `test`: testes unitários, de persistência e de interface.
- `docs`: requisitos, mapa das telas, guia e continuidade.

## Validação e entrega

Use testes pontuais durante mudanças, por exemplo:

```powershell
flutter test test/ordem_servico_repository_test.dart test/equipamento_repository_test.dart test/financeiro_regression_test.dart
```

No fechamento geral, executar separadamente:

```powershell
flutter test
```

```powershell
flutter analyze
```

```powershell
flutter build windows
```

Esses comandos de fechamento são instruções, não declaração de aprovação. Os resultados realmente obtidos estão em `docs/CONTINUIDADE.md`. Validar também teclado/NVDA, reabertura do aplicativo, alterações de status, filtros, financeiro e anexos.

## Limitações e pendências de entrega

- Identificação local não restringe permissões nem identifica o autor de cada alteração no histórico.
- Banco e imagens ficam neste computador, sem sincronização remota.
- A exclusão de uma OS remove registros dependentes no banco; a limpeza de arquivos físicos de evidências órfãos continua pendente.
- A distinção entre gravação confirmada e falha de recarga foi tratada no controlador de materiais; os demais fluxos ainda precisam dessa revisão geral.
- A entrega utiliza evidências textuais, por opção do aluno que usa NVDA; a ausência de prints será justificada diretamente ao professor.
- O repositório GitHub foi informado pelo autor. O envio dos commits ao remoto e a submissão acadêmica são etapas separadas do commit local de entrega.

A Etapa 8 está no commit `5ef7c58` e a Etapa 9 em `473d8e9`. A auditoria e os materiais acadêmicos integram o commit de entrega posterior à Etapa 9.

## Demonstração e evidências textuais

- [Roteiro de dez OS](docs/ROTEIRO_DEMONSTRACAO.md): cadastros fictícios, transições, valores esperados e conferência de persistência, sem apagar dados existentes.
- [Auditoria técnica](docs/AUDITORIA_TECNICA.md): resultados executados, cobertura e limites da verificação.
- [Texto do relatório acadêmico](docs/RELATORIO_FINAL_ACADEMICO.md): fonte textual do documento final, com identificação acadêmica e repositório.
- [Relatório final UNINTER em Word](docs/RELATORIO_FINAL_UNINTER.docx): documento acadêmico de entrega.
- [Continuidade](docs/CONTINUIDADE.md): estado atual e próximo passo.

Para reproduzir a verificação integrada em banco temporário, sem popular a base do aplicativo:

```powershell
flutter test test/auditoria_integracao_test.dart --reporter expanded
```

Para distribuir o executável, preserve toda a pasta `build/windows/x64/runner/Release`, incluindo DLLs e `data`; o arquivo EXE isolado não constitui a distribuição completa.

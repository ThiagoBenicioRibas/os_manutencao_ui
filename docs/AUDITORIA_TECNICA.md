# Auditoria técnica final

Data: 16/11/2026. Base: commit 473d8e9. Auditoria incorporada ao fechamento de entrega autorizado pelo autor; os resultados abaixo referem-se à execução de 16/11/2026.

## Conclusão

Análise estática, suíte completa e compilação limpa Windows aprovadas. O executável abriu em duas execuções com janela e processo respondendo, e aceitou fechamento normal entre elas. Nos cenários automatizados exercitados, não houve falhas. Isso não comprova ausência absoluta de defeitos nem substitui o roteiro manual completo com NVDA.

O pedido de não produzir prints foi respeitado. Não foram acrescentados comentários ao código da aplicação, nem modificados os arquivos de lib. Foram acrescentados dois testes de integração e documentação. A base de uso do usuário não foi populada ou alterada pela auditoria.

## Comandos e resultados executados

- flutter analyze: No issues found! Primeira execução em 127,3 segundos.
- flutter test --reporter expanded: 162 testes aprovados, zero falhas, aproximadamente 12 segundos de execução reportados pela suíte.
- flutter clean: removeu build, .dart_tool e artefatos efêmeros; terminou com sucesso.
- flutter build windows: sucesso após limpeza, 181,2 segundos; gerou build/windows/x64/runner/Release/os_manutencao_ui.exe.
- flutter analyze, repetido após as adições finais de testes/metadados: No issues found!, 7,3 segundos.
- Inicialização nativa: duas execuções em janela normal, cada uma observada por cinco segundos, Responding=True e identificador de janela não nulo. CloseMainWindow e WaitForExit concluíram nas duas. A propriedade ExitCode não forneceu valor nesse mecanismo; não se declara código de saída nativo zero. O comando de verificação concluiu com código zero.
- Logs de inicialização: apenas mensagem informativa do backend Impeller; nenhuma exceção registrada. Logs locais em build/auditoria_inicio_2.log, build/auditoria_erro_2.log e equivalentes com sufixo 3.
- A primeira tentativa em janela oculta iniciou o processo, mas CloseMainWindow não encontrou janela. Somente essa instância de teste foi encerrada antes das duas execuções normais. Essa limitação do método não foi ocultada nem contada como validação de fechamento.
- git diff --check: sem erros de whitespace; avisos de conversão LF/CRLF do Git no Windows.
- git remote -v: sem remoto configurado.
- pubspec.lock: sem alteração de versões. O resolvedor informou 13 pacotes com versões mais recentes fora das restrições; isso não impediu análise, testes ou build.
- Busca limitada por padrões de credenciais em lib, test, README, pubspec e guias não encontrou correspondências. Não constitui uma certificação geral de ausência de segredos.

Ambiente identificado no cache do SDK: Flutter 3.47.9 stable; Dart 3.13.7. Comandos Flutter precisaram de acesso fora do sandbox ao SDK/cache. Tentativas restritas sem progresso foram interrompidas, não contabilizadas como aprovadas.

## Integração verificada

### Interface e estado

main.dart fornece os controladores por MultiProvider. A identificação alterna login e AppShell. As telas consultam os controladores e tratam as falhas propagadas nos fluxos examinados. Ordens resolve nomes de clientes, equipamentos e técnicos a partir dos cadastros persistidos; a busca e os filtros são aplicados localmente.

O novo teste de widgets monta OrdersPage com controladores e repositórios reais conectados a arquivo SQLite temporário. Confirma dez resultados, pesquisa por código, cliente, equipamento e técnico, busca inexistente e filtro Concluída com dois resultados. Não é um teste de todos os formulários no Windows nativo. Filtros de prioridade/responsável foram inspecionados no código; o roteiro contém sua conferência manual.

Os testes existentes de interface cobrem identificação, foco obrigatório, entrada/saída e recuperação do financeiro após erro. Não foi executada nova sessão manual com NVDA nesta auditoria.

### CRUD e relacionamentos

Os testes existentes exercitam cadastro, leitura, atualização e exclusão em repositórios/controladores. A nova integração cria dez OS usando controladores reais, edita uma descrição, rejeita código duplicado e confirma bloqueio da exclusão de cliente, equipamento e técnico vinculados. Após excluir uma OS do banco temporário, seus materiais somem e as demais nove permanecem.

SQLite mantém foreign_keys ativado. A troca de cliente de equipamento com OS é protegida pelo repositório. A OS valida a associação equipamento/cliente. Operações destrutivas têm confirmação nas telas examinadas.

### Status e histórico

As regras permitem transições definidas entre seis estados. O repositório muda estado e registra histórico em transação. A edição comum rejeita mudança de status e preserva data de conclusão. Há testes para diagnóstico/solução, técnico, transições inválidas e rollback quando a gravação do histórico falha.

O conjunto integrado percorreu os seis estados e produziu 16 transições persistidas. Uma tentativa de concluir diretamente uma OS aberta foi rejeitada sem permitir o estado inválido.

### Financeiro e Dashboard

Materiais usam quantidade inteira e valor unitário em centavos. A tela soma materiais e mão de obra; DashboardService calcula os indicadores fora da UI. O Dashboard busca as listas completas e consulta ItemUtilizadoRepository diretamente para os materiais; portanto a aplicação não impõe passagem obrigatória de toda consulta por um Controller.

O teste integrado reabriu dez OS, cada uma com mão de obra de 100,00 e duas peças de 25,00. Total confirmado: 150.000 centavos, ou R$ 1.500,00. Confirmou distribuição 2/2/2/1/2/1 nos seis estados, uma urgente e uma atrasada na referência fixa do teste.

Os testes do serviço cobrem listas vazias, frações, atrasos, urgentes em estados finais, materiais e alertas. Os testes financeiros cobrem falhas de consulta, respostas atrasadas e gravação confirmada seguida de falha de recarga.

### Persistência e imagens

O teste integrado fecha a conexão e abre o mesmo arquivo por nova instância de DatabaseService. Confirma descrição editada, dez OS, materiais, estados e histórico. PRAGMA foreign_key_check retorna vazio; PRAGMA integrity_check retorna ok.

Os testes de armazenamento de imagens verificam cópia, recuperação após recriar o serviço, separação por OS, formatos/caminhos inválidos e exclusão. Testes de repositório verificam os registros de evidências e cascata. A seleção nativa de arquivo e abertura visual da imagem não foram exercitadas nesta auditoria.

A inicialização repetida do EXE não incluiu cadastro via interface. Não se deve alegar que os dez registros foram conferidos no aplicativo depois de fechá-lo: essa parte permanece no roteiro manual.

## Achados e limitações

1. Gravação seguida de falha de recarga: controladores de clientes, técnicos, equipamentos e OS mantêm operação e consulta no mesmo try/catch. Uma gravação pode estar confirmada e a interface informar falha genérica. Repetir um cadastro nessas condições pode duplicar dados. Materiais já distingue esse caso. Achado por inspeção; não houve injeção dessa falha nos fluxos nativos nesta sessão.
2. Abertura do banco: DatabaseService conserva a Future de abertura; se falhar, novas tentativas reutilizam a Future rejeitada. A recuperação sem reiniciar o processo precisa de revisão e teste específico.
3. Ciclo assíncrono: EvidenciaController é local à tela; não há cancelamento das consultas ao dispose. Sair durante uma consulta exige teste específico para descartar notificação após descarte. Risco identificado por inspeção, não falha reproduzida.
4. Validações de campos obrigatórios, prioridade e status inicial dependem parcialmente dos formulários. Os repositórios não são uma API de domínio totalmente validada para inserções arbitrárias. A carga demonstrativa deve seguir a interface/regras.
5. Excluir OS remove registros de imagens por cascata, mas pode deixar arquivos físicos órfãos. Identificação não autentica nem registra autor; não há sincronização; outras plataformas não foram validadas.
6. Na execução da auditoria não havia remoto GitHub configurado. Posteriormente, o autor informou a criação de https://github.com/ThiagoBenicioRibas/os_manutencao_ui.git; a URL foi incorporada aos materiais. A configuração do remoto e o push não fazem parte deste fechamento local. Os arquivos pessoais não rastreados, o enunciado, os PNGs antigos e o backup Dart foram preservados. Não utilizar git add . indiscriminadamente. O HTML local foi incluído no .gitignore conforme AGENTS.md.
7. Não foi verificada a existência de um protótipo publicável que satisfaça o entregável do enunciado. A ausência de prints será justificada pelo aluno; não foi assumida dispensa pelo professor.

Esses achados impedem certificar “sem falhas em qualquer situação”. Não foram feitas correções no código de produção nesta auditoria. As alterações de robustez devem ser avaliadas a partir desses cenários, sem confundir testes verdes com eliminação das limitações.

## Materiais preparados

- ROTEIRO_DEMONSTRACAO.md: dez OS reproduzíveis pela interface, cadastros fictícios, prazos relativos, valores e resultados esperados; verificação textual sem prints.
- RELATORIO_FINAL_ACADEMICO.md: fonte textual do DOCX, com Thiago Benício Ribas, RU 4391569 e URL do GitHub.
- README.md: ambiente verificado, links dos materiais, instruções e distribuição da pasta Release completa.
- pubspec.yaml: descrição atualizada para aplicativo persistente; dependências mantidas.
- test/auditoria_integracao_test.dart: dois novos testes de integração; sem dados permanentes na base do usuário.
- docs/relatorio_agente.html: relatório acessível para revisão local, excluído de commits.

## Revisão antes de publicação

O autor autorizou o commit dos arquivos revisados da auditoria e entrega. Os dados acadêmicos e a URL foram preenchidos e docs/RELATORIO_FINAL_UNINTER.docx foi gerado. O pacote ZIP/OOXML, o texto, os oito títulos de seção e os links foram conferidos. A renderização visual foi tentada com render_docx.py, mas falhou por ausência de LibreOffice (soffice.exe); a paginação ainda requer conferência no Word ou editor compatível. Permanecem as limitações técnicas registradas e o roteiro manual completo. Este fechamento não inclui push nem submissão.

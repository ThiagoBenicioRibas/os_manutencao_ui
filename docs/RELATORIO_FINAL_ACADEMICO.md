# Relatório final acadêmico

Sistema de Ordem de Serviço e Manutenção Técnica
Disciplina: Desenvolvimento Multiplataforma Desktop
Aluno: Thiago Benício Ribas
RU: 4391569
Professor: Rodrigo da S. do Nascimento
Ano: 2026
Repositório: https://github.com/ThiagoBenicioRibas/os_manutencao_ui.git

## Descrição e problema

O OS Manutenção é um aplicativo Flutter para gerenciar atendimentos de manutenção técnica. A solução reúne clientes, técnicos, equipamentos e ordens de serviço em uma interface desktop, substituindo registros dispersos em planilhas, papéis e mensagens. A versão foi desenvolvida e validada tecnicamente em Windows.

## Objetivos

O objetivo geral é permitir o acompanhamento de atendimentos desde a abertura até a conclusão ou cancelamento, com persistência local e indicadores operacionais.

Os objetivos específicos são cadastrar entidades relacionadas; consultar, editar e excluir registros quando permitido; atribuir responsáveis e prioridades; controlar prazos e evolução do atendimento; registrar diagnóstico e solução; calcular custos de materiais e mão de obra; associar imagens; pesquisar e filtrar ordens; e conservar os dados entre execuções.

## Tecnologias e arquitetura

A aplicação utiliza Dart e Flutter, componentes Material e organização em camadas. Models representam as entidades e convertem dados para registros SQLite. Screens e widgets compõem a interface. Controllers utilizam ChangeNotifier, disponibilizado por Provider, para comunicar estados de carregamento, dados e erros. Repositories centralizam acesso ao banco e proteções de integridade. Services oferecem abertura do banco, armazenamento de imagens, regras de status e cálculo dos indicadores.

O SQLite é acessado por sqflite_common_ffi. DatabaseService compartilha a conexão na aplicação e admite bancos separados nos testes. São sete tabelas: clientes, técnicos, equipamentos, ordens de serviço, itens utilizados, histórico de status e evidências. Chaves estrangeiras restringem exclusões incompatíveis e removem registros dependentes de OS em cascata. A mudança de status e seu histórico são gravados na mesma transação.

Repository é aplicado efetivamente à persistência, e a instância compartilhada do serviço de banco segue a ideia de Singleton. As transições são expressas por regras centralizadas; não se afirma implementação do padrão State com classes por estado.

## Funcionalidades implementadas

A identificação inicial exige um nome e mantém a sessão em memória. Não se trata de autenticação com senha nem de controle de permissões.

Clientes, técnicos e equipamentos possuem cadastro, consulta, edição e exclusão com proteção dos vínculos. As ordens associam cliente e equipamento, responsável, problema, prioridade, datas, diagnóstico, solução, observações e mão de obra. O código é gerado na abertura e possui restrição de unicidade no banco.

O fluxo inclui Aberta, Atribuída, Em atendimento, Aguardando peça, Concluída e Cancelada. A atribuição e o atendimento exigem técnico. A conclusão exige diagnóstico e solução. Estados finais não permitem novas transições; a edição não pode contornar essa regra.

Materiais registram descrição, quantidade inteira e valor unitário. Os valores são armazenados em centavos para evitar erros de representação monetária na soma. O total combina materiais e mão de obra.

A seleção de imagens utiliza arquivos locais. O aplicativo copia os arquivos para a pasta de suporte e registra caminhos relativos. Há consulta, visualização e exclusão de evidências.

A busca localiza ordens por código, cliente, equipamento e técnico. Os filtros abrangem status, prioridade e responsável. O Dashboard apresenta oito indicadores reais, distribuição pelos seis estados e até três alertas. Os cálculos ficam em serviço separado da tela.

## Metodologia de verificação e evidências textuais

A auditoria partiu do commit 473d8e9, que concluiu a Etapa 9, e acrescentou testes de integração em banco temporário. A revisão estática acompanhou a chamada das telas aos controladores, repositórios, serviços e SQLite, incluindo captura de falhas nos fluxos de interface examinados.

Em 16/11/2026, flutter analyze terminou com “No issues found!” e a suíte completa executada por flutter test --reporter expanded terminou com 162 testes aprovados e zero falhas. Os testes incluem CRUD, vínculos, regras, histórico transacional e rollback, materiais, mensagens, armazenamento de imagens, identificação e componentes da interface.

Os novos testes cadastraram dez OS por controladores e repositórios reais, verificaram exclusões protegidas, código duplicado, transição inválida, edição e total de R$ 1.500,00. Após fechar a conexão e abrir o mesmo arquivo por outra instância, foram recuperados os registros e 16 transições. PRAGMA foreign_key_check não apontou vínculos inválidos e PRAGMA integrity_check retornou “ok”. O teste da tela de ordens confirmou busca por código, cliente, equipamento e técnico, ausência de resultados e filtro de concluídas sem exceção de widgets observada.

Essas evidências comprovam os cenários automatizados executados. A reabertura do arquivo SQLite em teste não equivale à execução manual de todos os fluxos do executável desktop. A verificação final com NVDA e o roteiro de fechamento/reabertura do aplicativo devem ser registrados separadamente. Realizei e aprovei anteriormente a validação manual da Etapa 9 com teclado e NVDA, conforme o registro de continuidade.

Após flutter clean, flutter build windows gerou o executável Release com sucesso em 181,2 segundos. A análise final voltou a apresentar zero problemas. O executável iniciou duas vezes em janela normal, permaneceu respondendo e aceitou fechamento normal entre as execuções. Os logs registraram apenas a inicialização do backend gráfico Impeller. Esse teste de inicialização não incluiu operação dos formulários nem validação visual. Os detalhes e limites estão em AUDITORIA_TECNICA.md.

Por utilizar o leitor de tela NVDA, optei por apresentar evidências textuais e um roteiro reproduzível em lugar de capturas de tela. Justificarei essa opção diretamente ao professor. Essa decisão não pressupõe dispensa já concedida dos critérios visuais do enunciado.

## Dados de demonstração

O documento ROTEIRO_DEMONSTRACAO.md especifica três clientes, dois técnicos, três equipamentos e dez OS distribuídas entre seis estados e quatro prioridades, com prazos relativos ao dia da execução. Ele permite reproduzir os cadastros pela interface sem importação direta de SQL e descreve os totais esperados. Também fornece verificação automatizada isolada. O teste não instala dados na base de uso do aplicativo.

## Análise crítica

A separação de responsabilidades permitiu testar regras e persistência sem depender de interação visual. A evolução do protótipo para SQLite exigiu substituir dados demonstrativos por consultas reais e conservar a coerência entre formulário, estado compartilhado e banco.

Os principais desafios técnicos registrados foram proteger a alteração de status contra edição comum, preservar o vínculo entre cliente e equipamento, realizar histórico atomicamente e evitar totais antigos após falha de consulta. O uso de transações, restrições relacionais e testes de regressão tornou essas decisões verificáveis. O controlador de materiais também distingue gravação confirmada de falha na recarga posterior.

A versão possui limites. A identificação não autentica identidade nem registra autoria individual no histórico. Os dados permanecem locais, sem sincronização. Apenas Windows foi validado. A exclusão de uma OS remove os registros de evidência, mas não limpa automaticamente todos os arquivos físicos correspondentes. Nos demais controladores, gravação e recarga ainda compartilham tratamento de falha, podendo produzir mensagem ambígua quando apenas a recarga falha. A recuperação após falha na abertura inicial do banco e a navegação durante operações assíncronas merecem testes adicionais.

Algumas validações de entrada estão na interface e não são repetidas integralmente nos repositórios. A integração não deve ser confundida com uma API pública pronta para receber dados arbitrários. Os testes aprovados não demonstram ausência absoluta de falhas em todos os cenários de execução.

Como melhorias futuras, propõem-se tratamento uniforme de gravação/recarga e concorrência, limpeza segura de arquivos órfãos, recuperação da conexão após erro, validações de domínio centralizadas, testes desktop completos com NVDA e validação em outras plataformas. Autenticação, sincronização e exportação poderão ser avaliadas após essas melhorias de robustez.

## Materiais e reprodução

A entrega reúne código-fonte, pubspec.yaml e pubspec.lock, README, mapa das telas, guia técnico, roteiro demonstrativo e auditoria textual. O histórico Git local está preservado. O repositório do projeto é https://github.com/ThiagoBenicioRibas/os_manutencao_ui.git. A criação desse repositório foi informada após a auditoria técnica. O commit local e o envio dos arquivos ao GitHub são operações distintas.

O documento de entrega é RELATORIO_FINAL_UNINTER.docx. Antes da submissão, devem ser conferidos o acesso aos arquivos no repositório e os demais entregáveis solicitados, incluindo o protótipo. O enunciado aceita .doc ou .docx e informa que não é possível reenviar após a submissão.

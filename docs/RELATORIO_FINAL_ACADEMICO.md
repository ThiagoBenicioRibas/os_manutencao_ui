# Relatório Final — Sistema de Ordem de Serviço e Manutenção Técnica

**Disciplina:** Desenvolvimento Multiplataforma Desktop  
**Aluno:** Thiago Benício Ribas  
**RU:** 4391569  
**Professor:** Rodrigo da S. do Nascimento  
**Ano:** 2026  
**Repositório:** https://github.com/ThiagoBenicioRibas/os_manutencao_ui.git  

## 1. Descrição do Projeto e Problema Resolvido

O **OS Manutenção** é um aplicativo desktop desenvolvido em Flutter para gerenciar atendimentos de manutenção técnica. Em pequenas assistências e oficinas, o controle de chamados costuma ficar espalhado entre planilhas, anotações em papel e mensagens avulsas, o que dificulta saber quais equipamentos estão aguardando peça, quais prazos já venceram ou quanto foi cobrado em cada serviço.

Para resolver esse cenário, construí uma aplicação desktop com persistência local que centraliza o cadastro de clientes, técnicos e equipamentos, além de acompanhar todo o ciclo de vida das ordens de serviço (OS), desde a abertura até a conclusão ou o cancelamento. O desenvolvimento e os testes foram realizados em ambiente Windows.

## 2. Objetivos

O objetivo geral do trabalho foi construir um sistema funcional de controle de ordens de serviço com armazenamento local confiável e indicadores operacionais em tempo real.

Como objetivos específicos, busquei:
* Estruturar cadastros completos de clientes, técnicos e equipamentos com integridade entre os registros;
* Controlar o fluxo de atendimento por meio de estados bem definidos, prioridades e prazos;
* Registrar diagnóstico técnico, solução aplicada e histórico de movimentações;
* Calcular automaticamente o custo total de cada atendimento somando peças utilizadas e mão de obra;
* Permitir anexar imagens locais como evidências do serviço;
* Oferecer busca rápida, filtros combinados e um painel de indicadores (Dashboard) com os números reais da operação.

## 3. Tecnologias e Arquitetura

Desenvolvi a aplicação em **Dart** e **Flutter** (utilizando componentes Material) e organizei o código em camadas para separar a interface das regras de negócio e do acesso ao banco de dados:

* **Models:** representam as entidades do sistema e fazem a conversão entre objetos Dart e registros relacionais.
* **Repositories:** centralizam as consultas SQL, gravações e bloqueios de integridade.
* **Controllers:** gerenciam o estado das telas usando `ChangeNotifier` e `Provider`, notificando carregamentos, atualizações e mensagens de erro.
* **Services:** isolam a conexão com o banco, o armazenamento de imagens, a validação de transição entre status e os cálculos do Dashboard.
* **Screens e Widgets:** compõem a interface desktop com foco em navegação por teclado e semântica para leitores de tela.

Para a persistência, utilizei **SQLite** por meio do pacote `sqflite_common_ffi`. O `DatabaseService` mantém uma instância compartilhada da conexão durante o uso do aplicativo e permite abrir bancos isolados nos testes automatizados. O esquema conta com sete tabelas relacionais (`clientes`, `tecnicos`, `equipamentos`, `ordens_servico`, `itens_utilizados`, `historico_status` e `evidencias`) com chaves estrangeiras ativadas. Sempre que uma OS muda de status, a atualização da ordem e o registro no histórico acontecem dentro da mesma transação no banco.

## 4. Funcionalidades Implementadas

* **Identificação de Sessão:** Tela inicial onde o operador informa seu nome para iniciar o uso, mantendo a identificação ativa durante a sessão.
* **Cadastros com Proteção de Vínculos:** Inclusão, consulta, edição e exclusão de clientes, técnicos e equipamentos. O banco impede excluir registros que já estejam ligados a alguma ordem de serviço e bloqueia a troca de cliente em equipamentos que possuem histórico de atendimento.
* **Abertura e Edição de Ordens de Serviço:** Vinculação entre cliente, equipamento e técnico responsável, com geração automática de código único, nível de prioridade (`Baixa`, `Média`, `Alta` e `Urgente`), datas de abertura e prazo, descrição do problema e valor de mão de obra.
* **Fluxo de Estados e Histórico:** Controle das etapas `Aberta`, `Atribuída`, `Em atendimento`, `Aguardando peça`, `Concluída` e `Cancelada`. O sistema exige técnico atribuído antes de iniciar o atendimento e só permite concluir a OS quando diagnóstico e solução estiverem preenchidos. Após encerrada ou cancelada, a ordem não pode mais retroceder de estado.
* **Controle Financeiro:** Lançamento de peças e materiais com quantidade inteira e valor unitário armazenado em centavos — escolha feita para evitar imprecisões de arredondamento em ponto flutuante — somados automaticamente à mão de obra.
* **Evidências Fotográficas:** Seleção de arquivos de imagem locais (JPG, PNG ou WEBP), com cópia automática para o diretório de suporte do aplicativo e registro do caminho relativo no SQLite.
* **Busca, Filtros e Dashboard:** Pesquisa por código da OS, cliente, equipamento ou técnico, combinada com filtros por status, prioridade e responsável. A tela inicial exibe oito indicadores operacionais, a distribuição das ordens por status e até três alertas de pendências urgentes ou atrasadas.

## 5. Validação Técnica e Evidências de Funcionamento

Como sou usuário de leitor de tela (**NVDA**), conduzi toda a navegação e validação manual da interface pelo teclado, verificando a ordem de foco, os rótulos semânticos e o retorno sonoro dos formulários, mensagens de erro e confirmações. Por essa mesma razão de acessibilidade, optei por substituir capturas de tela (prints) por evidências técnicas reproduzíveis, testes automatizados de integração e um roteiro detalhado de demonstração na documentação do projeto.

Para garantir a estabilidade do sistema antes da entrega, executei a bateria completa de verificação técnica:
* **Análise Estática (`flutter analyze`):** Concluída sem nenhum erro ou alerta de código.
* **Suíte de Testes (`flutter test`):** **162 testes automatizados aprovados** sem falhas, cobrindo operações CRUD, bloqueios de exclusão, regras de transição de status, rollback de transações, cálculos financeiros em centavos, armazenamento de imagens e comportamento dos componentes de tela.
* **Teste de Integração Ponta a Ponta:** Criei uma suíte específica que simula o cadastro de 10 ordens de serviço passando pelos seis estados (totalizando 16 transições de histórico e R$ 1.500,00 em serviços e peças), fecha a conexão com o SQLite e reabre o arquivo em uma nova instância para comprovar a persistência e a integridade das chaves estrangeiras (`PRAGMA integrity_check` e `foreign_key_check`).
* **Compilação Desktop (`flutter build windows`):** Executável Release gerado do zero após limpeza do ambiente (`flutter clean`), abrindo e encerrando normalmente no Windows.

Na pasta `docs/` do repositório (`ROTEIRO_DEMONSTRACAO.md`), deixei um passo a passo completo com dados fictícios de clientes, técnicos, equipamentos e dez ordens de serviço para reproduzir todos os fluxos e indicadores diretamente na interface.

## 6. Análise Crítica, Limitações e Melhorias Futuras

Organizar o projeto em camadas desde o início facilitou bastante a evolução do protótipo inicial para o banco SQLite, permitindo validar as regras de negócio de forma isolada antes de conectá-las às telas. Os maiores desafios técnicos durante o desenvolvimento foram garantir que a tela de edição comum não permitisse burlar o fluxo de status, impedir a alteração de dono em equipamentos com histórico e manter o resumo financeiro consistente mesmo quando ocorre falha de consulta no banco.

Ao mesmo tempo, reconheço algumas limitações importantes nesta versão acadêmica:
1. **Controle de Acesso:** A identificação inicial serve apenas para registrar o operador na sessão, sem autenticação por senha, perfis de permissão ou gravação do autor em cada linha do histórico.
2. **Armazenamento Local:** Os dados e imagens ficam restritos à máquina onde o aplicativo roda, sem sincronização em nuvem.
3. **Limpeza de Arquivos Físicos:** Ao excluir uma ordem de serviço, o banco remove os registros de evidências em cascata, mas o arquivo físico da imagem pode permanecer na pasta de suporte.
4. **Tratamento de Recarga nos Controladores:** No módulo de materiais, já tratei separadamente a falha de gravação e a falha de recarga da lista; nos demais cadastros, ambas ainda compartilham o mesmo bloco de tratamento de erro.
5. **Escopo de Plataforma:** Embora a estrutura do Flutter seja multiplataforma, a validação prática foi concentrada no desktop Windows.

Como próximos passos para evoluir o sistema, pretendo unificar o tratamento de recarga nos controladores, implementar uma rotina de limpeza segura para arquivos de imagem órfãos, adicionar autenticação com níveis de acesso e validar a execução em Linux e macOS.

## 7. Materiais Entregues no Repositório

Todo o código-fonte, arquivos de configuração (`pubspec.yaml` e `pubspec.lock`), suíte de testes e documentação técnica estão disponíveis com histórico completo de commits no GitHub:

* **Repositório:** https://github.com/ThiagoBenicioRibas/os_manutencao_ui.git
* **Documentação de Apoio (pasta `docs/`):** Roteiro reproduzível de demonstração (`ROTEIRO_DEMONSTRACAO.md`), mapa das telas (`MAPA_TELAS.md`) e guia técnico de implementação (`GUIA_IMPLEMENTACAO.md`).
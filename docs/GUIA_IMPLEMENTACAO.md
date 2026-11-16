# Guia de implementação e manutenção

## Estado do sistema

As camadas reais de modelos, SQLite, repositórios, controladores, cadastros, ordens, status, materiais e evidências estão implementadas. A Etapa 8 integrou Dashboard e identificação local. Não use a numeração deste documento como cronograma oficial do professor: `docs/enunciado.docx` é a referência de requisitos, e `docs/CONTINUIDADE.md` registra a etapa atual.

## Fluxo e responsabilidades

1. A tela inicial valida um nome e inicia uma sessão em memória por `IdentificacaoController`; `main.dart` alterna a tela inicial e o aplicativo. Sair encerra essa sessão.
2. Telas usam controladores ChangeNotifier disponibilizados por Provider; repositórios acessam `DatabaseService`.
3. Repositórios protegem vínculos de cliente/equipamento e executam alterações sensíveis em transações.
4. `OrdemServicoRepository.atualizar` é edição comum: rejeita status diferente do persistido, conserva data de conclusão e exige técnico/dados de conclusão conforme o estado. A mudança de status deve usar `alterarStatus`, que valida o fluxo e grava histórico atomicamente.
5. `EquipamentoRepository.atualizar` impede trocar cliente enquanto houver qualquer OS vinculada. Outros dados continuam editáveis.
6. Materiais pertencem à OS e usam quantidades inteiras, valores unitários e totais em centavos. `ItemUtilizadoController` limpa dados ao recarregar e ignora consultas antigas; erro de consulta deixa os dados indisponíveis. Gravação confirmada seguida de falha de recarga gera mensagem específica, sem pedir que a gravação seja repetida.
7. Evidências usam repositório e serviço de cópia para a pasta local; seleção de arquivos é feita pela tela. Não há promessa de captura por câmera nesta versão.
8. `DashboardService` centraliza indicadores, frações e seleção de alertas; atraso reutiliza `RegrasOrdemServico.estaAtrasada`. A tela consulta listas completas e trata carga/erro.

## Regras e interface

- Ordens novas começam abertas; status posterior é alterado nos detalhes.
- Atribuição e atendimento exigem técnico. Conclusão exige diagnóstico e solução. Concluída e Cancelada não possuem próximas transições.
- Valores monetários permanecem inteiros em centavos, inclusive na soma de materiais e mão de obra.
- O formulário registra mão de obra. Após salvar, Financeiro e Evidências nos detalhes gerenciam materiais e fotografias; não há botões demonstrativos para essas operações no formulário.
- Não exibir exceções técnicas diretamente nas mensagens dos controladores. Mensagens devem indicar o que falhou e orientar nova tentativa ou conferência dos dados.
- Manter rótulos, foco de teclado, tooltip e Semantics. Validar com NVDA após mudanças de interface.

## Trabalho restante

A Etapa 9 está concluída no commit `473d8e9`. Consulte `AUDITORIA_TECNICA.md` para os resultados da auditoria final, `ROTEIRO_DEMONSTRACAO.md` para reproduzir dez OS e `RELATORIO_FINAL_ACADEMICO.md` para o texto de entrega. As evidências serão textuais; o aluno justificará diretamente ao professor a ausência de prints em razão do uso do NVDA. Limpeza de arquivos órfãos e revisão de falha de recarga após gravação nos demais controladores continuam como limitações registradas. A continuidade discrimina o que ainda aguarda revisão.

O arquivo `lib/core/mock_data.dart` é legado do protótipo, não a fonte do Dashboard real. Comentários antigos não substituem inspeção do código. Não recriar funcionalidades concluídas com base em antigos TODOs.

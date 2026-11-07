# Guia para implementação futura das funcionalidades

A interface foi deixada propositalmente sem lógica de negócio. Os pontos de integração estão marcados com `TODO(FUNCIONALIDADE)`.

## Ordem sugerida de implementação

1. Criar os modelos em `lib/models/`: Cliente, Tecnico, Equipamento, OrdemServico, ItemUtilizado e HistoricoStatus.
2. Criar a persistência em `lib/services/` e `lib/repositories/`.
3. Criar controladores, providers ou viewmodels em `lib/controllers/`.
4. Substituir os dados de `lib/core/mock_data.dart` por dados reais vindos dos controladores.
5. Conectar os formulários aos métodos de cadastro e edição.
6. Implementar exclusão com confirmação.
7. Implementar busca e filtros da lista de OS.
8. Implementar regras de status: Aberta, Atribuída, Em atendimento, Aguardando peça, Concluída e Cancelada.
9. Implementar regras de prioridade e atraso.
10. Implementar cálculo de peças, materiais, mão de obra e total.
11. Implementar seleção/captura de imagens.
12. Implementar autenticação ou identificação local.

## Convenções de comentários

- `TODO(FUNCIONALIDADE)`: ponto que precisa receber lógica real.
- `UI APENAS`: trecho usado somente para composição visual.
- `DADO MOCKADO`: informação fictícia para preencher a tela.

## Observação sobre navegação

A navegação entre as telas está ativa para facilitar a inspeção da interface. Ela não autentica usuários, não salva registros e não aplica regras de negócio.

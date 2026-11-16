# Mapa das telas do sistema

## Identificação e navegação

- `lib/screens/auth/login_screen.dart`: nome obrigatório, entrada por Enter/botão, validação e foco. Sem senha ou acesso demonstrativo.
- `lib/screens/app_shell.dart`: navegação lateral ou drawer conforme largura; nome da sessão, ajuda e Sair.

## Dashboard

`lib/screens/dashboard/dashboard_page.dart`: total de OS, abertas, em atendimento, aguardando peça, concluídas, urgentes, atrasadas e valor registrado. Distribuição inclui também Atribuída e Cancelada. Até três alertas de ordens pendentes. Cálculos em `DashboardService`, dados dos controladores/repositórios; carga, erro e nova tentativa na tela.

## Ordens

- `lib/screens/orders/orders_page.dart`: listagem real, busca por código/cliente/equipamento/técnico e filtros de status, prioridade e responsável.
- `lib/screens/orders/order_form_page.dart`: cliente, equipamento, técnico, problema, prioridade, datas, diagnóstico, solução, observações e mão de obra. Edição preserva o status; materiais e imagens são gerenciados nos detalhes após salvar.
- `lib/screens/orders/order_details_page.dart`: abas Resumo, Serviço, Financeiro, Evidências e Histórico. Permite editar, alterar status pelo fluxo válido e excluir com confirmação.
- Aba Financeiro: itens e resumo de mão de obra, materiais e total. Se a consulta falhar, materiais/total ficam indisponíveis e há nova tentativa; valores antigos não são tratados como atuais.
- `lib/screens/orders/order_items_page.dart`: adicionar, editar e excluir peças/materiais com quantidade e valor unitário.
- `lib/screens/orders/order_evidences_page.dart`: selecionar arquivo, listar, visualizar e excluir fotografias.
- Aba Histórico: eventos persistidos de transição de status.

## Cadastros

- `lib/screens/clients/clients_page.dart` e `client_form_page.dart`: listagem, cadastro, edição e exclusão de clientes; identificação, telefone, e-mail e endereço.
- `lib/screens/technicians/technicians_page.dart` e `technician_form_page.dart`: técnicos com contato, especialidade e situação.
- `lib/screens/equipment/equipment_page.dart` e `equipment_form_page.dart`: cliente, tipo, marca, modelo, série, patrimônio e observações. Cliente não pode ser trocado quando há OS vinculada.

## Acessibilidade e persistência

As telas usam componentes Material, rótulos, botões identificados e elementos semânticos. Dashboard e identificação foram aprovados manualmente com teclado/NVDA na Etapa 8. A validação das alterações posteriores deve ser registrada separadamente.

Os registros usam SQLite e as fotografias ficam no diretório de suporte do aplicativo. Sessão de identificação é apenas em memória. A plataforma de validação é Windows. Consulte README e CONTINUIDADE para execução, testes e limitações; este mapa descreve a implementação, não comprova validação de todos os fluxos.

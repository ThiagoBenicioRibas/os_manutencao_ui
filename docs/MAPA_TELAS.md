# Mapa das telas e dos requisitos visuais

## Acesso
- `lib/screens/auth/login_screen.dart`
- Campos de identificação e senha.
- Botão Entrar sem autenticação implementada.
- Botão separado para visualizar o protótipo.

## Estrutura principal
- `lib/screens/app_shell.dart`
- NavigationRail em desktop e NavigationDrawer em telas menores.
- Dashboard, Ordens de serviço, Clientes, Técnicos e Equipamentos.

## Dashboard
- `lib/screens/dashboard/dashboard_page.dart`
- Total de ordens.
- Abertas.
- Em atendimento.
- Aguardando peça.
- Concluídas.
- Urgentes.
- Atrasadas.
- Valor registrado.
- Distribuição visual por status e ordens que exigem atenção.

## Ordens de serviço
- `lib/screens/orders/orders_page.dart`
- Busca por texto.
- Filtros de status, prioridade e técnico.
- Cards com código, cliente, equipamento, técnico, prazo, status, prioridade, total e evidências.

## Nova OS / Editar OS
- `lib/screens/orders/order_form_page.dart`
- Cliente e equipamento.
- Técnico responsável.
- Descrição do problema.
- Prioridade.
- Status.
- Datas.
- Diagnóstico.
- Solução.
- Mão de obra.
- Peças/materiais.
- Total visual.
- Evidências.

## Detalhes da OS
- `lib/screens/orders/order_details_page.dart`
- Resumo.
- Serviço.
- Financeiro.
- Evidências.
- Histórico.
- Confirmação visual de exclusão.

## Clientes
- `lib/screens/clients/clients_page.dart`
- `lib/screens/clients/client_form_page.dart`
- Nome/razão social, CPF/CNPJ/identificação, telefone, e-mail e endereço.

## Técnicos
- `lib/screens/technicians/technicians_page.dart`
- `lib/screens/technicians/technician_form_page.dart`
- Nome, contato, especialidade e situação.

## Equipamentos
- `lib/screens/equipment/equipment_page.dart`
- `lib/screens/equipment/equipment_form_page.dart`
- Cliente, tipo, marca, modelo, série, patrimônio e observações.

## Funcionalidades não implementadas
Todos os pontos onde a lógica deve ser criada estão marcados por `TODO(FUNCIONALIDADE)`.

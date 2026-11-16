# Roteiro reproduzível de demonstração

## Preparação

Use Windows com Flutter 3.47.9 e Dart 3.13.7 (versões verificadas nesta auditoria), suporte desktop e ferramentas C++ do Visual Studio. Abra o PowerShell na raiz do projeto. Execute um comando por vez:

1. `flutter doctor -v` — conferir suporte Windows.
2. `flutter pub get` — resolver dependências usando pubspec.lock.
3. `flutter run -d windows` — abrir a identificação.

O aplicativo cria as sete tabelas SQLite automaticamente. Não há carga automática de demonstração. O roteiro abaixo popula pela interface e preserva as regras do sistema. Não apague uma base existente. Para obter exatamente os totais propostos, use uma instalação/perfil de Windows sem dados anteriores; em base existente, os indicadores globais também incluirão os outros registros.

Os dados são fictícios. Registre os códigos gerados pela aplicação junto aos apelidos D01 a D10 abaixo: os apelidos são referências do roteiro, não códigos digitáveis.

## Cadastros

Crie três clientes, com identificação, telefone, e-mail e endereço:
- Oficina Aurora; DEMO-C1; 41999990001; aurora@example.com; Rua Exemplo, 10.
- Mercado Horizonte; DEMO-C2; 41999990002; horizonte@example.com; Rua Exemplo, 20.
- Escola Ipê; DEMO-C3; 41999990003; ipe@example.com; Rua Exemplo, 30.

Crie dois técnicos ativos:
- Ana Técnica; 41999990004; Informática.
- Bruno Técnico; 41999990005; Climatização.

Crie três equipamentos:
- E1: Oficina Aurora; Notebook; marca Exemplo; modelo Alfa; série DEMO-E1; patrimônio P1.
- E2: Mercado Horizonte; Ar-condicionado; marca Exemplo; modelo Beta; série DEMO-E2; patrimônio P2.
- E3: Escola Ipê; Computador; marca Exemplo; modelo Gama; série DEMO-E3; patrimônio P3.

## Dez ordens de serviço

D é a data em que o roteiro é executado. Use abertura D menos 7 dias para todas. Os prazos abaixo são relativos a D; isso mantém a demonstração de atraso reproduzível em qualquer dia.

Em cada OS: informe o cliente do equipamento, o técnico indicado, problema iniciando pelo apelido D01–D10 e mão de obra de 100,00. Salve, anote o código gerado e, em Financeiro, adicione “Peça de demonstração”, quantidade 2, valor unitário 25,00. Resultado por OS: materiais 50,00; mão de obra 100,00; total 150,00.

1. D01: E1, Ana, Urgente, prazo D menos 1; problema “D01 Não liga”; manter Aberta.
2. D02: E2, Bruno, Baixa, prazo D mais 7; problema “D02 Ruído”; manter Aberta.
3. D03: E3, Ana, Média, prazo D mais 7; problema “D03 Lentidão”; alterar Aberta para Atribuída.
4. D04: E1, Ana, Alta, prazo D mais 7; problema “D04 Aquecimento”; alterar Aberta para Atribuída.
5. D05: E2, Bruno, Urgente, prazo D menos 1; problema “D05 Não refrigera”; alterar Aberta para Atribuída e Em atendimento.
6. D06: E3, Ana, Média, prazo D mais 7; problema “D06 Reinicia”; alterar Aberta para Atribuída e Em atendimento.
7. D07: E2, Bruno, Alta, prazo D mais 7; problema “D07 Ventilador parado”; alterar Aberta para Atribuída, Em atendimento e Aguardando peça.
8. D08: E1, Ana, Baixa, prazo D menos 1; problema “D08 Falha de memória”; preencher diagnóstico “Módulo de memória defeituoso” e solução “Módulo substituído e funcionamento conferido”; alterar Aberta para Atribuída, Em atendimento e Concluída.
9. D09: E3, Ana, Média, prazo D menos 1; problema “D09 Falha de fonte”; diagnóstico “Fonte defeituosa”, solução “Fonte substituída e funcionamento conferido”; alterar Aberta para Atribuída, Em atendimento e Concluída.
10. D10: E2, Bruno, Alta, prazo D menos 1; problema “D10 Atendimento dispensado”; alterar Aberta para Cancelada.

Para verificar o requisito de anexos, associe uma imagem local JPG/PNG/WEBP a D08 em Evidências, com descrição “Imagem de teste do atendimento D08”. Não é necessário produzir print. A seleção de arquivo é uma funcionalidade do aplicativo e pode ser verificada pelo professor. A ausência de prints no relatório será justificada diretamente pelo aluno ao professor.

## Resultados esperados no mesmo dia

Em base contendo somente este conjunto: total 10; abertas 2; atribuídas 2; em atendimento 2; aguardando peça 1; concluídas 2; canceladas 1; urgentes 2; atrasadas 2; valor registrado R$ 1.500,00.

Urgentes e valor registrado incluem todos os status. Concluídas/canceladas não contam como atrasadas. O valor registrado não representa receita recebida. Prazos relativos mudam a contagem de atrasadas se a demonstração for repetida dias depois.

## Verificação funcional sem prints

1. Buscar pelo código anotado de D01: uma OS. Limpar. Buscar Oficina Aurora: três. Buscar Alfa: três. Buscar Ana Técnica: seis.
2. Filtrar Concluída: duas. Limpar. Filtrar Urgente: duas. Combinar Urgente com Em atendimento: uma. Filtrar responsável Bruno, sem outros filtros: quatro.
3. Editar a descrição de D02 e reabrir detalhes: mudança preservada.
4. Em D01, verificar que Concluída não aparece como próxima transição. Em D06, tentar concluir sem diagnóstico/solução: rejeição compreensível e status preservado.
5. Tentar excluir cliente, técnico e equipamento vinculados: operação bloqueada. Cancelar a confirmação também deve preservar o registro.
6. Em D02, editar a quantidade do material de 2 para 3: total 175,00 e Dashboard 1.525,00. Restaurar para 2: totais 150,00 e 1.500,00.
7. Criar uma OS adicional para demonstrar exclusão confirmada. Excluir somente essa OS; as dez de demonstração permanecem.
8. Fechar o aplicativo inteiro e abrir novamente. Identificar-se novamente. Conferir dez OS, edição de D02, estados finais, 16 transições no conjunto, financeiro e imagem de D08 quando adicionada.
9. Registrar resultado textual: data, código da OS, ação, valor esperado, valor observado e aprovado/falhou. Não marcar este roteiro manual como executado com base apenas nos testes automatizados.

## Reprodução automatizada da auditoria

Na raiz, execute `flutter test test/auditoria_integracao_test.dart --reporter expanded`.

Os dois testes criam dez OS em banco temporário isolado, exercitam controladores/repositórios reais, estados, restrições, edição, financeiro, integridade SQLite e reabertura. O teste de widgets monta a tela real de ordens e verifica buscas e filtro de status. Ao terminar, removem apenas seus dados temporários. Não populam o banco do aplicativo.

O conjunto automatizado é específico: um cliente/equipamento/técnico, uma urgente, uma atrasada na referência fixa de 10/01/2026 e total de R$ 1.500,00. Não confundir seus indicadores com os do roteiro manual acima.

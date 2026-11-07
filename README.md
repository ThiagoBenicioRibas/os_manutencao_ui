# OS Manutenção — somente interface gráfica

Este projeto contém **somente a camada visual** de um aplicativo Flutter para gerenciamento de ordens de serviço e manutenção técnica.

A interface foi preparada para representar os requisitos visuais do trabalho acadêmico: acesso inicial, dashboard, clientes, técnicos, equipamentos, listagem e filtros de ordens de serviço, formulário de OS, detalhes da OS, diagnóstico, solução, financeiro, evidências e histórico.

## Importante

- Não há banco de dados.
- Não há autenticação real.
- Não há CRUD real.
- Não há cálculo financeiro real.
- Não há seleção/captura de imagens.
- Não há regras de transição de status.
- Busca e filtros não alteram os dados exibidos.
- Os dados mostrados são **mockados** apenas para preencher a interface.
- A navegação entre telas existe somente para permitir a visualização do protótipo.

## Como localizar os pontos de implementação

Pesquise no projeto por:

```text
TODO(FUNCIONALIDADE)
```

Cada ocorrência indica explicitamente onde a lógica deverá ser implementada depois.

## Estrutura

```text
lib/
  core/          tema e dados mockados de interface
  screens/       telas visuais
  widgets/       componentes visuais reutilizáveis
  models/        reservado para os modelos de domínio reais
  services/      reservado para banco, imagens e integrações
  repositories/  reservado para acesso e persistência
  controllers/   reservado para estado e regras da interface
```

## Acessibilidade para quem continuará o desenvolvimento

O código usa nomes descritivos, widgets padrão do Material, textos visíveis em ações importantes, `Semantics` em indicadores e `tooltip` nos botões de ícone. Isso ajuda tanto usuários de leitores de tela quanto o desenvolvedor que navegará pelo projeto com tecnologia assistiva.

## Executando

Como este pacote foi montado sem os wrappers nativos de plataforma, em uma máquina com Flutter instalado execute na raiz do projeto:

```bash
flutter create .
flutter pub get
flutter run
```

O comando `flutter create .` preserva a pasta `lib/` e gera Android, iOS, web e plataformas desktop disponíveis no ambiente.

Leia também `docs/GUIA_IMPLEMENTACAO.md`.

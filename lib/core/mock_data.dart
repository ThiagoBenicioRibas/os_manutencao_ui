// Dados fictícios usados exclusivamente para preencher a interface.
//
// DADO MOCKADO: não substitui os modelos reais do domínio. Quando a camada de
// funcionalidades for implementada, este arquivo pode ser removido.

class MockOrderData {
  const MockOrderData({
    required this.code,
    required this.client,
    required this.equipment,
    required this.technician,
    required this.status,
    required this.priority,
    required this.deadline,
    required this.totalValue,
    this.laborValue = 0.0,
    this.partsValue = 0.0,
    required this.problem,
    required this.diagnosis,
    required this.solution,
    this.isLate = false,
    this.hasEvidence = false,
  });

  final String code;
  final String client;
  final String equipment;
  final String technician;
  final String status;
  final String priority;
  final String deadline;
  final double totalValue;
  final double laborValue;
  final double partsValue;
  final String problem;
  final String diagnosis;
  final String solution;
  final bool isLate;
  final bool hasEvidence;
}

class MockEntityData {
  const MockEntityData({
    required this.title,
    required this.subtitle,
    required this.details,
    this.status,
  });

  final String title;
  final String subtitle;
  final String details;
  final String? status;
}

class MockData {
  MockData._();

  static const orders = <MockOrderData>[
    MockOrderData(
      code: 'OS-2026-0010',
      client: 'Clínica Horizonte',
      equipment: 'Ar-condicionado Split 24.000 BTU',
      technician: 'Carlos Almeida',
      status: 'Em atendimento',
      priority: 'Urgente',
      deadline: '19/08/2026',
      totalValue: 780.00,
      laborValue: 300.00,
      partsValue: 480.00,
      problem: 'Equipamento liga, mas não refrigera adequadamente.',
      diagnosis: 'Baixa pressão no circuito e possível vazamento na linha.',
      solution: 'Aguardando conclusão do teste de estanqueidade.',
      isLate: true,
      hasEvidence: true,
    ),
    MockOrderData(
      code: 'OS-2026-0009',
      client: 'Escritório Delta',
      equipment: 'Notebook Lenovo ThinkPad E14',
      technician: 'Fernanda Souza',
      status: 'Aguardando peça',
      priority: 'Alta',
      deadline: '22/08/2026',
      totalValue: 520.00,
      laborValue: 180.00,
      partsValue: 340.00,
      problem: 'Notebook desliga durante uso intenso.',
      diagnosis: 'Sistema de refrigeração com ventoinha danificada.',
      solution: 'Substituição da ventoinha pendente.',
      hasEvidence: true,
    ),
    MockOrderData(
      code: 'OS-2026-0008',
      client: 'Padaria Avenida',
      equipment: 'Freezer horizontal Metalfrio',
      technician: 'Carlos Almeida',
      status: 'Atribuída',
      priority: 'Média',
      deadline: '25/08/2026',
      totalValue: 180.00,
      laborValue: 180.00,
      partsValue: 0.00,
      problem: 'Ruído excessivo na unidade condensadora.',
      diagnosis: 'Ainda não informado.',
      solution: 'Ainda não informada.',
    ),
    MockOrderData(
      code: 'OS-2026-0007',
      client: 'Condomínio Jardim Sul',
      equipment: 'Bomba d’água Schneider',
      technician: 'Rafael Martins',
      status: 'Concluída',
      priority: 'Alta',
      deadline: '16/08/2026',
      totalValue: 940.00,
      laborValue: 350.00,
      partsValue: 590.00,
      problem: 'Bomba não pressurizava a rede.',
      diagnosis: 'Selo mecânico e rolamento com desgaste.',
      solution: 'Selo e rolamento substituídos; sistema testado.',
      hasEvidence: true,
    ),
    MockOrderData(
      code: 'OS-2026-0006',
      client: 'Mercado Central',
      equipment: 'Impressora térmica Elgin',
      technician: 'Fernanda Souza',
      status: 'Aberta',
      priority: 'Baixa',
      deadline: '29/08/2026',
      totalValue: 0.00,
      laborValue: 0.00,
      partsValue: 0.00,
      problem: 'Falha intermitente na impressão de cupons.',
      diagnosis: 'Ainda não informado.',
      solution: 'Ainda não informada.',
    ),
    MockOrderData(
      code: 'OS-2026-0005',
      client: 'Academia Movimento',
      equipment: 'Esteira Movement RT250',
      technician: 'Rafael Martins',
      status: 'Cancelada',
      priority: 'Média',
      deadline: '18/08/2026',
      totalValue: 120.00,
      laborValue: 120.00,
      partsValue: 0.00,
      problem: 'Correia apresenta trancos durante o funcionamento.',
      diagnosis: 'Avaliação preliminar realizada.',
      solution: 'Atendimento cancelado pelo cliente.',
    ),
    MockOrderData(
      code: 'OS-2026-0004',
      client: 'Clínica Horizonte',
      equipment: 'Autoclave Cristófoli',
      technician: 'Fernanda Souza',
      status: 'Concluída',
      priority: 'Média',
      deadline: '14/08/2026',
      totalValue: 650.00,
      laborValue: 260.00,
      partsValue: 390.00,
      problem: 'Ciclo de esterilização interrompido antes da pressurização.',
      diagnosis: 'Sensor de temperatura apresentava leitura instável.',
      solution: 'Sensor substituído e ciclo completo testado.',
      hasEvidence: true,
    ),
    MockOrderData(
      code: 'OS-2026-0003',
      client: 'Escritório Delta',
      equipment: 'Nobreak SMS 1500 VA',
      technician: 'Fernanda Souza',
      status: 'Aguardando peça',
      priority: 'Urgente',
      deadline: '20/08/2026',
      totalValue: 410.00,
      laborValue: 150.00,
      partsValue: 260.00,
      problem: 'Nobreak não mantém os computadores ligados durante queda de energia.',
      diagnosis: 'Banco de baterias com capacidade abaixo do limite.',
      solution: 'Aguardando conjunto de baterias para substituição.',
      hasEvidence: true,
    ),
    MockOrderData(
      code: 'OS-2026-0002',
      client: 'Padaria Avenida',
      equipment: 'Forno turbo Progás',
      technician: 'Rafael Martins',
      status: 'Em atendimento',
      priority: 'Alta',
      deadline: '21/08/2026',
      totalValue: 360.00,
      laborValue: 220.00,
      partsValue: 140.00,
      problem: 'Temperatura oscila durante o processo de assamento.',
      diagnosis: 'Termostato em avaliação.',
      solution: 'Teste de estabilidade térmica em andamento.',
    ),
    MockOrderData(
      code: 'OS-2026-0001',
      client: 'Condomínio Jardim Sul',
      equipment: 'Portão eletrônico PPA',
      technician: 'Carlos Almeida',
      status: 'Aberta',
      priority: 'Baixa',
      deadline: '31/08/2026',
      totalValue: 0.00,
      laborValue: 0.00,
      partsValue: 0.00,
      problem: 'Portão apresenta lentidão no fechamento.',
      diagnosis: 'Ainda não informado.',
      solution: 'Ainda não informada.',
    ),
  ];

  static const clients = <MockEntityData>[
    MockEntityData(
      title: 'Clínica Horizonte',
      subtitle: 'CNPJ 12.345.678/0001-90 • (41) 3333-1100',
      details: 'contato@clinicahorizonte.com.br • Curitiba/PR',
    ),
    MockEntityData(
      title: 'Escritório Delta',
      subtitle: 'CNPJ 23.456.789/0001-10 • (41) 3333-2200',
      details: 'suporte@delta.com.br • Curitiba/PR',
    ),
    MockEntityData(
      title: 'Padaria Avenida',
      subtitle: 'CNPJ 34.567.890/0001-20 • (41) 3333-3300',
      details: 'gerencia@padariaavenida.com.br • São José dos Pinhais/PR',
    ),
    MockEntityData(
      title: 'Condomínio Jardim Sul',
      subtitle: 'CNPJ 45.678.901/0001-30 • (41) 3333-4400',
      details: 'sindico@jardimsul.com.br • Curitiba/PR',
    ),
  ];

  static const technicians = <MockEntityData>[
    MockEntityData(
      title: 'Carlos Almeida',
      subtitle: '(41) 99911-2211 • carlos@assistencia.com',
      details: 'Especialidade: climatização e refrigeração',
      status: 'Ativo',
    ),
    MockEntityData(
      title: 'Fernanda Souza',
      subtitle: '(41) 99922-3322 • fernanda@assistencia.com',
      details: 'Especialidade: informática e eletrônica',
      status: 'Ativo',
    ),
    MockEntityData(
      title: 'Rafael Martins',
      subtitle: '(41) 99933-4433 • rafael@assistencia.com',
      details: 'Especialidade: elétrica e mecânica',
      status: 'Ativo',
    ),
  ];

  static const equipments = <MockEntityData>[
    MockEntityData(
      title: 'Ar-condicionado Split 24.000 BTU',
      subtitle: 'Clínica Horizonte • LG Dual Inverter',
      details: 'Série: LG24-998712 • Patrimônio: CL-AR-04',
    ),
    MockEntityData(
      title: 'Notebook Lenovo ThinkPad E14',
      subtitle: 'Escritório Delta • Lenovo',
      details: 'Série: PF4A1234 • Patrimônio: DEL-NB-18',
    ),
    MockEntityData(
      title: 'Freezer horizontal Metalfrio',
      subtitle: 'Padaria Avenida • Metalfrio DA550',
      details: 'Série: MF-552010 • Patrimônio: PAD-FR-02',
    ),
    MockEntityData(
      title: 'Bomba d’água Schneider',
      subtitle: 'Condomínio Jardim Sul • Schneider BC-98',
      details: 'Série: SC-881020 • Patrimônio: CJS-BM-01',
    ),
  ];
}

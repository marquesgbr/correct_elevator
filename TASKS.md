
## Ordem de implementação

Ordem obtida por ordenação topológica do grafo de dependências (`A → B` = `A
INCLUDES/SEES B`, logo `B` deve estar pronto antes de `A`). Máquinas do mesmo
nível não dependem entre si e podem ser feitas em paralelo.

```
L0: CabinCapacity | CabinState | ElevatorPanels
L1: CabinDoor | ElevatorRequests
L2: ElevatorMaintenance | RequestService
L3: ElevatorIndicators
L4: ElevatorTimers
L5: ElevatorControl
```


### Nível -1 - Máquina de refinamento de contexto
**ElevatorContext** - Máquina que será usada para colocar os SETS, CONSTANTS e PROPERTIES que será refinada e implementada para que possamos garantir que existem valores que satisfazem às propriedades. Fica no -1 porque não necessariamente vais ser feita "antes" de qualquer outra coisa, mas vai ser atualizada pouco a pouco à medida que formos criando as máquinas


### Nível 0 — máquinas sem dependências
**CabinState.mch** — estado da cabine (HLR-001/003)
- [ ] `VARIABLES`: pavimento atual, direção, condição de movimento
- [ ] `INVARIANT`: pavimento atual ∈ `FLOORS`; direção coerente com o movimento
- [ ] `INVARIANT`: sentido de deslocamento consistente com os limites do prédio
  (não subir no último pavimento, não descer no primeiro)
- [ ] `OPERATIONS`: mover para cima, mover para baixo, parar em um pavimento
- [ ] `OPERATIONS` (consulta): pavimento atual, direção, está parada?

**ElevatorPanels.mch** — painéis, botões e LEDs (HLR-002/004)
- [ ] `VARIABLES`: botões de pavimento do painel interno, botões
  subir/descer externos, botões abrir/fechar imediatamente, estado dos LEDs
- [ ] `INVARIANT`: painel externo do último pavimento só tem botão descer e o do
  primeiro só tem botão subir (HLR-002)
- [ ] `INVARIANT`: LED aceso ⇔ pedido correspondente ativo (HLR-004)
- [ ] `OPERATIONS`: pressionar/soltar botão, acender LED, apagar LED, piscar LED
  duas vezes, apagar todos os LEDs

**CabinCapacity.mch** — capacidade e excesso de peso (HLR-009)
- [ ] `VARIABLES`: peso atual, indicador de excesso de peso
- [ ] `INVARIANT`: excesso de peso ⇔ peso atual > capacidade máxima
- [ ] `OPERATIONS`: embarque/desembarque (atualização do peso)
- [ ] `OPERATIONS` (consulta): há excesso de peso? / pode se mover?
- [ ] Não referenciar `CabinState`: a proibição de movimento é imposta pelo
  `ElevatorControl` (evita dependência invertida)

### Nível 1 — dispositivos e pedidos

**CabinDoor.mch** — porta da cabine (HLR-003)
- [ ] Depende de: `CabinState`, `ElevatorPanels`
- [ ] `VARIABLES`: estado da porta (aberta/fechando/fechada/abrindo), comandos
  imediatos
- [ ] `INVARIANT`: comando de abrir/fechar imediato só tem efeito se a cabine não
  estiver em movimento (HLR-003)
- [ ] `OPERATIONS`: abrir automaticamente, fechar automaticamente, abrir
  imediatamente, fechar imediatamente
- [ ] `OPERATIONS` (consulta): porta aberta? / porta fechada? / tempo de porta
  aberta expirado?

**ElevatorRequests.mch** — pedidos internos e externos (HLR-004/005/006)
- [ ] Depende de: `ElevatorPanels`
- [ ] `VARIABLES`: pedidos de pavimento internos, chamadas externas de
  subir/descer
- [ ] `INVARIANT`: todo pedido ativo tem o LED correspondente aceso (HLR-004)
- [ ] `OPERATIONS`: registrar pedido a partir de botão pressionado
- [ ] `OPERATIONS`: atender pedido (apaga o LED) e cancelar pedido (apaga o LED)
- [ ] `OPERATIONS`: cancelar por retenção de botão (3 s) com a exceção do
  HLR-005 — último botão de pavimento do painel interno não pode ser cancelado,
  LED pisca duas vezes e continua aceso
- [ ] `OPERATIONS`: botões abrir/fechar imediatamente não são canceláveis (HLR-005)
- [ ] `OPERATIONS` (consulta): há pedidos ativos? / há pedidos na direção atual?
- [ ] Não referenciar `ElevatorMaintenance`: o bloqueio durante a manutenção é
  imposto pelo `ElevatorControl` (evita ciclo)

### Nível 2 — manutenção e estratégia de atendimento

**ElevatorMaintenance.mch** — modo manutenção (HLR-008)
- [ ] Depende de: `CabinState`, `ElevatorPanels`, `ElevatorRequests`
- [ ] `VARIABLES`: chave inserida, modo de manutenção
- [ ] `INVARIANT`: em manutenção ⇒ nenhum pedido ativo
- [ ] `INVARIANT`: em manutenção ⇒ painéis internos e externos inoperantes
- [ ] `OPERATIONS`: inserir chave; entrar em manutenção somente quando a cabine
  parar (ou se já estiver parada), cancelando todos os pedidos ativos
- [ ] `OPERATIONS`: remover chave e sair da manutenção
- [ ] `OPERATIONS`: acionamento de botão durante manutenção → LED pisca duas
  vezes e permanece apagado (HLR-008)

**RequestService.mch** — seleção e atendimento dos pedidos (HLR-006/010)
- [ ] Depende de: `CabinState`, `ElevatorRequests`
- [ ] `VARIABLES`: pedido em atendimento, direção de varredura
- [ ] `INVARIANT`: pedido selecionado sempre é um pedido ativo
- [ ] `OPERATIONS`: selecionar próximo pedido priorizando o mesmo sentido de
  movimento (varredura tipo SCAN)
- [ ] `OPERATIONS`: parar no próximo pavimento, na direção atual, quando o
  último pedido for cancelado em movimento (HLR-006)
- [ ] Provar justiça: todo pedido ativo é eventualmente atendido (HLR-010)
- [ ] Provar minimização do deslocamento acumulado da cabine (HLR-010)

### Nível 3 — visores

**ElevatorIndicators.mch** — visores internos e externos (HLR-001/003/007/008/009)
- [ ] Depende de: `CabinState`, `CabinCapacity`, `ElevatorMaintenance`
- [ ] `VARIABLES`: visor interno (pavimento, direção, excesso de peso,
  manutenção) e visores externos por pavimento (pavimento, direção,
  parado/quebrado, manutenção)
- [ ] `INVARIANT`: pavimento e direção exibidos = estado real da cabine (HLR-001/003)
- [ ] `INVARIANT`: símbolo de excesso de peso aceso ⇔ excesso de peso (HLR-009)
- [ ] `INVARIANT`: aviso de manutenção aceso ⇔ modo manutenção (HLR-008)
- [ ] `OPERATIONS`: atualizar pavimento/direção nos visores
- [ ] `OPERATIONS`: exibir/apagar excesso de peso e aviso de manutenção
- [ ] `OPERATIONS`: exibir/apagar símbolo de elevador parado/quebrado (HLR-007,
  acionado pelo `ElevatorTimers`)

### Nível 4 — temporizações

**ElevatorTimers.mch** — temporizações do sistema (HLR-005/007)
- [ ] Depende de: `ElevatorPanels`, `CabinDoor`, `ElevatorIndicators`
- [ ] `VARIABLES`: temporizador de retenção por botão, temporizador de porta
  aberta, temporizador de sinalização
- [ ] `INVARIANT`: temporizadores sempre ≥ 0 e limitados ao seu limite
- [ ] `OPERATIONS`: `tick` (avanço do relógio), iniciar/parar cada temporizador
- [ ] `OPERATIONS`: expiração da retenção de 3 s → pedido cancelado (HLR-005)
- [ ] `OPERATIONS`: expiração dos 2 min de porta aberta → símbolo de elevador
  parado/quebrado nos visores externos (HLR-007)
- [ ] `OPERATIONS`: sequência de piscar o LED duas vezes

### Nível 5 — integração

**ElevatorControl.mch** — máquina principal de coordenação
- [ ] Depende de: todas as anteriores
- [ ] `INCLUDES`/`SEES`: estado da cabine, pedidos, porta, painéis, indicadores,
  manutenção, capacidade, temporizadores e estratégia de atendimento
- [ ] `INVARIANT` global: excesso de peso ⇒ cabine não se move (HLR-009)
- [ ] `INVARIANT` global: cabine em movimento ⇒ porta fechada (HLR-003)
- [ ] `INVARIANT` global: manutenção ⇒ cabine parada e painéis inoperantes (HLR-008)
- [ ] `OPERATIONS`: pressionar botão (interno/externo) respeitando manutenção e
  encaminhando ao registro de pedidos
- [ ] `OPERATIONS`: ciclo de movimento — selecionar pedido, mover, parar,
  abrir/fechar porta, atender pedido, atualizar visores
- [ ] `OPERATIONS`: abrir/fechar imediatamente a porta (somente com a cabine parada)
- [ ] Rodar as obrigações de prova (Atelier B / ProB) e descarregar todas as POs

### Rastreabilidade das obrigações de prova

- [ ] HLR-001, HLR-003 → `CabinState`, `ElevatorIndicators`
- [ ] HLR-002, HLR-004 → `ElevatorPanels`
- [ ] HLR-005 → `ElevatorRequests`, `ElevatorTimers`
- [ ] HLR-006 → `RequestService`
- [ ] HLR-007 → `ElevatorIndicators`, `ElevatorTimers`
- [ ] HLR-008 → `ElevatorMaintenance`
- [ ] HLR-009 → `CabinCapacity`
- [ ] HLR-010 → `RequestService`

# Correct Elevator

Este projeto especifica um sistema de controle de elevador usando métodos formais.

## Máquinas abstratas

Os arquivos das máquinas abstratas estão em
[abstract_machines](./abstract_machines).

- **ElevatorControl.mch** — máquina principal de coordenação do sistema. Deve
  integrar o estado da cabine, os pedidos, a porta, os indicadores, a manutenção
  e as restrições de capacidade.
- **CabinState.mch** — deve representar o estado da cabine, incluindo o
  pavimento atual e a direção ou condição de movimento.
- **ElevatorRequests.mch** — deve controlar os pedidos originados nos painéis
  internos e externos, incluindo sua ativação, atendimento e cancelamento.
- **ElevatorPanels.mch** — deve representar os painéis internos e externos,
  seus botões, acionamentos e estados dos LEDs associados.
- **CabinDoor.mch** — deve representar o estado e os comandos da porta da
  cabine, incluindo abertura, fechamento e os comandos imediatos.
- **ElevatorIndicators.mch** — deve controlar as informações exibidas nos
  visores internos e externos, como pavimento, direção, manutenção, excesso de
  peso e elevador parado ou quebrado.
- **ElevatorMaintenance.mch** — deve representar a entrada e a saída do modo de
  manutenção, o uso da chave especial, o cancelamento dos pedidos e a
  indisponibilidade dos painéis durante a manutenção.
- **CabinCapacity.mch** — deve representar a capacidade de peso da cabine,
  detectar excesso de peso e impedir o movimento quando o limite for excedido.
- **ElevatorTimers.mch** — deve controlar as temporizações relevantes
  do sistema, como o cancelamento por retenção de botão, o tempo de porta aberta
  e as sinalizações temporizadas.
- **RequestService.mch** — deve representar a estratégia de seleção e
  atendimento dos pedidos, garantindo justiça e minimização do deslocamento
  acumulado da cabine.

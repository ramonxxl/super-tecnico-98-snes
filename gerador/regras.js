// Tabelas de regras do jogo (usadas pelo build e pelo simulador de calibracao).
// Todas as contas do assembly usam estas tabelas com aritmetica inteira.
'use strict';

// valor de mercado (R$ mil) por forca 0..50
const VALOR = Array.from({ length: 51 }, (_, f) => f === 0 ? 0 : Math.round(15 * Math.pow(1.135, f)));
// salario por rodada (R$ mil) por forca
const SALARIO = VALOR.map((v, f) => f === 0 ? 0 : Math.max(1, Math.round(v / 45)));

// chance de gol por minuto (em 1/4096) pelo indice r = 64 * ataque*2 / defesa (0..255)
const QGOL = Array.from({ length: 256 }, (_, r) => Math.max(6, Math.min(250, Math.round(44 * Math.pow(Math.max(r, 1) / 64, 2.6)))));

// tabela de jogos (metodo do circulo): 15 rodadas x 8 jogos [mandante, visitante] (posicoes 0..15)
function tabelaJogos() {
  const rounds = [];
  for (let r = 0; r < 15; r++) {
    const jogos = [];
    for (let i = 0; i < 8; i++) {
      let a, b;
      if (i === 0) { a = 15; b = r; if (r % 2 === 1) [a, b] = [b, a]; }
      else { a = (r + i) % 15; b = (r + 15 - i) % 15; if (i % 2 === 0) [a, b] = [b, a]; }
      jogos.push([a, b]);
    }
    rounds.push(jogos);
  }
  return rounds;
}

// por divisao A,B,C,D
const DIV = {
  cotaTV: [1250, 380, 120, 45],          // R$ mil por rodada
  publico: [22000, 11000, 5000, 2500], // publico base
  ingresso: [40, 25, 15, 10],          // preco de referencia (R$)
  caixa: [15000, 4000, 1200, 400],     // caixa inicial (R$ mil)
  base: [30, 21, 14, 8],               // forca base dos garotos da base
  premio: [9000, 2500, 800, 250],      // premio do campeao (R$ mil); cai com a posicao
};

// calendario: 42 datas; 1 = data de copa (ida e volta de cada fase depois destas rodadas)
const COPA_DEPOIS = [2, 4, 7, 9, 12, 14, 17, 19, 22, 24, 27, 29];
const CALENDARIO = [];
for (let r = 1; r <= 30; r++) { CALENDARIO.push(0); if (COPA_DEPOIS.includes(r)) CALENDARIO.push(1); }
// premio da copa (R$ mil) por passar de cada fase (a ultima = campeao)
const PREMIO_COPA = [150, 300, 600, 1200, 2500, 6000];
// emprestimo maximo por serie (R$ mil)
const EMPRESTIMO = [20000, 6000, 2000, 800];

// eventos por minuto (1/4096)
const EVT = { amarelo: 120, vermelho: 4, lesao: 9 };

module.exports = { VALOR, SALARIO, QGOL, tabelaJogos, DIV, EVT, CALENDARIO, PREMIO_COPA, EMPRESTIMO };
